package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

const (
	menuExpectKeys = "ctrl-a,ctrl-d,ctrl-x"

	menuActionSSH     = "SSH into instance"
	menuActionDown    = "Down instance"
	menuActionUp      = "Start new instance (up)"
	menuActionDownAll = "Down all instances"
	menuActionConsole = "Foreground console"

	menuUpModeDefault  = "Default (share host repos)"
	menuUpModePlain    = "Plain (no host repos)"
	menuUpModeMountCWD = "Plain + mount current directory"
)

var (
	errMenuCanceled   = errors.New("selection canceled")
	workspaceMountRe  = regexp.MustCompile(`-fsdev 'local,id=fs_workspace,path=([^']+),`)
	plainEmptyMountRe = regexp.MustCompile(`-fsdev 'local,id=fs2,path=[^']+/empty,security_model=none,readonly=true'`)
)

type menuChoice struct {
	Query string
	Key   string
	Name  string
}

type menuUI struct {
	listInstances func(root string) ([]instanceInfo, error)
	selectItem    func(fzfArgs []string, input io.Reader, stderr io.Writer) (menuChoice, error)
	chooseAction  func(header string, options []string, stderr io.Writer) (string, error)
	inputText     func(prompt, placeholder string, stderr io.Writer) (string, error)
	confirm       func(prompt string, defaultYes bool, stderr io.Writer) (bool, error)
	getwd         func() (string, error)
	runSSH        func(root, name string) error
	runUp         func(args []string, stdout, stderr io.Writer) error
	runDown       func(root, name string, stdout io.Writer) error
	runDownAll    func(root string, stdout io.Writer) error
	runConsole    func() error
}

func (ui menuUI) withDefaults() menuUI {
	if ui.listInstances == nil {
		ui.listInstances = listInstances
	}
	if ui.selectItem == nil {
		ui.selectItem = selectMenuItemWithFzf
	}
	if ui.chooseAction == nil {
		ui.chooseAction = chooseMenuActionWithGum
	}
	if ui.inputText == nil {
		ui.inputText = inputTextWithGum
	}
	if ui.confirm == nil {
		ui.confirm = runGumConfirm
	}
	if ui.getwd == nil {
		ui.getwd = os.Getwd
	}
	if ui.runSSH == nil {
		ui.runSSH = sshInstance
	}
	if ui.runUp == nil {
		ui.runUp = cmdUp
	}
	if ui.runDown == nil {
		ui.runDown = stopInstance
	}
	if ui.runDownAll == nil {
		ui.runDownAll = stopAllInstances
	}
	if ui.runConsole == nil {
		ui.runConsole = func() error {
			return cmdConsole(nil)
		}
	}
	return ui
}

func isTerminalFile(f *os.File) bool {
	if f == nil {
		return false
	}
	stat, err := f.Stat()
	if err != nil {
		return false
	}
	return (stat.Mode() & os.ModeCharDevice) != 0
}

func isTerminal(w io.Writer) bool {
	f, ok := w.(*os.File)
	if !ok {
		return false
	}
	return isTerminalFile(f)
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func isCancelExitError(err error) bool {
	var exitErr *exec.ExitError
	return errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130)
}

func parseMenuFzfOutput(raw string) menuChoice {
	trimmed := strings.TrimSuffix(raw, "\n")
	if trimmed == "" {
		return menuChoice{}
	}
	lines := strings.Split(trimmed, "\n")
	choice := menuChoice{
		Query: strings.TrimSpace(lines[0]),
	}
	if len(lines) >= 2 {
		choice.Key = strings.TrimSpace(lines[1])
	}
	if len(lines) >= 3 {
		choice.Name = strings.TrimSpace(lines[2])
	}
	return choice
}

func formatMenuInstanceLine(inst instanceInfo) string {
	stateCell := fmt.Sprintf("\x1b[2m%-10s\x1b[0m", "stopped")
	pidStr := "-"
	if inst.running {
		stateCell = fmt.Sprintf("\x1b[32m%-10s\x1b[0m", "running")
		if inst.pid > 0 {
			pidStr = strconv.Itoa(inst.pid)
		}
	}
	portStr := "-"
	if inst.port > 0 {
		portStr = strconv.Itoa(inst.port)
	}
	display := fmt.Sprintf("%-20s %s %-10s %s", inst.name, stateCell, pidStr, portStr)
	return inst.name + "\t" + display
}

func menuFzfArgs(selfExe string) []string {
	previewCmd := fmt.Sprintf("%s _preview {1}", shellQuote(selfExe))
	header := fmt.Sprintf(
		"ENTER: ssh | ^A: up | ^D: down | ^X: actions | ^/: preview\n%-20s %-10s %-10s %s",
		"NAME", "STATE", "PID", "PORT",
	)
	return []string{
		"--height=75%",
		"--tmux=90%,70%",
		"--layout=reverse",
		"--min-height=20+",
		"--border",
		"--no-separator",
		"--header-border=horizontal",
		"--border-label-pos=2",
		"--color=label:blue",
		"--border-label=📦 MicroVM Sandbox",
		"--header=" + header,
		"--bind=ctrl-/:change-preview-window(down,60%|hidden|)",
		"--print-query",
		"--expect=" + menuExpectKeys,
		"--ansi",
		"--delimiter=\t",
		"--nth=2",
		"--with-nth=2",
		"--accept-nth=1",
		"--preview=" + previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
	}
}

func selectMenuItemWithFzf(fzfArgs []string, input io.Reader, stderr io.Writer) (menuChoice, error) {
	fzfBin, err := exec.LookPath("fzf")
	if err != nil {
		return menuChoice{}, err
	}
	cmd := exec.Command(fzfBin, fzfArgs...)
	cmd.Stdin = input
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			switch exitErr.ExitCode() {
			case 130:
				return menuChoice{}, errMenuCanceled
			case 1:
				choice := parseMenuFzfOutput(out.String())
				if choice.Query == "" && choice.Key == "" && choice.Name == "" {
					return menuChoice{}, errMenuCanceled
				}
				return choice, nil
			}
		}
		return menuChoice{}, fmt.Errorf("fzf failed: %w", err)
	}
	return parseMenuFzfOutput(out.String()), nil
}

func runGumOutput(args []string, stderr io.Writer) (string, error) {
	gumBin, err := exec.LookPath("gum")
	if err != nil {
		return "", err
	}
	cmd := exec.Command(gumBin, args...)
	cmd.Stdin = os.Stdin
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		if isCancelExitError(err) {
			return "", errMenuCanceled
		}
		return "", fmt.Errorf("gum %s failed: %w", args[0], err)
	}
	return strings.TrimSpace(out.String()), nil
}

func chooseMenuActionWithGum(header string, options []string, stderr io.Writer) (string, error) {
	args := make([]string, 0, 2+len(options))
	args = append(args, "choose", "--header="+header)
	args = append(args, options...)
	return runGumOutput(args, stderr)
}

func inputTextWithGum(prompt, placeholder string, stderr io.Writer) (string, error) {
	val, err := runGumOutput([]string{
		"input",
		"--prompt=" + prompt,
		"--placeholder=" + placeholder,
	}, stderr)
	if err != nil {
		return "", err
	}
	if val == "" {
		return "", errMenuCanceled
	}
	return val, nil
}

func runGumConfirm(prompt string, defaultYes bool, stderr io.Writer) (bool, error) {
	gumBin, err := exec.LookPath("gum")
	if err != nil {
		return false, err
	}
	cmd := exec.Command(gumBin, "confirm", fmt.Sprintf("--default=%t", defaultYes), prompt)
	cmd.Stdin = os.Stdin
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			switch exitErr.ExitCode() {
			case 1:
				return false, nil
			case 130:
				return false, errMenuCanceled
			}
		}
		return false, fmt.Errorf("gum confirm failed: %w", err)
	}
	return true, nil
}

func detectMountMode(runnerPath string) string {
	data, err := os.ReadFile(runnerPath)
	if err != nil {
		return "unknown"
	}
	src := string(data)
	if m := workspaceMountRe.FindStringSubmatch(src); len(m) == 2 {
		return "plain + mount " + m[1]
	}
	if plainEmptyMountRe.MatchString(src) {
		return "plain"
	}
	if strings.Contains(src, "mount_tag=repos") {
		return "default (" + hostReposPath + ")"
	}
	return "unknown"
}

func renderInstancePreview(root, name string, stdout io.Writer) error {
	name = strings.TrimSpace(name)
	if name == "" {
		return nil
	}
	if err := validateName(name); err != nil {
		return err
	}

	stateDir := stateDirFor(root, name)
	if info, err := os.Stat(stateDir); err != nil || !info.IsDir() {
		_, err := fmt.Fprintf(stdout, "Instance %q not found.\n", name)
		return err
	}

	pidFile := filepath.Join(stateDir, "qemu.pid")
	state := "stopped"
	pidStr := "-"
	if isRunning(pidFile) {
		state = "running"
		if pid, ok := readPID(pidFile); ok {
			pidStr = strconv.Itoa(pid)
		}
	}

	portStr := "-"
	if data, err := os.ReadFile(filepath.Join(stateDir, "ssh.port")); err == nil {
		if trimmed := strings.TrimSpace(string(data)); trimmed != "" {
			portStr = trimmed
		}
	}

	mountMode := detectMountMode(filepath.Join(stateDir, "microvm-run"))

	_, _ = fmt.Fprintf(stdout, "Name:  %s\n", name)
	_, _ = fmt.Fprintf(stdout, "State: %s\n", state)
	_, _ = fmt.Fprintf(stdout, "PID:   %s\n", pidStr)
	_, _ = fmt.Fprintf(stdout, "Port:  %s\n", portStr)
	_, _ = fmt.Fprintf(stdout, "Mount: %s\n", mountMode)

	logPath := filepath.Join(stateDir, "console.log")
	data, err := os.ReadFile(logPath)
	if err != nil || len(bytes.TrimSpace(data)) == 0 {
		return nil
	}
	_, _ = io.WriteString(stdout, "\n--- console.log (tail) ---\n")
	lines := strings.Split(strings.TrimRight(string(data), "\n"), "\n")
	if len(lines) > 40 {
		lines = lines[len(lines)-40:]
	}
	_, err = io.WriteString(stdout, strings.Join(lines, "\n")+"\n")
	return err
}

func cmdPreview(args []string, stdout io.Writer) error {
	if len(args) == 0 {
		return nil
	}
	return renderInstancePreview(stateRoot(), args[0], stdout)
}

func findInstanceByName(instances []instanceInfo, name string) (instanceInfo, bool) {
	for _, inst := range instances {
		if inst.name == name {
			return inst, true
		}
	}
	return instanceInfo{}, false
}

func menuActionOptions(inst instanceInfo, hasInst bool, total int) (string, []string) {
	var options []string
	header := "MicroVM Sandbox actions"
	if hasInst {
		state := "stopped"
		if inst.running {
			state = "running"
		}
		header = fmt.Sprintf("Action for %s (%s)", inst.name, state)
		if inst.running {
			options = append(options, menuActionSSH)
		}
		options = append(options, menuActionDown)
	}
	options = append(options, menuActionUp)
	if total > 0 {
		options = append(options, menuActionDownAll)
	}
	options = append(options, menuActionConsole)
	return header, options
}

func confirmAndDownInstance(root, name string, ui menuUI, stdout, stderr io.Writer) error {
	ok, err := ui.confirm(fmt.Sprintf("Down instance %q?", name), true, stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		return err
	}
	if !ok {
		return nil
	}
	return ui.runDown(root, name, stdout)
}

func confirmAndDownAllInstances(root string, ui menuUI, stdout, stderr io.Writer) error {
	ok, err := ui.confirm("Down all instances?", false, stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		return err
	}
	if !ok {
		return nil
	}
	return ui.runDownAll(root, stdout)
}

func runMenuUpFlow(ui menuUI, stdout, stderr io.Writer) error {
	name, err := ui.inputText("Instance name: ", "work-1", stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		return err
	}
	if err := validateName(name); err != nil {
		return err
	}

	mode, err := ui.chooseAction("Mount mode for "+name, []string{
		menuUpModeDefault,
		menuUpModePlain,
		menuUpModeMountCWD,
	}, stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		return err
	}

	var upArgs []string
	switch mode {
	case menuUpModeDefault:
		upArgs = []string{name}
	case menuUpModePlain:
		upArgs = []string{"--plain", name}
	case menuUpModeMountCWD:
		cwd, err := ui.getwd()
		if err != nil {
			return err
		}
		upArgs = []string{"--plain", "--mount", cwd, name}
	default:
		return fmt.Errorf("unexpected mount mode selection: %q", mode)
	}

	return ui.runUp(upArgs, stdout, stderr)
}

func runMenuActionMenu(root string, inst instanceInfo, hasInst bool, total int, ui menuUI, stdout, stderr io.Writer) (bool, error) {
	header, options := menuActionOptions(inst, hasInst, total)
	picked, err := ui.chooseAction(header, options, stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return false, nil
		}
		return false, err
	}

	switch picked {
	case menuActionSSH:
		if !hasInst {
			return false, nil
		}
		return true, ui.runSSH(root, inst.name)
	case menuActionDown:
		if !hasInst {
			return false, nil
		}
		return false, confirmAndDownInstance(root, inst.name, ui, stdout, stderr)
	case menuActionUp:
		return false, runMenuUpFlow(ui, stdout, stderr)
	case menuActionDownAll:
		return false, confirmAndDownAllInstances(root, ui, stdout, stderr)
	case menuActionConsole:
		return true, ui.runConsole()
	default:
		return false, fmt.Errorf("unexpected action selection: %q", picked)
	}
}

func runMenuLoop(root, selfExe string, ui menuUI, stdout, stderr io.Writer) error {
	ui = ui.withDefaults()
	fzfArgs := menuFzfArgs(selfExe)

	for {
		instances, err := ui.listInstances(root)
		if err != nil {
			return err
		}

		var listBuf bytes.Buffer
		for _, inst := range instances {
			listBuf.WriteString(formatMenuInstanceLine(inst))
			listBuf.WriteByte('\n')
		}

		choice, err := ui.selectItem(fzfArgs, &listBuf, stderr)
		if err != nil {
			if errors.Is(err, errMenuCanceled) {
				return nil
			}
			return err
		}

		inst, hasInst := findInstanceByName(instances, choice.Name)

		switch choice.Key {
		case "":
			if !hasInst {
				continue
			}
			if inst.running {
				return ui.runSSH(root, inst.name)
			}
			done, err := runMenuActionMenu(root, inst, true, len(instances), ui, stdout, stderr)
			if err != nil {
				_, _ = fmt.Fprintf(stderr, "error: %v\n", err)
			}
			if done {
				return err
			}
		case "ctrl-d":
			if !hasInst {
				continue
			}
			if err := confirmAndDownInstance(root, inst.name, ui, stdout, stderr); err != nil {
				_, _ = fmt.Fprintf(stderr, "error: %v\n", err)
			}
		case "ctrl-a":
			if err := runMenuUpFlow(ui, stdout, stderr); err != nil {
				_, _ = fmt.Fprintf(stderr, "error: %v\n", err)
			}
		case "ctrl-x":
			done, err := runMenuActionMenu(root, inst, hasInst, len(instances), ui, stdout, stderr)
			if err != nil {
				_, _ = fmt.Fprintf(stderr, "error: %v\n", err)
			}
			if done {
				return err
			}
		default:
			return fmt.Errorf("unexpected fzf key: %q", choice.Key)
		}
	}
}

func cmdMenu(stdout, stderr io.Writer) error {
	selfExe, err := os.Executable()
	if err != nil {
		selfExe = "microvm-sandbox"
	}
	return runMenuLoop(stateRoot(), selfExe, menuUI{}, stdout, stderr)
}
