package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestTranslationCacheReadWriteAndTouch(t *testing.T) {
	cacheDir := filepath.Join(t.TempDir(), "translations")
	key1 := translationCacheKey("prompt-a", "Add feature")
	key2 := translationCacheKey("prompt-b", "Add feature")
	if key1 == key2 {
		t.Fatalf("expected distinct cache keys for different prompts, got %q", key1)
	}

	if _, ok := readTranslationCache(cacheDir, key1); ok {
		t.Fatal("expected cache miss before write")
	}

	if err := writeTranslationCache(cacheDir, key1, "機能を追加\n"); err != nil {
		t.Fatalf("writeTranslationCache failed: %v", err)
	}

	path := translationCachePath(cacheDir, key1)
	oldTime := time.Now().Add(-48 * time.Hour)
	if err := os.Chtimes(path, oldTime, oldTime); err != nil {
		t.Fatalf("os.Chtimes failed: %v", err)
	}

	got, ok := readTranslationCache(cacheDir, key1)
	if !ok {
		t.Fatal("expected cache hit after write")
	}
	if got != "機能を追加" {
		t.Errorf("readTranslationCache = %q, want %q", got, "機能を追加")
	}

	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("os.Stat failed: %v", err)
	}
	if !info.ModTime().After(oldTime) {
		t.Errorf("expected mtime to be refreshed on cache hit: got %v, old %v", info.ModTime(), oldTime)
	}
}

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

	t.Chdir(repoDir)
	if !hasPersistentTranslation("HEAD") {
		t.Error("expected hasPersistentTranslation(\"HEAD\") to be true after caching")
	}
}
