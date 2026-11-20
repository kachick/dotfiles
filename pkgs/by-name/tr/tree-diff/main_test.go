package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRenderNormalizedTree(t *testing.T) {
	root := t.TempDir()

	if err := os.MkdirAll(filepath.Join(root, "sub", "nested"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "a.txt"), []byte("a"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, ".hidden"), []byte("h"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "sub", "b.txt"), []byte("b"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "sub", "nested", "c.txt"), []byte("c"), 0o644); err != nil {
		t.Fatal(err)
	}
	// Symlink to a directory must not recurse.
	if err := os.Symlink(filepath.Join(root, "sub"), filepath.Join(root, "link_to_sub")); err != nil {
		t.Fatal(err)
	}

	got, err := renderNormalizedTree(root, false)
	if err != nil {
		t.Fatalf("renderNormalizedTree failed: %v", err)
	}

	want := strings.Join([]string{
		".",
		"├── a.txt",
		"├── link_to_sub -> " + filepath.Join(root, "sub"),
		"├── sub/",
		"│   ├── b.txt",
		"│   ├── nested/",
		"│   │   ├── c.txt",
		"",
	}, "\n")

	if got != want {
		t.Fatalf("rendered tree mismatch:\ngot:\n%s\nwant:\n%s", got, want)
	}
	if strings.Contains(got, "└── ") {
		t.Fatalf("output must never contain corner connector '└── ':\n%s", got)
	}
}

func TestRenderNormalizedTree_HiddenFlag(t *testing.T) {
	root := t.TempDir()

	if err := os.WriteFile(filepath.Join(root, ".gitignore"), []byte("dist/\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, ".hidden_dir"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, ".hidden_dir", "secret.txt"), []byte("s"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "visible.txt"), []byte("v"), 0o644); err != nil {
		t.Fatal(err)
	}

	withoutHidden, err := renderNormalizedTree(root, false)
	if err != nil {
		t.Fatalf("renderNormalizedTree(false) failed: %v", err)
	}
	if strings.Contains(withoutHidden, ".gitignore") || strings.Contains(withoutHidden, ".hidden_dir") {
		t.Fatalf("expected hidden entries to be excluded by default:\n%s", withoutHidden)
	}

	withHidden, err := renderNormalizedTree(root, true)
	if err != nil {
		t.Fatalf("renderNormalizedTree(true) failed: %v", err)
	}
	want := strings.Join([]string{
		".",
		"├── .gitignore",
		"├── .hidden_dir/",
		"│   ├── secret.txt",
		"├── visible.txt",
		"",
	}, "\n")
	if withHidden != want {
		t.Fatalf("rendered tree with hidden entries mismatch:\ngot:\n%s\nwant:\n%s", withHidden, want)
	}
}

func TestRunTreeDiff(t *testing.T) {
	dirA := t.TempDir()
	dirB := t.TempDir()

	for _, d := range []string{dirA, dirB} {
		if err := os.MkdirAll(filepath.Join(d, "sub"), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(d, "a.txt"), []byte("a"), 0o644); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(d, "sub", "item.txt"), []byte("i"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	t.Run("identical directories", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		code := run([]string{dirA, dirB}, nil, &stdout, &stderr)
		if code != 0 {
			t.Fatalf("exit code = %d, want 0; stderr: %s", code, stderr.String())
		}
		if stdout.Len() != 0 {
			t.Fatalf("expected empty diff output, got:\n%s", stdout.String())
		}
	})

	t.Run("added file at end keeps previous lines intact", func(t *testing.T) {
		if err := os.WriteFile(filepath.Join(dirB, "z.txt"), []byte("z"), 0o644); err != nil {
			t.Fatal(err)
		}

		var stdout, stderr bytes.Buffer
		code := run([]string{dirA, dirB}, nil, &stdout, &stderr)
		if code != 1 {
			t.Fatalf("exit code = %d, want 1; stderr: %s", code, stderr.String())
		}

		diffOut := stdout.String()
		if !strings.Contains(diffOut, "+├── z.txt") {
			t.Fatalf("expected diff to contain '+├── z.txt', got:\n%s", diffOut)
		}
		if strings.Contains(diffOut, "-├── ") {
			t.Fatalf("expected no removed sibling lines when adding z.txt, got:\n%s", diffOut)
		}
	})

	t.Run("hidden flag includes dotfile diff", func(t *testing.T) {
		if err := os.WriteFile(filepath.Join(dirB, ".env"), []byte("K=V"), 0o644); err != nil {
			t.Fatal(err)
		}

		var stdout, stderr bytes.Buffer
		code := run([]string{"--all", dirA, dirB}, nil, &stdout, &stderr)
		if code != 1 {
			t.Fatalf("exit code = %d, want 1; stderr: %s", code, stderr.String())
		}
		if !strings.Contains(stdout.String(), "+├── .env") {
			t.Fatalf("expected diff to contain '+├── .env', got:\n%s", stdout.String())
		}
	})

	t.Run("invalid arguments exit 2", func(t *testing.T) {
		filePath := filepath.Join(dirA, "a.txt")
		cases := [][]string{
			{},
			{dirA},
			{dirA, filePath},
			{dirA, filepath.Join(dirA, "missing")},
		}
		for _, args := range cases {
			var stdout, stderr bytes.Buffer
			code := run(args, nil, &stdout, &stderr)
			if code != 2 {
				t.Errorf("run(%v) exit code = %d, want 2", args, code)
			}
		}
	})
}
