package main

import (
	"testing"
)

func Test_initializeLinters(t *testing.T) {
	t.Run("returns linters covering title, message body, and diff against secrets and typos", func(t *testing.T) {
		line := "refs/heads/feature 1111111111111111111111111111111111111111 refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(linters) != 3 {
			t.Fatalf("got %d linters, want 3", len(linters))
		}

		expectedKeyTags := map[string]string{
			"prevent secrets in log and diff": "betterleaks",
			"prevent typos in log and diff":   "typos-commits",
			"prevent typos in branch name":    "typos-branch",
		}

		for key, wantTag := range expectedKeyTags {
			linter, ok := linters[key]
			if !ok {
				t.Errorf("missing expected linter key: %q", key)
				continue
			}
			if linter.Tag != wantTag {
				t.Errorf("linter %q tag = %q, want %q", key, linter.Tag, wantTag)
			}
		}
	})

	t.Run("skips deleted ref when localRef is (delete)", func(t *testing.T) {
		line := "(delete) 0000000000000000000000000000000000000000 refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for deleted ref", linters)
		}
	})

	t.Run("skips deleted ref when localOid is SHA-1 zero OID", func(t *testing.T) {
		line := "refs/heads/feature " + zeroOIDSHA1 + " refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for SHA-1 zero oid", linters)
		}
	})

	t.Run("skips deleted ref when localOid is SHA-256 zero OID", func(t *testing.T) {
		line := "refs/heads/feature " + zeroOIDSHA256 + " refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for SHA-256 zero oid", linters)
		}
	})

	t.Run("returns error on invalid line format", func(t *testing.T) {
		line := "invalid input"
		_, err := initializeLinters(line, "main", "dev@example.com")
		if err == nil {
			t.Fatal("expected error on invalid input, got nil")
		}
	})
}
