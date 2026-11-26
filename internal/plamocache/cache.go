package plamocache

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Bump when the cache layout or default translation behavior changes incompatibly.
const version = "v1"

// Dir returns the shared persistent translation cache directory under XDG_CACHE_HOME.
func Dir() (string, error) {
	base, err := os.UserCacheDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(base, "plamo", "translations"), nil
}

// Key computes a content-addressed cache key from the system prompt and input text.
func Key(systemPrompt, text string) string {
	h := sha256.New()
	h.Write([]byte(version))
	h.Write([]byte{0})
	h.Write([]byte(systemPrompt))
	h.Write([]byte{0})
	h.Write([]byte(text))
	return hex.EncodeToString(h.Sum(nil))
}

// Path returns the sharded file path for a cache key inside cacheDir.
func Path(cacheDir, key string) string {
	return filepath.Join(cacheDir, key[:2], key+".txt")
}

// Read returns a cached translation and refreshes its mtime on hit.
func Read(cacheDir, key string) (string, bool) {
	if cacheDir == "" || len(key) < 2 {
		return "", false
	}

	path := Path(cacheDir, key)
	data, err := os.ReadFile(path)
	if err != nil {
		return "", false
	}

	text := strings.TrimSpace(string(data))
	if text == "" {
		return "", false
	}

	// Refresh timestamps on cache hits so systemd-tmpfiles keeps frequently used translations.
	now := time.Now()
	_ = os.Chtimes(path, now, now)

	return text, true
}

// Write stores a translation atomically so concurrent callers never corrupt an entry.
func Write(cacheDir, key, translated string) error {
	if cacheDir == "" || len(key) < 2 {
		return nil
	}

	text := strings.TrimSpace(translated)
	if text == "" {
		return nil
	}

	path := Path(cacheDir, key)
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}

	// Use a unique temp file plus atomic rename so parallel callers (e.g. git-x log-fzf workers) never corrupt an entry.
	tmp, err := os.CreateTemp(dir, key+".tmp-*")
	if err != nil {
		return err
	}
	tmpPath := tmp.Name()

	if _, err := tmp.WriteString(text); err != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpPath)
		return err
	}
	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}
	return nil
}
