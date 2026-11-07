package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

const (
	defaultPort = "18080"
	cyan        = "\033[36m"
	yellow      = "\033[33m"
	reset       = "\033[0m"
	clearLine   = "\033[2K\r"
)

var diffHeaderRegex = regexp.MustCompile(`^(\x1b\[[0-9;]*m)?diff --git`)

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Messages    []chatMessage `json:"messages"`
	Temperature float64       `json:"temperature"`
}

type chatChoice struct {
	Message chatMessage `json:"message"`
}

type chatResponse struct {
	Choices []chatChoice `json:"choices"`
	Error   *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

type parsedArgs struct {
	ref         string
	placeholder string
	gitArgs     []string
}

func parseArgs(args []string) parsedArgs {
	var parsed parsedArgs
	parsed.ref = "HEAD"
	var refFound bool

	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--placeholder" && i+1 < len(args) {
			parsed.placeholder = args[i+1]
			i++
			continue
		}
		if strings.HasPrefix(arg, "--placeholder=") {
			parsed.placeholder = strings.TrimPrefix(arg, "--placeholder=")
			continue
		}
		if !strings.HasPrefix(arg, "-") && !refFound {
			parsed.ref = arg
			refFound = true
		}
		parsed.gitArgs = append(parsed.gitArgs, arg)
	}

	return parsed
}

func extractRef(args []string) string {
	return parseArgs(args).ref
}

func formatTranslationBlock(text string) string {
	lines := strings.Split(text, "\n")
	var b strings.Builder
	b.WriteString(cyan + "<ja>" + reset + "\n")
	for _, line := range lines {
		if len(line) > 0 {
			b.WriteString(cyan + line + reset + "\n")
		} else {
			b.WriteString("\n")
		}
	}
	b.WriteString(cyan + "</ja>" + reset)
	return b.String()
}

func injectTranslation(gitShowOutput, formattedBlock string) string {
	lines := strings.Split(gitShowOutput, "\n")
	var result []string
	inHeader := true
	inserted := false

	for _, line := range lines {
		if inHeader && line == "" {
			inHeader = false
			result = append(result, line)
			continue
		}

		if !inHeader && !inserted && diffHeaderRegex.MatchString(line) {
			result = append(result, formattedBlock, "")
			inserted = true
		}

		result = append(result, line)
	}

	if !inserted {
		result = append(result, "", formattedBlock)
	}

	return strings.Join(result, "\n")
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

func checkServerHealth(ctx context.Context, serverURL string) error {
	client := &http.Client{Timeout: 1 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, serverURL+"/health", nil)
	if err != nil {
		return err
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	return nil
}

func buildSystemPrompt(surroundingContext string) string {
	prompt := "[plamo-translate]\ntarget_lang=ja\nform=plain"
	if surroundingContext != "" {
		prompt += "\n---\n" + surroundingContext
	}
	return prompt
}

func buildCommitContext(rev, workDir string) string {
	cmd := exec.Command("git", "diff-tree", "--no-commit-id", "--name-only", "-r", rev)
	if workDir != "" {
		cmd.Dir = workDir
	}
	out, err := cmd.Output()
	if err != nil {
		return "Git commit message"
	}
	files := strings.TrimSpace(string(out))
	if files == "" {
		return "Git commit message"
	}

	lines := strings.Split(files, "\n")
	const maxFiles = 10
	if len(lines) > maxFiles {
		files = strings.Join(lines[:maxFiles], "\n") + "\n..."
	}

	return fmt.Sprintf("Git commit message\nChanged files:\n%s", files)
}

func translateMessage(ctx context.Context, serverURL, message, surroundingContext string) (string, error) {
	reqBody := chatRequest{
		Messages: []chatMessage{
			{
				Role:    "system",
				Content: buildSystemPrompt(surroundingContext),
			},
			{
				Role:    "user",
				Content: message,
			},
		},
		Temperature: 0,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("marshal request: %w", err)
	}

	client := &http.Client{Timeout: 60 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, serverURL+"/v1/chat/completions", bytes.NewReader(jsonData))
	if err != nil {
		return "", fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("call completions API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(body))
	}

	var chatResp chatResponse
	if err := json.NewDecoder(resp.Body).Decode(&chatResp); err != nil {
		return "", fmt.Errorf("decode response: %w", err)
	}

	if chatResp.Error != nil && chatResp.Error.Message != "" {
		return "", fmt.Errorf("API returned error: %s", chatResp.Error.Message)
	}

	if len(chatResp.Choices) == 0 || chatResp.Choices[0].Message.Content == "" {
		return "", errors.New("empty translation returned from model")
	}

	return strings.TrimSpace(chatResp.Choices[0].Message.Content), nil
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	parsed := parseArgs(args)

	var formattedBlock string
	if parsed.placeholder != "" {
		formattedBlock = formatTranslationBlock(parsed.placeholder)
	} else {
		rev := parsed.ref

		port := os.Getenv("PLAMO_PORT")
		if port == "" {
			port = defaultPort
		}
		serverURL := fmt.Sprintf("http://127.0.0.1:%s", port)

		// Fail-closed: check health first
		ctx := context.Background()
		if err := checkServerHealth(ctx, serverURL); err != nil {
			return fmt.Errorf("llama-server is not reachable at %s: %w\nStart the service with: systemctl --user start llama-plamo (or 'plamo-start')", serverURL, err)
		}

		// Fetch commit message
		gitLogCmd := exec.Command("git", "log", "-1", "--format=%B", rev)
		if workDir != "" {
			gitLogCmd.Dir = workDir
		}
		msgBytes, err := gitLogCmd.Output()
		if err != nil {
			return fmt.Errorf("failed to retrieve commit message for '%s': %w", rev, err)
		}
		msg := strings.TrimSpace(string(msgBytes))
		if msg == "" {
			return fmt.Errorf("commit message for '%s' is empty", rev)
		}

		// Progress indicator
		if isTerminal(stderr) {
			fmt.Fprint(stderr, yellow+"Translating commit message with PLaMo-3..."+reset+"\r")
		}

		commitContext := buildCommitContext(rev, workDir)
		translated, err := translateMessage(ctx, serverURL, msg, commitContext)
		if isTerminal(stderr) {
			fmt.Fprint(stderr, clearLine)
		}
		if err != nil {
			return fmt.Errorf("translation failed: %w", err)
		}

		formattedBlock = formatTranslationBlock(translated)
	}

	// Fetch git show with ANSI colors
	gitShowArgs := append([]string{"show", "--color=always"}, parsed.gitArgs...)
	gitShowCmd := exec.Command("git", gitShowArgs...)
	if workDir != "" {
		gitShowCmd.Dir = workDir
	}
	showBytes, err := gitShowCmd.Output()
	if err != nil {
		return fmt.Errorf("git show failed: %w", err)
	}

	finalOutput := injectTranslation(string(showBytes), formattedBlock)

	// If connected to a terminal and riff is available, stream into riff for diff highlighting and paging
	if isTerminal(stdout) {
		if riffPath, err := exec.LookPath("riff"); err == nil {
			riffCmd := exec.Command(riffPath)
			if workDir != "" {
				riffCmd.Dir = workDir
			}
			riffCmd.Stdin = strings.NewReader(finalOutput)
			riffCmd.Stdout = stdout
			riffCmd.Stderr = stderr
			return riffCmd.Run()
		}
	}

	_, err = fmt.Fprint(stdout, finalOutput)
	return err
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}
