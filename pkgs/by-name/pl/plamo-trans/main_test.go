package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestBuildSystemPrompt(t *testing.T) {
	got := buildSystemPrompt("ja", "plain")
	want := "[plamo-translate]\ntarget_lang=ja\nform=plain"
	if got != want {
		t.Errorf("buildSystemPrompt(ja, plain) = %q, want %q", got, want)
	}

	gotPolite := buildSystemPrompt("en", "polite")
	wantPolite := "[plamo-translate]\ntarget_lang=en\nform=polite"
	if gotPolite != wantPolite {
		t.Errorf("buildSystemPrompt(en, polite) = %q, want %q", gotPolite, wantPolite)
	}
}

func TestRunEmptyInput(t *testing.T) {
	var stdout, stderr bytes.Buffer
	stdin := strings.NewReader("   \n\t  ")

	err := run([]string{}, stdin, &stdout, &stderr)
	if err != nil {
		t.Fatalf("expected nil error for empty whitespace input, got: %v", err)
	}
	if stdout.String() != "" {
		t.Errorf("expected empty stdout, got: %q", stdout.String())
	}
}

func TestRunHelp(t *testing.T) {
	var stdout, stderr bytes.Buffer
	stdin := strings.NewReader("")

	err := run([]string{"--help"}, stdin, &stdout, &stderr)
	if err != nil {
		t.Fatalf("expected nil error for --help, got: %v", err)
	}
	if !strings.Contains(stderr.String(), "Usage: plamo-trans") {
		t.Errorf("expected usage in stderr, got: %s", stderr.String())
	}
}
