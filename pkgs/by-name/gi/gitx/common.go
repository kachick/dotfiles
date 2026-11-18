package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

const (
	defaultPlamoPort = "18080"
	defaultLogFormat = "format:%C(cyan)%ad %C(auto)%h %C(auto)%s %C(auto)%d"
)

func plamoServerURL() string {
	port := os.Getenv("PLAMO_PORT")
	if port == "" {
		port = defaultPlamoPort
	}
	return fmt.Sprintf("http://127.0.0.1:%s", port)
}

func isDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func isRegularOrSymlinkNonDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func resolveRealPath(path string) string {
	abs, err := filepath.Abs(path)
	if err != nil {
		return filepath.Clean(path)
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return abs
	}
	return resolved
}

func isSameOrInside(parentDir, targetPath string) bool {
	rel, err := filepath.Rel(parentDir, targetPath)
	if err != nil {
		return false
	}
	return rel == "." || (rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)))
}

func hasOriginRemote(r *gitcmd.Runner) bool {
	out, err := r.Output("remote")
	if err != nil {
		return false
	}
	return slices.Contains(strings.Fields(out), "origin")
}

func isDirenvAllowed(dir string) bool {
	cmd := exec.Command("direnv", "status", "--json")
	cmd.Dir = dir
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	var parsed struct {
		State struct {
			FoundRC *struct {
				Allowed int `json:"allowed"`
			} `json:"foundRC"`
		} `json:"state"`
	}
	if err := json.Unmarshal(out, &parsed); err != nil {
		return false
	}
	return parsed.State.FoundRC != nil && parsed.State.FoundRC.Allowed == 0
}

func allowDirenv(dir string, stderr io.Writer) error {
	cmd := exec.Command("direnv", "allow", dir)
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("direnv allow %s: %w", dir, err)
	}
	return nil
}

func allowDirenvIfTrusted(targetDir string, trusted bool, stderr io.Writer) error {
	if !trusted || !isRegularOrSymlinkNonDir(filepath.Join(targetDir, ".envrc")) {
		return nil
	}
	return allowDirenv(targetDir, stderr)
}

func maybeAllowExtraWorktreeDirenv(targetDir, currentWT string, wasTrusted, trust bool, stderr io.Writer) error {
	envrcPath := filepath.Join(targetDir, ".envrc")
	if !isRegularOrSymlinkNonDir(envrcPath) {
		return nil
	}
	if trust {
		return allowDirenv(targetDir, stderr)
	}
	if !wasTrusted {
		return nil
	}

	targetBytes, err := os.ReadFile(envrcPath)
	if err != nil {
		return err
	}
	currentBytes, err := os.ReadFile(filepath.Join(currentWT, ".envrc"))
	if err != nil || !bytes.Equal(targetBytes, currentBytes) {
		return nil
	}
	// Only auto-allow when the extra worktree's .envrc matches the already-trusted current worktree.
	return allowDirenv(targetDir, stderr)
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func isTerminal(w io.Writer) bool {
	f, ok := w.(*os.File)
	if !ok {
		return false
	}
	stat, err := f.Stat()
	if err != nil {
		return false
	}
	return (stat.Mode() & os.ModeCharDevice) != 0
}

func isCancelExitError(err error) bool {
	var exitErr *exec.ExitError
	return errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130)
}
