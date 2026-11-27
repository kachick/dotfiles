package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"strings"
)

func usage(w io.Writer) {
	fmt.Fprint(w, `Usage:
  vault                         # Interactive TUI menu
  vault menu                    # Interactive TUI menu
  vault init [PATH] [--size 512M] [--label NAME]
  vault open [PATH]
  vault close [PATH|--all]
  vault status

Environment:
  VAULT_DIR   Extra directory to scan for *.luks containers
`)
}

func run(args []string, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		if !isTerminalFile(os.Stdin) || !isTerminalFile(os.Stdout) {
			return cmdStatus(stdout)
		}
		return cmdMenu(stdout, stderr)
	}

	switch args[0] {
	case "-h", "--help", "help":
		usage(stdout)
		return nil
	case "menu":
		return cmdMenu(stdout, stderr)
	case "init":
		return cmdInit(args[1:], stdout, stderr)
	case "open":
		return cmdOpen(args[1:], stdout, stderr)
	case "close":
		return cmdClose(args[1:], stdout, stderr)
	case "status":
		return cmdStatus(stdout)
	case "_preview":
		return cmdPreview(args[1:], stdout)
	default:
		return fmt.Errorf("unknown command %q (run 'vault --help')", args[0])
	}
}

func cmdMenu(stdout, stderr io.Writer) error {
	selfExe, err := os.Executable()
	if err != nil {
		selfExe = "vault"
	}
	return runMenuLoop(selfExe, menuUI{}, stdout, stderr)
}

func cmdInit(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("vault init", flag.ContinueOnError)
	fs.SetOutput(stderr)
	size := fs.String("size", defaultInitSize, "Container size (e.g. 256M, 1G)")
	label := fs.String("label", "", "Filesystem label (defaults to file stem, max 16 chars)")

	// Reorder positional arguments after flags so `vault init /path --size 64M` works too.
	var flagArgs, posArgs []string
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--" {
			posArgs = append(posArgs, args[i+1:]...)
			break
		}
		if strings.HasPrefix(arg, "-") {
			flagArgs = append(flagArgs, arg)
			if !strings.Contains(arg, "=") && arg != "-h" && arg != "--help" && i+1 < len(args) {
				i++
				flagArgs = append(flagArgs, args[i])
			}
			continue
		}
		posArgs = append(posArgs, arg)
	}
	if err := fs.Parse(flagArgs); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	path := defaultInitPath()
	if len(posArgs) > 0 {
		path = posArgs[0]
	}
	if len(posArgs) > 1 {
		return errors.New("vault init accepts at most one path argument")
	}
	return initVault(path, *size, *label, stdout, stderr)
}

func resolveSingleVaultPath(args []string, wantOpen bool, stderr io.Writer) (string, error) {
	if len(args) > 1 {
		return "", errors.New("expected at most one path argument")
	}
	if len(args) == 1 {
		return args[0], nil
	}
	vaults, err := discoverVaults()
	if err != nil {
		return "", err
	}
	var candidates []vaultInfo
	for _, v := range vaults {
		if wantOpen && v.State == stateLocked {
			continue
		}
		candidates = append(candidates, v)
	}
	if len(candidates) == 0 {
		if wantOpen {
			return "", errors.New("no open vaults found")
		}
		return "", errors.New("no *.luks vaults found (create one with 'vault init')")
	}
	if len(candidates) == 1 {
		return candidates[0].Path, nil
	}
	var buf strings.Builder
	for _, v := range candidates {
		buf.WriteString(formatMenuVaultLine(v))
		buf.WriteByte('\n')
	}
	choice, err := selectMenuItemWithFzf([]string{
		"--height=40%",
		"--layout=reverse",
		"--border",
		"--ansi",
		"--delimiter=\t",
		"--nth=2",
		"--with-nth=2",
		"--accept-nth=1",
		"--print-query",
		"--expect=",
	}, strings.NewReader(buf.String()), stderr)
	if err != nil {
		return "", err
	}
	if choice.Path == "" {
		return "", errMenuCanceled
	}
	return choice.Path, nil
}

func cmdOpen(args []string, stdout, stderr io.Writer) error {
	path, err := resolveSingleVaultPath(args, false, stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		return err
	}
	_, err = openVault(path, stdout, stderr)
	return err
}

func cmdClose(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("vault close", flag.ContinueOnError)
	fs.SetOutput(stderr)
	all := fs.Bool("all", false, "Close all open or attached vaults")
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if *all {
		vaults, err := discoverVaults()
		if err != nil {
			return err
		}
		closed := 0
		for _, v := range vaults {
			if v.State != stateLocked {
				if err := closeVault(v.Path, stdout, stderr); err != nil {
					return err
				}
				closed++
			}
		}
		if closed == 0 {
			fmt.Fprintln(stdout, "No open vaults.")
		}
		return nil
	}
	path, err := resolveSingleVaultPath(fs.Args(), true, stderr)
	if err != nil {
		if errors.Is(err, errMenuCanceled) {
			return nil
		}
		return err
	}
	return closeVault(path, stdout, stderr)
}

func cmdStatus(stdout io.Writer) error {
	vaults, err := discoverVaults()
	if err != nil {
		return err
	}
	if len(vaults) == 0 {
		fmt.Fprintln(stdout, "No *.luks vaults found.")
		return nil
	}
	fmt.Fprintf(stdout, "%-20s %-10s %-10s %s\n", "NAME", "STATE", "SIZE", "MOUNTPOINT / PATH")
	for _, v := range vaults {
		loc := v.Mountpoint
		if loc == "" {
			loc = v.Path
		}
		fmt.Fprintf(stdout, "%-20s %-10s %-10s %s\n", v.Name, v.State, formatBytes(v.SizeBytes), loc)
	}
	return nil
}

func cmdPreview(args []string, stdout io.Writer) error {
	if len(args) == 0 || strings.TrimSpace(args[0]) == "" {
		fmt.Fprintln(stdout, "No vault selected.\nPress Ctrl-N to create a new vault.")
		return nil
	}
	loops, _ := queryLoopDevices()
	blocks, _ := queryLsblk()
	v := inspectVaultPath(args[0], loops, blocks)

	fmt.Fprintf(stdout, "Path:       %s\n", v.Path)
	fmt.Fprintf(stdout, "State:      %s\n", v.State)
	fmt.Fprintf(stdout, "Size:       %s\n", formatBytes(v.SizeBytes))
	if v.LoopDev != "" {
		fmt.Fprintf(stdout, "Loop:       %s\n", v.LoopDev)
	}
	if v.MapperDev != "" {
		fmt.Fprintf(stdout, "Mapper:     %s\n", v.MapperDev)
	}
	if v.Mountpoint != "" {
		fmt.Fprintf(stdout, "Mountpoint: %s\n", v.Mountpoint)
	}
	if summary := luksSummary(v.Path); summary != "" {
		fmt.Fprintf(stdout, "\nLUKS2 Header:\n%s\n", summary)
	}
	return nil
}

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "vault: %v\n", err)
		os.Exit(1)
	}
}
