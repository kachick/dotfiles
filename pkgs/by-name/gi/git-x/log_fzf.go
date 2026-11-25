package main

import (
	"bytes"
	"context"
	"flag"
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
)

const (
	maxParallelSlots       = 4
	maxPrefetchSlots       = 2
	commitIndexLimit       = 2000
	logFzfBorderLabelPlain = "🪵 Logs"
	logFzfBorderLabelJa    = "🪵 Logs (ja)"
	jaEnabledFilename      = "ja_enabled"
	previewColsFilename    = "preview_cols"
)

type commitIndex struct {
	commits []string
	idxMap  map[string]int
}

var ansiRegex = regexp.MustCompile(`\x1b\[[0-9;]*[a-zA-Z]`)

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

func renderCommit(selfExe, rev, placeholder string, columns int, stdout, stderr io.Writer) error {
	showArgs := []string{"show", "--ja"}
	if placeholder != "" {
		showArgs = append(showArgs, "--placeholder", placeholder)
	}
	if columns > 0 {
		showArgs = append(showArgs, "--columns", strconv.Itoa(columns))
	}
	showArgs = append(showArgs, "--color=always", rev)

	return renderCmdPipeline(exec.Command(selfExe, showArgs...), stdout, stderr)
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

func renderPlainCommit(revRaw string, stdout, stderr io.Writer) error {
	rev := cleanRev(revRaw)
	if rev == "" {
		return nil
	}

	return renderCmdPipeline(exec.Command("git", "show", "--color=always", rev), stdout, stderr)
}

func hasPersistentTranslation(rev string) bool {
	cacheDir, err := translationCacheDir()
	if err != nil {
		return false
	}
	msg, _, systemPrompt, err := loadCommitTranslationInput(rev, "")
	if err != nil {
		return false
	}
	_, ok := readTranslationCache(cacheDir, translationCacheKey(systemPrompt, msg))
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

func logFzfRunToggleJa(cacheDir string, stdout io.Writer) error {
	next := !isJaEnabled(cacheDir)
	if err := setJaEnabled(cacheDir, next); err != nil {
		return err
	}
	label := logFzfBorderLabelPlain
	if next {
		label = logFzfBorderLabelJa
	}
	_, err := fmt.Fprintf(stdout, "change-border-label(%s)+refresh-preview\n", label)
	return err
}

func logFzfRunPreview(selfExe, cacheDir, rawItem string, stdout, stderr io.Writer) error {
	rev := cleanRev(rawItem)
	if rev == "" {
		return nil
	}

	if !isJaEnabled(cacheDir) {
		return renderPlainCommit(rev, stdout, stderr)
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

	if hasPersistentTranslation(rev) {
		var buf bytes.Buffer
		if err := renderCommit(selfExe, rev, "", cols, &buf, stderr); err == nil {
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

	return renderCommit(selfExe, rev, placeholder, cols, stdout, stderr)
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

func loadCommitIndex(limit int) ([]string, map[string]int) {
	out, err := exec.Command("git", "log", "--format=%h", fmt.Sprintf("-n%d", limit)).Output()
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

func fetchFollowingRevs(rev string) []string {
	out, err := exec.Command("git", "log", "--format=%h", "-n", "3", rev).Output()
	if err != nil {
		return nil
	}
	lines := strings.Fields(string(out))
	if len(lines) <= 1 {
		return nil
	}
	return lines[1:]
}

func runWorker(ctx context.Context, selfExe, cacheDir, fzfSock string, stderr io.Writer) {
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
				renderErr = renderCommit(selfExe, targetRev, "", cols, f, stderr)
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
			// Stay idle while translation is off so default `git lf` does not touch git log or llama-server.
			if !isJaEnabled(cacheDir) {
				prevFocus = ""
				continue
			}

			indexOnce.Do(func() {
				go func() {
					commits, idxMap := loadCommitIndex(commitIndexLimit)
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
					lastFallbackNeighbors = fetchFollowingRevs(current)
				}
				neighbors = lastFallbackNeighbors
			}
			for _, neighbor := range neighbors {
				startTranslation(neighbor, cols, maxPrefetchSlots)
			}
		}
	}
}

type logFzfOptions struct {
	ja    bool
	query string
	help  bool
}

func parseLogFzfArgs(args []string) (logFzfOptions, error) {
	var opts logFzfOptions
	var positional []string
	for _, arg := range args {
		switch arg {
		case "-h", "--help":
			opts.help = true
			return opts, nil
		case "--ja":
			opts.ja = true
		default:
			if strings.HasPrefix(arg, "-") {
				return opts, fmt.Errorf("unknown flag: %s", arg)
			}
			positional = append(positional, arg)
		}
	}
	if len(positional) > 1 {
		return opts, fmt.Errorf("expected at most 1 query argument, got %d", len(positional))
	}
	if len(positional) == 1 {
		opts.query = positional[0]
	}
	return opts, nil
}

func buildLogFzfArgs(selfExe, cacheDir, fzfSock string, opts logFzfOptions) []string {
	borderLabel := logFzfBorderLabelPlain
	if opts.ja {
		borderLabel = logFzfBorderLabelJa
	}
	previewCmd := fmt.Sprintf("%q log-fzf _preview %q {2}", selfExe, cacheDir)
	toggleJaBind := fmt.Sprintf("alt-j:transform(%q log-fzf _toggle-ja %q)", selfExe, cacheDir)

	fzfArgs := []string{
		"--ansi",
		"--nth", "1,3..",
		"--no-sort",
		"--border-label", borderLabel,
		"--preview", previewCmd,
		"--preview-window", "right,60%",
		"--preview-border", "line",
		"--layout", "reverse",
		"--multi",
		"--border",
		"--no-separator",
		"--header-border", "horizontal",
		"--border-label-pos", "2",
		"--color", "label:blue",
		"--header", "CTRL-O (Open in browser) / CTRL-R (Revert)\nALT-J (Toggle ja) / ALT-F (Zoom preview)\n\n",
		"--bind", "ctrl-o:execute-silent(gh browse {2})",
		"--bind", "ctrl-r:become(git revert {2})",
		"--bind", toggleJaBind,
		"--bind", "alt-f:change-preview-window(down,80%|)",
		"--bind", "ctrl-/:change-preview-window(down,60%|hidden|)",
	}

	if fzfSock != "" {
		fzfArgs = append(fzfArgs, "--listen="+fzfSock)
	}
	if opts.query != "" {
		fzfArgs = append(fzfArgs, "--query", opts.query)
	}
	return fzfArgs
}

func runLogFzfPipeline(logCmd, fzfCmd *exec.Cmd) error {
	// Use os.Pipe instead of logCmd.StdoutPipe so the parent can close the read end
	// right after fzf starts; otherwise git log blocks on a full pipe after fzf exits early.
	r, w, err := os.Pipe()
	if err != nil {
		return fmt.Errorf("failed to create git log pipe: %w", err)
	}
	logCmd.Stdout = w
	fzfCmd.Stdin = r

	if err := logCmd.Start(); err != nil {
		_ = r.Close()
		_ = w.Close()
		return fmt.Errorf("failed to start git log: %w", err)
	}
	_ = w.Close()

	if err := fzfCmd.Start(); err != nil {
		_ = r.Close()
		_ = logCmd.Process.Kill()
		_ = logCmd.Wait()
		return fmt.Errorf("failed to start fzf: %w", err)
	}
	_ = r.Close()

	fzfErr := fzfCmd.Wait()
	_ = logCmd.Process.Kill()
	_ = logCmd.Wait()
	if fzfErr != nil {
		if isCancelExitError(fzfErr) {
			return nil
		}
		return fzfErr
	}
	return nil
}

func runLogFzfMain(opts logFzfOptions, stdin io.Reader, stdout, stderr io.Writer) error {
	selfExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}

	cacheDir, err := os.MkdirTemp("", "git-x-log-fzf-*")
	if err != nil {
		return fmt.Errorf("failed to create temp cache dir: %w", err)
	}
	defer os.RemoveAll(cacheDir)

	if opts.ja {
		if err := setJaEnabled(cacheDir, true); err != nil {
			return fmt.Errorf("failed to enable translation mode: %w", err)
		}
	}

	fzfSock := filepath.Join(cacheDir, "fzf.sock")
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go runWorker(ctx, selfExe, cacheDir, fzfSock, stderr)

	// Do not add `--graph`, it makes it too slow in large repositories such as NixOS/nixpkgs.
	logCmd := exec.Command("git", "log", "--format="+defaultLogFormat, "--date=short", "--color=always")
	logCmd.Stderr = stderr

	fzfArgs := buildLogFzfArgs(selfExe, cacheDir, fzfSock, opts)
	fzfCmd := exec.Command("fzf", fzfArgs...)
	fzfCmd.Stdout = stdout
	fzfCmd.Stderr = stderr
	_ = stdin

	return runLogFzfPipeline(logCmd, fzfCmd)
}

func logFzfFlags() []cliFlagSpec {
	return []cliFlagSpec{
		{
			name:        "ja",
			description: "Start with asynchronous Japanese commit message translation preview enabled",
		},
	}
}

func printLogFzfUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git x log-fzf [--ja] [query]\n\n")
	fmt.Fprintf(w, "Search git log via fzf with preview and quick actions.\n\n")
	fmt.Fprintf(w, "Options:\n")
	for _, f := range logFzfFlags() {
		fmt.Fprintf(w, "  --%-6s%s\n", f.name, f.description)
	}
}

func runLogFzf(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if len(args) > 0 {
		switch args[0] {
		case "_preview":
			if len(args) < 3 {
				return nil
			}
			selfExe, err := os.Executable()
			if err != nil {
				return fmt.Errorf("failed to get executable path: %w", err)
			}
			return logFzfRunPreview(selfExe, args[1], args[2], stdout, stderr)
		case "_toggle-ja":
			if len(args) < 2 {
				return nil
			}
			return logFzfRunToggleJa(args[1], stdout)
		case "_preview-plain":
			if len(args) < 2 {
				return nil
			}
			return renderPlainCommit(args[1], stdout, stderr)
		}
	}

	opts, err := parseLogFzfArgs(args)
	if err != nil {
		printLogFzfUsage(stderr)
		return err
	}
	if opts.help {
		printLogFzfUsage(stderr)
		return flag.ErrHelp
	}

	return runLogFzfMain(opts, stdin, stdout, stderr)
}
