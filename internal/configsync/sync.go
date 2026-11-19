package configsync

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"strings"
)

// ConflictPolicy controls how Sync handles a destination file that differs from the source.
type ConflictPolicy uint8

const (
	ConflictSkip ConflictPolicy = iota
	ConflictOverwrite
	ConflictBackup
	ConflictPrompt
	ConflictWarnOverwrite
)

// Status describes the action taken (or planned in DryRun mode) for one destination file.
type Status string

const (
	StatusCreated     Status = "created"
	StatusUpdated     Status = "updated"
	StatusOverwritten Status = "overwritten"
	StatusBackedUp    Status = "backed-up"
	StatusUnchanged   Status = "unchanged"
	StatusSkipped     Status = "skipped"
	StatusWouldCreate Status = "would-create"
	StatusWouldUpdate Status = "would-update"
)

const defaultDirPerm fs.FileMode = 0o750

// Entry defines a single file or directory tree to sync from SrcFS into DstPath.
type Entry struct {
	SrcFS   fs.FS
	SrcPath string
	DstPath string
	Perm    fs.FileMode
	DirPerm fs.FileMode
	IsDir   bool
}

// Result records the outcome for one synced destination file.
type Result struct {
	SrcPath    string
	DstPath    string
	Status     Status
	Diff       string
	BackupPath string
	Warned     bool
}

// Options configures Sync behavior, state tracking, and interactive conflict prompts.
type Options struct {
	DryRun        bool
	Conflict      ConflictPolicy
	PrevHash      func(dstPath string) (string, bool)
	OnWritten     func(dstPath, srcHash string) error
	In            io.Reader
	Out           io.Writer
	ErrOut        io.Writer
	IsInteractive func() bool
}

// SHA256Hex returns the lowercase hexadecimal SHA-256 digest of data.
func SHA256Hex(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

// Sync applies all entries according to opts and returns per-file results.
func Sync(entries []Entry, opts Options) ([]Result, error) {
	if opts.In == nil {
		opts.In = os.Stdin
	}
	if opts.Out == nil {
		opts.Out = os.Stdout
	}
	if opts.ErrOut == nil {
		opts.ErrOut = os.Stderr
	}
	if opts.IsInteractive == nil {
		opts.IsInteractive = func() bool {
			f, ok := opts.In.(*os.File)
			if !ok {
				return false
			}
			info, err := f.Stat()
			if err != nil {
				return false
			}
			return (info.Mode() & os.ModeCharDevice) != 0
		}
	}

	var results []Result
	reader := bufio.NewReader(opts.In)
	overwriteAll := false

	for _, entry := range entries {
		files, err := expandEntry(entry)
		if err != nil {
			return results, err
		}
		for _, f := range files {
			res, err := syncOne(f, opts, reader, &overwriteAll)
			if err != nil {
				return results, err
			}
			results = append(results, res)
		}
	}
	return results, nil
}

type fileSpec struct {
	srcFS   fs.FS
	srcPath string
	dstPath string
	perm    fs.FileMode
	dirPerm fs.FileMode
}

func expandEntry(entry Entry) ([]fileSpec, error) {
	dirPerm := entry.DirPerm
	if dirPerm == 0 {
		dirPerm = defaultDirPerm
	}

	if !entry.IsDir {
		return []fileSpec{{
			srcFS:   entry.SrcFS,
			srcPath: entry.SrcPath,
			dstPath: entry.DstPath,
			perm:    entry.Perm,
			dirPerm: dirPerm,
		}}, nil
	}

	var files []fileSpec
	err := fs.WalkDir(entry.SrcFS, entry.SrcPath, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		rel := strings.TrimPrefix(p, entry.SrcPath)
		rel = strings.TrimPrefix(rel, "/")
		if rel == "" {
			rel = path.Base(p)
		}
		files = append(files, fileSpec{
			srcFS:   entry.SrcFS,
			srcPath: p,
			dstPath: filepath.Join(entry.DstPath, filepath.FromSlash(rel)),
			perm:    entry.Perm,
			dirPerm: dirPerm,
		})
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("walking %s: %w", entry.SrcPath, err)
	}
	if len(files) == 0 {
		return nil, fmt.Errorf("directory %s has no files", entry.SrcPath)
	}
	return files, nil
}

func syncOne(f fileSpec, opts Options, reader *bufio.Reader, overwriteAll *bool) (Result, error) {
	srcBytes, err := fs.ReadFile(f.srcFS, f.srcPath)
	if err != nil {
		return Result{}, fmt.Errorf("reading source %s: %w", f.srcPath, err)
	}
	srcHash := SHA256Hex(srcBytes)

	info, lstatErr := os.Lstat(f.dstPath)
	if lstatErr != nil {
		if !errors.Is(lstatErr, os.ErrNotExist) {
			return Result{}, fmt.Errorf("stat %s: %w", f.dstPath, lstatErr)
		}
		if opts.DryRun {
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusWouldCreate}, nil
		}
		if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
			return Result{}, err
		}
		if opts.OnWritten != nil {
			if err := opts.OnWritten(f.dstPath, srcHash); err != nil {
				return Result{}, err
			}
		}
		return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusCreated}, nil
	}

	// Replace leftover symlinks (such as old Home Manager store links) directly.
	var dstBytes []byte
	isSymlink := (info.Mode() & os.ModeSymlink) != 0
	if !isSymlink {
		dstBytes, err = os.ReadFile(f.dstPath)
		if err != nil {
			return Result{}, fmt.Errorf("reading destination %s: %w", f.dstPath, err)
		}
		if bytes.Equal(dstBytes, srcBytes) {
			if !opts.DryRun && opts.OnWritten != nil {
				if err := opts.OnWritten(f.dstPath, srcHash); err != nil {
					return Result{}, err
				}
			}
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusUnchanged}, nil
		}
	}

	// When state tracking confirms no local edits occurred since the last sync, update cleanly.
	if !isSymlink && opts.PrevHash != nil {
		if prev, ok := opts.PrevHash(f.dstPath); ok && SHA256Hex(dstBytes) == prev {
			diff := UnifiedDiff(f.dstPath, f.srcPath, dstBytes, srcBytes)
			if opts.DryRun {
				return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusWouldUpdate, Diff: diff}, nil
			}
			if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
				return Result{}, err
			}
			if err := opts.OnWritten(f.dstPath, srcHash); err != nil {
				return Result{}, err
			}
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusUpdated, Diff: diff}, nil
		}
	}

	var diff string
	if isSymlink {
		target, _ := os.Readlink(f.dstPath)
		diff = fmt.Sprintf("--- %s (symlink -> %s)\n+++ %s\n", f.dstPath, target, f.srcPath)
	} else {
		diff = UnifiedDiff(f.dstPath, f.srcPath, dstBytes, srcBytes)
	}

	if opts.DryRun {
		return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusWouldUpdate, Diff: diff}, nil
	}

	policy := opts.Conflict
	if policy == ConflictPrompt && *overwriteAll {
		policy = ConflictOverwrite
	}

	switch policy {
	case ConflictSkip:
		return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusSkipped, Diff: diff}, nil

	case ConflictOverwrite:
		if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
			return Result{}, err
		}
		if opts.OnWritten != nil {
			if err := opts.OnWritten(f.dstPath, srcHash); err != nil {
				return Result{}, err
			}
		}
		return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusOverwritten, Diff: diff}, nil

	case ConflictWarnOverwrite:
		fmt.Fprintf(opts.ErrOut, "warning: local changes in %s will be overwritten\n%s", f.dstPath, diff)
		if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
			return Result{}, err
		}
		if opts.OnWritten != nil {
			if err := opts.OnWritten(f.dstPath, srcHash); err != nil {
				return Result{}, err
			}
		}
		return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusOverwritten, Diff: diff, Warned: true}, nil

	case ConflictBackup:
		backupPath, err := backupFile(f.dstPath)
		if err != nil {
			return Result{}, err
		}
		if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
			return Result{}, err
		}
		if opts.OnWritten != nil {
			if err := opts.OnWritten(f.dstPath, srcHash); err != nil {
				return Result{}, err
			}
		}
		return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusBackedUp, Diff: diff, BackupPath: backupPath}, nil

	case ConflictPrompt:
		fmt.Fprintf(opts.Out, "\n%s", diff)
		if !opts.IsInteractive() {
			fmt.Fprintf(opts.ErrOut, "skipping %s (differs; non-interactive session, pass --force or --backup to apply)\n", f.dstPath)
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusSkipped, Diff: diff}, nil
		}
		choice, err := promptChoice(reader, opts.Out, f.dstPath)
		if err != nil {
			return Result{}, err
		}
		switch choice {
		case "o":
			if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
				return Result{}, err
			}
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusOverwritten, Diff: diff}, nil
		case "a":
			*overwriteAll = true
			if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
				return Result{}, err
			}
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusOverwritten, Diff: diff}, nil
		case "b":
			backupPath, err := backupFile(f.dstPath)
			if err != nil {
				return Result{}, err
			}
			if err := writeTarget(f.dstPath, srcBytes, f.perm, f.dirPerm); err != nil {
				return Result{}, err
			}
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusBackedUp, Diff: diff, BackupPath: backupPath}, nil
		default:
			return Result{SrcPath: f.srcPath, DstPath: f.dstPath, Status: StatusSkipped, Diff: diff}, nil
		}

	default:
		return Result{}, fmt.Errorf("unknown conflict policy: %d", policy)
	}
}

func promptChoice(reader *bufio.Reader, out io.Writer, dstPath string) (string, error) {
	for {
		fmt.Fprintf(out, "Conflict for %s: [o]verwrite / [s]kip / [b]ackup / [a]ll overwrite [default: s]: ", dstPath)
		line, err := reader.ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return "", fmt.Errorf("reading prompt input: %w", err)
		}
		choice := strings.ToLower(strings.TrimSpace(line))
		switch choice {
		case "", "s", "skip":
			return "s", nil
		case "o", "overwrite":
			return "o", nil
		case "b", "backup":
			return "b", nil
		case "a", "all":
			return "a", nil
		default:
			if errors.Is(err, io.EOF) {
				return "s", nil
			}
			fmt.Fprintf(out, "Invalid choice %q. Enter o, s, b, or a.\n", choice)
		}
	}
}

func backupFile(dstPath string) (string, error) {
	backupPath := dstPath + ".bak"
	body, err := os.ReadFile(dstPath)
	if err != nil {
		return "", fmt.Errorf("reading %s for backup: %w", dstPath, err)
	}
	info, err := os.Stat(dstPath)
	if err != nil {
		return "", fmt.Errorf("stat %s for backup: %w", dstPath, err)
	}
	if err := os.WriteFile(backupPath, body, info.Mode().Perm()); err != nil {
		return "", fmt.Errorf("writing backup %s: %w", backupPath, err)
	}
	return backupPath, nil
}

func writeTarget(dstPath string, data []byte, perm, dirPerm fs.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(dstPath), dirPerm); err != nil {
		return fmt.Errorf("creating parent directory for %s: %w", dstPath, err)
	}
	// Remove an existing symlink or read-only file before writing the writable copy.
	if info, err := os.Lstat(dstPath); err == nil {
		if (info.Mode()&os.ModeSymlink) != 0 || (info.Mode().Perm()&0o200) == 0 {
			if err := os.Remove(dstPath); err != nil {
				return fmt.Errorf("removing %s: %w", dstPath, err)
			}
		}
	}
	if err := os.WriteFile(dstPath, data, perm); err != nil {
		return fmt.Errorf("writing %s: %w", dstPath, err)
	}
	if err := os.Chmod(dstPath, perm); err != nil {
		return fmt.Errorf("chmod %s: %w", dstPath, err)
	}
	return nil
}
