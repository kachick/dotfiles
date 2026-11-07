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
	"strings"
	"time"
)

const (
	defaultPort = "18080"
)

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

func buildSystemPrompt(targetLang, form string) string {
	return fmt.Sprintf("[plamo-translate]\ntarget_lang=%s\nform=%s", targetLang, form)
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
	sb.WriteString(fmt.Sprintf("llama-server is not reachable at %s.\n", serverURL))

	if _, err := exec.LookPath("systemctl"); err == nil {
		cmdFailed := exec.Command("systemctl", "--user", "is-failed", "llama-plamo")
		if cmdFailed.Run() == nil {
			sb.WriteString("Service 'llama-plamo' failed. Check logs with: journalctl --user -u llama-plamo -e")
			return sb.String()
		}

		cmdActive := exec.Command("systemctl", "--user", "is-active", "llama-plamo")
		out, _ := cmdActive.Output()
		if strings.TrimSpace(string(out)) == "activating" {
			sb.WriteString("Service 'llama-plamo' is still starting up. Please wait a moment.\nMonitor progress with: journalctl --user -u llama-plamo -f")
			return sb.String()
		}
	}

	sb.WriteString("Start the service with: systemctl --user start llama-plamo (or 'plamo-start')")
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

func run(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("plamo-trans", flag.ContinueOnError)
	fs.SetOutput(stderr)

	defaultP := os.Getenv("PLAMO_PORT")
	if defaultP == "" {
		defaultP = defaultPort
	}

	var targetLang, form, port string
	fs.StringVar(&targetLang, "t", "ja", "Target language code")
	fs.StringVar(&targetLang, "to", "ja", "Target language code")
	fs.StringVar(&form, "f", "plain", "Sentence form: plain or polite")
	fs.StringVar(&form, "form", "plain", "Sentence form: plain or polite")
	fs.StringVar(&port, "p", defaultP, "Port of llama-server")
	fs.StringVar(&port, "port", defaultP, "Port of llama-server")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: plamo-trans [OPTIONS] [TEXT...]\n\n")
		fmt.Fprintf(stderr, "Translate text using local PLaMo-3-Translate via llama-server.\n")
		fmt.Fprintf(stderr, "Reads from arguments if provided, otherwise reads from standard input.\n\n")
		fmt.Fprintf(stderr, "Options:\n")
		fmt.Fprintf(stderr, "  -t, --to LANG       Target language code (default: ja)\n")
		fmt.Fprintf(stderr, "  -f, --form FORM     Sentence form: plain or polite (default: plain)\n")
		fmt.Fprintf(stderr, "  -p, --port PORT     Port of llama-server (default: %s, env: PLAMO_PORT)\n", defaultP)
		fmt.Fprintf(stderr, "  -h, --help          Show this help message\n\n")
		fmt.Fprintf(stderr, "Server controls:\n")
		fmt.Fprintf(stderr, "  Start:   systemctl --user start llama-plamo (or plamo-start)\n")
		fmt.Fprintf(stderr, "  Stop:    systemctl --user stop llama-plamo (or plamo-stop)\n")
		fmt.Fprintf(stderr, "  Status:  systemctl --user status llama-plamo (or plamo-status)\n")
	}

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	var text string
	remaining := fs.Args()
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

	serverURL := fmt.Sprintf("http://127.0.0.1:%s", port)

	// Health check
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

	systemPrompt := buildSystemPrompt(targetLang, form)
	result, err := translateText(ctx, serverURL, systemPrompt, text)
	if err != nil {
		return err
	}

	fmt.Fprintln(stdout, result)
	return nil
}

func main() {
	if err := run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}
