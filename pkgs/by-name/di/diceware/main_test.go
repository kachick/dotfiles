package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestEmbeddedWordlist(t *testing.T) {
	words, err := parseWordlist(rawWordlist)
	if err != nil {
		t.Fatalf("parseWordlist failed: %v", err)
	}

	const expectedCount = 7776
	if len(words) != expectedCount {
		t.Fatalf("got %d words, want %d", len(words), expectedCount)
	}

	seen := make(map[string]struct{}, len(words))
	for i, w := range words {
		if _, dup := seen[w]; dup {
			t.Fatalf("duplicate word %q at index %d", w, i)
		}
		seen[w] = struct{}{}

		for j := range len(w) {
			b := w[j]
			if !((b >= 'a' && b <= 'z') || b == '-') {
				t.Fatalf("unexpected byte %q in word %q at index %d", b, w, i)
			}
		}
	}
}

func TestRunDefaults(t *testing.T) {
	var stdout, stderr bytes.Buffer
	code := run(nil, &stdout, &stderr)
	if code != 0 {
		t.Fatalf("exit code = %d, want 0 (stderr=%q)", code, stderr.String())
	}

	lines := strings.Split(strings.TrimSuffix(stdout.String(), "\n"), "\n")
	if len(lines) != 8 {
		t.Fatalf("got %d lines, want 8", len(lines))
	}
	for _, line := range lines {
		// EFF wordlist includes hyphenated words such as "yo-yo", so 6 words joined by "-" have at least 5 hyphens.
		if strings.Count(line, "-") < 5 {
			t.Fatalf("expected at least 5 hyphens for default 6 words, got %q", line)
		}
	}
}

func TestRunOptions(t *testing.T) {
	words, err := parseWordlist(rawWordlist)
	if err != nil {
		t.Fatalf("parseWordlist failed: %v", err)
	}
	wordSet := make(map[string]struct{}, len(words))
	for _, w := range words {
		wordSet[w] = struct{}{}
	}

	t.Run("custom words, separator, and count", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		code := run([]string{"--words", "2", "--sep", "_", "--count", "3"}, &stdout, &stderr)
		if code != 0 {
			t.Fatalf("exit code = %d, want 0 (stderr=%q)", code, stderr.String())
		}

		lines := strings.Split(strings.TrimSuffix(stdout.String(), "\n"), "\n")
		if len(lines) != 3 {
			t.Fatalf("got %d lines, want 3", len(lines))
		}
		for _, line := range lines {
			parts := strings.Split(line, "_")
			if len(parts) != 2 {
				t.Fatalf("got %d words in %q, want 2", len(parts), line)
			}
			for _, p := range parts {
				if _, ok := wordSet[p]; !ok {
					t.Fatalf("word %q is not in EFF wordlist", p)
				}
			}
		}
	})

	t.Run("capitalize, number, and symbols with single word", func(t *testing.T) {
		const allowedSymbols = "!@#?"
		var stdout, stderr bytes.Buffer
		code := run([]string{"--words", "1", "--count", "1", "--capitalize", "--number", "--symbols", allowedSymbols}, &stdout, &stderr)
		if code != 0 {
			t.Fatalf("exit code = %d, want 0 (stderr=%q)", code, stderr.String())
		}

		got := strings.TrimSuffix(stdout.String(), "\n")
		if len(got) < 3 {
			t.Fatalf("unexpectedly short output %q", got)
		}
		if got[0] < 'A' || got[0] > 'Z' {
			t.Fatalf("first character is not uppercase in %q", got)
		}
		if !strings.ContainsAny(got, "0123456789") {
			t.Fatalf("expected a digit in %q", got)
		}
		if !strings.ContainsAny(got, allowedSymbols) {
			t.Fatalf("expected a symbol from %q in %q", allowedSymbols, got)
		}
	})

	t.Run("dump-wordlist prints raw embedded wordlist", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		code := run([]string{"--dump-wordlist"}, &stdout, &stderr)
		if code != 0 {
			t.Fatalf("exit code = %d, want 0 (stderr=%q)", code, stderr.String())
		}
		if stdout.String() != rawWordlist {
			t.Fatalf("stdout does not match embedded wordlist (got %d bytes, want %d bytes)", stdout.Len(), len(rawWordlist))
		}
		if stderr.Len() != 0 {
			t.Fatalf("unexpected stderr %q", stderr.String())
		}
	})

	t.Run("help exits 0", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		code := run([]string{"--help"}, &stdout, &stderr)
		if code != 0 {
			t.Fatalf("exit code = %d, want 0", code)
		}
	})
}

func TestRunInvalidArgs(t *testing.T) {
	cases := [][]string{
		{"--words", "0"},
		{"--count", "0"},
		{"--dump-wordlist", "--words", "2"},
		{"-w", "2"},
		{"extra"},
		{"--unknown"},
	}

	for _, args := range cases {
		var stdout, stderr bytes.Buffer
		code := run(args, &stdout, &stderr)
		if code != 2 {
			t.Errorf("run(%v) = %d, want 2", args, code)
		}
	}
}
