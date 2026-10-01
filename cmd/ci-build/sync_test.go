package main

import (
	"testing"
)

func TestReplaceMarkedBlock(t *testing.T) {
	orig := `
prefix:
  steps:
    # BEGIN MANAGED PACKAGES
    - old-step-1
    - old-step-2
    # END MANAGED PACKAGES
suffix: value
`

	newBlock := "    - new-step-1\n    - new-step-2"
	expected := `
prefix:
  steps:
    # BEGIN MANAGED PACKAGES
    - new-step-1
    - new-step-2
    # END MANAGED PACKAGES
suffix: value
`

	got, err := replaceMarkedBlock(orig, newBlock)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if got != expected {
		t.Errorf("expected:\n%s\ngot:\n%s", expected, got)
	}
}

func TestReplaceMarkedBlockErrors(t *testing.T) {
	tests := []struct {
		name    string
		content string
	}{
		{
			name:    "missing begin marker",
			content: "foo\n# END MANAGED PACKAGES\nbar",
		},
		{
			name:    "missing end marker",
			content: "foo\n# BEGIN MANAGED PACKAGES\nbar",
		},
		{
			name:    "reversed markers",
			content: "foo\n# END MANAGED PACKAGES\n# BEGIN MANAGED PACKAGES\nbar",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := replaceMarkedBlock(tt.content, "dummy")
			if err == nil {
				t.Errorf("expected error for %s, but got nil", tt.name)
			}
		})
	}
}
