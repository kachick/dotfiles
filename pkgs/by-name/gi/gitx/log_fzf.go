package main

import (
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
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

const (
	maxParallelSlots = 4
	maxPrefetchSlots = 2
	commitIndexLimit = 2000
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

func renderCommit(selfExe, rev, placeholder string, stdout, stderr io.Writer) error {
	showArgs := []string{"show", "--ja"}
	if placeholder != "" {
		showArgs = append(showArgs, "--placeholder", placeholder)
	}
	showArgs = append(showArgs, "--color=always", rev)

	cmd1 := exec.Command(selfExe, showArgs...)

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
		return err
	}
	if err := cmd3.Start(); err != nil {
		_ = w1.Close()
		_ = w2.Close()
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

func logFzfRunPreview(selfExe, cacheDir, rawItem string, stdout, stderr io.Writer) error {
	rev := cleanRev(rawItem)
	if rev == "" {
		return nil
	}

	focusFile := filepath.Join(cacheDir, "current_focus")
	focusTmp := focusFile + ".tmp"
	if err := os.WriteFile(focusTmp, []byte(rev), 0o600); err == nil {
		_ = os.Rename(focusTmp, focusFile)
	}

	outPath := filepath.Join(cacheDir, rev+".out")
	if data, err := os.ReadFile(outPath); err == nil {
		_, err = stdout.Write(data)
		return err
	}

	placeholder := "翻訳待機中 (PLaMo-3)..."
	translatingPath := filepath.Join(cacheDir, rev+".translating")
	serviceDownPath := filepath.Join(cacheDir, "service_down")

	if _, err := os.Stat(translatingPath); err == nil {
		placeholder = "翻訳中 (PLaMo-3)..."
	} else if _, err := os.Stat(serviceDownPath); err == nil {
		placeholder = "PLaMo-3 サービス未起動 (systemctl --user start llama-plamo)"
	}

	return renderCommit(selfExe, rev, placeholder, stdout, stderr)
}

func logFzfRunDetail(selfExe, cacheDir, revRaw string, stdout, stderr io.Writer) error {
	rev := cleanRev(revRaw)
	if rev == "" {
		return nil
	}
	outPath := filepath.Join(cacheDir, rev+".out")
	if data, err := os.ReadFile(outPath); err == nil {
		_, err = stdout.Write(data)
		return err
	}
	return renderCommit(selfExe, rev, "", stdout, stderr)
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

	var indexPtr atomic.Pointer[commitIndex]
	go func() {
		commits, idxMap := loadCommitIndex(commitIndexLimit)
		if len(commits) > 0 {
			indexPtr.Store(&commitIndex{commits: commits, idxMap: idxMap})
		}
	}()

	var (
		mu          sync.Mutex
		inFlight    = make(map[string]bool)
		failed      = make(map[string]bool)
		activeCount int
	)

	isCached := func(rev string) bool {
		_, err := os.Stat(filepath.Join(cacheDir, rev+".out"))
		return err == nil
	}

	startTranslation := func(targetRev string, maxAllowed int) bool {
		if targetRev == "" || isCached(targetRev) {
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
		_ = sendRefreshPreview(fzfSock)

		go func() {
			outPath := filepath.Join(cacheDir, targetRev+".out")
			tmpOutPath := filepath.Join(cacheDir, targetRev+".out.tmp")
			var renderErr error
			f, err := os.Create(tmpOutPath)
			if err != nil {
				renderErr = err
			} else {
				renderErr = renderCommit(selfExe, targetRev, "", f, stderr)
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

			_ = sendRefreshPreview(fzfSock)
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

			// Prioritize currently focused commit before dispatching any prefetch jobs.
			if !isCached(current) {
				startTranslation(current, maxParallelSlots)
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
				startTranslation(neighbor, maxPrefetchSlots)
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
	borderLabel := "🪵 Logs"
	previewCmd := `echo {} | cut --delimiter " " --fields 2 --only-delimited | ansi2txt | xargs --no-run-if-empty --max-lines=1 git show --color=always | riff --color=on | bat --language=gitlog --color=always --style=plain --wrap=character`
	detailBind := "enter:become(git show --color=always {2} | riff --color=on | bat --language=gitlog --color=always --style=plain --wrap=character)"

	if opts.ja {
		borderLabel = "🪵 Logs (ja)"
		previewCmd = fmt.Sprintf("%q log-fzf _preview %q {2}", selfExe, cacheDir)
		detailBind = fmt.Sprintf("enter:become(%q log-fzf _detail %q {2})", selfExe, cacheDir)
	}

	fzfArgs := []string{
		"--ansi",
		"--nth", "1,3..",
		"--no-sort",
		"--border-label", borderLabel,
		"--preview", previewCmd,
		"--preview-window", "right,60%",
		"--preview-border", "line",
		"--height", "75%",
		"--tmux", "90%,70%",
		"--layout", "reverse",
		"--multi",
		"--min-height", "20+",
		"--border",
		"--no-separator",
		"--header-border", "horizontal",
		"--border-label-pos", "2",
		"--color", "label:blue",
		"--header", "CTRL-O (Open in browser) / CTRL-R (Revert)\nEnter (Detail)\n\n",
		"--bind", "ctrl-o:execute-silent(gh browse {2})",
		"--bind", "ctrl-r:become(git revert {2})",
		"--bind", detailBind,
		"--bind", "ctrl-/:change-preview-window(down,60%|hidden|)",
	}

	if opts.ja && fzfSock != "" {
		fzfArgs = append(fzfArgs, "--listen="+fzfSock)
	}
	if opts.query != "" {
		fzfArgs = append(fzfArgs, "--query", opts.query)
	}
	return fzfArgs
}

func runLogFzfMain(opts logFzfOptions, stdin io.Reader, stdout, stderr io.Writer) error {
	var (
		cacheDir string
		fzfSock  string
		selfExe  string
		cancel   context.CancelFunc
	)

	if opts.ja {
		var err error
		cacheDir, err = os.MkdirTemp("", "gitx-log-fzf-ja-*")
		if err != nil {
			return fmt.Errorf("failed to create temp cache dir: %w", err)
		}
		defer os.RemoveAll(cacheDir)

		fzfSock = filepath.Join(cacheDir, "fzf.sock")

		selfExe, err = os.Executable()
		if err != nil {
			return fmt.Errorf("failed to get executable path: %w", err)
		}

		var ctx context.Context
		ctx, cancel = context.WithCancel(context.Background())
		defer cancel()

		go runWorker(ctx, selfExe, cacheDir, fzfSock, stderr)
	}

	// Do not add `--graph`, it makes it too slow in large repositories such as NixOS/nixpkgs.
	logCmd := exec.Command("git", "log", "--format="+defaultLogFormat, "--date=short", "--color=always")
	logCmd.Stderr = stderr
	logStdout, err := logCmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to get git log pipe: %w", err)
	}

	fzfArgs := buildLogFzfArgs(selfExe, cacheDir, fzfSock, opts)
	fzfCmd := exec.Command("fzf", fzfArgs...)
	fzfCmd.Stdin = logStdout
	fzfCmd.Stdout = stdout
	fzfCmd.Stderr = stderr
	_ = stdin

	if err := logCmd.Start(); err != nil {
		return fmt.Errorf("failed to start git log: %w", err)
	}
	if err := fzfCmd.Start(); err != nil {
		_ = logCmd.Wait()
		return fmt.Errorf("failed to start fzf: %w", err)
	}

	_ = logCmd.Wait()
	if err := fzfCmd.Wait(); err != nil {
		if isCancelExitError(err) {
			return nil
		}
		return err
	}
	return nil
}

func printLogFzfUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: gitx log-fzf [--ja] [query]\n\n")
	fmt.Fprintf(w, "Search git log via fzf with preview and quick actions.\n\n")
	fmt.Fprintf(w, "Options:\n")
	fmt.Fprintf(w, "  --ja    Enable asynchronous Japanese commit message translation preview\n")
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
		case "_detail":
			if len(args) < 3 {
				return nil
			}
			selfExe, err := os.Executable()
			if err != nil {
				return fmt.Errorf("failed to get executable path: %w", err)
			}
			return logFzfRunDetail(selfExe, args[1], args[2], stdout, stderr)
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
