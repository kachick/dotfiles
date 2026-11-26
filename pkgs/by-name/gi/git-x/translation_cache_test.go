package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
)

func TestRunShow_PersistentTranslationCache(t *testing.T) {
	isolateEnv(t)
	repoDir := filepath.Join(t.TempDir(), "repo")
	initSeedRepo(t, repoDir, "main")

	var completionsCalls atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/health":
			w.WriteHeader(http.StatusOK)
		case "/v1/chat/completions":
			completionsCalls.Add(1)
			resp := chatResponse{
				Choices: []chatChoice{
					{Message: chatMessage{Role: "assistant", Content: "初回コミット"}},
				},
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(resp)
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()

	u, err := url.Parse(server.URL)
	if err != nil {
		t.Fatalf("parse mock server URL: %v", err)
	}
	t.Setenv("PLAMO_PORT", u.Port())

	// First run populates the XDG cache via the mock server.
	var stdout, stderr bytes.Buffer
	if err := runShow([]string{"--ja", "HEAD"}, repoDir, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("first runShow --ja failed: %v", err)
	}
	if !strings.Contains(stdout.String(), "初回コミット") {
		t.Errorf("expected translation in first output, got:\n%s", stdout.String())
	}
	if got := completionsCalls.Load(); got != 1 {
		t.Fatalf("completionsCalls = %d, want 1", got)
	}

	// Second run must succeed from persistent cache even after llama-server stops.
	server.Close()
	stdout.Reset()
	stderr.Reset()
	if err := runShow([]string{"--ja", "HEAD"}, repoDir, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("second runShow --ja failed with server stopped: %v", err)
	}
	if !strings.Contains(stdout.String(), "初回コミット") {
		t.Errorf("expected cached translation in second output, got:\n%s", stdout.String())
	}
	if got := completionsCalls.Load(); got != 1 {
		t.Errorf("completionsCalls = %d, want 1 after cache hit", got)
	}

	if !hasPersistentTranslation(repoDir, "HEAD") {
		t.Error("expected hasPersistentTranslation(repoDir, \"HEAD\") to be true after caching")
	}
}
