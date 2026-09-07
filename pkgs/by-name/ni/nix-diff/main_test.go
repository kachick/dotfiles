package main

import (
	"errors"
	"strings"
	"testing"
)

func TestFormatReport(t *testing.T) {
	tests := []struct {
		name       string
		dixOut     string
		nixDiffOut string
		dixErr     error
		nixDiffErr error
		wantSub    []string
	}{
		{
			name:       "both have output",
			dixOut:     "CHANGED\n[U.] foo 1.0 -> 1.1\n",
			nixDiffOut: "• foo differs\n",
			dixErr:     nil,
			nixDiffErr: nil,
			wantSub: []string{
				"### Package Version Changes (dix)",
				"[U.] foo 1.0 -> 1.1",
				"<details><summary>Detailed Derivation Diff (nix-diff)</summary>",
				"• foo differs",
			},
		},
		{
			name:       "dix empty but nix-diff has changes",
			dixOut:     "",
			nixDiffOut: "• typescript-go differs\n",
			dixErr:     nil,
			nixDiffErr: nil,
			wantSub: []string{
				"### Package Version Changes (dix)",
				"No version changes detected.",
				"<details><summary>Detailed Derivation Diff (nix-diff)</summary>",
				"• typescript-go differs",
			},
		},
		{
			name:       "dix error but nix-diff succeeds",
			dixOut:     "",
			nixDiffOut: "• bar differs\n",
			dixErr:     errors.New("dix: broken drv"),
			nixDiffErr: nil,
			wantSub: []string{
				"### Package Version Changes (dix)",
				"dix: broken drv",
				"<details><summary>Detailed Derivation Diff (nix-diff)</summary>",
				"• bar differs",
			},
		},
		{
			name:       "both empty",
			dixOut:     "",
			nixDiffOut: "",
			dixErr:     nil,
			nixDiffErr: nil,
			wantSub: []string{
				"### Package Version Changes (dix)",
				"No version changes detected.",
				"<details><summary>Detailed Derivation Diff (nix-diff)</summary>",
				"No derivation changes detected.",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := formatReport(tt.dixOut, tt.nixDiffOut, tt.dixErr, tt.nixDiffErr)
			for _, sub := range tt.wantSub {
				if !strings.Contains(got, sub) {
					t.Errorf("formatReport() missing expected substring %q in:\n%s", sub, got)
				}
			}
		})
	}
}
