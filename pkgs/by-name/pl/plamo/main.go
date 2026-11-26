package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
	"unicode"

	"github.com/kachick/dotfiles/internal/plamocache"
)

const (
	defaultPort = "18080"
	serviceName = "llama-plamo"
)

type exitError struct {
	code int
	err  error
}

func (e *exitError) Error() string {
	if e.err == nil {
		return ""
	}
	return e.err.Error()
}

func (e *exitError) Unwrap() error {
	return e.err
}

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

func buildSystemPrompt(sourceLang, targetLang, form, surroundingContext string) string {
	var sb strings.Builder
	sb.WriteString("[plamo-translate]\n")
	if sourceLang != "" {
		fmt.Fprintf(&sb, "source_lang=%s\n", sourceLang)
	}
	fmt.Fprintf(&sb, "target_lang=%s", targetLang)
	if form != "" {
		fmt.Fprintf(&sb, "\nform=%s", form)
	}
	if surroundingContext != "" {
		sb.WriteString("\n---\n")
		sb.WriteString(surroundingContext)
	}
	return sb.String()
}

func isASCIIAlphaLower(s string) bool {
	for i := range len(s) {
		if s[i] < 'a' || s[i] > 'z' {
			return false
		}
	}
	return len(s) > 0
}

// isLangCode matches short lowercase ISO-like language codes such as "ja",
// "en", or "zh-hans" so prose tokens like "Error:" or URLs are not mistaken
// for translate-shell language specs.
func isLangCode(s string) bool {
	base, sub, hasSub := strings.Cut(s, "-")
	if len(base) < 2 || len(base) > 3 || !isASCIIAlphaLower(base) {
		return false
	}
	if !hasSub {
		return true
	}
	return len(sub) >= 2 && len(sub) <= 4 && isASCIIAlphaLower(sub)
}

func parseLangSpec(token string) (sourceLang, targetLang string, ok bool) {
	source, target, hasColon := strings.Cut(token, ":")
	if !hasColon || strings.Contains(target, ":") {
		return "", "", false
	}
	if source != "" && !isLangCode(source) {
		return "", "", false
	}
	if !isLangCode(target) {
		return "", "", false
	}
	return source, target, true
}

// detectDefaultTargetLang routes Japanese text (containing Hiragana or Katakana)
// to English and everything else (including Chinese-only kanji) to Japanese.
func detectDefaultTargetLang(text string) string {
	for _, r := range text {
		if unicode.In(r, unicode.Hiragana, unicode.Katakana) {
			return "en"
		}
	}
	return "ja"
}

func isTerminal(r io.Reader) bool {
	f, ok := r.(*os.File)
	if !ok {
		return false
	}
	stat, err := f.Stat()
	if err != nil {
		return false
	}
	return (stat.Mode() & os.ModeCharDevice) != 0
}

func checkServiceStatus(serverURL string) string {
	var sb strings.Builder
	fmt.Fprintf(&sb, "llama-server is not reachable at %s.\n", serverURL)

	if _, err := exec.LookPath("systemctl"); err == nil {
		cmdFailed := exec.Command("systemctl", "--user", "is-failed", serviceName)
		if cmdFailed.Run() == nil {
			sb.WriteString("Service 'llama-plamo' failed. Check logs with: journalctl --user -u llama-plamo -e")
			return sb.String()
		}

		cmdActive := exec.Command("systemctl", "--user", "is-active", serviceName)
		out, _ := cmdActive.Output()
		if strings.TrimSpace(string(out)) == "activating" {
			sb.WriteString("Service 'llama-plamo' is still starting up. Please wait a moment.\nMonitor progress with: journalctl --user -u llama-plamo -f")
			return sb.String()
		}
	}

	sb.WriteString("Start the service with: plamo start")
	return sb.String()
}

func translateText(ctx context.Context, serverURL, systemPrompt, text string) (string, error) {
	reqBody := chatRequest{
		Messages: []chatMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: text},
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

func hasExplicitDoubleDash(args []string, remaining []string) bool {
	if len(remaining) == 0 {
		return false
	}
	idx := len(args) - len(remaining) - 1
	return idx >= 0 && args[idx] == "--"
}

func runTrans(progName string, args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	var specSource, specTarget string
	hasSpec := false

	// Allow `[SOURCE]:TARGET` before options (e.g. `trans :en --form polite ...`),
	// which Go's standard flag.FlagSet would otherwise stop parsing on.
	if len(args) > 0 && args[0] != "--" && !strings.HasPrefix(args[0], "-") {
		if src, dst, ok := parseLangSpec(args[0]); ok {
			specSource, specTarget, hasSpec = src, dst, true
			args = args[1:]
		}
	}

	fs := flag.NewFlagSet(progName, flag.ContinueOnError)
	fs.SetOutput(stderr)

	defaultP := os.Getenv("PLAMO_PORT")
	if defaultP == "" {
		defaultP = defaultPort
	}

	var targetFlag, form, surroundingContext, port string
	var noCache bool
	fs.StringVar(&targetFlag, "to", "", "Target language code")
	fs.StringVar(&form, "form", "", "Sentence form for target_lang=ja: plain or polite (default: plain)")
	fs.StringVar(&surroundingContext, "context", "", "Surrounding context or background information")
	fs.StringVar(&port, "port", defaultP, "Port of llama-server")
	fs.BoolVar(&noCache, "no-cache", false, "Bypass reading and writing the translation cache")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: %s [OPTIONS] [[SOURCE]:TARGET] [TEXT...]\n\n", progName)
		fmt.Fprintf(stderr, "Translate text using local PLaMo-3-Translate via llama-server.\n")
		fmt.Fprintf(stderr, "Reads from arguments if provided, otherwise reads from standard input.\n\n")
		fmt.Fprintf(stderr, "Language selection:\n")
		fmt.Fprintf(stderr, "  Omitted          Auto-detect: Japanese text (kana) -> en, otherwise -> ja\n")
		fmt.Fprintf(stderr, "  :LANG            Translate to LANG (e.g. :en, :ja, :zh-hans)\n")
		fmt.Fprintf(stderr, "  SRC:LANG         Set source and target languages (e.g. ja:en)\n")
		fmt.Fprintf(stderr, "  --               Stop option and language-spec parsing\n\n")
		fmt.Fprintf(stderr, "Options:\n")
		fmt.Fprintf(stderr, "  --to LANG        Target language code (alternative to :LANG)\n")
		fmt.Fprintf(stderr, "  --form FORM      Sentence form for target_lang=ja: plain or polite (default: plain)\n")
		fmt.Fprintf(stderr, "  --context TEXT   Surrounding context or background information\n")
		fmt.Fprintf(stderr, "  --port PORT      Port of llama-server (default: %s, env: PLAMO_PORT)\n", defaultP)
		fmt.Fprintf(stderr, "  --no-cache       Bypass reading and writing the translation cache\n")
		fmt.Fprintf(stderr, "  --help           Show this help message\n")
	}

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	if form != "" && form != "plain" && form != "polite" {
		return fmt.Errorf("invalid --form value %q: must be plain or polite", form)
	}

	remaining := fs.Args()
	if !hasSpec && len(remaining) > 0 && !hasExplicitDoubleDash(args, remaining) {
		if src, dst, ok := parseLangSpec(remaining[0]); ok {
			specSource, specTarget, hasSpec = src, dst, true
			remaining = remaining[1:]
		}
	}

	if hasSpec && targetFlag != "" {
		return errors.New("cannot specify both [SOURCE]:TARGET and --to")
	}

	var text string
	if len(remaining) > 0 {
		text = strings.Join(remaining, " ")
	} else {
		if isTerminal(stdin) {
			fs.Usage()
			return errors.New("no input text provided via arguments or stdin")
		}
		data, err := io.ReadAll(stdin)
		if err != nil {
			return fmt.Errorf("read stdin: %w", err)
		}
		text = string(data)
	}

	text = strings.TrimSpace(text)
	if text == "" {
		return nil
	}

	sourceLang := specSource
	targetLang := targetFlag
	if hasSpec {
		targetLang = specTarget
	}
	if targetLang == "" {
		targetLang = detectDefaultTargetLang(text)
	}

	// PLaMo-3-Translate's chat template rejects `form` unless target_lang is "ja".
	if form != "" && targetLang != "ja" {
		return fmt.Errorf("--form is only supported when target language is \"ja\" (got %q)", targetLang)
	}
	if form == "" && targetLang == "ja" {
		form = "plain"
	}

	systemPrompt := buildSystemPrompt(sourceLang, targetLang, form, surroundingContext)

	var cacheDir, cacheKey string
	if !noCache {
		cacheDir, _ = plamocache.Dir()
		cacheKey = plamocache.Key(systemPrompt, text)
		// Check persistent cache before llama-server health so cached translations stay available offline.
		if cached, ok := plamocache.Read(cacheDir, cacheKey); ok {
			fmt.Fprintln(stdout, cached)
			return nil
		}
	}

	serverURL := fmt.Sprintf("http://127.0.0.1:%s", port)

	ctx := context.Background()
	client := &http.Client{Timeout: 1 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, serverURL+"/health", nil)
	if err != nil {
		return err
	}
	resp, err := client.Do(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		if resp != nil {
			resp.Body.Close()
		}
		return errors.New(checkServiceStatus(serverURL))
	}
	resp.Body.Close()

	result, err := translateText(ctx, serverURL, systemPrompt, text)
	if err != nil {
		return err
	}

	if !noCache {
		_ = plamocache.Write(cacheDir, cacheKey, result)
	}

	fmt.Fprintln(stdout, result)
	return nil
}

func runSystemctl(action string, args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if len(args) > 0 {
		if args[0] == "-h" || args[0] == "--help" {
			fmt.Fprintf(stderr, "Usage: plamo %s\n\nRun: systemctl --user %s %s\n", action, action, serviceName)
			return nil
		}
		return fmt.Errorf("unexpected arguments for %s: %s", action, strings.Join(args, " "))
	}

	if _, err := exec.LookPath("systemctl"); err != nil {
		return errors.New("systemctl not found in PATH")
	}

	cmd := exec.Command("systemctl", "--user", action, serviceName)
	cmd.Stdin = stdin
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var ee *exec.ExitError
		if errors.As(err, &ee) {
			return &exitError{code: ee.ExitCode()}
		}
		return err
	}
	return nil
}

func printRootUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: plamo <command> [args...]\n\n")
	fmt.Fprintf(w, "Local PLaMo-3-Translate CLI and service controller.\n\n")
	fmt.Fprintf(w, "Commands:\n")
	fmt.Fprintf(w, "  trans    Translate text (shorthand symlink: trans)\n")
	fmt.Fprintf(w, "  start    Start the llama-plamo user service\n")
	fmt.Fprintf(w, "  stop     Stop the llama-plamo user service\n")
	fmt.Fprintf(w, "  status   Show llama-plamo user service status\n\n")
	fmt.Fprintf(w, "Run 'plamo <command> --help' for command options.\n")
}

func run(argv0 string, args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if filepath.Base(argv0) == "trans" {
		return runTrans("trans", args, stdin, stdout, stderr)
	}

	if len(args) == 0 {
		printRootUsage(stderr)
		return errors.New("missing command")
	}

	switch args[0] {
	case "trans":
		return runTrans("plamo trans", args[1:], stdin, stdout, stderr)
	case "start", "stop", "status":
		return runSystemctl(args[0], args[1:], stdin, stdout, stderr)
	case "-h", "--help", "help":
		printRootUsage(stderr)
		return nil
	default:
		printRootUsage(stderr)
		return fmt.Errorf("unknown command %q", args[0])
	}
}

func main() {
	if err := run(os.Args[0], os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		var ee *exitError
		if errors.As(err, &ee) {
			if ee.err != nil {
				fmt.Fprintf(os.Stderr, "Error: %s\n", ee.err)
			}
			os.Exit(ee.code)
		}
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}
