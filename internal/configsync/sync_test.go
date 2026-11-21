package configsync

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
)

func TestUnifiedDiff(t *testing.T) {
	t.Run("Identical", func(t *testing.T) {
		got := UnifiedDiff("a", "b", []byte("line1\nline2\n"), []byte("line1\nline2\n"))
		if got != "" {
			t.Fatalf("expected empty diff, got:\n%s", got)
		}
	})

	t.Run("ChangedLine", func(t *testing.T) {
		got := UnifiedDiff("old.txt", "new.txt", []byte("a\nb\nc\n"), []byte("a\nB\nc\n"))
		for _, want := range []string{"--- old.txt", "+++ new.txt", "-b", "+B"} {
			if !strings.Contains(got, want) {
				t.Errorf("diff missing %q:\n%s", want, got)
			}
		}
	})

	t.Run("Binary", func(t *testing.T) {
		got := UnifiedDiff("old.bin", "new.bin", []byte{0, 1}, []byte{0, 2, 3})
		if !strings.Contains(got, "Binary files differ") {
			t.Fatalf("expected binary diff notice, got:\n%s", got)
		}
	})
}

func TestSync_CreateAndUnchanged(t *testing.T) {
	fsys := fstest.MapFS{
		"dir/a.toml": &fstest.MapFile{Data: []byte("alpha = 1\n")},
		"dir/b.toml": &fstest.MapFile{Data: []byte("beta = 2\n")},
	}
	dstDir := t.TempDir()

	entries := []Entry{{
		SrcFS:   fsys,
		SrcPath: "dir",
		DstPath: filepath.Join(dstDir, "nested"),
		Perm:    0o600,
		IsDir:   true,
	}}

	res, err := Sync(entries, Options{})
	if err != nil {
		t.Fatalf("initial Sync failed: %v", err)
	}
	if len(res) != 2 {
		t.Fatalf("len(res) = %d, want 2", len(res))
	}
	for _, r := range res {
		if r.Status != StatusCreated {
			t.Errorf("%s: status = %s, want %s", r.DstPath, r.Status, StatusCreated)
		}
	}

	res, err = Sync(entries, Options{})
	if err != nil {
		t.Fatalf("second Sync failed: %v", err)
	}
	for _, r := range res {
		if r.Status != StatusUnchanged {
			t.Errorf("%s: status = %s, want %s", r.DstPath, r.Status, StatusUnchanged)
		}
	}
}

func TestSync_PromptPerFileSkipAndOverwrite(t *testing.T) {
	fsys := fstest.MapFS{
		"first.txt":  &fstest.MapFile{Data: []byte("new-1\n")},
		"second.txt": &fstest.MapFile{Data: []byte("new-2\n")},
		"third.txt":  &fstest.MapFile{Data: []byte("new-3\n")},
	}
	dstDir := t.TempDir()
	firstDst := filepath.Join(dstDir, "first.txt")
	secondDst := filepath.Join(dstDir, "second.txt")
	thirdDst := filepath.Join(dstDir, "third.txt")

	for _, p := range []string{firstDst, secondDst, thirdDst} {
		if err := os.WriteFile(p, []byte("old\n"), 0o600); err != nil {
			t.Fatalf("write %s: %v", p, err)
		}
	}

	entries := []Entry{
		{SrcFS: fsys, SrcPath: "first.txt", DstPath: firstDst, Perm: 0o600},
		{SrcFS: fsys, SrcPath: "second.txt", DstPath: secondDst, Perm: 0o600},
		{SrcFS: fsys, SrcPath: "third.txt", DstPath: thirdDst, Perm: 0o600},
	}

	var out, errOut bytes.Buffer
	res, err := Sync(entries, Options{
		Conflict:      ConflictPrompt,
		In:            strings.NewReader("s\nb\no\n"),
		Out:           &out,
		ErrOut:        &errOut,
		IsInteractive: func() bool { return true },
	})
	if err != nil {
		t.Fatalf("Sync failed: %v", err)
	}

	if res[0].Status != StatusSkipped {
		t.Errorf("first status = %s, want %s", res[0].Status, StatusSkipped)
	}
	if res[1].Status != StatusBackedUp {
		t.Errorf("second status = %s, want %s", res[1].Status, StatusBackedUp)
	}
	if res[2].Status != StatusOverwritten {
		t.Errorf("third status = %s, want %s", res[2].Status, StatusOverwritten)
	}

	gotFirst, _ := os.ReadFile(firstDst)
	if string(gotFirst) != "old\n" {
		t.Errorf("firstDst = %q, want old\\n", gotFirst)
	}
	gotSecondBak, _ := os.ReadFile(secondDst + ".bak")
	if string(gotSecondBak) != "old\n" {
		t.Errorf("secondDst.bak = %q, want old\\n", gotSecondBak)
	}
	gotSecond, _ := os.ReadFile(secondDst)
	if string(gotSecond) != "new-2\n" {
		t.Errorf("secondDst = %q, want new-2\\n", gotSecond)
	}
	gotThird, _ := os.ReadFile(thirdDst)
	if string(gotThird) != "new-3\n" {
		t.Errorf("thirdDst = %q, want new-3\\n", gotThird)
	}
}

func TestSync_StateTrackingAndWarnOverwrite(t *testing.T) {
	dstDir := t.TempDir()
	dstPath := filepath.Join(dstDir, "settings.json")
	if err := os.WriteFile(dstPath, []byte("v1\n"), 0o600); err != nil {
		t.Fatalf("write initial dst: %v", err)
	}

	v1Hash := SHA256Hex([]byte("v1\n"))
	stored := map[string]string{dstPath: v1Hash}

	// Clean source upgrade without local modification: updates silently without warning.
	fsysV2 := fstest.MapFS{
		"settings.json": &fstest.MapFile{Data: []byte("v2\n")},
	}
	var errOut bytes.Buffer
	res, err := Sync(
		[]Entry{{SrcFS: fsysV2, SrcPath: "settings.json", DstPath: dstPath, Perm: 0o600}},
		Options{
			Conflict:  ConflictWarnOverwrite,
			PrevHash:  func(p string) (string, bool) { h, ok := stored[p]; return h, ok },
			OnWritten: func(p, h string) error { stored[p] = h; return nil },
			ErrOut:    &errOut,
		},
	)
	if err != nil {
		t.Fatalf("clean update failed: %v", err)
	}
	if res[0].Status != StatusUpdated || res[0].Warned {
		t.Fatalf("expected silent StatusUpdated, got %+v", res[0])
	}
	if errOut.Len() != 0 {
		t.Fatalf("unexpected warning on clean update: %s", errOut.String())
	}

	// Local modification followed by source v3: warns and overwrites.
	if err := os.WriteFile(dstPath, []byte("local-edit\n"), 0o600); err != nil {
		t.Fatalf("write local edit: %v", err)
	}
	fsysV3 := fstest.MapFS{
		"settings.json": &fstest.MapFile{Data: []byte("v3\n")},
	}
	res, err = Sync(
		[]Entry{{SrcFS: fsysV3, SrcPath: "settings.json", DstPath: dstPath, Perm: 0o600}},
		Options{
			Conflict:  ConflictWarnOverwrite,
			PrevHash:  func(p string) (string, bool) { h, ok := stored[p]; return h, ok },
			OnWritten: func(p, h string) error { stored[p] = h; return nil },
			ErrOut:    &errOut,
		},
	)
	if err != nil {
		t.Fatalf("warn overwrite failed: %v", err)
	}
	if res[0].Status != StatusOverwritten || !res[0].Warned {
		t.Fatalf("expected StatusOverwritten with Warned=true, got %+v", res[0])
	}
	if !strings.Contains(errOut.String(), "warning:") || !strings.Contains(errOut.String(), "-local-edit") {
		t.Fatalf("expected warning with diff, got:\n%s", errOut.String())
	}
	gotDst, _ := os.ReadFile(dstPath)
	if string(gotDst) != "v3\n" {
		t.Fatalf("dst = %q, want v3\\n", gotDst)
	}
}
