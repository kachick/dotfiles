package main

import (
	"testing"
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
		"nested/owner/repo": {
			input: "gitlab.com/group/subgroup/repo",
			repo:  "repo",
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
			if got := extractRepo(tc.input); got != tc.repo {
				t.Errorf("extractRepo(%q) = %q, want %q", tc.input, got, tc.repo)
			}
		})
	}
}
