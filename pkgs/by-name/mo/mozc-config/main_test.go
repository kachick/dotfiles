package main

import (
	"strings"
	"testing"
)

func TestBuildCustomKeymapTextproto(t *testing.T) {
	input := "status\tkey\tcommand\nDirectInput\tCtrl Space\tIMEOn\nPrecomposition\tMuhenkan\tIMEOff\n"
	got := string(buildCustomKeymapTextproto([]byte(input)))

	wantPrefix := "session_keymap: CUSTOM\ncustom_keymap_table: \""
	if !strings.HasPrefix(got, wantPrefix) {
		t.Fatalf("unexpected prefix:\ngot:  %q\nwant: %q", got, wantPrefix)
	}
	if !strings.Contains(got, `status\tkey\tcommand\n`) {
		t.Fatalf("expected escaped tab and newline in %q", got)
	}
	if !strings.Contains(got, `DirectInput\tCtrl Space\tIMEOn\n`) {
		t.Fatalf("expected Ctrl Space entry in %q", got)
	}
}

func TestResolveProtoDir(t *testing.T) {
	t.Setenv("MOZC_PROTO_DIR", "/env/proto")

	got, err := resolveProtoDir("/flag/proto")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "/flag/proto" {
		t.Fatalf("flag should win over env: got %q, want %q", got, "/flag/proto")
	}

	got, err = resolveProtoDir("")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "/env/proto" {
		t.Fatalf("env fallback failed: got %q, want %q", got, "/env/proto")
	}

	t.Setenv("MOZC_PROTO_DIR", "")
	if _, err := resolveProtoDir(""); err == nil {
		t.Fatal("expected error when neither flag nor env is set")
	}
}

func TestDefaultConfigDBPath(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/tmp/custom-xdg")
	got, err := defaultConfigDBPath()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := "/tmp/custom-xdg/mozc/config1.db"
	if got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
}
