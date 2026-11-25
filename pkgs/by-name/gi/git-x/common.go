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

// recoverDeletedWorkDir moves the process to the nearest existing directory of $PWD
// when the current directory was removed, for example by `git worktree remove` from another shell.
// Git refuses to start in a removed directory, and child processes such as fzf previews would inherit it,
// so passing a fallback workDir only to gitcmd runners is not enough.
// It keeps the original behavior when $PWD cannot be trusted.
func recoverDeletedWorkDir(stderr io.Writer) error {
	if _, err := os.Getwd(); err == nil {
		return nil
	}
	pwd := os.Getenv("PWD")
	if !filepath.IsAbs(pwd) {
		return nil
	}
	for dir := filepath.Clean(pwd); ; dir = filepath.Dir(dir) {
		if isDir(dir) {
			if err := os.Chdir(dir); err != nil {
				return fmt.Errorf("change to existing directory %s: %w", dir, err)
			}
			if err := os.Setenv("PWD", dir); err != nil {
				return fmt.Errorf("update PWD: %w", err)
			}
			fmt.Fprintf(stderr, "Current directory no longer exists; using %s\n", dir)
			return nil
		}
		if parent := filepath.Dir(dir); parent == dir {
			return nil
		}
	}
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

func commonFzfStyleArgs(borderLabel, header string) []string {
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
		"--border-label=" + borderLabel,
		"--header=" + header,
		"--bind=ctrl-/:change-preview-window(down,60%|hidden|)",
	}
}
