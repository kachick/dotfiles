package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/kachick/dotfiles/internal/gitcmd"
	"github.com/kachick/dotfiles/internal/plamocache"
)

const (
	maxParallelSlots           = 4
	maxPrefetchSlots           = 2
	commitIndexLimit           = 2000
	menuCommitBorderLabelPlain = "🪵 Commits (Ctrl-G)"
	menuCommitBorderLabelJa    = "🪵 Commits (ja) (Ctrl-G)"
	jaEnabledFilename          = "ja_enabled"
	previewColsFilename        = "preview_cols"
)

type commitIndex struct {
	commits []string
	idxMap  map[string]int
}

var ansiRegex = regexp.MustCompile(`\x1b\[[0-9;]*[a-zA-Z]`)

func localeDefaultsToJa() bool {
	for _, key := range []string{"LC_ALL", "LC_MESSAGES", "LANG"} {
		val := strings.TrimSpace(os.Getenv(key))
		if val == "" {
			continue
		}
		lower := strings.ToLower(val)
		return lower == "ja" || strings.HasPrefix(lower, "ja_") || strings.HasPrefix(lower, "ja-")
	}
	return false
}

func menuCommitBorderLabel(ja bool) string {
	if ja {
		return menuCommitBorderLabelJa
	}
	return menuCommitBorderLabelPlain
}

func cleanRev(raw string) string {
	clean := ansiRegex.ReplaceAllString(raw, "")
	fields := strings.Fields(clean)
	if len(fields) >= 2 {
		// git log format: "<date> <hash> <message>..."
		return fields[1]
	}
	if len(fields) == 1 {
		// Single token passed via fzf {2}
		return fields[0]
	}
	return ""
}

func sendRefreshPreview(sockPath string) error {
	if _, err := os.Stat(sockPath); err != nil {
		return err
	}

	client := &http.Client{
		Timeout: 200 * time.Millisecond,
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
				return (&net.Dialer{}).DialContext(ctx, "unix", sockPath)
			},
		},
	}
	req, err := http.NewRequest(http.MethodPost, "http://localhost", strings.NewReader("refresh-preview"))
	if err != nil {
		return err
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	resp.Body.Close()
	return nil
}

func checkPlamoHealth(serverURL string) bool {
	client := &http.Client{Timeout: 200 * time.Millisecond}
	resp, err := client.Get(serverURL + "/health")
	if err != nil {
		return false
	}
	resp.Body.Close()
	return resp.StatusCode == http.StatusOK
}

func renderCmdPipeline(cmd1 *exec.Cmd, stdout, stderr io.Writer) error {
	riffPath, errRiff := exec.LookPath("riff")
	batPath, errBat := exec.LookPath("bat")

	if errRiff != nil || errBat != nil {
		cmd1.Stdout = stdout
		cmd1.Stderr = stderr
		return cmd1.Run()
	}

	cmd2 := exec.Command(riffPath, "--color=on")
	cmd3 := exec.Command(batPath, "--language=gitlog", "--color=always", "--style=plain", "--wrap=character")

	r1, w1 := io.Pipe()
	r2, w2 := io.Pipe()

	cmd1.Stdout = w1
	cmd1.Stderr = stderr

	cmd2.Stdin = r1
	cmd2.Stdout = w2
	cmd2.Stderr = stderr

	cmd3.Stdin = r2
	cmd3.Stdout = stdout
	cmd3.Stderr = stderr

	if err := cmd1.Start(); err != nil {
		_ = w1.Close()
		_ = w2.Close()
		return err
	}
	if err := cmd2.Start(); err != nil {
		_ = w1.Close()
		_ = w2.Close()
		_ = cmd1.Wait()
		return err
	}
	if err := cmd3.Start(); err != nil {
		_ = w1.Close()
		_ = w2.Close()
		_ = cmd1.Wait()
		_ = cmd2.Wait()
		return err
	}

	go func() {
		_ = cmd1.Wait()
		_ = w1.Close()
	}()
	go func() {
		_ = cmd2.Wait()
		_ = w2.Close()
	}()

	return cmd3.Wait()
}

func renderCommitInDir(selfExe, workDir, rev, placeholder string, columns int, stdout, stderr io.Writer) error {
	showArgs := []string{"show", "--ja"}
	if placeholder != "" {
		showArgs = append(showArgs, "--placeholder", placeholder)
	}
	if columns > 0 {
		showArgs = append(showArgs, "--columns", strconv.Itoa(columns))
	}
	showArgs = append(showArgs, "--color=always", rev)

	cmd := exec.Command(selfExe, showArgs...)
	if workDir != "" {
		cmd.Dir = workDir
	}
	return renderCmdPipeline(cmd, stdout, stderr)
}

func envPreviewColumns() int {
	n, err := strconv.Atoi(strings.TrimSpace(os.Getenv("FZF_PREVIEW_COLUMNS")))
	if err != nil || n <= 0 {
		return 0
	}
	return n
}

func savePreviewColumns(cacheDir string, cols int) {
	if cacheDir == "" || cols <= 0 {
		return
	}
	path := filepath.Join(cacheDir, previewColsFilename)
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, []byte(strconv.Itoa(cols)), 0o600); err == nil {
		_ = os.Rename(tmp, path)
	}
}

func loadPreviewColumns(cacheDir string) int {
	if cacheDir == "" {
		return 0
	}
	data, err := os.ReadFile(filepath.Join(cacheDir, previewColsFilename))
	if err != nil {
		return 0
	}
	n, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil || n <= 0 {
		return 0
	}
	return n
}

func previewCachePath(cacheDir, rev string, cols int) string {
	if cols > 0 {
		return filepath.Join(cacheDir, fmt.Sprintf("%s.%d.out", rev, cols))
	}
	return filepath.Join(cacheDir, rev+".out")
}

func hasPersistentTranslation(workDir, rev string) bool {
	cacheDir, err := plamocache.Dir()
	if err != nil {
		return false
	}
	msg, _, systemPrompt, err := loadCommitTranslationInput(rev, workDir)
	if err != nil {
		return false
	}
	_, ok := plamocache.Read(cacheDir, plamocache.Key(systemPrompt, msg))
	return ok
}

func isJaEnabled(cacheDir string) bool {
	if cacheDir == "" {
		return false
	}
	_, err := os.Stat(filepath.Join(cacheDir, jaEnabledFilename))
	return err == nil
}

func setJaEnabled(cacheDir string, enabled bool) error {
	if cacheDir == "" {
		return nil
	}
	path := filepath.Join(cacheDir, jaEnabledFilename)
	if enabled {
		return os.WriteFile(path, []byte("1"), 0o600)
	}
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

func menuRunToggleJa(cacheDir string, stdout io.Writer) error {
	next := !isJaEnabled(cacheDir)
	if err := setJaEnabled(cacheDir, next); err != nil {
		return err
	}
	_, err := fmt.Fprintf(stdout, "change-border-label(%s)+refresh-preview\n", menuCommitBorderLabel(next))
	return err
}

func menuRunCommitPreview(selfExe, workDir, cacheDir, rawItem string, stdout, stderr io.Writer) error {
	rev := cleanRev(rawItem)
	if rev == "" {
		return nil
	}

	if !isJaEnabled(cacheDir) {
		return renderPlainCommitInDir(workDir, rev, stdout, stderr)
	}

	cols := envPreviewColumns()
	savePreviewColumns(cacheDir, cols)

	focusFile := filepath.Join(cacheDir, "current_focus")
	focusTmp := focusFile + ".tmp"
	if err := os.WriteFile(focusTmp, []byte(rev), 0o600); err == nil {
		_ = os.Rename(focusTmp, focusFile)
	}

	outPath := previewCachePath(cacheDir, rev, cols)
	if data, err := os.ReadFile(outPath); err == nil {
		_, err = stdout.Write(data)
		return err
	}

	if hasPersistentTranslation(workDir, rev) {
		var buf bytes.Buffer
		if err := renderCommitInDir(selfExe, workDir, rev, "", cols, &buf, stderr); err == nil {
			tmpOutPath := outPath + ".tmp"
			if writeErr := os.WriteFile(tmpOutPath, buf.Bytes(), 0o600); writeErr == nil {
				_ = os.Rename(tmpOutPath, outPath)
			}
			_, err = stdout.Write(buf.Bytes())
			return err
		}
	}

	placeholder := "翻訳待機中 (PLaMo-3)..."
	translatingPath := filepath.Join(cacheDir, rev+".translating")
	serviceDownPath := filepath.Join(cacheDir, "service_down")

	if _, err := os.Stat(translatingPath); err == nil {
		placeholder = "翻訳中 (PLaMo-3)..."
	} else if _, err := os.Stat(serviceDownPath); err == nil {
		placeholder = "PLaMo-3 サービス未起動 (systemctl --user start llama-plamo)"
	}

	return renderCommitInDir(selfExe, workDir, rev, placeholder, cols, stdout, stderr)
}

func neighborRevs(commits []string, idxMap map[string]int, rev string) []string {
	idx, ok := idxMap[rev]
	if !ok {
		return nil
	}
	var neighbors []string
	if idx+1 < len(commits) {
		neighbors = append(neighbors, commits[idx+1])
	}
	if idx-1 >= 0 {
		neighbors = append(neighbors, commits[idx-1])
	}
	if idx+2 < len(commits) {
		neighbors = append(neighbors, commits[idx+2])
	}
	return neighbors
}

func loadCommitIndex(workDir string, limit int) ([]string, map[string]int) {
	cmd := exec.Command("git", "log", "--format=%h", fmt.Sprintf("-n%d", limit))
	if workDir != "" {
		cmd.Dir = workDir
	}
	out, err := cmd.Output()
	if err != nil {
		return nil, nil
	}
	commits := strings.Fields(string(out))
	idxMap := make(map[string]int, len(commits))
	for i, c := range commits {
		idxMap[c] = i
	}
	return commits, idxMap
}

func fetchFollowingRevs(workDir, rev string) []string {
	cmd := exec.Command("git", "log", "--format=%h", "-n", "3", rev)
	if workDir != "" {
		cmd.Dir = workDir
	}
	out, err := cmd.Output()
	if err != nil {
		return nil
	}
	lines := strings.Fields(string(out))
	if len(lines) <= 1 {
		return nil
	}
	return lines[1:]
}

func runCommitTranslationWorker(ctx context.Context, selfExe, workDir, cacheDir, fzfSock string, stderr io.Writer) {
	serverURL := plamoServerURL()

	focusFile := filepath.Join(cacheDir, "current_focus")
	serviceDownFile := filepath.Join(cacheDir, "service_down")

	var (
		indexOnce sync.Once
		indexPtr  atomic.Pointer[commitIndex]
	)

	var (
		mu          sync.Mutex
		inFlight    = make(map[string]bool)
		failed      = make(map[string]bool)
		activeCount int
	)

	isCached := func(rev string, cols int) bool {
		_, err := os.Stat(previewCachePath(cacheDir, rev, cols))
		return err == nil
	}

	startTranslation := func(targetRev string, cols, maxAllowed int) bool {
		if targetRev == "" || isCached(targetRev, cols) {
			return false
		}

		mu.Lock()
		if inFlight[targetRev] || failed[targetRev] || activeCount >= maxAllowed {
			mu.Unlock()
			return false
		}
		inFlight[targetRev] = true
		activeCount++
		mu.Unlock()

		translatingPath := filepath.Join(cacheDir, targetRev+".translating")
		_ = os.WriteFile(translatingPath, []byte("1"), 0o600)
		if isJaEnabled(cacheDir) {
			_ = sendRefreshPreview(fzfSock)
		}

		go func() {
			outPath := previewCachePath(cacheDir, targetRev, cols)
			tmpOutPath := outPath + ".tmp"
			var renderErr error
			f, err := os.Create(tmpOutPath)
			if err != nil {
				renderErr = err
			} else {
				renderErr = renderCommitInDir(selfExe, workDir, targetRev, "", cols, f, stderr)
				_ = f.Close()
				if renderErr == nil {
					_ = os.Rename(tmpOutPath, outPath)
				} else {
					_ = os.Remove(tmpOutPath)
				}
			}

			_ = os.Remove(translatingPath)

			mu.Lock()
			delete(inFlight, targetRev)
			if renderErr != nil {
				failed[targetRev] = true
			}
			activeCount--
			mu.Unlock()

			if isJaEnabled(cacheDir) {
				_ = sendRefreshPreview(fzfSock)
			}
		}()

		return true
	}

	var (
		prevFocus             string
		focusStart            time.Time
		lastFallbackRev       string
		lastFallbackNeighbors []string
	)

	ticker := time.NewTicker(30 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			// Stay idle while translation is off so non-ja locales do not touch git log or llama-server.
			if !isJaEnabled(cacheDir) {
				prevFocus = ""
				continue
			}

			indexOnce.Do(func() {
				go func() {
					commits, idxMap := loadCommitIndex(workDir, commitIndexLimit)
					if len(commits) > 0 {
						indexPtr.Store(&commitIndex{commits: commits, idxMap: idxMap})
					}
				}()
			})

			if !checkPlamoHealth(serverURL) {
				_ = os.WriteFile(serviceDownFile, []byte("1"), 0o600)
				time.Sleep(500 * time.Millisecond)
				continue
			}
			_ = os.Remove(serviceDownFile)

			data, err := os.ReadFile(focusFile)
			if err != nil {
				continue
			}
			current := strings.TrimSpace(string(data))
			now := time.Now()

			if current != prevFocus {
				prevFocus = current
				focusStart = now
				continue
			}

			if current == "" || now.Sub(focusStart) < 100*time.Millisecond {
				continue
			}

			cols := loadPreviewColumns(cacheDir)

			// Prioritize currently focused commit before dispatching any prefetch jobs.
			if !isCached(current, cols) {
				startTranslation(current, cols, maxParallelSlots)
				continue
			}

			// Once current commit is cached, prefetch adjacent commits in background.
			var neighbors []string
			if idx := indexPtr.Load(); idx != nil {
				neighbors = neighborRevs(idx.commits, idx.idxMap, current)
			}
			if len(neighbors) == 0 {
				if current != lastFallbackRev {
					lastFallbackRev = current
					lastFallbackNeighbors = fetchFollowingRevs(workDir, current)
				}
				neighbors = lastFallbackNeighbors
			}
			for _, neighbor := range neighbors {
				startTranslation(neighbor, cols, maxPrefetchSlots)
			}
		}
	}
}

func runMenuCommitPipeline(logCmd, fzfCmd *exec.Cmd) (selectChoice, error) {
	// Use os.Pipe instead of logCmd.StdoutPipe so the parent can close the read end
	// right after fzf starts; otherwise git log blocks on a full pipe after fzf exits early.
	r, w, err := os.Pipe()
	if err != nil {
		return selectChoice{}, fmt.Errorf("failed to create git log pipe: %w", err)
	}
	logCmd.Stdout = w
	fzfCmd.Stdin = r

	var out bytes.Buffer
	fzfCmd.Stdout = &out

	if err := logCmd.Start(); err != nil {
		_ = r.Close()
		_ = w.Close()
		return selectChoice{}, fmt.Errorf("failed to start git log: %w", err)
	}
	_ = w.Close()

	if err := fzfCmd.Start(); err != nil {
		_ = r.Close()
		_ = logCmd.Process.Kill()
		_ = logCmd.Wait()
		return selectChoice{}, fmt.Errorf("failed to start fzf: %w", err)
	}
	_ = r.Close()

	fzfErr := fzfCmd.Wait()
	_ = logCmd.Process.Kill()
	_ = logCmd.Wait()
	if fzfErr != nil {
		var exitErr *exec.ExitError
		if errors.As(fzfErr, &exitErr) {
			switch exitErr.ExitCode() {
			case 130:
				return selectChoice{}, gitcmd.ErrSelectionCanceled
			case 1:
				choice := parseFzfSelectOutput(out.String())
				if choice.Query == "" && choice.Key == "" && choice.Path == "" {
					return selectChoice{}, gitcmd.ErrSelectionCanceled
				}
				return choice, nil
			}
		}
		return selectChoice{}, fmt.Errorf("fzf failed: %w", fzfErr)
	}
	return parseFzfSelectOutput(out.String()), nil
}

func selectMenuCommitStreaming(gitDir string, fzfArgs []string, stderr io.Writer) (selectChoice, error) {
	r := gitcmd.New(gitDir, stderr, stderr)
	if !r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}") {
		return selectMenuItemWithFzf(menuModeCommits, fzfArgs, strings.NewReader(""), stderr)
	}

	// Do not add `--graph`, it makes it too slow in large repositories such as NixOS/nixpkgs.
	logCmd := exec.Command("git", "log", "--format="+defaultLogFormat, "--date=short", "--color=always")
	if gitDir != "" {
		logCmd.Dir = gitDir
	}
	logCmd.Stderr = stderr

	fzfCmd := exec.Command("fzf", fzfArgs...)
	if gitDir != "" {
		fzfCmd.Dir = gitDir
	}
	fzfCmd.Stderr = stderr

	return runMenuCommitPipeline(logCmd, fzfCmd)
}
