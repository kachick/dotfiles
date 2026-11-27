package main

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseByteSize(t *testing.T) {
	tests := []struct {
		in      string
		want    int64
		wantErr bool
	}{
		{"512M", 512 * 1024 * 1024, false},
		{"1G", 1024 * 1024 * 1024, false},
		{"256MiB", 256 * 1024 * 1024, false},
		{"1024K", 1024 * 1024, false},
		{"0M", 0, true},
		{"-10M", 0, true},
		{"abc", 0, true},
	}
	for _, tc := range tests {
		got, err := parseByteSize(tc.in)
		if tc.wantErr {
			if err == nil {
				t.Errorf("parseByteSize(%q): expected error, got %d", tc.in, got)
			}
			continue
		}
		if err != nil {
			t.Errorf("parseByteSize(%q): unexpected error: %v", tc.in, err)
			continue
		}
		if got != tc.want {
			t.Errorf("parseByteSize(%q) = %d, want %d", tc.in, got, tc.want)
		}
	}
}

func TestParseUdisksctlOutputs(t *testing.T) {
	loop, err := parseLoopSetupOutput("Mapped file /mnt/shared/vault.luks as /dev/loop3.\n")
	if err != nil || loop != "/dev/loop3" {
		t.Fatalf("parseLoopSetupOutput got (%q, %v), want (/dev/loop3, nil)", loop, err)
	}

	dm, err := parseUnlockOutput("Unlocked /dev/loop3 as /dev/dm-4.\n")
	if err != nil || dm != "/dev/dm-4" {
		t.Fatalf("parseUnlockOutput got (%q, %v), want (/dev/dm-4, nil)", dm, err)
	}

	mp, err := parseMountOutput("Mounted /dev/dm-4 at /run/media/owner/vault.\n")
	if err != nil || mp != "/run/media/owner/vault" {
		t.Fatalf("parseMountOutput got (%q, %v), want (/run/media/owner/vault, nil)", mp, err)
	}
}

func TestParseLosetupAndLsblkJSON(t *testing.T) {
	tmp := t.TempDir()
	vaultFile := filepath.Join(tmp, "vault.luks")
	if err := os.WriteFile(vaultFile, []byte("test"), 0o600); err != nil {
		t.Fatal(err)
	}

	losetupRaw := `{"loopdevices":[{"name":"/dev/loop0","back-file":"` + vaultFile + `"},{"name":"/dev/loop1","back-file":"/tmp/gone.luks (deleted)"}]}`
	loops, err := parseLosetupJSON([]byte(losetupRaw))
	if err != nil {
		t.Fatalf("parseLosetupJSON error: %v", err)
	}
	if len(loops) != 1 {
		t.Fatalf("expected deleted loop backing file to be skipped, got %v", loops)
	}
	if got := loops[canonicalPath(vaultFile)]; got != "/dev/loop0" {
		t.Fatalf("loops[%s] = %q, want /dev/loop0", vaultFile, got)
	}

	lsblkRaw := `{
		"blockdevices": [
			{
				"name": "/dev/loop0",
				"type": "loop",
				"children": [
					{
						"name": "/dev/mapper/luks-1234",
						"type": "crypt",
						"mountpoints": ["/run/media/owner/vault"]
					}
				]
			}
		]
	}`
	blocks, err := parseLsblkJSON([]byte(lsblkRaw))
	if err != nil {
		t.Fatalf("parseLsblkJSON error: %v", err)
	}
	info := inspectVaultPath(vaultFile, loops, blocks)
	if info.State != stateOpen {
		t.Fatalf("state = %q, want %q", info.State, stateOpen)
	}
	if info.Mountpoint != "/run/media/owner/vault" {
		t.Fatalf("mountpoint = %q, want /run/media/owner/vault", info.Mountpoint)
	}
}

func TestSanitizeExt4Label(t *testing.T) {
	if got := sanitizeExt4Label("/mnt/shared/vault.luks"); got != "vault" {
		t.Fatalf("got %q, want vault", got)
	}
	if got := sanitizeExt4Label("/mnt/shared/a-very-long-vault-label-name.luks"); len(got) != 16 {
		t.Fatalf("expected 16-char label, got %q (len %d)", got, len(got))
	}
}

func TestLuksFormatArgs(t *testing.T) {
	got := strings.Join(luksFormatArgs("/mnt/shared/vault.luks"), " ")
	want := "luksFormat --type luks2 --batch-mode --verify-passphrase /mnt/shared/vault.luks"
	if got != want {
		t.Fatalf("luksFormatArgs = %q, want %q", got, want)
	}
}

func TestHasEncryptedInterface(t *testing.T) {
	withEnc := "/org/freedesktop/UDisks2/block_devices/loop0:\n  org.freedesktop.UDisks2.Encrypted:\n"
	if !hasEncryptedInterface(withEnc) {
		t.Fatalf("expected encrypted interface to be detected")
	}
	withoutEnc := "/org/freedesktop/UDisks2/block_devices/loop0:\n  org.freedesktop.UDisks2.Block:\n"
	if hasEncryptedInterface(withoutEnc) {
		t.Fatalf("expected encrypted interface not to be detected")
	}
}

func TestParseUdisksObjectPath(t *testing.T) {
	info := "/org/freedesktop/UDisks2/block_devices/dm_2d2:\n  org.freedesktop.UDisks2.Block:\n"
	got, err := parseUdisksObjectPath(info)
	if err != nil || got != "/org/freedesktop/UDisks2/block_devices/dm_2d2" {
		t.Fatalf("parseUdisksObjectPath got (%q, %v)", got, err)
	}
}

func TestMenuLoopOpenAndQuit(t *testing.T) {
	opened := ""
	calls := 0
	ui := menuUI{
		listVaults: func() ([]vaultInfo, error) {
			return []vaultInfo{
				{
					Path:      "/mnt/shared/vault.luks",
					Name:      "vault.luks",
					SizeBytes: 512 * 1024 * 1024,
					State:     stateLocked,
				},
			}, nil
		},
		selectItem: func(_ []string, _ io.Reader, _ io.Writer) (menuChoice, error) {
			calls++
			if calls == 1 {
				return menuChoice{Path: "/mnt/shared/vault.luks"}, nil
			}
			return menuChoice{}, errMenuCanceled
		},
		openVault: func(path string, stdout, _ io.Writer) (string, error) {
			opened = path
			_, _ = io.WriteString(stdout, "opened\n")
			return "/run/media/owner/vault", nil
		},
	}

	var stdout, stderr bytes.Buffer
	if err := runMenuLoop("/bin/vault", ui, &stdout, &stderr); err != nil {
		t.Fatalf("runMenuLoop failed: %v", err)
	}
	if opened != "/mnt/shared/vault.luks" {
		t.Fatalf("opened = %q, want /mnt/shared/vault.luks", opened)
	}
}

func TestRunHelp(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if err := run([]string{"--help"}, &stdout, &stderr); err != nil {
		t.Fatalf("run --help failed: %v", err)
	}
	if !strings.Contains(stdout.String(), "vault init") {
		t.Fatalf("help output missing expected usage: %s", stdout.String())
	}
}
