package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
)

const (
	menuExpectKeys = "ctrl-n,ctrl-o,ctrl-x"

	menuActionOpen     = "Open (unlock & mount)"
	menuActionClose    = "Close (unmount & lock)"
	menuActionFiles    = "Open in file manager"
	menuActionInit     = "Create new vault (init)"
	menuActionCloseAll = "Close all open vaults"
)

var errMenuCanceled = errors.New("selection canceled")

type menuChoice struct {
	Query string
	Key   string
	Path  string
}

type menuUI struct {
	listVaults   func() ([]vaultInfo, error)
	selectItem   func(fzfArgs []string, input io.Reader, stderr io.Writer) (menuChoice, error)
	chooseAction func(header string, options []string, stderr io.Writer) (string, error)
	inputText    func(prompt, placeholder, value string, stderr io.Writer) (string, error)
	openVault    func(path string, stdout, stderr io.Writer) (string, error)
	closeVault   func(path string, stdout, stderr io.Writer) error
	initVault    func(path, sizeRaw, label string, stdout, stderr io.Writer) error
	openFiles    func(mountpoint string) error
}

func (ui menuUI) withDefaults() menuUI {
	if ui.listVaults == nil {
		ui.listVaults = discoverVaults
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
	if ui.openVault == nil {
		ui.openVault = openVault
	}
	if ui.closeVault == nil {
		ui.closeVault = closeVault
	}
	if ui.initVault == nil {
		ui.initVault = initVault
	}
	if ui.openFiles == nil {
		ui.openFiles = openInFileManager
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
		choice.Path = strings.TrimSpace(lines[2])
	}
	return choice
}

func formatMenuVaultLine(v vaultInfo) string {
	var stateCell string
	switch v.State {
	case stateOpen:
		stateCell = fmt.Sprintf("\x1b[32m%-10s\x1b[0m", v.State)
	case stateUnlocked, stateAttached:
		stateCell = fmt.Sprintf("\x1b[33m%-10s\x1b[0m", v.State)
	default:
		stateCell = fmt.Sprintf("\x1b[2m%-10s\x1b[0m", v.State)
	}
	mp := v.Mountpoint
	if mp == "" {
		mp = "-"
	}
	display := fmt.Sprintf("%-20s %s %-10s %s", v.Name, stateCell, formatBytes(v.SizeBytes), mp)
	return v.Path + "\t" + display
}

func menuFzfArgs(selfExe string) []string {
	previewCmd := fmt.Sprintf("%s _preview {1}", shellQuote(selfExe))
	header := fmt.Sprintf(
		"ENTER: open/close | ^N: new | ^O: files | ^X: actions | ^/: preview\n%-20s %-10s %-10s %s",
		"NAME", "STATE", "SIZE", "MOUNTPOINT",
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
		"--border-label=🔐 LUKS Vault",
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
				if choice.Query == "" && choice.Key == "" && choice.Path == "" {
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

func inputTextWithGum(prompt, placeholder, value string, stderr io.Writer) (string, error) {
	args := []string{
		"input",
		"--prompt=" + prompt,
		"--placeholder=" + placeholder,
	}
	if value != "" {
		args = append(args, "--value="+value)
	}
	val, err := runGumOutput(args, stderr)
	if err != nil {
		return "", err
	}
	if val == "" {
		return "", errMenuCanceled
	}
	return val, nil
}

func openInFileManager(mountpoint string) error {
	cmd := exec.Command("xdg-open", mountpoint)
	return cmd.Start()
}

func runMenuInit(ui menuUI, stdout, stderr io.Writer) error {
	defPath := defaultInitPath()
	path, err := ui.inputText("Vault path> ", defPath, defPath, stderr)
	if err != nil {
		return err
	}
	size, err := ui.inputText("Size (e.g. 512M, 2G)> ", defaultInitSize, defaultInitSize, stderr)
	if err != nil {
		return err
	}
	return ui.initVault(path, size, "", stdout, stderr)
}

func runMenuLoop(selfExe string, ui menuUI, stdout, stderr io.Writer) error {
	ui = ui.withDefaults()
	for {
		vaults, err := ui.listVaults()
		if err != nil {
			return err
		}

		var buf strings.Builder
		byPath := make(map[string]vaultInfo, len(vaults))
		for _, v := range vaults {
			byPath[v.Path] = v
			buf.WriteString(formatMenuVaultLine(v))
			buf.WriteByte('\n')
		}

		choice, err := ui.selectItem(menuFzfArgs(selfExe), strings.NewReader(buf.String()), stderr)
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		if err != nil {
			return err
		}

		selected, hasSelected := byPath[choice.Path]

		switch choice.Key {
		case "ctrl-n":
			if err := runMenuInit(ui, stdout, stderr); err != nil && !errors.Is(err, errMenuCanceled) {
				fmt.Fprintf(stderr, "error: %v\n", err)
			}
			continue
		case "ctrl-o":
			if !hasSelected || selected.Mountpoint == "" {
				fmt.Fprintf(stderr, "vault is not mounted\n")
				continue
			}
			if err := ui.openFiles(selected.Mountpoint); err != nil {
				fmt.Fprintf(stderr, "error: %v\n", err)
			}
			continue
		case "ctrl-x":
			var actions []string
			if hasSelected {
				if selected.State == stateOpen {
					actions = append(actions, menuActionFiles, menuActionClose)
				} else {
					actions = append(actions, menuActionOpen)
				}
			}
			actions = append(actions, menuActionInit, menuActionCloseAll)
			header := "Vault action"
			if hasSelected {
				header = fmt.Sprintf("Action for %s", selected.Name)
			}
			action, err := ui.chooseAction(header, actions, stderr)
			if errors.Is(err, errMenuCanceled) {
				continue
			}
			if err != nil {
				return err
			}
			switch action {
			case menuActionOpen:
				if _, err := ui.openVault(selected.Path, stdout, stderr); err != nil && !errors.Is(err, errMenuCanceled) {
					fmt.Fprintf(stderr, "error: %v\n", err)
				}
			case menuActionClose:
				if err := ui.closeVault(selected.Path, stdout, stderr); err != nil {
					fmt.Fprintf(stderr, "error: %v\n", err)
				}
			case menuActionFiles:
				if err := ui.openFiles(selected.Mountpoint); err != nil {
					fmt.Fprintf(stderr, "error: %v\n", err)
				}
			case menuActionInit:
				if err := runMenuInit(ui, stdout, stderr); err != nil && !errors.Is(err, errMenuCanceled) {
					fmt.Fprintf(stderr, "error: %v\n", err)
				}
			case menuActionCloseAll:
				for _, v := range vaults {
					if v.State != stateLocked {
						if err := ui.closeVault(v.Path, stdout, stderr); err != nil {
							fmt.Fprintf(stderr, "error: %v\n", err)
						}
					}
				}
			}
			continue
		default:
			if !hasSelected {
				if len(vaults) == 0 {
					if err := runMenuInit(ui, stdout, stderr); err != nil && !errors.Is(err, errMenuCanceled) {
						fmt.Fprintf(stderr, "error: %v\n", err)
					}
				}
				continue
			}
			if selected.State == stateOpen {
				if err := ui.closeVault(selected.Path, stdout, stderr); err != nil {
					fmt.Fprintf(stderr, "error: %v\n", err)
				}
			} else {
				if _, err := ui.openVault(selected.Path, stdout, stderr); err != nil && !errors.Is(err, errMenuCanceled) {
					fmt.Fprintf(stderr, "error: %v\n", err)
				}
			}
		}
	}
}
