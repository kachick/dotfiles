# Plan 02: Replace `rclone-*` Shell and Nushell Scripts with Go

## Goal

Replace the Nushell and Bash implementations of `rclone-list-mounted`, `rclone-mount`, and `rclone-fzf` with a self-contained Go implementation that reads `/proc/self/mountinfo` directly. This removes the runtime dependencies on `nushell` (process regex parsing) and `util-linux` (`mountpoint`) from `home-manager/storage.nix`.

## Clean-Room & Safety Rules

- Do not read or copy code from external repositories.
- Use only the Go standard library (and the Linux `/proc/self/mountinfo` specification from `proc(5)`).
- Follow Plain English (Junior High Grade 2 level) in all comments, docs, and commit messages. Do not use "we".
- Do not add inline linter suppression comments.

## Background

Currently, three separate packages exist under `pkgs/by-name/rc/`:

1. `rclone-list-mounted`: A Nushell script (`pkgs.writers.writeNuBin`) that runs `ps --long` and parses the `rclone mount <remote> <local>` command string with a regex.
   - Problem: Pulling `nushell` into `storage.nix` for a 6-line script is heavy, and regex matching process arguments breaks if flag order changes.
2. `rclone-mount`: A Bash script that checks `mountpoint -q "$mount_to"` (`util-linux`), creates `$XDG_DATA_HOME/mnt/rclone/<remote_without_colon>`, and runs `rclone mount "$remote" "$mount_to" --vfs-cache-mode writes --daemon`.
   - Note: It also contains a typo `"Mmounted to:"` on stderr.
3. `rclone-fzf`: A Bash script that prints `rclone-list-mounted >&2`, pipes `rclone listremotes` into `fzf`, and binds:
   - `ctrl-/:become(rclone-mount {})`
   - `alt-a:become(rclone about {})`
   - `enter:become(echo {})`

On Linux, `/proc/self/mountinfo` records active FUSE mounts directly without spawning `ps` or `mountpoint`.

## Specification

### 1. Parsing `/proc/self/mountinfo`

According to Linux `proc(5)`, each line in `/proc/self/mountinfo` has the form:

```text
36 35 98:0 /mnt1 /mnt2 rw,noatime master:1 - ext3 /dev/root rw,errors=continue
(1)(2)(3)   (4)   (5)      (6)      (7)   (8) (9)   (10)         (11)
```

- Field (5) is the mount point (e.g. `/home/user/.local/share/mnt/rclone/gdrive`).
- Field (8) is the separator `-` marking the end of optional fields.
- Field (9) (immediately after `-`) is the filesystem type (for rclone FUSE mounts: `fuse.rclone` or `rclone`).
- Field (10) (second field after `-`) is the mount source (e.g. `gdrive:` or `gdrive:vault`).
- Escape sequences in paths: spaces (`\040`), tabs (`\011`), newlines (`\012`), and backslashes (`\134`) are octal-escaped in `mountinfo`. Implement a small unescape helper `unescapeMountinfoField(s string) string`.

Define:

```go
type MountEntry struct {
    Remote     string
    MountPoint string
}
```

- `parseMountinfo(r io.Reader) ([]MountEntry, error)`:
  - Scan line by line.
  - Split on `" - "` (or find the `"-"` token) to separate fields before and after the separator.
  - Extract `mountPoint` from index 4 of the pre-separator fields.
  - Extract `fsType` (index 0) and `mountSource` (index 1) from the post-separator fields.
  - Keep entries where `fsType == "fuse.rclone" || fsType == "rclone"`.
  - Unescape `mountSource` and `mountPoint`.
- `isMountPoint(mountinfo io.Reader, targetPath string) (bool, error)`:
  - Clean `targetPath` with `filepath.Clean`.
  - Check whether any line in `mountinfo` (regardless of `fsType`, matching `mountpoint -q` behavior) has field (5) equal to `targetPath`.

### 2. Commands and CLI Interface

To keep existing user muscle memory and documentation (`config/rclone.md`, `home-manager/storage.nix`) intact while building a single Go binary:

- Package location: `pkgs/by-name/rc/rclone-fzf/` (`main.go`, `main_test.go`, `package.nix`).
- Remove separate package directories `pkgs/by-name/rc/rclone-mount` and `pkgs/by-name/rc/rclone-list-mounted` (or have `rclone-fzf` install symlinks `rclone-mount` and `rclone-list-mounted` in `$out/bin/` and dispatch on `filepath.Base(os.Args[0])` or subcommands `rclone-fzf list-mounted` / `rclone-fzf mount`).
  - **Recommended approach**: Dispatch by subcommand (`rclone-fzf mount <remote>`, `rclone-fzf list-mounted`) AND support `argv[0]` symlink dispatch (`rclone-mount`, `rclone-list-mounted`) installed in `postInstall` of `rclone-fzf/package.nix`. Then delete `pkgs/by-name/rc/rclone-mount` and `pkgs/by-name/rc/rclone-list-mounted`, and update `home-manager/storage.nix` to include `rclone-fzf`.

#### Behavior of `list-mounted` (`rclone-list-mounted`)

- Read `/proc/self/mountinfo`.
- If no `fuse.rclone` mounts exist, print nothing and exit 0.
- If mounts exist, print a clean aligned table to `stdout`:

  ```text
  REMOTE  LOCAL
  foo:    /home/user/.local/share/mnt/rclone/foo
  ```

#### Behavior of `mount` (`rclone-mount <remote>`)

- Require 1 argument `<remote>` (e.g. `foo:`). Return an error if missing.
- Resolve base data directory: `os.Getenv("XDG_DATA_HOME")`, falling back to `filepath.Join(homeDir, ".local", "share")` if unset.
- Compute `mountTo := filepath.Join(dataHome, "mnt", "rclone", strings.TrimSuffix(remote, ":"))`.
- Check if `mountTo` is already mounted using `isMountPoint` on `/proc/self/mountinfo`:
  - If already mounted:
    - Print `"Already mounted:"` to `stderr`.
    - Print `mountTo` to `stdout`.
    - Return `nil` (exit 0).
- Create directory with `os.MkdirAll(mountTo, 0o755)`.
- Run `rclone mount <remote> <mountTo> --vfs-cache-mode writes --daemon` (forwarding stderr).
- Print `"Mounted to:"` to `stderr` and `mountTo` to `stdout`.

#### Behavior of `rclone-fzf [query]`

- Accept optional `[query]` positional argument.
- Print current mounted list (via `list-mounted` logic) to `stderr`.
- Run `rclone listremotes` and capture `stdout`. If empty, return `nil`.
- Invoke `fzf` with `Stdin` set to the `listremotes` output, `Stdout` and `Stderr` connected, and arguments:

  ```go
  []string{
      "--query", query,
      "--border-label", "☁️ Rclone Remotes",
      "--layout=reverse",
      "--height=85%",
      "--min-height=20",
      "--border",
      "--border-label-pos=2",
      "--color=header:italic:underline,label:blue",
      "--header", "Ctrl-/ (Mount) / Alt-A (Inspect)\n\n",
      "--bind", fmt.Sprintf("ctrl-/:become(%q mount {})", selfExe),
      "--bind", "alt-a:become(rclone about {})",
      "--bind", "enter:become(echo {})",
  }
  ```

- Treat `fzf` exit codes 1 and 130 as normal cancelation (`return nil`).

## Target Files

- Create: `pkgs/by-name/rc/rclone-fzf/main.go`
- Create: `pkgs/by-name/rc/rclone-fzf/main_test.go`
- Modify: `pkgs/by-name/rc/rclone-fzf/package.nix`
- Delete: `pkgs/by-name/rc/rclone-fzf/rclone-fzf.bash`
- Delete: `pkgs/by-name/rc/rclone-mount/package.nix`
- Delete: `pkgs/by-name/rc/rclone-mount/rclone-mount.bash`
- Delete: `pkgs/by-name/rc/rclone-list-mounted/package.nix`
- Delete: `pkgs/by-name/rc/rclone-list-mounted/script.nu`
- Modify: `home-manager/storage.nix` (remove `rclone-list-mounted` and `rclone-mount` from `home.packages`, as `rclone-fzf` provides them)
- Modify: `pkgs/list.toml` (add `rclone-fzf = { build = true, test = true, update = false }` and run `task sync-workflows`)

## Packaging Details (`pkgs/by-name/rc/rclone-fzf/package.nix`)

Follow the pattern in `pkgs/by-name/pl/plamo-trans/package.nix` and `pkgs/by-name/gi/gitx/package.nix`:

- Use `buildGo127Module` with `passthru.shared-gomod = true;` and `vendorHash = "sha256-k/qRQykTmtKBdYeT1vtKXNVTjPkhzjYeJgiXR3zQ/js=";` (same shared `go.mod` hash).
- Wrap `$out/bin/rclone-fzf` with `makeWrapper` to prefix `PATH` with `lib.makeBinPath [ fzf rclone ]`.
- In `postInstall` (or `postFixup` after wrapping), create symlinks:

  ```nix
  ln -s rclone-fzf $out/bin/rclone-mount
  ln -s rclone-fzf $out/bin/rclone-list-mounted
  ```

## Unit Tests (`pkgs/by-name/rc/rclone-fzf/main_test.go`)

1. `TestParseMountinfo`:
   - Sample `/proc/self/mountinfo` content including standard ext4/tmpfs mounts, a `fuse.rclone` mount, and a path with `\040` escaped space.
   - Verify only `fuse.rclone` / `rclone` entries are returned and paths are unescaped properly.
2. `TestIsMountPoint`:
   - Verify `isMountPoint` returns `true` for mounted paths and `false` for unmounted parent/child paths.
3. `TestResolveMountPath`:
   - Verify `XDG_DATA_HOME` handling and trailing `:` stripping from remote names (e.g. `gdrive:` -> `$XDG_DATA_HOME/mnt/rclone/gdrive`).

## Verification

```console
go test ./pkgs/by-name/rc/rclone-fzf/...
task sync-workflows
task fmt
task lint
```

If running with Nix store access (`BypassSandbox: true`):

```console
nix build .#rclone-fzf --no-link
```
