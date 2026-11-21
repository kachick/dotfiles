package main

import (
	"bytes"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestParseMountinfo(t *testing.T) {
	sample := strings.Join([]string{
		"22 1 8:1 / / rw,relatime shared:1 - ext4 /dev/sda1 rw",
		"25 22 0:23 / /tmp rw,nosuid,nodev - tmpfs tmpfs rw",
		"104 22 0:45 / /home/user/.local/share/mnt/rclone/gdrive rw,nosuid,nodev,relatime shared:60 - fuse.rclone gdrive: rw,user_id=1000,group_id=1000",
		`105 22 0:46 / /home/user/My\040Drive\011Vault rw,relatime - rclone gdrive:my\040vault rw`,
		`106 22 0:47 / /home/user/back\\slash\134dir rw,relatime - fuse.rclone work: rw`,
	}, "\n")

	got, err := parseMountinfo(strings.NewReader(sample))
	if err != nil {
		t.Fatalf("parseMountinfo failed: %v", err)
	}

	want := []MountEntry{
		{
			Remote:     "gdrive:",
			MountPoint: "/home/user/.local/share/mnt/rclone/gdrive",
		},
		{
			Remote:     "gdrive:my vault",
			MountPoint: "/home/user/My Drive\tVault",
		},
		{
			Remote:     "work:",
			MountPoint: `/home/user/back\\slash\dir`,
		},
	}

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("parseMountinfo mismatch:\ngot:  %#v\nwant: %#v", got, want)
	}
}

func TestIsMountPoint(t *testing.T) {
	sample := strings.Join([]string{
		"22 1 8:1 / / rw,relatime shared:1 - ext4 /dev/sda1 rw",
		"104 22 0:45 / /home/user/.local/share/mnt/rclone/gdrive rw,relatime - fuse.rclone gdrive: rw",
		`105 22 0:46 / /home/user/My\040Mount rw,relatime - tmpfs tmpfs rw`,
	}, "\n")

	tests := []struct {
		name   string
		target string
		want   bool
	}{
		{
			name:   "exact rclone mount",
			target: "/home/user/.local/share/mnt/rclone/gdrive",
			want:   true,
		},
		{
			name:   "trailing slash cleaned",
			target: "/home/user/.local/share/mnt/rclone/gdrive/",
			want:   true,
		},
		{
			name:   "escaped space mount regardless of fsType",
			target: "/home/user/My Mount",
			want:   true,
		},
		{
			name:   "unmounted parent directory",
			target: "/home/user/.local/share/mnt/rclone",
			want:   false,
		},
		{
			name:   "unmounted child directory",
			target: "/home/user/.local/share/mnt/rclone/gdrive/sub",
			want:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := isMountPoint(strings.NewReader(sample), tt.target)
			if err != nil {
				t.Fatalf("isMountPoint failed: %v", err)
			}
			if got != tt.want {
				t.Fatalf("isMountPoint(%q) = %v, want %v", tt.target, got, tt.want)
			}
		})
	}
}

func TestResolveMountPath(t *testing.T) {
	t.Run("uses XDG_DATA_HOME and strips trailing colon", func(t *testing.T) {
		t.Setenv("XDG_DATA_HOME", "/custom/data")
		got, err := resolveMountPath("gdrive:")
		if err != nil {
			t.Fatalf("resolveMountPath failed: %v", err)
		}
		want := filepath.Join("/custom/data", "mnt", "rclone", "gdrive")
		if got != want {
			t.Fatalf("got %q, want %q", got, want)
		}
	})

	t.Run("falls back to HOME/.local/share when XDG_DATA_HOME is empty", func(t *testing.T) {
		t.Setenv("XDG_DATA_HOME", "")
		t.Setenv("HOME", "/home/alice")
		got, err := resolveMountPath("vault")
		if err != nil {
			t.Fatalf("resolveMountPath failed: %v", err)
		}
		want := filepath.Join("/home/alice", ".local", "share", "mnt", "rclone", "vault")
		if got != want {
			t.Fatalf("got %q, want %q", got, want)
		}
	})

	t.Run("rejects empty remote name", func(t *testing.T) {
		t.Setenv("XDG_DATA_HOME", "/custom/data")
		if _, err := resolveMountPath(":"); err == nil {
			t.Fatal("expected error for empty remote name")
		}
	})
}

func TestFormatMountEntries(t *testing.T) {
	var empty bytes.Buffer
	if err := formatMountEntries(nil, &empty); err != nil {
		t.Fatalf("formatMountEntries(nil) failed: %v", err)
	}
	if empty.Len() != 0 {
		t.Fatalf("expected empty output for no mounts, got %q", empty.String())
	}

	var buf bytes.Buffer
	entries := []MountEntry{
		{Remote: "foo:", MountPoint: "/home/user/.local/share/mnt/rclone/foo"},
	}
	if err := formatMountEntries(entries, &buf); err != nil {
		t.Fatalf("formatMountEntries failed: %v", err)
	}
	want := "REMOTE  LOCAL\nfoo:    /home/user/.local/share/mnt/rclone/foo\n"
	if buf.String() != want {
		t.Fatalf("formatMountEntries mismatch:\ngot:\n%s\nwant:\n%s", buf.String(), want)
	}
}
