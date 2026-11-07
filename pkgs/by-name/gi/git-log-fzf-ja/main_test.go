package main

import (
	"slices"
	"testing"
)

func TestCleanRev(t *testing.T) {
	tests := []struct {
		name string
		raw  string
		want string
	}{
		{
			name: "empty input",
			raw:  "",
			want: "",
		},
		{
			name: "git-log-simple full line",
			raw:  "2026-11-07 c38fc2ba Migrate git-log-fzf-ja to Go  (HEAD -> main)",
			want: "c38fc2ba",
		},
		{
			name: "single field token from fzf {2}",
			raw:  "c38fc2ba",
			want: "c38fc2ba",
		},
		{
			name: "single token with ansi escapes from fzf {2}",
			raw:  "\x1b[33mc38fc2ba\x1b[0m",
			want: "c38fc2ba",
		},
		{
			name: "full line with ansi escapes",
			raw:  "\x1b[36m2026-11-07\x1b[0m \x1b[33mc38fc2ba\x1b[0m \x1b[32mMigrate git-log-fzf-ja\x1b[0m",
			want: "c38fc2ba",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := cleanRev(tt.raw)
			if got != tt.want {
				t.Errorf("cleanRev(%q) = %q, want %q", tt.raw, got, tt.want)
			}
		})
	}
}

func TestNeighborRevs(t *testing.T) {
	commits := []string{"c0", "c1", "c2", "c3", "c4"}
	idxMap := map[string]int{
		"c0": 0,
		"c1": 1,
		"c2": 2,
		"c3": 3,
		"c4": 4,
	}

	tests := []struct {
		name string
		rev  string
		want []string
	}{
		{
			name: "first commit in log",
			rev:  "c0",
			want: []string{"c1", "c2"},
		},
		{
			name: "middle commit in log",
			rev:  "c2",
			want: []string{"c3", "c1", "c4"},
		},
		{
			name: "last commit in log",
			rev:  "c4",
			want: []string{"c3"},
		},
		{
			name: "unknown commit",
			rev:  "unknown",
			want: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := neighborRevs(commits, idxMap, tt.rev)
			if !slices.Equal(got, tt.want) {
				t.Errorf("neighborRevs(%q) = %v, want %v", tt.rev, got, tt.want)
			}
		})
	}
}
