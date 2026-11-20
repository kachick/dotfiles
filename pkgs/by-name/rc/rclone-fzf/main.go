package main

import (
	"bufio"
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"text/tabwriter"
)

const mountinfoPath = "/proc/self/mountinfo"

type MountEntry struct {
	Remote     string
	MountPoint string
}

func isOctalDigit(b byte) bool {
	return b >= '0' && b <= '7'
}

func unescapeMountinfoField(s string) string {
	if !strings.ContainsRune(s, '\\') {
		return s
	}

	var b strings.Builder
	b.Grow(len(s))
	for i := 0; i < len(s); i++ {
		if s[i] == '\\' && i+3 < len(s) && isOctalDigit(s[i+1]) && isOctalDigit(s[i+2]) && isOctalDigit(s[i+3]) {
			val := int(s[i+1]-'0')*64 + int(s[i+2]-'0')*8 + int(s[i+3]-'0')
			if val <= 255 {
				b.WriteByte(byte(val))
				i += 3
				continue
			}
		}
		b.WriteByte(s[i])
	}
	return b.String()
}

func parseMountinfoLine(line string) (mountPoint, fsType, mountSource string, ok bool) {
	fields := strings.Fields(line)
	sepIdx := slices.Index(fields, "-")
	// proc(5) places mount point at field 5 (index 4) and fsType/source after "-".
	if sepIdx < 5 || sepIdx+2 >= len(fields) {
		return "", "", "", false
	}
	return unescapeMountinfoField(fields[4]), fields[sepIdx+1], unescapeMountinfoField(fields[sepIdx+2]), true
}

func parseMountinfo(r io.Reader) ([]MountEntry, error) {
	var entries []MountEntry
	scanner := bufio.NewScanner(r)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		mountPoint, fsType, mountSource, ok := parseMountinfoLine(scanner.Text())
		if !ok {
			continue
		}
		if fsType != "fuse.rclone" && fsType != "rclone" {
			continue
		}
		entries = append(entries, MountEntry{
			Remote:     mountSource,
			MountPoint: mountPoint,
		})
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return entries, nil
}

func isMountPoint(r io.Reader, targetPath string) (bool, error) {
	cleanTarget := filepath.Clean(targetPath)
	scanner := bufio.NewScanner(r)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		mountPoint, _, _, ok := parseMountinfoLine(scanner.Text())
		if !ok {
			continue
		}
		if filepath.Clean(mountPoint) == cleanTarget {
			return true, nil
		}
	}
	if err := scanner.Err(); err != nil {
		return false, err
	}
	return false, nil
}

func readMountedEntries(path string) ([]MountEntry, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open %s: %w", path, err)
	}
	defer f.Close()
	return parseMountinfo(f)
}

func checkMountPoint(path, targetPath string) (bool, error) {
	f, err := os.Open(path)
	if err != nil {
		return false, fmt.Errorf("open %s: %w", path, err)
	}
	defer f.Close()
	return isMountPoint(f, targetPath)
}

func formatMountEntries(entries []MountEntry, w io.Writer) error {
	if len(entries) == 0 {
		return nil
	}
	tw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)
	if _, err := fmt.Fprintln(tw, "REMOTE\tLOCAL"); err != nil {
		return err
	}
	for _, entry := range entries {
		if _, err := fmt.Fprintf(tw, "%s\t%s\n", entry.Remote, entry.MountPoint); err != nil {
			return err
		}
	}
	return tw.Flush()
}

func resolveMountPath(remote string) (string, error) {
	name := strings.TrimSuffix(remote, ":")
	if name == "" || name == "." || name == ".." || strings.Contains(name, "..") {
		return "", fmt.Errorf("invalid remote name: %q", remote)
	}
	dataHome := os.Getenv("XDG_DATA_HOME")
	if dataHome == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("resolve home directory: %w", err)
		}
		dataHome = filepath.Join(homeDir, ".local", "share")
	}
	return filepath.Join(dataHome, "mnt", "rclone", name), nil
}

func runListMounted(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("rclone-list-mounted", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: rclone-list-mounted\n\n")
		fmt.Fprintf(stderr, "List currently mounted rclone remotes from %s.\n", mountinfoPath)
	}
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if fs.NArg() > 0 {
		fs.Usage()
		return fmt.Errorf("unexpected arguments: %v", fs.Args())
	}

	entries, err := readMountedEntries(mountinfoPath)
	if err != nil {
		return err
	}
	return formatMountEntries(entries, stdout)
}

func runMount(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("rclone-mount", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: rclone-mount <remote>\n\n")
		fmt.Fprintf(stderr, "Mount an rclone remote under XDG_DATA_HOME/mnt/rclone.\n")
	}
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if fs.NArg() != 1 {
		fs.Usage()
		return errors.New("requires exactly 1 argument: <remote>")
	}

	remote := fs.Arg(0)
	mountTo, err := resolveMountPath(remote)
	if err != nil {
		return err
	}

	mounted, err := checkMountPoint(mountinfoPath, mountTo)
	if err != nil {
		return err
	}
	if mounted {
		fmt.Fprintln(stderr, "Already mounted:")
		fmt.Fprintln(stdout, mountTo)
		return nil
	}

	if err := os.MkdirAll(mountTo, 0o755); err != nil {
		return fmt.Errorf("create mount directory %s: %w", mountTo, err)
	}

	cmd := exec.Command("rclone", "mount", remote, mountTo, "--vfs-cache-mode", "writes", "--daemon")
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("rclone mount %s: %w", remote, err)
	}

	fmt.Fprintln(stderr, "Mounted to:")
	fmt.Fprintln(stdout, mountTo)
	return nil
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func isCancelExitError(err error) bool {
	var exitErr *exec.ExitError
	return errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130)
}

func runFzf(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("rclone-fzf", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: rclone-fzf [query]\n")
		fmt.Fprintf(stderr, "       rclone-fzf mount <remote>\n")
		fmt.Fprintf(stderr, "       rclone-fzf list-mounted\n\n")
		fmt.Fprintf(stderr, "List and operate rclone remotes interactively with fzf.\n")
	}
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	query := ""
	if fs.NArg() >= 1 {
		query = fs.Arg(0)
	}

	entries, err := readMountedEntries(mountinfoPath)
	if err != nil {
		return err
	}
	if err := formatMountEntries(entries, stderr); err != nil {
		return err
	}

	listCmd := exec.Command("rclone", "listremotes")
	listCmd.Stderr = stderr
	remotesOut, err := listCmd.Output()
	if err != nil {
		return fmt.Errorf("rclone listremotes: %w", err)
	}
	if len(bytes.TrimSpace(remotesOut)) == 0 {
		return nil
	}

	selfExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable path: %w", err)
	}

	fzfArgs := []string{
		"--query", query,
		"--border-label", "☁️ Rclone Remotes",
		"--layout=reverse",
		"--height=85%",
		"--min-height=20",
		"--border",
		"--border-label-pos=2",
		"--color=header:italic:underline,label:blue",
		"--header", "Ctrl-/ (Mount) / Alt-A (Inspect)\n\n",
		"--bind", fmt.Sprintf("ctrl-/:become(%s mount {})", shellQuote(selfExe)),
		"--bind", "alt-a:become(rclone about {})",
		"--bind", "enter:become(echo {})",
	}

	fzfCmd := exec.Command("fzf", fzfArgs...)
	fzfCmd.Stdin = bytes.NewReader(remotesOut)
	fzfCmd.Stdout = stdout
	fzfCmd.Stderr = stderr
	if err := fzfCmd.Run(); err != nil {
		if isCancelExitError(err) {
			return nil
		}
		return fmt.Errorf("fzf failed: %w", err)
	}
	return nil
}

func dispatch(argv0 string, args []string, stdout, stderr io.Writer) error {
	switch filepath.Base(argv0) {
	case "rclone-mount":
		return runMount(args, stdout, stderr)
	case "rclone-list-mounted":
		return runListMounted(args, stdout, stderr)
	}

	if len(args) > 0 {
		switch args[0] {
		case "mount":
			return runMount(args[1:], stdout, stderr)
		case "list-mounted":
			return runListMounted(args[1:], stdout, stderr)
		}
	}

	return runFzf(args, stdout, stderr)
}

func main() {
	if err := dispatch(os.Args[0], os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
