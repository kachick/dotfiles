package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const (
	portStart          = 2221
	portEnd            = 2320
	bootTimeoutSeconds = 30
	hostReposPath      = "/home/kachick/repos/github.com/kachick"
)

var validNamePattern = regexp.MustCompile(`^[a-zA-Z0-9._-]+$`)

const usageText = `Usage:
  microvm-sandbox console
  microvm-sandbox up [--plain] [--mount <DIR>] <NAME>
  microvm-sandbox exec <NAME> -- <COMMAND...>
  microvm-sandbox ssh [NAME]
  microvm-sandbox status
  microvm-sandbox down <NAME>|--all
`

type upOptions struct {
	name     string
	plain    bool
	mountDir string
}

type patchOptions struct {
	name     string
	port     int
	stateDir string
	plain    bool
	mountDir string
}

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			os.Exit(exitErr.ExitCode())
		}
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		_, _ = io.WriteString(stderr, usageText)
		return errors.New("missing subcommand")
	}

	subcommand := args[0]
	rest := args[1:]

	switch subcommand {
	case "-h", "--help", "help":
		_, err := io.WriteString(stdout, usageText)
		return err
	case "console":
		return cmdConsole(rest)
	case "up":
		return cmdUp(rest, stdout, stderr)
	case "exec":
		return cmdExec(rest)
	case "ssh":
		return cmdSSH(rest)
	case "status":
		return cmdStatus(stdout)
	case "down":
		return cmdDown(rest, stdout)
	default:
		_, _ = io.WriteString(stderr, usageText)
		return fmt.Errorf("unknown subcommand: %s", subcommand)
	}
}

func microvmRunPath() (string, error) {
	p := os.Getenv("MICROVM_RUN")
	if p == "" {
		return "", errors.New("MICROVM_RUN is not set or not executable")
	}
	info, err := os.Stat(p)
	if err != nil || info.IsDir() || info.Mode()&0o111 == 0 {
		return "", errors.New("MICROVM_RUN is not set or not executable")
	}
	return p, nil
}

func stateRoot() string {
	if rt := os.Getenv("XDG_RUNTIME_DIR"); rt != "" {
		return filepath.Join(rt, "microvm-sandbox")
	}
	return filepath.Join(fmt.Sprintf("/run/user/%d", os.Getuid()), "microvm-sandbox")
}

func stateDirFor(root, name string) string {
	return filepath.Join(root, name)
}

func validateName(name string) error {
	if !validNamePattern.MatchString(name) {
		return fmt.Errorf("invalid instance name: %s", name)
	}
	return nil
}

func validateMountPath(dir string) (string, error) {
	absDir, err := filepath.Abs(dir)
	if err != nil {
		return "", fmt.Errorf("resolve mount path %q: %w", dir, err)
	}
	if strings.ContainsAny(absDir, "',\r\n") {
		return "", fmt.Errorf("mount path contains unsupported characters: %q", absDir)
	}
	info, err := os.Stat(absDir)
	if err != nil {
		return "", fmt.Errorf("stat mount path %q: %w", absDir, err)
	}
	if !info.IsDir() {
		return "", fmt.Errorf("mount path is not a directory: %q", absDir)
	}
	return absDir, nil
}

func readPID(pidFile string) (int, bool) {
	data, err := os.ReadFile(pidFile)
	if err != nil {
		return 0, false
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil || pid <= 0 {
		return 0, false
	}
	return pid, true
}

func isRunning(pidFile string) bool {
	pid, ok := readPID(pidFile)
	if !ok {
		return false
	}
	err := syscall.Kill(pid, 0)
	return err == nil || errors.Is(err, syscall.EPERM)
}

func portInUse(root string, port int) bool {
	ln, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	if err != nil {
		return true
	}
	_ = ln.Close()

	entries, err := os.ReadDir(root)
	if err != nil {
		return false
	}
	portStr := strconv.Itoa(port)
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		dir := filepath.Join(root, entry.Name())
		data, err := os.ReadFile(filepath.Join(dir, "ssh.port"))
		if err != nil {
			continue
		}
		if strings.TrimSpace(string(data)) == portStr && isRunning(filepath.Join(dir, "qemu.pid")) {
			return true
		}
	}
	return false
}

func findFreePort(root string) (int, error) {
	for port := portStart; port <= portEnd; port++ {
		if !portInUse(root, port) {
			return port, nil
		}
	}
	return 0, fmt.Errorf("no free local port in %d-%d", portStart, portEnd)
}

// Disable ControlMaster so restarted instances reusing a port never hit stale sockets.
func sshBaseArgs(port int) []string {
	return []string{
		"-o", "StrictHostKeyChecking=no",
		"-o", "UserKnownHostsFile=/dev/null",
		"-o", "LogLevel=ERROR",
		"-o", "ControlMaster=no",
		"-o", "ControlPath=none",
		"-o", "PasswordAuthentication=no",
		"-o", "ConnectTimeout=5",
		"-p", strconv.Itoa(port),
	}
}

// Build an RFC 1123 hostname accepted by systemd.hostname=.
func guestHostname(name string) string {
	const (
		prefix = "sandbox-"
		maxLen = 63
	)
	var labels []string
	for part := range strings.SplitSeq(name, ".") {
		part = strings.ReplaceAll(part, "_", "-")
		part = strings.Trim(part, "-")
		if part != "" {
			labels = append(labels, part)
		}
	}
	if len(labels) == 0 {
		return "sandbox"
	}
	host := prefix + strings.Join(labels, ".")
	if len(host) > maxLen {
		host = strings.TrimRight(host[:maxLen], "-.")
	}
	return host
}

func patchRunnerContent(src string, opts patchOptions) (string, error) {
	requiredTokens := []string{
		"-name sandbox",
		"-chardev 'stdio,id=stdio,signal=off'",
		"-serial chardev:stdio",
		"-append '",
		"-netdev 'user,id=net0'",
	}

	usePlain := opts.plain || opts.mountDir != ""
	reposFsdevToken := fmt.Sprintf("-fsdev 'local,id=fs2,path=%s,security_model=none,readonly=false'", hostReposPath)
	reposDeviceToken := "-device 'virtio-9p-pci,fsdev=fs2,mount_tag=repos'"

	if usePlain {
		requiredTokens = append(requiredTokens, reposFsdevToken, reposDeviceToken)
	}

	for _, token := range requiredTokens {
		if !strings.Contains(src, token) {
			return "", fmt.Errorf("unexpected microvm-run format; missing token: %s", token)
		}
	}

	out := src
	out = strings.Replace(out, "-name sandbox", fmt.Sprintf("-name 'sandbox-%s'", opts.name), 1)
	out = strings.Replace(out, "-chardev 'stdio,id=stdio,signal=off'", "", 1)
	out = strings.Replace(
		out,
		"-serial chardev:stdio",
		fmt.Sprintf("-serial 'file:%s/console.log' -daemonize -pidfile '%s/qemu.pid'", opts.stateDir, opts.stateDir),
		1,
	)
	// systemd.hostname= overrides static /etc/hostname during early boot without rebuilding the NixOS image.
	out = strings.Replace(
		out,
		"-append '",
		fmt.Sprintf("-append 'systemd.hostname=%s ", guestHostname(opts.name)),
		1,
	)
	out = strings.Replace(
		out,
		"-netdev 'user,id=net0'",
		fmt.Sprintf("-netdev 'user,id=net0,hostfwd=tcp:127.0.0.1:%d-:22'", opts.port),
		1,
	)

	if usePlain {
		emptyDir := filepath.Join(opts.stateDir, "empty")
		if strings.ContainsAny(emptyDir, "',\r\n") {
			return "", fmt.Errorf("state dir contains unsupported characters: %q", emptyDir)
		}
		out = strings.Replace(
			out,
			reposFsdevToken,
			fmt.Sprintf("-fsdev 'local,id=fs2,path=%s,security_model=none,readonly=true'", emptyDir),
			1,
		)
		if opts.mountDir != "" {
			if strings.ContainsAny(opts.mountDir, "',\r\n") {
				return "", fmt.Errorf("mount path contains unsupported characters: %q", opts.mountDir)
			}
			workspaceShare := fmt.Sprintf(
				" -fsdev 'local,id=fs_workspace,path=%s,security_model=none,readonly=false' -device 'virtio-9p-pci,fsdev=fs_workspace,mount_tag=workspace'",
				opts.mountDir,
			)
			out = strings.Replace(out, reposDeviceToken, reposDeviceToken+workspaceShare, 1)
		}
	}

	return out, nil
}

func parseUpArgs(args []string) (upOptions, error) {
	fs := flag.NewFlagSet("up", flag.ContinueOnError)
	fs.SetOutput(io.Discard)

	var opts upOptions
	fs.BoolVar(&opts.plain, "plain", false, "disable default host repos mount")
	fs.StringVar(&opts.mountDir, "mount", "", "host directory to mount at /home/user/workspace (implies --plain)")

	if err := fs.Parse(args); err != nil {
		return upOptions{}, err
	}
	if fs.NArg() == 0 {
		return upOptions{}, errors.New("missing instance name")
	}
	if fs.NArg() > 1 {
		return upOptions{}, fmt.Errorf("unexpected arguments: %s", strings.Join(fs.Args()[1:], " "))
	}

	opts.name = fs.Arg(0)
	if err := validateName(opts.name); err != nil {
		return upOptions{}, err
	}
	if opts.mountDir != "" {
		opts.plain = true
	}
	return opts, nil
}

func parseExecArgs(args []string) (string, []string, error) {
	if len(args) == 0 || args[0] == "--" {
		return "", nil, errors.New("missing instance name")
	}

	name := args[0]
	if len(args) < 2 || args[1] != "--" {
		return "", nil, errors.New("expected '--' before command")
	}
	cmd := args[2:]

	if len(cmd) == 0 {
		return "", nil, errors.New("missing command after '--'")
	}
	if err := validateName(name); err != nil {
		return "", nil, err
	}
	return name, cmd, nil
}

func cmdConsole(args []string) error {
	runPath, err := microvmRunPath()
	if err != nil {
		return err
	}
	argv := append([]string{runPath}, args...)
	return syscall.Exec(runPath, argv, os.Environ())
}

func cmdUp(args []string, stdout, stderr io.Writer) error {
	runPath, err := microvmRunPath()
	if err != nil {
		return err
	}

	opts, err := parseUpArgs(args)
	if err != nil {
		return err
	}

	if opts.mountDir != "" {
		absDir, err := validateMountPath(opts.mountDir)
		if err != nil {
			return err
		}
		opts.mountDir = absDir
	}

	root := stateRoot()
	stateDir := stateDirFor(root, opts.name)
	pidFile := filepath.Join(stateDir, "qemu.pid")
	portFile := filepath.Join(stateDir, "ssh.port")

	if isRunning(pidFile) {
		pid, _ := readPID(pidFile)
		portStr := "unknown"
		if data, err := os.ReadFile(portFile); err == nil {
			portStr = strings.TrimSpace(string(data))
		}
		_, err := fmt.Fprintf(stdout, "already running %s (pid=%d, port=%s)\n", opts.name, pid, portStr)
		return err
	}

	_ = os.RemoveAll(stateDir)
	if err := os.MkdirAll(stateDir, 0o755); err != nil {
		return err
	}

	if opts.plain {
		emptyDir := filepath.Join(stateDir, "empty")
		if err := os.Mkdir(emptyDir, 0o555); err != nil {
			_ = os.RemoveAll(stateDir)
			return err
		}
	}

	port, err := findFreePort(root)
	if err != nil {
		_ = os.RemoveAll(stateDir)
		return err
	}
	if err := os.WriteFile(portFile, []byte(fmt.Sprintf("%d\n", port)), 0o644); err != nil {
		_ = os.RemoveAll(stateDir)
		return err
	}

	rawRunner, err := os.ReadFile(runPath)
	if err != nil {
		_ = os.RemoveAll(stateDir)
		return err
	}

	patched, err := patchRunnerContent(string(rawRunner), patchOptions{
		name:     opts.name,
		port:     port,
		stateDir: stateDir,
		plain:    opts.plain,
		mountDir: opts.mountDir,
	})
	if err != nil {
		_ = os.RemoveAll(stateDir)
		return err
	}

	patchedRunner := filepath.Join(stateDir, "microvm-run")
	if err := os.WriteFile(patchedRunner, []byte(patched), 0o755); err != nil {
		_ = os.RemoveAll(stateDir)
		return err
	}

	startCmd := exec.Command(patchedRunner)
	startCmd.Stdout = stdout
	startCmd.Stderr = stderr
	if err := startCmd.Run(); err != nil {
		_ = os.RemoveAll(stateDir)
		return err
	}

	// Probe the SSH banner instead of running ssh BatchMode auth so `up` succeeds
	// before a passphrase-protected key is loaded into ssh-agent and never triggers
	// sshd failed-auth rate limits.
	addr := fmt.Sprintf("127.0.0.1:%d", port)
	for range bootTimeoutSeconds {
		if !isRunning(pidFile) {
			printConsoleTail(filepath.Join(stateDir, "console.log"), stderr)
			_ = os.RemoveAll(stateDir)
			return fmt.Errorf("instance '%s' exited during boot", opts.name)
		}
		if probeSSHBanner(addr, 2*time.Second) {
			pid, _ := readPID(pidFile)
			_, err := fmt.Fprintf(stdout, "started %s (pid=%d, port=%d)\n", opts.name, pid, port)
			return err
		}
		time.Sleep(time.Second)
	}

	return fmt.Errorf("timed out waiting for SSH on %s (127.0.0.1:%d); check %s/console.log", opts.name, port, stateDir)
}

func probeSSHBanner(addr string, timeout time.Duration) bool {
	conn, err := net.DialTimeout("tcp", addr, timeout)
	if err != nil {
		return false
	}
	defer func() {
		_ = conn.Close()
	}()
	_ = conn.SetReadDeadline(time.Now().Add(timeout))
	line, err := bufio.NewReader(conn).ReadString('\n')
	if err != nil {
		return false
	}
	return strings.HasPrefix(line, "SSH-")
}

func printConsoleTail(path string, w io.Writer) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	lines := strings.Split(strings.TrimRight(string(data), "\n"), "\n")
	if len(lines) > 20 {
		lines = lines[len(lines)-20:]
	}
	_, _ = io.WriteString(w, strings.Join(lines, "\n")+"\n")
}

func requireRunningPort(root, name string) (int, error) {
	stateDir := stateDirFor(root, name)
	if !isRunning(filepath.Join(stateDir, "qemu.pid")) {
		return 0, fmt.Errorf("instance '%s' is not running", name)
	}
	data, err := os.ReadFile(filepath.Join(stateDir, "ssh.port"))
	if err != nil {
		return 0, fmt.Errorf("missing ssh.port for instance '%s'", name)
	}
	port, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil || port <= 0 {
		return 0, fmt.Errorf("invalid ssh.port for instance '%s'", name)
	}
	return port, nil
}

func cmdExec(args []string) error {
	name, cmdArgs, err := parseExecArgs(args)
	if err != nil {
		return err
	}
	port, err := requireRunningPort(stateRoot(), name)
	if err != nil {
		return err
	}
	sshBin, err := exec.LookPath("ssh")
	if err != nil {
		return err
	}
	argv := append([]string{"ssh"}, sshBaseArgs(port)...)
	argv = append(argv, "-o", "BatchMode=yes", "user@127.0.0.1", "--")
	argv = append(argv, cmdArgs...)
	return syscall.Exec(sshBin, argv, os.Environ())
}

type instanceInfo struct {
	name    string
	running bool
	pid     int
	port    int
}

func listInstances(root string) ([]instanceInfo, error) {
	entries, err := os.ReadDir(root)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, nil
		}
		return nil, err
	}

	var instances []instanceInfo
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		name := entry.Name()
		dir := filepath.Join(root, name)
		inst := instanceInfo{name: name}
		if data, err := os.ReadFile(filepath.Join(dir, "ssh.port")); err == nil {
			if port, err := strconv.Atoi(strings.TrimSpace(string(data))); err == nil && port > 0 {
				inst.port = port
			}
		}
		pidFile := filepath.Join(dir, "qemu.pid")
		if isRunning(pidFile) {
			inst.running = true
			if pid, ok := readPID(pidFile); ok {
				inst.pid = pid
			}
		}
		instances = append(instances, inst)
	}
	return instances, nil
}

func listRunningInstances(root string) ([]instanceInfo, error) {
	all, err := listInstances(root)
	if err != nil {
		return nil, err
	}
	var running []instanceInfo
	for _, inst := range all {
		if inst.running && inst.port > 0 {
			running = append(running, inst)
		}
	}
	return running, nil
}

func pickInstanceWithFzf(instances []instanceInfo, fzfBin string) (string, error) {
	if len(instances) == 0 {
		return "", errors.New("no running microvm-sandbox instances")
	}

	var input strings.Builder
	for _, inst := range instances {
		fmt.Fprintf(&input, "%-20s %-10d %d\n", inst.name, inst.pid, inst.port)
	}

	header := fmt.Sprintf("%-20s %-10s %s", "NAME", "PID", "PORT")
	cmd := exec.Command(fzfBin, "--reverse", "--prompt", "ssh> ", "--header", header)
	cmd.Stdin = strings.NewReader(input.String())
	cmd.Stderr = os.Stderr

	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	fields := strings.Fields(strings.TrimSpace(string(out)))
	if len(fields) == 0 {
		return "", errors.New("no instance selected")
	}
	return fields[0], nil
}

func cmdSSH(args []string) error {
	root := stateRoot()
	var name string
	if len(args) > 0 {
		name = args[0]
	} else {
		instances, err := listRunningInstances(root)
		if err != nil {
			return err
		}
		if len(instances) == 0 {
			return errors.New("no running microvm-sandbox instances")
		}
		fzfBin, err := exec.LookPath("fzf")
		if err != nil {
			return err
		}
		name, err = pickInstanceWithFzf(instances, fzfBin)
		if err != nil {
			return err
		}
	}
	if err := validateName(name); err != nil {
		return err
	}
	port, err := requireRunningPort(root, name)
	if err != nil {
		return err
	}
	sshBin, err := exec.LookPath("ssh")
	if err != nil {
		return err
	}
	argv := append([]string{"ssh"}, sshBaseArgs(port)...)
	argv = append(argv, "user@127.0.0.1")
	return syscall.Exec(sshBin, argv, os.Environ())
}

func cmdStatus(stdout io.Writer) error {
	instances, err := listInstances(stateRoot())
	if err != nil {
		return err
	}
	if len(instances) == 0 {
		_, err := io.WriteString(stdout, "No microvm-sandbox instances.\n")
		return err
	}

	_, _ = fmt.Fprintf(stdout, "%-20s %-10s %-10s %s\n", "NAME", "STATE", "PID", "PORT")
	for _, inst := range instances {
		state := "stopped"
		pidStr := "-"
		if inst.running {
			state = "running"
			if inst.pid > 0 {
				pidStr = strconv.Itoa(inst.pid)
			}
		}
		portStr := "-"
		if inst.port > 0 {
			portStr = strconv.Itoa(inst.port)
		}
		_, _ = fmt.Fprintf(stdout, "%-20s %-10s %-10s %s\n", inst.name, state, pidStr, portStr)
	}
	return nil
}

func stopInstance(root, name string, stdout io.Writer) error {
	stateDir := stateDirFor(root, name)
	info, err := os.Stat(stateDir)
	if err != nil || !info.IsDir() {
		return fmt.Errorf("instance '%s' is not found", name)
	}

	pidFile := filepath.Join(stateDir, "qemu.pid")
	if pid, ok := readPID(pidFile); ok && isRunning(pidFile) {
		_ = syscall.Kill(pid, syscall.SIGTERM)
		for range 25 {
			if !isRunning(pidFile) {
				break
			}
			time.Sleep(200 * time.Millisecond)
		}
		if isRunning(pidFile) {
			_ = syscall.Kill(pid, syscall.SIGKILL)
		}
	}

	// Ensure read-only empty dir can be removed cleanly.
	_ = os.Chmod(filepath.Join(stateDir, "empty"), 0o755)
	if err := os.RemoveAll(stateDir); err != nil {
		return err
	}
	_, err = fmt.Fprintf(stdout, "stopped %s\n", name)
	return err
}

func cmdDown(args []string, stdout io.Writer) error {
	if len(args) == 0 {
		return errors.New("missing instance name or --all")
	}
	if len(args) > 1 {
		return fmt.Errorf("unexpected arguments: %s", strings.Join(args[1:], " "))
	}

	root := stateRoot()
	if args[0] == "--all" {
		entries, err := os.ReadDir(root)
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				return nil
			}
			return err
		}
		for _, entry := range entries {
			if !entry.IsDir() {
				continue
			}
			if err := stopInstance(root, entry.Name(), stdout); err != nil {
				return err
			}
		}
		return nil
	}

	name := args[0]
	if err := validateName(name); err != nil {
		return err
	}
	return stopInstance(root, name, stdout)
}
