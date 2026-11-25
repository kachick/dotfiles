package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestBuildSystemPrompt(t *testing.T) {
	got := buildSystemPrompt("", "ja", "plain", "")
	want := "[plamo-translate]\ntarget_lang=ja\nform=plain"
	if got != want {
		t.Errorf("buildSystemPrompt(\"\", ja, plain, \"\") = %q, want %q", got, want)
	}

	gotWithSource := buildSystemPrompt("ja", "en", "polite", "")
	wantWithSource := "[plamo-translate]\nsource_lang=ja\ntarget_lang=en\nform=polite"
	if gotWithSource != wantWithSource {
		t.Errorf("buildSystemPrompt(ja, en, polite, \"\") = %q, want %q", gotWithSource, wantWithSource)
	}

	gotWithContext := buildSystemPrompt("", "ja", "plain", "Git commit message")
	wantWithContext := "[plamo-translate]\ntarget_lang=ja\nform=plain\n---\nGit commit message"
	if gotWithContext != wantWithContext {
		t.Errorf("buildSystemPrompt(\"\", ja, plain, ctx) = %q, want %q", gotWithContext, wantWithContext)
	}
}

func TestParseLangSpec(t *testing.T) {
	tests := []struct {
		token      string
		wantSource string
		wantTarget string
		wantOK     bool
	}{
		{":en", "", "en", true},
		{":ja", "", "ja", true},
		{"ja:en", "ja", "en", true},
		{"en:zh-hans", "en", "zh-hans", true},
		{":zh-hant", "", "zh-hant", true},
		{"Error: failed", "", "", false},
		{"Error:", "", "", false},
		{"https://example.com", "", "", false},
		{"12:30", "", "", false},
		{"note:hello", "", "", false},
		{"ja:en:fr", "", "", false},
		{"ja:", "", "", false},
		{"plain", "", "", false},
	}

	for _, tc := range tests {
		src, dst, ok := parseLangSpec(tc.token)
		if ok != tc.wantOK || src != tc.wantSource || dst != tc.wantTarget {
			t.Errorf("parseLangSpec(%q) = (%q, %q, %v), want (%q, %q, %v)",
				tc.token, src, dst, ok, tc.wantSource, tc.wantTarget, tc.wantOK)
		}
	}
}

func TestDetectDefaultTargetLang(t *testing.T) {
	tests := []struct {
		text string
		want string
	}{
		{"Hello, world!", "ja"},
		{"こんにちは世界", "en"},
		{"テスト", "en"},
		{"Go言語で書く", "en"},
		{"你好世界", "ja"},
		{"12345", "ja"},
	}

	for _, tc := range tests {
		got := detectDefaultTargetLang(tc.text)
		if got != tc.want {
			t.Errorf("detectDefaultTargetLang(%q) = %q, want %q", tc.text, got, tc.want)
		}
	}
}

func startMockPlamoServer(t *testing.T, gotReq *chatRequest) string {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/health":
			w.WriteHeader(http.StatusOK)
		case "/v1/chat/completions":
			if err := json.NewDecoder(r.Body).Decode(gotReq); err != nil {
				t.Errorf("decode request: %v", err)
				w.WriteHeader(http.StatusBadRequest)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(chatResponse{
				Choices: []chatChoice{
					{Message: chatMessage{Role: "assistant", Content: "translated"}},
				},
			})
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	t.Cleanup(srv.Close)

	u, err := url.Parse(srv.URL)
	if err != nil {
		t.Fatalf("parse mock server URL: %v", err)
	}
	return u.Port()
}

func TestRunTransBehavior(t *testing.T) {
	tests := []struct {
		name       string
		argv0      string
		args       []string
		stdin      string
		wantPrompt string
		wantText   string
	}{
		{
			name:       "auto detect English to Japanese via trans symlink",
			argv0:      "/nix/store/xxx/bin/trans",
			args:       []string{"Hello,", "world!"},
			wantPrompt: "[plamo-translate]\ntarget_lang=ja\nform=plain",
			wantText:   "Hello, world!",
		},
		{
			name:       "auto detect Japanese to English",
			argv0:      "trans",
			args:       []string{"こんにちは"},
			wantPrompt: "[plamo-translate]\ntarget_lang=en\nform=plain",
			wantText:   "こんにちは",
		},
		{
			name:       "lang spec before flags",
			argv0:      "trans",
			args:       []string{":ja", "--form", "polite", "Good morning"},
			wantPrompt: "[plamo-translate]\ntarget_lang=ja\nform=polite",
			wantText:   "Good morning",
		},
		{
			name:       "flags before lang spec via plamo trans",
			argv0:      "plamo",
			args:       []string{"trans", "--form", "polite", "ja:en", "おはよう"},
			wantPrompt: "[plamo-translate]\nsource_lang=ja\ntarget_lang=en\nform=polite",
			wantText:   "おはよう",
		},
		{
			name:       "double dash stops lang spec parsing",
			argv0:      "trans",
			args:       []string{"--", ":en", "literal"},
			wantPrompt: "[plamo-translate]\ntarget_lang=ja\nform=plain",
			wantText:   ":en literal",
		},
		{
			name:       "colon in prose is not mistaken for lang spec",
			argv0:      "trans",
			args:       []string{"Error:", "file", "not", "found"},
			wantPrompt: "[plamo-translate]\ntarget_lang=ja\nform=plain",
			wantText:   "Error: file not found",
		},
		{
			name:       "stdin with lang spec",
			argv0:      "trans",
			args:       []string{":en"},
			stdin:      "日本語のテスト\n",
			wantPrompt: "[plamo-translate]\ntarget_lang=en\nform=plain",
			wantText:   "日本語のテスト",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			var gotReq chatRequest
			port := startMockPlamoServer(t, &gotReq)
			t.Setenv("PLAMO_PORT", port)

			var stdout, stderr bytes.Buffer
			err := run(tc.argv0, tc.args, strings.NewReader(tc.stdin), &stdout, &stderr)
			if err != nil {
				t.Fatalf("unexpected error: %v (stderr: %s)", err, stderr.String())
			}
			if strings.TrimSpace(stdout.String()) != "translated" {
				t.Errorf("stdout = %q, want %q", stdout.String(), "translated\n")
			}
			if len(gotReq.Messages) != 2 {
				t.Fatalf("messages count = %d, want 2", len(gotReq.Messages))
			}
			if gotReq.Messages[0].Content != tc.wantPrompt {
				t.Errorf("system prompt = %q, want %q", gotReq.Messages[0].Content, tc.wantPrompt)
			}
			if gotReq.Messages[1].Content != tc.wantText {
				t.Errorf("user text = %q, want %q", gotReq.Messages[1].Content, tc.wantText)
			}
		})
	}
}

func TestRunErrors(t *testing.T) {
	t.Run("conflicting lang spec and --to", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{":en", "--to", "ja", "hello"}, strings.NewReader(""), &stdout, &stderr)
		if err == nil || !strings.Contains(err.Error(), "cannot specify both") {
			t.Fatalf("expected conflict error, got: %v", err)
		}
	})

	t.Run("short -p flag is rejected", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{"-p", "18080", "hello"}, strings.NewReader(""), &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error for removed -p flag, got nil")
		}
	})

	t.Run("invalid form value", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{"--form", "casual", "hello"}, strings.NewReader(""), &stdout, &stderr)
		if err == nil || !strings.Contains(err.Error(), "invalid --form") {
			t.Fatalf("expected invalid form error, got: %v", err)
		}
	})

	t.Run("empty whitespace input returns nil", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{}, strings.NewReader("   \n\t  "), &stdout, &stderr)
		if err != nil {
			t.Fatalf("expected nil error for empty input, got: %v", err)
		}
		if stdout.String() != "" {
			t.Errorf("expected empty stdout, got: %q", stdout.String())
		}
	})

	t.Run("root help", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("plamo", []string{"--help"}, strings.NewReader(""), &stdout, &stderr)
		if err != nil {
			t.Fatalf("expected nil error for plamo --help, got: %v", err)
		}
		if !strings.Contains(stderr.String(), "Usage: plamo <command>") {
			t.Errorf("expected root usage in stderr, got: %s", stderr.String())
		}
	})

	t.Run("trans help", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{"--help"}, strings.NewReader(""), &stdout, &stderr)
		if err != nil {
			t.Fatalf("expected nil error for trans --help, got: %v", err)
		}
		if !strings.Contains(stderr.String(), "Usage: trans [OPTIONS]") {
			t.Errorf("expected trans usage in stderr, got: %s", stderr.String())
		}
	})
}
