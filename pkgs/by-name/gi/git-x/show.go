package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode"
)

const (
	ansiCyan             = "\033[36m"
	ansiDim              = "\033[90m"
	ansiYellow           = "\033[33m"
	ansiReset            = "\033[0m"
	ansiClearLine        = "\033[2K\r"
	sideBySideMinColumns = 100
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

type parsedShowArgs struct {
	ja          bool
	ref         string
	placeholder string
	columns     int
	gitArgs     []string
}

func showFlags() []cliFlagSpec {
	// Omit internal --placeholder and --columns used only by `git-x log-fzf` preview workers.
	return []cliFlagSpec{
		{
			name:        "ja",
			description: "Translate commit message to Japanese via local llama-server",
		},
	}
}

func parseShowArgs(args []string) parsedShowArgs {
	var parsed parsedShowArgs
	parsed.ref = "HEAD"
	var refFound bool

	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--ja" {
			parsed.ja = true
			continue
		}
		if arg == "--placeholder" && i+1 < len(args) {
			parsed.placeholder = args[i+1]
			i++
			continue
		}
		if strings.HasPrefix(arg, "--placeholder=") {
			parsed.placeholder = strings.TrimPrefix(arg, "--placeholder=")
			continue
		}
		if arg == "--columns" && i+1 < len(args) {
			if n, err := strconv.Atoi(args[i+1]); err == nil && n > 0 {
				parsed.columns = n
			}
			i++
			continue
		}
		if strings.HasPrefix(arg, "--columns=") {
			if n, err := strconv.Atoi(strings.TrimPrefix(arg, "--columns=")); err == nil && n > 0 {
				parsed.columns = n
			}
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

func extractShowRef(args []string) string {
	return parseShowArgs(args).ref
}

func formatTranslationBlock(text string) string {
	lines := strings.Split(text, "\n")
	var b strings.Builder
	b.WriteString(ansiCyan + "<ja>" + ansiReset + "\n")
	for _, line := range lines {
		if len(line) > 0 {
			b.WriteString(ansiCyan + line + ansiReset + "\n")
		} else {
			b.WriteString("\n")
		}
	}
	b.WriteString(ansiCyan + "</ja>" + ansiReset)
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

func runeDisplayWidth(r rune) int {
	if r == 0 || unicode.Is(unicode.Mn, r) || unicode.Is(unicode.Me, r) || unicode.Is(unicode.Cf, r) {
		return 0
	}
	switch {
	case r >= 0x1100 && r <= 0x115F,
		r >= 0x2E80 && r <= 0x303E,
		r >= 0x3041 && r <= 0x33FF,
		r >= 0x3400 && r <= 0x4DBF,
		r >= 0x4E00 && r <= 0xA4CF,
		r >= 0xAC00 && r <= 0xD7A3,
		r >= 0xF900 && r <= 0xFAFF,
		r >= 0xFE10 && r <= 0xFE19,
		r >= 0xFE30 && r <= 0xFE6F,
		r >= 0xFF01 && r <= 0xFF60,
		r >= 0xFFE0 && r <= 0xFFE6,
		r >= 0x1F300 && r <= 0x1FAFF,
		r >= 0x20000 && r <= 0x3FFFF:
		return 2
	default:
		return 1
	}
}

func displayWidth(s string) int {
	w := 0
	for _, r := range s {
		w += runeDisplayWidth(r)
	}
	return w
}

func wrapLineToWidth(line string, maxWidth int) []string {
	if maxWidth <= 0 {
		return []string{line}
	}
	line = strings.ReplaceAll(line, "\t", "    ")
	if line == "" {
		return []string{""}
	}

	runes := []rune(line)
	var out []string
	start := 0
	for start < len(runes) {
		width := 0
		end := start
		lastSpace := -1
		for end < len(runes) {
			rw := runeDisplayWidth(runes[end])
			if width+rw > maxWidth {
				break
			}
			if runes[end] == ' ' {
				lastSpace = end
			}
			width += rw
			end++
		}
		if end == start {
			// Ensure progress even if a single rune is wider than maxWidth.
			end++
		} else if end < len(runes) && lastSpace > start && width >= maxWidth/2 {
			out = append(out, string(runes[start:lastSpace]))
			start = lastSpace + 1
			continue
		}
		out = append(out, string(runes[start:end]))
		start = end
	}
	return out
}

func wrapLinesToWidth(lines []string, maxWidth int) []string {
	var out []string
	for _, line := range lines {
		out = append(out, wrapLineToWidth(line, maxWidth)...)
	}
	return out
}

func splitGitShowSections(gitShowOutput string) (header, message, diff []string) {
	lines := strings.Split(gitShowOutput, "\n")
	inHeader := true
	inDiff := false

	for _, line := range lines {
		if inHeader {
			if line == "" {
				inHeader = false
				continue
			}
			header = append(header, line)
			continue
		}
		if !inDiff && diffHeaderRegex.MatchString(line) {
			inDiff = true
		}
		if inDiff {
			diff = append(diff, line)
		} else {
			message = append(message, line)
		}
	}

	for len(message) > 0 && strings.TrimSpace(message[len(message)-1]) == "" {
		message = message[:len(message)-1]
	}
	return header, message, diff
}

func injectSideBySideTranslation(gitShowOutput, translationText string, columns int) string {
	header, rawMessage, diff := splitGitShowSections(gitShowOutput)

	origLines := make([]string, len(rawMessage))
	for i, line := range rawMessage {
		clean := ansiRegex.ReplaceAllString(line, "")
		origLines[i] = strings.TrimPrefix(clean, "    ")
	}

	const sepWidth = 3 // " │ "
	usable := columns - sepWidth
	leftWidth := usable / 2
	rightWidth := usable - leftWidth

	leftWrapped := wrapLinesToWidth(origLines, leftWidth)
	rightWrapped := wrapLinesToWidth(strings.Split(translationText, "\n"), rightWidth)

	rowCount := max(len(leftWrapped), len(rightWrapped))
	var result []string
	result = append(result, header...)
	result = append(result, "")

	sep := " " + ansiDim + "│" + ansiReset + " "
	for i := range rowCount {
		var left, right string
		if i < len(leftWrapped) {
			left = leftWrapped[i]
		}
		if i < len(rightWrapped) {
			right = rightWrapped[i]
		}
		pad := max(leftWidth-displayWidth(left), 0)
		var row strings.Builder
		row.WriteString(left)
		row.WriteString(strings.Repeat(" ", pad))
		row.WriteString(sep)
		if right != "" {
			row.WriteString(ansiCyan)
			row.WriteString(right)
			row.WriteString(ansiReset)
		}
		result = append(result, row.String())
	}

	if len(diff) > 0 {
		result = append(result, "")
		result = append(result, diff...)
	}

	return strings.Join(result, "\n")
}

func injectTranslationLayout(gitShowOutput, translationText string, columns int) string {
	if columns >= sideBySideMinColumns {
		return injectSideBySideTranslation(gitShowOutput, translationText, columns)
	}
	return injectTranslation(gitShowOutput, formatTranslationBlock(translationText))
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

func loadCommitTranslationInput(rev, workDir string) (msg, commitContext, systemPrompt string, err error) {
	gitLogCmd := exec.Command("git", "log", "-1", "--format=%B", rev)
	if workDir != "" {
		gitLogCmd.Dir = workDir
	}
	msgBytes, err := gitLogCmd.Output()
	if err != nil {
		return "", "", "", fmt.Errorf("failed to retrieve commit message for '%s': %w", rev, err)
	}
	msg = strings.TrimSpace(string(msgBytes))
	if msg == "" {
		return "", "", "", fmt.Errorf("commit message for '%s' is empty", rev)
	}

	commitContext = buildCommitContext(rev, workDir)
	systemPrompt = buildSystemPrompt(commitContext)
	return msg, commitContext, systemPrompt, nil
}

func runShow(args []string, workDir string, stdin io.Reader, stdout, stderr io.Writer) error {
	parsed := parseShowArgs(args)
	if !parsed.ja {
		cmd := exec.Command("git", append([]string{"show"}, parsed.gitArgs...)...)
		if workDir != "" {
			cmd.Dir = workDir
		}
		cmd.Stdin = stdin
		cmd.Stdout = stdout
		cmd.Stderr = stderr
		return cmd.Run()
	}

	var translationText string
	if parsed.placeholder != "" {
		translationText = parsed.placeholder
	} else {
		rev := parsed.ref
		msg, commitContext, systemPrompt, err := loadCommitTranslationInput(rev, workDir)
		if err != nil {
			return err
		}

		cacheDir, _ := translationCacheDir()
		cacheKey := translationCacheKey(systemPrompt, msg)

		// Check persistent cache before llama-server health so cached commits stay readable offline.
		translated, ok := readTranslationCache(cacheDir, cacheKey)
		if !ok {
			serverURL := plamoServerURL()
			ctx := context.Background()
			if err := checkServerHealth(ctx, serverURL); err != nil {
				return fmt.Errorf("llama-server is not reachable at %s: %w\nStart the service with: plamo start", serverURL, err)
			}

			if isTerminal(stderr) {
				fmt.Fprint(stderr, ansiYellow+"Translating commit message with PLaMo-3..."+ansiReset+"\r")
			}

			translated, err = translateMessage(ctx, serverURL, msg, commitContext)
			if isTerminal(stderr) {
				fmt.Fprint(stderr, ansiClearLine)
			}
			if err != nil {
				return fmt.Errorf("translation failed: %w", err)
			}

			_ = writeTranslationCache(cacheDir, cacheKey, translated)
		}

		translationText = translated
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

	finalOutput := injectTranslationLayout(string(showBytes), translationText, parsed.columns)

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
