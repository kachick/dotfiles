package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync/atomic"
	"testing"
)

func TestBuildSystemPrompt(t *testing.T) {
	got := buildSystemPrompt("", "ja", "plain", "")
	want := "[plamo-translate]\ntarget_lang=ja\nform=plain"
	if got != want {
		t.Errorf("buildSystemPrompt(\"\", ja, plain, \"\") = %q, want %q", got, want)
	}

	gotWithSource := buildSystemPrompt("ja", "en", "", "")
	wantWithSource := "[plamo-translate]\nsource_lang=ja\ntarget_lang=en"
	if gotWithSource != wantWithSource {
		t.Errorf("buildSystemPrompt(ja, en, \"\", \"\") = %q, want %q", gotWithSource, wantWithSource)
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
			wantPrompt: "[plamo-translate]\ntarget_lang=en",
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
			args:       []string{"trans", "--form", "polite", "en:ja", "Good morning"},
			wantPrompt: "[plamo-translate]\nsource_lang=en\ntarget_lang=ja\nform=polite",
			wantText:   "Good morning",
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
			wantPrompt: "[plamo-translate]\ntarget_lang=en",
			wantText:   "日本語のテスト",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("XDG_CACHE_HOME", t.TempDir())
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

	t.Run("form rejected for non-ja target", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{":en", "--form", "polite", "おはよう"}, strings.NewReader(""), &stdout, &stderr)
		if err == nil || !strings.Contains(err.Error(), "--form is only supported") {
			t.Fatalf("expected form target error, got: %v", err)
		}
	})

	t.Run("form rejected for auto-detected en target", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := run("trans", []string{"--form", "plain", "こんにちは"}, strings.NewReader(""), &stdout, &stderr)
		if err == nil || !strings.Contains(err.Error(), "--form is only supported") {
			t.Fatalf("expected form target error, got: %v", err)
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

func TestRunTransPersistentCache(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", t.TempDir())

	var calls atomic.Int32
	var responseText atomic.Value
	responseText.Store("最初の翻訳")

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/health":
			w.WriteHeader(http.StatusOK)
		case "/v1/chat/completions":
			calls.Add(1)
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(chatResponse{
				Choices: []chatChoice{
					{Message: chatMessage{Role: "assistant", Content: responseText.Load().(string)}},
				},
			})
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer srv.Close()

	u, err := url.Parse(srv.URL)
	if err != nil {
		t.Fatalf("parse mock server URL: %v", err)
	}
	t.Setenv("PLAMO_PORT", u.Port())

	// First run calls llama-server and saves the result to persistent cache.
	var stdout, stderr bytes.Buffer
	if err := run("trans", nil, strings.NewReader("Long input text from stdin\n"), &stdout, &stderr); err != nil {
		t.Fatalf("first run failed: %v", err)
	}
	if strings.TrimSpace(stdout.String()) != "最初の翻訳" {
		t.Errorf("first stdout = %q, want %q", stdout.String(), "最初の翻訳\n")
	}
	if got := calls.Load(); got != 1 {
		t.Fatalf("calls after first run = %d, want 1", got)
	}

	// --no-cache bypasses reading and writing the cache.
	responseText.Store("キャッシュ無視の翻訳")
	stdout.Reset()
	stderr.Reset()
	if err := run("trans", []string{"--no-cache"}, strings.NewReader("Long input text from stdin\n"), &stdout, &stderr); err != nil {
		t.Fatalf("--no-cache run failed: %v", err)
	}
	if strings.TrimSpace(stdout.String()) != "キャッシュ無視の翻訳" {
		t.Errorf("--no-cache stdout = %q, want %q", stdout.String(), "キャッシュ無視の翻訳\n")
	}
	if got := calls.Load(); got != 2 {
		t.Fatalf("calls after --no-cache = %d, want 2", got)
	}

	// Different prompt options (--form polite) must not collide with the cached entry.
	responseText.Store("丁寧な翻訳")
	stdout.Reset()
	stderr.Reset()
	if err := run("trans", []string{"--form", "polite"}, strings.NewReader("Long input text from stdin\n"), &stdout, &stderr); err != nil {
		t.Fatalf("--form polite run failed: %v", err)
	}
	if strings.TrimSpace(stdout.String()) != "丁寧な翻訳" {
		t.Errorf("--form polite stdout = %q, want %q", stdout.String(), "丁寧な翻訳\n")
	}
	if got := calls.Load(); got != 3 {
		t.Fatalf("calls after --form polite = %d, want 3", got)
	}

	// Second default run must return the original cached value even after llama-server stops.
	srv.Close()
	stdout.Reset()
	stderr.Reset()
	if err := run("trans", nil, strings.NewReader("Long input text from stdin\n"), &stdout, &stderr); err != nil {
		t.Fatalf("cached run failed with server stopped: %v", err)
	}
	if strings.TrimSpace(stdout.String()) != "最初の翻訳" {
		t.Errorf("cached stdout = %q, want %q", stdout.String(), "最初の翻訳\n")
	}
	if got := calls.Load(); got != 3 {
		t.Errorf("calls after cache hit = %d, want 3", got)
	}
}
