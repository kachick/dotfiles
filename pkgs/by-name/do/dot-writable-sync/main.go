package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/kachick/dotfiles/internal/configsync"
)

const usage = `Usage: dot-writable-sync <SUB> [OPTIONS]

Repository-internal Home Manager helper to initialize writable config files.

Subcommands:
  sync    Sync writable config entries from a JSON manifest
`

type manifestItem struct {
	Source string `json:"source"`
	Dest   string `json:"dest"`
	Perm   string `json:"perm"`
}

type stateFile struct {
	Files map[string]fileState `json:"files"`
}

type fileState struct {
	SourceSHA256 string `json:"source_sha256"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	switch os.Args[1] {
	case "sync":
		syncCmd := flag.NewFlagSet("sync", flag.ExitOnError)
		manifestFlag := syncCmd.String("manifest", "", "Path to JSON manifest file")
		stateFlag := syncCmd.String("state", "", "Path to state JSON file")
		dryRunFlag := syncCmd.Bool("dry-run", false, "Show planned updates without writing files")

		if err := syncCmd.Parse(os.Args[2:]); err != nil {
			log.Fatalf("parsing flags: %+v", err)
		}
		if *manifestFlag == "" {
			log.Fatalln("--manifest is required")
		}
		if err := runSync(*manifestFlag, *stateFlag, *dryRunFlag); err != nil {
			log.Fatalf("sync failed: %+v", err)
		}
	default:
		fmt.Fprintf(os.Stderr, "unknown subcommand %q\n\n%s", os.Args[1], usage)
		os.Exit(1)
	}
}

func runSync(manifestPath, statePath string, dryRun bool) error {
	items, err := loadManifest(manifestPath)
	if err != nil {
		return err
	}
	if len(items) == 0 {
		return nil
	}

	if statePath == "" {
		statePath, err = defaultStatePath()
		if err != nil {
			return err
		}
	}

	state, err := loadState(statePath)
	if err != nil {
		return err
	}

	entries, err := buildEntries(items)
	if err != nil {
		return err
	}

	dirtyState := false
	results, err := configsync.Sync(entries, configsync.Options{
		DryRun:   dryRun,
		Conflict: configsync.ConflictWarnOverwrite,
		PrevHash: func(dstPath string) (string, bool) {
			st, ok := state.Files[dstPath]
			return st.SourceSHA256, ok && st.SourceSHA256 != ""
		},
		OnWritten: func(dstPath, srcHash string) error {
			prev, ok := state.Files[dstPath]
			if !ok || prev.SourceSHA256 != srcHash {
				state.Files[dstPath] = fileState{SourceSHA256: srcHash}
				dirtyState = true
			}
			return nil
		},
	})
	if err != nil {
		return err
	}

	for _, r := range results {
		if r.Status == configsync.StatusUnchanged {
			continue
		}
		fmt.Fprintf(os.Stderr, "dot-writable-sync [%s]: %s\n", r.Status, r.DstPath)
		if dryRun && r.Diff != "" {
			fmt.Fprint(os.Stderr, r.Diff)
		}
	}

	if !dryRun && dirtyState {
		if err := saveState(statePath, state); err != nil {
			return err
		}
	}
	return nil
}

func loadManifest(path string) ([]manifestItem, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading manifest %s: %w", path, err)
	}
	var items []manifestItem
	if err := json.Unmarshal(raw, &items); err != nil {
		return nil, fmt.Errorf("parsing manifest %s: %w", path, err)
	}
	return items, nil
}

func defaultStatePath() (string, error) {
	stateHome := os.Getenv("XDG_STATE_HOME")
	if stateHome == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("resolving home directory for state: %w", err)
		}
		stateHome = filepath.Join(home, ".local", "state")
	}
	return filepath.Join(stateHome, "dot-writable-sync", "state.json"), nil
}

func loadState(path string) (stateFile, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return stateFile{Files: make(map[string]fileState)}, nil
		}
		return stateFile{}, fmt.Errorf("reading state %s: %w", path, err)
	}
	var s stateFile
	if err := json.Unmarshal(raw, &s); err != nil {
		return stateFile{}, fmt.Errorf("parsing state %s: %w", path, err)
	}
	if s.Files == nil {
		s.Files = make(map[string]fileState)
	}
	return s, nil
}

func saveState(path string, state stateFile) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("creating state directory for %s: %w", path, err)
	}
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return fmt.Errorf("encoding state: %w", err)
	}
	data = append(data, '\n')
	if err := os.WriteFile(path, data, 0o600); err != nil {
		return fmt.Errorf("writing state %s: %w", path, err)
	}
	return nil
}

func buildEntries(items []manifestItem) ([]configsync.Entry, error) {
	entries := make([]configsync.Entry, 0, len(items))
	for _, item := range items {
		info, err := os.Stat(item.Source)
		if err != nil {
			return nil, fmt.Errorf("stat source %s: %w", item.Source, err)
		}
		perm, err := parsePerm(item.Perm, info.Mode().Perm())
		if err != nil {
			return nil, fmt.Errorf("parsing perm %q for %s: %w", item.Perm, item.Dest, err)
		}
		if info.IsDir() {
			entries = append(entries, configsync.Entry{
				SrcFS:   os.DirFS(item.Source),
				SrcPath: ".",
				DstPath: item.Dest,
				Perm:    perm,
				DirPerm: 0o755,
				IsDir:   true,
			})
			continue
		}
		entries = append(entries, configsync.Entry{
			SrcFS:   os.DirFS(filepath.Dir(item.Source)),
			SrcPath: filepath.Base(item.Source),
			DstPath: item.Dest,
			Perm:    perm,
			DirPerm: 0o755,
		})
	}
	return entries, nil
}

// parsePerm interprets chmod-style octal ("600", "0644") or symbolic ("u+w", "u=rw,go=r") modes.
func parsePerm(spec string, base fs.FileMode) (fs.FileMode, error) {
	spec = strings.TrimSpace(spec)
	if spec == "" {
		return 0o644, nil
	}
	if mode, err := strconv.ParseUint(spec, 8, 32); err == nil {
		return fs.FileMode(mode) & fs.ModePerm, nil
	}

	mode := base & fs.ModePerm
	if mode == 0 {
		mode = 0o444
	}

	for clause := range strings.SplitSeq(spec, ",") {
		clause = strings.TrimSpace(clause)
		opIdx := strings.IndexAny(clause, "+-=")
		if opIdx == -1 {
			return 0, fmt.Errorf("unsupported mode clause %q", clause)
		}
		who := clause[:opIdx]
		if who == "" {
			who = "a"
		}
		op := clause[opIdx]
		permsStr := clause[opIdx+1:]

		var permBits fs.FileMode
		for _, ch := range permsStr {
			switch ch {
			case 'r':
				permBits |= 0o4
			case 'w':
				permBits |= 0o2
			case 'x':
				permBits |= 0o1
			default:
				return 0, fmt.Errorf("unsupported permission char %q in %q", ch, clause)
			}
		}

		var shifts []uint
		for _, w := range who {
			switch w {
			case 'u':
				shifts = append(shifts, 6)
			case 'g':
				shifts = append(shifts, 3)
			case 'o':
				shifts = append(shifts, 0)
			case 'a':
				shifts = append(shifts, 6, 3, 0)
			default:
				return 0, fmt.Errorf("unsupported target %q in %q", w, clause)
			}
		}

		for _, shift := range shifts {
			shifted := permBits << shift
			mask := fs.FileMode(0o7) << shift
			switch op {
			case '+':
				mode |= shifted
			case '-':
				mode &^= shifted
			case '=':
				mode = (mode &^ mask) | shifted
			}
		}
	}
	return mode, nil
}
