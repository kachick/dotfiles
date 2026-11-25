package main

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Bump when the cache layout or default translation behavior changes incompatibly.
const translationCacheVersion = "v1"

func translationCacheDir() (string, error) {
	base, err := os.UserCacheDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(base, "git-x", "translations"), nil
}

func translationCacheKey(systemPrompt, message string) string {
	h := sha256.New()
	h.Write([]byte(translationCacheVersion))
	h.Write([]byte{0})
	h.Write([]byte(systemPrompt))
	h.Write([]byte{0})
	h.Write([]byte(message))
	return hex.EncodeToString(h.Sum(nil))
}

func translationCachePath(cacheDir, key string) string {
	return filepath.Join(cacheDir, key[:2], key+".txt")
}

func readTranslationCache(cacheDir, key string) (string, bool) {
	if cacheDir == "" || len(key) < 2 {
		return "", false
	}

	path := translationCachePath(cacheDir, key)
	data, err := os.ReadFile(path)
	if err != nil {
		return "", false
	}

	text := strings.TrimSpace(string(data))
	if text == "" {
		return "", false
	}

	// Refresh timestamps on cache hits so systemd-tmpfiles keeps frequently viewed commits.
	now := time.Now()
	_ = os.Chtimes(path, now, now)

	return text, true
}

func writeTranslationCache(cacheDir, key, translated string) error {
	if cacheDir == "" || len(key) < 2 {
		return nil
	}

	text := strings.TrimSpace(translated)
	if text == "" {
		return nil
	}

	path := translationCachePath(cacheDir, key)
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}

	// Use a unique temp file plus atomic rename so parallel log-fzf workers never corrupt an entry.
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
