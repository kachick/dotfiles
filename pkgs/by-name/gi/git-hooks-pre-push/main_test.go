package main

import (
	"strings"
	"testing"
)

func Test_isZeroOID(t *testing.T) {
	tests := []struct {
		name string
		oid  string
		want bool
	}{
		{
			name: "SHA-1 null OID",
			oid:  strings.Repeat("0", 40),
			want: true,
		},
		{
			name: "SHA-256 null OID",
			oid:  strings.Repeat("0", 64),
			want: true,
		},
		{
			name: "empty string",
			oid:  "",
			want: false,
		},
		{
			name: "SHA-1 non-zero OID",
			oid:  strings.Repeat("0", 39) + "1",
			want: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isZeroOID(tt.oid); got != tt.want {
				t.Errorf("isZeroOID(%q) = %v, want %v", tt.oid, got, tt.want)
			}
		})
	}
}

func Test_initializeLinters(t *testing.T) {
	t.Run("returns linters for normal push", func(t *testing.T) {
		line := "refs/heads/feature 1111111111111111111111111111111111111111 refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(linters) != 3 {
			t.Fatalf("got %d linters, want 3", len(linters))
		}

		tags := map[string]bool{}
		for _, l := range linters {
			tags[l.Tag] = true
		}
		expectedTags := []string{"betterleaks", "typos-commits", "typos-branch"}
		for _, tag := range expectedTags {
			if !tags[tag] {
				t.Errorf("missing expected tag: %s", tag)
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

	t.Run("skips deleted ref when localOid is all zero", func(t *testing.T) {
		line := "refs/heads/feature 0000000000000000000000000000000000000000 refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for zero oid", linters)
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
