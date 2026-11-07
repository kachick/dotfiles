package main

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

const (
	defaultPort = "18080"
)

var ansiRegex = regexp.MustCompile(`\x1b\[[0-9;]*[a-zA-Z]`)

func cleanRev(raw string) string {
	clean := ansiRegex.ReplaceAllString(raw, "")
	fields := strings.Fields(clean)
	if len(fields) >= 2 {
		// git-log-simple format: "<date> <hash> <message>..."
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

func checkHealth(serverURL string) bool {
	client := &http.Client{Timeout: 200 * time.Millisecond}
	resp, err := client.Get(serverURL + "/health")
	if err != nil {
		return false
	}
	resp.Body.Close()
	return resp.StatusCode == http.StatusOK
}

func renderCommit(rev, placeholder string, stdout io.Writer) error {
	var gitShowArgs []string
	if placeholder != "" {
		gitShowArgs = []string{"--placeholder", placeholder, "--color=always", rev}
	} else {
		gitShowArgs = []string{"--color=always", rev}
	}

	cmd1 := exec.Command("git-show-ja", gitShowArgs...)

	riffPath, errRiff := exec.LookPath("riff")
	batPath, errBat := exec.LookPath("bat")

	if errRiff != nil || errBat != nil {
		cmd1.Stdout = stdout
		cmd1.Stderr = os.Stderr
		return cmd1.Run()
	}

	cmd2 := exec.Command(riffPath, "--color=on")
	cmd3 := exec.Command(batPath, "--language=gitlog", "--color=always", "--style=plain", "--wrap=character")

	r1, w1 := io.Pipe()
	r2, w2 := io.Pipe()

	cmd1.Stdout = w1
	cmd1.Stderr = os.Stderr

	cmd2.Stdin = r1
	cmd2.Stdout = w2
	cmd2.Stderr = os.Stderr

	cmd3.Stdin = r2
	cmd3.Stdout = stdout
	cmd3.Stderr = os.Stderr

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

func runPreview(cacheDir, rawItem string) error {
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
		_, err = os.Stdout.Write(data)
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

	return renderCommit(rev, placeholder, os.Stdout)
}

func runDetail(cacheDir, revRaw string) error {
	rev := cleanRev(revRaw)
	if rev == "" {
		return nil
	}
	outPath := filepath.Join(cacheDir, rev+".out")
	if data, err := os.ReadFile(outPath); err == nil {
		_, err = os.Stdout.Write(data)
		return err
	}
	return renderCommit(rev, "", os.Stdout)
}

func runWorker(ctx context.Context, cacheDir, fzfSock string) {
	port := os.Getenv("PLAMO_PORT")
	if port == "" {
		port = defaultPort
	}
	serverURL := fmt.Sprintf("http://127.0.0.1:%s", port)

	focusFile := filepath.Join(cacheDir, "current_focus")
	serviceDownFile := filepath.Join(cacheDir, "service_down")

	var prevFocus string
	var focusStart time.Time

	ticker := time.NewTicker(30 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if !checkHealth(serverURL) {
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

			if current == "" {
				continue
			}

			outPath := filepath.Join(cacheDir, current+".out")
			translatingPath := filepath.Join(cacheDir, current+".translating")

			if _, err := os.Stat(outPath); err == nil {
				continue
			}
			if _, err := os.Stat(translatingPath); err == nil {
				continue
			}

			if now.Sub(focusStart) >= 100*time.Millisecond {
				_ = os.WriteFile(translatingPath, []byte("1"), 0o600)
				_ = sendRefreshPreview(fzfSock)

				tmpOutPath := filepath.Join(cacheDir, current+".out.tmp")
				f, err := os.Create(tmpOutPath)
				if err == nil {
					renderErr := renderCommit(current, "", f)
					f.Close()
					if renderErr == nil {
						_ = os.Rename(tmpOutPath, outPath)
					} else {
						_ = os.Remove(tmpOutPath)
					}
				}
				_ = os.Remove(translatingPath)
				_ = sendRefreshPreview(fzfSock)
			}
		}
	}
}

func runMain(query string) error {
	cacheDir, err := os.MkdirTemp("", "git-log-fzf-ja-*")
	if err != nil {
		return fmt.Errorf("failed to create temp cache dir: %w", err)
	}
	defer os.RemoveAll(cacheDir)

	fzfSock := filepath.Join(cacheDir, "fzf.sock")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	self, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}

	go runWorker(ctx, cacheDir, fzfSock)

	logCmd := exec.Command("git-log-simple")
	logStdout, err := logCmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to get git-log-simple pipe: %w", err)
	}

	previewCmd := fmt.Sprintf("%q _preview %q {2}", self, cacheDir)
	detailCmd := fmt.Sprintf("%q _detail %q {2}", self, cacheDir)

	fzfArgs := []string{
		"--ansi",
		"--nth", "1,3..",
		"--no-sort",
		"--border-label", "🪵 Logs (ja)",
		"--listen=" + fzfSock,
		"--preview", previewCmd,
		"--preview-window", "right,70%",
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
		"--bind", fmt.Sprintf("enter:become(%s)", detailCmd),
		"--bind", "ctrl-/:change-preview-window(down,70%|hidden|)",
	}

	if query != "" {
		fzfArgs = append(fzfArgs, "--query", query)
	}

	fzfCmd := exec.Command("fzf", fzfArgs...)
	fzfCmd.Stdin = logStdout
	fzfCmd.Stdout = os.Stdout
	fzfCmd.Stderr = os.Stderr

	if err := logCmd.Start(); err != nil {
		return fmt.Errorf("failed to start git-log-simple: %w", err)
	}
	if err := fzfCmd.Start(); err != nil {
		return fmt.Errorf("failed to start fzf: %w", err)
	}

	_ = logCmd.Wait()
	return fzfCmd.Wait()
}

func main() {
	args := os.Args[1:]
	if len(args) > 0 {
		switch args[0] {
		case "_preview":
			if len(args) < 3 {
				os.Exit(0)
			}
			if err := runPreview(args[1], args[2]); err != nil {
				fmt.Fprintf(os.Stderr, "Preview error: %v\n", err)
				os.Exit(1)
			}
			return
		case "_detail":
			if len(args) < 3 {
				os.Exit(0)
			}
			if err := runDetail(args[1], args[2]); err != nil {
				fmt.Fprintf(os.Stderr, "Detail error: %v\n", err)
				os.Exit(1)
			}
			return
		}
	}

	query := ""
	if len(args) > 0 {
		query = args[0]
	}
	if err := runMain(query); err != nil {
		// Exit code 130 is normal for user cancellation (Ctrl-C / Esc) in fzf
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
			os.Exit(0)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
