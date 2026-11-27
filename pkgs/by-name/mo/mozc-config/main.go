package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/kachick/dotfiles/internal/configsync"
)

const (
	mozcConfigMessage = "mozc.config.Config"
	mozcConfigProto   = "protocol/config.proto"
)

const usage = `Usage: mozc-config <SUB> [OPTIONS]

Inspect, diff, generate, and reload Mozc user configuration (config1.db).

Subcommands:
  dump    Decode a config1.db file into textproto format
  diff    Show a unified textproto diff between expected and target config1.db
  encode  Encode a custom keymap TSV file into a binary config1.db
  reload  Refresh IBus cache/daemon and restart mozc_server
`

func main() {
	log.SetFlags(0)
	if len(os.Args) < 2 {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(2)
	}

	var exitCode int
	var err error
	switch os.Args[1] {
	case "dump":
		err = runDump(os.Args[2:], os.Stdout)
	case "diff":
		exitCode, err = runDiff(os.Args[2:], os.Stdout)
	case "encode":
		err = runEncode(os.Args[2:], os.Stdout)
	case "reload":
		err = runReload(os.Args[2:])
	case "-h", "--help", "help":
		fmt.Fprint(os.Stdout, usage)
		return
	default:
		fmt.Fprintf(os.Stderr, "unknown subcommand %q\n\n%s", os.Args[1], usage)
		os.Exit(2)
	}

	if err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return
		}
		log.Fatalf("mozc-config %s: %v", os.Args[1], err)
	}
	if exitCode != 0 {
		os.Exit(exitCode)
	}
}

func defaultConfigDBPath() (string, error) {
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return filepath.Join(xdg, "mozc", "config1.db"), nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("resolving home directory: %w", err)
	}
	return filepath.Join(home, ".config", "mozc", "config1.db"), nil
}

func resolveProtoDir(flagVal string) (string, error) {
	if flagVal != "" {
		return flagVal, nil
	}
	if env := os.Getenv("MOZC_PROTO_DIR"); env != "" {
		return env, nil
	}
	return "", errors.New("proto directory not set; pass --proto-dir or set MOZC_PROTO_DIR")
}

func runDump(args []string, out io.Writer) error {
	fs := flag.NewFlagSet("dump", flag.ContinueOnError)
	protoDirFlag := fs.String("proto-dir", "", "Directory containing protocol/config.proto (default: $MOZC_PROTO_DIR)")
	if err := fs.Parse(args); err != nil {
		return err
	}

	protoDir, err := resolveProtoDir(*protoDirFlag)
	if err != nil {
		return err
	}

	targetPath := fs.Arg(0)
	if targetPath == "" {
		targetPath, err = defaultConfigDBPath()
		if err != nil {
			return err
		}
	}

	raw, err := os.ReadFile(targetPath)
	if err != nil {
		return fmt.Errorf("reading %s: %w", targetPath, err)
	}

	decoded, err := decodeConfigDB(protoDir, raw)
	if err != nil {
		return fmt.Errorf("decoding %s: %w", targetPath, err)
	}

	_, err = out.Write(decoded)
	return err
}

func runDiff(args []string, out io.Writer) (int, error) {
	fs := flag.NewFlagSet("diff", flag.ContinueOnError)
	protoDirFlag := fs.String("proto-dir", "", "Directory containing protocol/config.proto (default: $MOZC_PROTO_DIR)")
	expectedFlag := fs.String("expected", "", "Expected config1.db path (default: $MOZC_EXPECTED_CONFIG_DB)")
	if err := fs.Parse(args); err != nil {
		return 2, err
	}

	protoDir, err := resolveProtoDir(*protoDirFlag)
	if err != nil {
		return 2, err
	}

	expectedPath := *expectedFlag
	if expectedPath == "" {
		expectedPath = os.Getenv("MOZC_EXPECTED_CONFIG_DB")
	}
	if expectedPath == "" {
		return 2, errors.New("expected config path not set; pass --expected or set MOZC_EXPECTED_CONFIG_DB")
	}

	targetPath := fs.Arg(0)
	if targetPath == "" {
		targetPath, err = defaultConfigDBPath()
		if err != nil {
			return 2, err
		}
	}

	expectedRaw, err := os.ReadFile(expectedPath)
	if err != nil {
		return 2, fmt.Errorf("reading expected %s: %w", expectedPath, err)
	}
	targetRaw, err := os.ReadFile(targetPath)
	if err != nil {
		return 2, fmt.Errorf("reading target %s: %w", targetPath, err)
	}

	expectedText, err := decodeConfigDB(protoDir, expectedRaw)
	if err != nil {
		return 2, fmt.Errorf("decoding expected %s: %w", expectedPath, err)
	}
	targetText, err := decodeConfigDB(protoDir, targetRaw)
	if err != nil {
		return 2, fmt.Errorf("decoding target %s: %w", targetPath, err)
	}

	diff := configsync.UnifiedDiff(expectedPath, targetPath, expectedText, targetText)
	if diff == "" {
		return 0, nil
	}
	if _, err := io.WriteString(out, diff); err != nil {
		return 2, err
	}
	return 1, nil
}

func runEncode(args []string, out io.Writer) error {
	fs := flag.NewFlagSet("encode", flag.ContinueOnError)
	protoDirFlag := fs.String("proto-dir", "", "Directory containing protocol/config.proto (default: $MOZC_PROTO_DIR)")
	keymapFlag := fs.String("keymap", "", "Path to Mozc custom keymap TSV file")
	outputFlag := fs.String("output", "", "Output path for binary config1.db (default: stdout)")
	if err := fs.Parse(args); err != nil {
		return err
	}

	protoDir, err := resolveProtoDir(*protoDirFlag)
	if err != nil {
		return err
	}
	if *keymapFlag == "" {
		return errors.New("--keymap is required")
	}

	keymapRaw, err := os.ReadFile(*keymapFlag)
	if err != nil {
		return fmt.Errorf("reading keymap %s: %w", *keymapFlag, err)
	}

	textproto := buildCustomKeymapTextproto(keymapRaw)
	encoded, err := encodeConfigDB(protoDir, textproto)
	if err != nil {
		return err
	}

	if *outputFlag == "" {
		_, err = out.Write(encoded)
		return err
	}

	if err := os.MkdirAll(filepath.Dir(*outputFlag), 0o755); err != nil {
		return fmt.Errorf("creating directory for %s: %w", *outputFlag, err)
	}
	if err := os.WriteFile(*outputFlag, encoded, 0o644); err != nil {
		return fmt.Errorf("writing %s: %w", *outputFlag, err)
	}
	return nil
}

func runReload(args []string) error {
	fs := flag.NewFlagSet("reload", flag.ContinueOnError)
	ifRunningFlag := fs.Bool("if-running", false, "Skip silently when IBus is not running")
	if err := fs.Parse(args); err != nil {
		return err
	}

	if *ifRunningFlag {
		if _, err := exec.LookPath("ibus"); err != nil {
			return nil
		}
		if err := exec.Command("ibus", "address").Run(); err != nil {
			return nil
		}
	}

	if err := runCommand("ibus", "write-cache"); err != nil {
		return err
	}
	if err := runCommand("ibus", "restart"); err != nil {
		return err
	}

	// Restart mozc_server so it drops cached settings and reads the updated config1.db on next input.
	if _, err := exec.LookPath("pkill"); err == nil {
		cmd := exec.Command("pkill", "--exact", "mozc_server")
		if err := cmd.Run(); err != nil {
			var exitErr *exec.ExitError
			// pkill exits with 1 when no matching process is running.
			if !errors.As(err, &exitErr) || exitErr.ExitCode() != 1 {
				return fmt.Errorf("pkill --exact mozc_server: %w", err)
			}
		}
	}
	return nil
}

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		msg := strings.TrimSpace(stderr.String())
		if msg != "" {
			return fmt.Errorf("%s %s: %w (%s)", name, strings.Join(args, " "), err, msg)
		}
		return fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
	}
	return nil
}

func buildCustomKeymapTextproto(keymap []byte) []byte {
	var b strings.Builder
	b.WriteString("session_keymap: CUSTOM\n")
	b.WriteString("custom_keymap_table: ")
	b.WriteString(strconv.Quote(string(keymap)))
	b.WriteByte('\n')
	return []byte(b.String())
}

func encodeConfigDB(protoDir string, textproto []byte) ([]byte, error) {
	return runProtoc(protoDir, "--encode="+mozcConfigMessage, textproto)
}

func decodeConfigDB(protoDir string, binary []byte) ([]byte, error) {
	return runProtoc(protoDir, "--decode="+mozcConfigMessage, binary)
}

func runProtoc(protoDir, modeFlag string, stdin []byte) ([]byte, error) {
	cmd := exec.Command("protoc", "--proto_path="+protoDir, modeFlag, mozcConfigProto)
	cmd.Stdin = bytes.NewReader(stdin)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		msg := strings.TrimSpace(stderr.String())
		if msg != "" {
			return nil, fmt.Errorf("protoc %s: %w (%s)", modeFlag, err, msg)
		}
		return nil, fmt.Errorf("protoc %s: %w", modeFlag, err)
	}
	return stdout.Bytes(), nil
}
