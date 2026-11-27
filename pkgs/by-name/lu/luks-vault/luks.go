package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"os/user"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const (
	vaultExt          = ".luks"
	defaultVaultName  = "vault.luks"
	defaultInitSize   = "512M"
	sharedDataDirLive = "/mnt/shared"
	algaeSharedDir    = "/mnt/archive/shared"
)

type vaultState string

const (
	stateLocked   vaultState = "locked"
	stateAttached vaultState = "attached"
	stateUnlocked vaultState = "unlocked"
	stateOpen     vaultState = "open"
)

type vaultInfo struct {
	Path       string
	Name       string
	SizeBytes  int64
	State      vaultState
	LoopDev    string
	MapperDev  string
	Mountpoint string
}

type losetupOutput struct {
	LoopDevices []losetupEntry `json:"loopdevices"`
}

type losetupEntry struct {
	Name     string `json:"name"`
	BackFile string `json:"back-file"`
}

type lsblkOutput struct {
	BlockDevices []lsblkDevice `json:"blockdevices"`
}

type lsblkDevice struct {
	Name        string        `json:"name"`
	Type        string        `json:"type"`
	FSType      string        `json:"fstype"`
	Mountpoint  string        `json:"mountpoint"`
	Mountpoints []string      `json:"mountpoints"`
	Label       string        `json:"label"`
	Size        string        `json:"size"`
	Children    []lsblkDevice `json:"children"`
}

var (
	loopSetupRe       = regexp.MustCompile(`as (/dev/loop\d+)\.?`)
	unlockRe          = regexp.MustCompile(`as (/dev/[^\s.]+)\.?`)
	alreadyUnlockedRe = regexp.MustCompile(`already unlocked as (/dev/[^\s.]+)`)
	mountRe           = regexp.MustCompile(`at (.+?)\.?$`)
	sizeRe            = regexp.MustCompile(`^(\d+)([KMGTP])?I?B?$`)
)

func parseByteSize(raw string) (int64, error) {
	s := strings.ToUpper(strings.TrimSpace(raw))
	m := sizeRe.FindStringSubmatch(s)
	if m == nil {
		return 0, fmt.Errorf("invalid size %q (examples: 256M, 1G)", raw)
	}
	n, err := strconv.ParseInt(m[1], 10, 64)
	if err != nil || n <= 0 {
		return 0, fmt.Errorf("invalid size %q: must be positive", raw)
	}
	var mult int64 = 1
	switch m[2] {
	case "K":
		mult = 1024
	case "M":
		mult = 1024 * 1024
	case "G":
		mult = 1024 * 1024 * 1024
	case "T":
		mult = 1024 * 1024 * 1024 * 1024
	case "P":
		mult = 1024 * 1024 * 1024 * 1024 * 1024
	}
	return n * mult, nil
}

func formatBytes(b int64) string {
	if b <= 0 {
		return "-"
	}
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%dB", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f%ciB", float64(b)/float64(div), "KMGTPE"[exp])
}

func parseLoopSetupOutput(out string) (string, error) {
	m := loopSetupRe.FindStringSubmatch(strings.TrimSpace(out))
	if m == nil {
		return "", fmt.Errorf("could not parse loop device from udisksctl output: %q", strings.TrimSpace(out))
	}
	return m[1], nil
}

func parseUnlockOutput(out string) (string, error) {
	m := unlockRe.FindStringSubmatch(strings.TrimSpace(out))
	if m == nil {
		return "", fmt.Errorf("could not parse unlocked device from udisksctl output: %q", strings.TrimSpace(out))
	}
	return m[1], nil
}

func parseMountOutput(out string) (string, error) {
	line := strings.TrimSpace(out)
	m := mountRe.FindStringSubmatch(line)
	if m == nil {
		return "", fmt.Errorf("could not parse mountpoint from udisksctl output: %q", line)
	}
	return strings.TrimSpace(m[1]), nil
}

func parseLosetupJSON(data []byte) (map[string]string, error) {
	trimmed := bytes.TrimSpace(data)
	result := make(map[string]string)
	if len(trimmed) == 0 {
		return result, nil
	}
	var parsed losetupOutput
	if err := json.Unmarshal(trimmed, &parsed); err != nil {
		return nil, fmt.Errorf("parse losetup json: %w", err)
	}
	for _, entry := range parsed.LoopDevices {
		if entry.Name == "" || entry.BackFile == "" {
			continue
		}
		if strings.HasSuffix(entry.BackFile, " (deleted)") {
			continue
		}
		result[canonicalPath(entry.BackFile)] = entry.Name
	}
	return result, nil
}

type loopBlockStatus struct {
	MapperDev  string
	Mountpoint string
}

func parseLsblkJSON(data []byte) (map[string]loopBlockStatus, error) {
	trimmed := bytes.TrimSpace(data)
	result := make(map[string]loopBlockStatus)
	if len(trimmed) == 0 {
		return result, nil
	}
	var parsed lsblkOutput
	if err := json.Unmarshal(trimmed, &parsed); err != nil {
		return nil, fmt.Errorf("parse lsblk json: %w", err)
	}
	var walk func(devs []lsblkDevice)
	walk = func(devs []lsblkDevice) {
		for _, d := range devs {
			if d.Type == "loop" {
				st := loopBlockStatus{}
				for _, child := range d.Children {
					if child.Type == "crypt" {
						st.MapperDev = child.Name
						st.Mountpoint = firstMountpoint(child)
						break
					}
				}
				result[d.Name] = st
			}
			if len(d.Children) > 0 {
				walk(d.Children)
			}
		}
	}
	walk(parsed.BlockDevices)
	return result, nil
}

func firstMountpoint(d lsblkDevice) string {
	if d.Mountpoint != "" {
		return d.Mountpoint
	}
	for _, mp := range d.Mountpoints {
		if mp != "" {
			return mp
		}
	}
	return ""
}

func canonicalPath(p string) string {
	abs, err := filepath.Abs(p)
	if err != nil {
		return p
	}
	if resolved, err := filepath.EvalSymlinks(abs); err == nil {
		return resolved
	}
	return abs
}

func searchDirs() []string {
	var dirs []string
	if envDir := strings.TrimSpace(os.Getenv("VAULT_DIR")); envDir != "" {
		dirs = append(dirs, envDir)
	}
	dirs = append(dirs, sharedDataDirLive)
	if user := os.Getenv("USER"); user != "" {
		mediaRoot := filepath.Join("/run/media", user)
		if entries, err := os.ReadDir(mediaRoot); err == nil {
			for _, e := range entries {
				if e.IsDir() {
					dirs = append(dirs, filepath.Join(mediaRoot, e.Name()))
				}
			}
		}
	}
	dirs = append(dirs, algaeSharedDir)
	if cwd, err := os.Getwd(); err == nil {
		dirs = append(dirs, cwd)
	}
	return dirs
}

func defaultInitPath() string {
	candidates := []string{sharedDataDirLive}
	if user := os.Getenv("USER"); user != "" {
		candidates = append(candidates, filepath.Join("/run/media", user, "SHARED_DATA"))
	}
	for _, dir := range candidates {
		if isWritableDir(dir) {
			return filepath.Join(dir, defaultVaultName)
		}
	}
	return defaultVaultName
}

func isWritableDir(dir string) bool {
	info, err := os.Stat(dir)
	if err != nil || !info.IsDir() {
		return false
	}
	f, err := os.CreateTemp(dir, ".vault-probe-*")
	if err != nil {
		return false
	}
	name := f.Name()
	_ = f.Close()
	_ = os.Remove(name)
	return true
}

func queryLoopDevices() (map[string]string, error) {
	cmd := exec.Command("losetup", "--json", "--output", "NAME,BACK-FILE")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("losetup failed: %w", err)
	}
	return parseLosetupJSON(out)
}

func queryLsblk() (map[string]loopBlockStatus, error) {
	cmd := exec.Command("lsblk", "--json", "--paths", "--output", "NAME,TYPE,FSTYPE,MOUNTPOINT,MOUNTPOINTS,LABEL,SIZE")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("lsblk failed: %w", err)
	}
	return parseLsblkJSON(out)
}

func inspectVaultPath(path string, loops map[string]string, blocks map[string]loopBlockStatus) vaultInfo {
	canon := canonicalPath(path)
	info := vaultInfo{
		Path:  canon,
		Name:  filepath.Base(canon),
		State: stateLocked,
	}
	if st, err := os.Stat(canon); err == nil {
		info.SizeBytes = st.Size()
	}
	if loopDev, ok := loops[canon]; ok {
		info.LoopDev = loopDev
		info.State = stateAttached
		if blk, ok := blocks[loopDev]; ok && blk.MapperDev != "" {
			info.MapperDev = blk.MapperDev
			info.Mountpoint = blk.Mountpoint
			if blk.Mountpoint != "" {
				info.State = stateOpen
			} else {
				info.State = stateUnlocked
			}
		}
	}
	return info
}

func discoverVaults() ([]vaultInfo, error) {
	loops, err := queryLoopDevices()
	if err != nil {
		loops = map[string]string{}
	}
	blocks, err := queryLsblk()
	if err != nil {
		blocks = map[string]loopBlockStatus{}
	}

	seen := make(map[string]struct{})
	var paths []string
	addPath := func(p string) {
		canon := canonicalPath(p)
		if _, exists := seen[canon]; exists {
			return
		}
		seen[canon] = struct{}{}
		paths = append(paths, canon)
	}

	for _, dir := range searchDirs() {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, e := range entries {
			if e.IsDir() {
				continue
			}
			if strings.HasSuffix(e.Name(), vaultExt) {
				addPath(filepath.Join(dir, e.Name()))
			}
		}
	}

	for backFile := range loops {
		if strings.HasSuffix(backFile, vaultExt) {
			addPath(backFile)
		}
	}

	vaults := make([]vaultInfo, 0, len(paths))
	for _, p := range paths {
		vaults = append(vaults, inspectVaultPath(p, loops, blocks))
	}

	sort.Slice(vaults, func(i, j int) bool {
		if vaults[i].State != vaults[j].State {
			return stateRank(vaults[i].State) < stateRank(vaults[j].State)
		}
		return vaults[i].Path < vaults[j].Path
	})
	return vaults, nil
}

func stateRank(s vaultState) int {
	switch s {
	case stateOpen:
		return 0
	case stateUnlocked:
		return 1
	case stateAttached:
		return 2
	default:
		return 3
	}
}

func runCommandCapture(name string, args []string, interactive bool, stderr io.Writer) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.Env = append(os.Environ(), "LC_ALL=C")
	var stdout bytes.Buffer
	cmd.Stdout = &stdout
	if interactive {
		cmd.Stdin = os.Stdin
		cmd.Stderr = stderr
	} else {
		var errBuf bytes.Buffer
		cmd.Stderr = &errBuf
		if err := cmd.Run(); err != nil {
			msg := strings.TrimSpace(errBuf.String())
			if msg != "" {
				return "", fmt.Errorf("%s %s: %s (%w)", name, strings.Join(args, " "), msg, err)
			}
			return "", fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
		}
		return stdout.String(), nil
	}
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
	}
	return stdout.String(), nil
}

func parseUdisksObjectPath(udisksInfo string) (string, error) {
	for _, line := range strings.Split(udisksInfo, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "/org/freedesktop/UDisks2/") && strings.HasSuffix(trimmed, ":") {
			return strings.TrimSuffix(trimmed, ":"), nil
		}
	}
	return "", fmt.Errorf("could not find UDisks2 object path in udisksctl info output")
}

func restoreTerminalEcho() {
	tty, err := os.OpenFile("/dev/tty", os.O_RDWR, 0)
	if err != nil {
		return
	}
	defer tty.Close()
	cmd := exec.Command("stty", "echo")
	cmd.Stdin = tty
	_ = cmd.Run()
}

func unlockLoopDevice(loopDev string, stderr io.Writer) (string, bool, error) {
	fmt.Fprintf(stderr, "Unlocking %s...\n", loopDev)
	cmd := exec.Command("udisksctl", "unlock", "--block-device", loopDev)
	cmd.Env = append(os.Environ(), "LC_ALL=C")
	cmd.Stdin = os.Stdin
	var outBuf, errBuf bytes.Buffer
	cmd.Stdout = &outBuf
	cmd.Stderr = io.MultiWriter(stderr, &errBuf)
	if err := cmd.Start(); err != nil {
		return "", false, fmt.Errorf("udisksctl unlock --block-device %s: %w", loopDev, err)
	}

	waitCh := make(chan error, 1)
	go func() {
		waitCh <- cmd.Wait()
	}()

	// Poll lsblk while waiting on Passphrase: so if GNOME's dialog unlocks the loop
	// device first, we stop waiting for terminal input and continue immediately.
	ticker := time.NewTicker(250 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case err := <-waitCh:
			if err == nil {
				dm, parseErr := parseUnlockOutput(outBuf.String())
				return dm, true, parseErr
			}
			if m := alreadyUnlockedRe.FindStringSubmatch(errBuf.String()); m != nil {
				return m[1], false, nil
			}
			return "", false, fmt.Errorf("udisksctl unlock --block-device %s: %w", loopDev, err)
		case <-ticker.C:
			blocks, err := queryLsblk()
			if err != nil {
				continue
			}
			if blk, ok := blocks[loopDev]; ok && blk.MapperDev != "" {
				_ = cmd.Process.Signal(syscall.SIGTERM)
				select {
				case <-waitCh:
				case <-time.After(500 * time.Millisecond):
					_ = cmd.Process.Kill()
					<-waitCh
				}
				restoreTerminalEcho()
				fmt.Fprintln(stderr)
				return blk.MapperDev, false, nil
			}
		}
	}
}

func lookupUsersGID() (int, bool) {
	grp, err := user.LookupGroup("users")
	if err != nil {
		return 0, false
	}
	gid, err := strconv.Atoi(grp.Gid)
	if err != nil {
		return 0, false
	}
	return gid, true
}

func formatBlockDeviceExt4(mapperDev, label string, stderr io.Writer) error {
	infoOut, err := runCommandCapture("udisksctl", []string{"info", "--block-device", mapperDev}, false, stderr)
	if err != nil {
		return err
	}
	objPath, err := parseUdisksObjectPath(infoOut)
	if err != nil {
		return err
	}
	// Format via UDisks2 D-Bus Block.Format so no sudo is required on desktop or Live ISO.
	_, err = runCommandCapture("busctl", []string{
		"call",
		"org.freedesktop.UDisks2",
		objPath,
		"org.freedesktop.UDisks2.Block",
		"Format",
		"sa{sv}",
		"ext4",
		"2",
		"label", "s", label,
		"take-ownership", "b", "true",
	}, false, stderr)
	if err != nil {
		return fmt.Errorf("udisks2 Block.Format failed: %w", err)
	}
	return nil
}

func isLuksFile(path string) bool {
	return exec.Command("cryptsetup", "isLuks", path).Run() == nil
}

func hasEncryptedInterface(udisksInfo string) bool {
	return strings.Contains(udisksInfo, "org.freedesktop.UDisks2.Encrypted:")
}

// Wait for udev/blkid to attach the UDisks2.Encrypted interface to a freshly mapped loop device.
func waitForEncryptedDevice(loopDev string, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for {
		out, err := runCommandCapture("udisksctl", []string{"info", "--block-device", loopDev}, false, io.Discard)
		if err == nil && hasEncryptedInterface(out) {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("%s did not appear as an encrypted LUKS device in udisks2 within %s", loopDev, timeout)
		}
		time.Sleep(100 * time.Millisecond)
	}
}

func openVault(path string, stdout, stderr io.Writer) (string, error) {
	canon := canonicalPath(path)
	if _, err := os.Stat(canon); err != nil {
		return "", fmt.Errorf("vault file not found: %w", err)
	}
	if !isLuksFile(canon) {
		return "", fmt.Errorf("%s is not a valid LUKS container (remove it and run 'vault init' if left from an aborted init)", canon)
	}

	loops, _ := queryLoopDevices()
	blocks, _ := queryLsblk()
	info := inspectVaultPath(canon, loops, blocks)

	if info.State == stateOpen {
		fmt.Fprintf(stdout, "Already open: %s\n", info.Mountpoint)
		return info.Mountpoint, nil
	}

	createdLoop := false
	loopDev := info.LoopDev
	if loopDev == "" {
		out, err := runCommandCapture("udisksctl", []string{"loop-setup", "--file", canon}, false, stderr)
		if err != nil {
			return "", err
		}
		loopDev, err = parseLoopSetupOutput(out)
		if err != nil {
			return "", err
		}
		createdLoop = true
		if err := waitForEncryptedDevice(loopDev, 5*time.Second); err != nil {
			_, _ = runCommandCapture("udisksctl", []string{"loop-delete", "--block-device", loopDev}, false, io.Discard)
			return "", err
		}
	}

	unlockedHere := false
	mapperDev := info.MapperDev
	if mapperDev == "" {
		dm, didUnlock, err := unlockLoopDevice(loopDev, stderr)
		if err != nil {
			if createdLoop {
				_, _ = runCommandCapture("udisksctl", []string{"loop-delete", "--block-device", loopDev}, false, io.Discard)
			}
			return "", err
		}
		mapperDev = dm
		unlockedHere = didUnlock
	}

	fmt.Fprintf(stderr, "Mounting %s...\n", filepath.Base(canon))
	out, err := runCommandCapture("udisksctl", []string{"mount", "--block-device", mapperDev}, false, stderr)
	if err != nil {
		if unlockedHere {
			_, _ = runCommandCapture("udisksctl", []string{"lock", "--block-device", loopDev}, false, io.Discard)
		}
		if createdLoop {
			_, _ = runCommandCapture("udisksctl", []string{"loop-delete", "--block-device", loopDev}, false, io.Discard)
		}
		return "", err
	}
	mountpoint, err := parseMountOutput(out)
	if err != nil {
		return "", err
	}
	fmt.Fprintf(stdout, "Opened %s -> %s\n", filepath.Base(canon), mountpoint)
	return mountpoint, nil
}

func closeVault(path string, stdout, stderr io.Writer) error {
	canon := canonicalPath(path)
	loops, err := queryLoopDevices()
	if err != nil {
		return err
	}
	blocks, err := queryLsblk()
	if err != nil {
		return err
	}
	info := inspectVaultPath(canon, loops, blocks)
	if info.State == stateLocked {
		fmt.Fprintf(stdout, "Already closed: %s\n", filepath.Base(canon))
		return nil
	}

	fmt.Fprintf(stderr, "Closing %s...\n", filepath.Base(canon))
	if info.Mountpoint != "" && info.MapperDev != "" {
		if _, err := runCommandCapture("udisksctl", []string{"unmount", "--block-device", info.MapperDev}, false, stderr); err != nil {
			return err
		}
	}
	if info.MapperDev != "" && info.LoopDev != "" {
		if _, err := runCommandCapture("udisksctl", []string{"lock", "--block-device", info.LoopDev}, false, stderr); err != nil {
			return err
		}
	}
	if info.LoopDev != "" {
		// udisks2 sets autoclear on loop devices, so locking can detach the loop automatically.
		if currentLoops, err := queryLoopDevices(); err == nil {
			stillAttached := false
			for _, dev := range currentLoops {
				if dev == info.LoopDev {
					stillAttached = true
					break
				}
			}
			if !stillAttached {
				fmt.Fprintf(stdout, "Closed %s\n", filepath.Base(canon))
				return nil
			}
		}
		if _, err := runCommandCapture("udisksctl", []string{"loop-delete", "--block-device", info.LoopDev}, false, stderr); err != nil {
			return err
		}
	}
	fmt.Fprintf(stdout, "Closed %s\n", filepath.Base(canon))
	return nil
}

func sanitizeExt4Label(name string) string {
	stem := strings.TrimSuffix(filepath.Base(name), filepath.Ext(name))
	if stem == "" {
		return "vault"
	}
	// ext4 volume labels are limited to 16 bytes.
	if len(stem) > 16 {
		return stem[:16]
	}
	return stem
}

func luksFormatArgs(path string) []string {
	// initVault creates the file with O_CREATE|O_EXCL, so cryptsetup's overwrite
	// confirmation prompt is misleading; skip it with --batch-mode while keeping
	// --verify-passphrase so the user still enters the passphrase twice.
	return []string{"luksFormat", "--type", "luks2", "--batch-mode", "--verify-passphrase", path}
}

func initVault(path, sizeRaw, label string, stdout, stderr io.Writer) error {
	sizeBytes, err := parseByteSize(sizeRaw)
	if err != nil {
		return err
	}
	if sizeBytes < 32*1024*1024 {
		return errors.New("size must be at least 32M for LUKS2 header + ext4")
	}
	absPath, err := filepath.Abs(path)
	if err != nil {
		return err
	}
	if _, err := os.Stat(absPath); err == nil {
		return fmt.Errorf("file already exists: %s", absPath)
	}
	if err := os.MkdirAll(filepath.Dir(absPath), 0o755); err != nil {
		return err
	}
	if label == "" {
		label = sanitizeExt4Label(absPath)
	}

	fmt.Fprintf(stderr, "Allocating %s container (may take a few seconds on USB)...\n", formatBytes(sizeBytes))
	f, err := os.OpenFile(absPath, os.O_CREATE|os.O_EXCL|os.O_RDWR, 0o600)
	if err != nil {
		return fmt.Errorf("create vault file: %w", err)
	}
	if err := f.Truncate(sizeBytes); err != nil {
		_ = f.Close()
		_ = os.Remove(absPath)
		return fmt.Errorf("allocate vault file: %w", err)
	}
	if err := f.Close(); err != nil {
		_ = os.Remove(absPath)
		return err
	}

	cleanupFile := true
	defer func() {
		if cleanupFile {
			_ = os.Remove(absPath)
		}
	}()

	// Trap SIGINT/SIGTERM so Ctrl-C during setup runs deferred cleanup
	// instead of leaving behind an empty unformatted file.
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(sigCh)

	fmt.Fprintf(stderr, "Formatting LUKS2 container (%s, may take a few seconds after passphrase)...\n", absPath)
	formatCmd := exec.Command("cryptsetup", luksFormatArgs(absPath)...)
	formatCmd.Stdin = os.Stdin
	formatCmd.Stdout = stderr
	formatCmd.Stderr = stderr
	if err := formatCmd.Run(); err != nil {
		return fmt.Errorf("cryptsetup luksFormat failed: %w", err)
	}

	loopOut, err := runCommandCapture("udisksctl", []string{"loop-setup", "--file", absPath}, false, stderr)
	if err != nil {
		return err
	}
	loopDev, err := parseLoopSetupOutput(loopOut)
	if err != nil {
		return err
	}
	defer func() {
		_, _ = runCommandCapture("udisksctl", []string{"loop-delete", "--block-device", loopDev}, false, io.Discard)
	}()

	if err := waitForEncryptedDevice(loopDev, 5*time.Second); err != nil {
		return err
	}

	mapperDev, _, err := unlockLoopDevice(loopDev, stderr)
	if err != nil {
		return err
	}
	defer func() {
		_, _ = runCommandCapture("udisksctl", []string{"lock", "--block-device", loopDev}, false, io.Discard)
	}()

	fmt.Fprintf(stderr, "Formatting ext4 filesystem inside %s (may take a few seconds)...\n", filepath.Base(absPath))
	if err := formatBlockDeviceExt4(mapperDev, label, stderr); err != nil {
		return err
	}

	// Mount once to set the local `users` group + setgid when available so different
	// Linux accounts in `users` (e.g. Live ISO and desktop host) can share write access.
	if mountOut, err := runCommandCapture("udisksctl", []string{"mount", "--block-device", mapperDev}, false, stderr); err == nil {
		if mp, err := parseMountOutput(mountOut); err == nil {
			if gid, ok := lookupUsersGID(); ok {
				if os.Chown(mp, -1, gid) == nil {
					_ = os.Chmod(mp, 0o775|os.ModeSetgid)
				}
			}
		}
		_, _ = runCommandCapture("udisksctl", []string{"unmount", "--block-device", mapperDev}, false, io.Discard)
	}

	cleanupFile = false
	fmt.Fprintf(stdout, "Created vault: %s (%s, label=%s)\n", absPath, formatBytes(sizeBytes), label)
	return nil
}

func luksSummary(path string) string {
	cmd := exec.Command("cryptsetup", "luksDump", path)
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	var lines []string
	for _, line := range strings.Split(string(out), "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "Version:") ||
			strings.HasPrefix(trimmed, "UUID:") ||
			strings.HasPrefix(trimmed, "Cipher:") ||
			strings.HasPrefix(trimmed, "PBKDF:") ||
			strings.HasPrefix(trimmed, "Keyslots:") ||
			strings.HasPrefix(trimmed, "Tokens:") ||
			strings.Contains(trimmed, ": luks2") ||
			strings.Contains(trimmed, ": systemd-") {
			lines = append(lines, line)
		}
	}
	return strings.Join(lines, "\n")
}
