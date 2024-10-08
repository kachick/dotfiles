package main

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestExtractRepo(t *testing.T) {
	type testCase struct {
		input string
		repo  string
	}

	testCases := map[string]testCase{
		"owner/repo": {
			input: "kachick/dotfiles",
			repo:  "dotfiles",
		},
		"repo": {
			input: "dotfiles",
			repo:  "dotfiles",
		},
		"SSH": {
			input: "git@github.com:kachick/dotfiles.git",
			repo:  "dotfiles",
		},
		"HTTPS": {
			input: "https://github.com/kachick/dotfiles.git",
			repo:  "dotfiles",
		},
		"Non Git URL": {
			input: "https://github.com/kachick/dotfiles",
			repo:  "dotfiles",
		},
	}

	for description, tc := range testCases {
		t.Run(description, func(t *testing.T) {
			if diff := cmp.Diff(tc.repo, extractRepo(tc.input)); diff != "" {
				t.Errorf("wrong result: %s", diff)
			}
		})
	}
}
