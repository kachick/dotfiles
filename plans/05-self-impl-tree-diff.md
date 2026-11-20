# Plan 05: Replace `tree-diff` Bash + Nushell Script with Go

## Goal

Replace the `tree-diff` script (`tree` + `nushell` + `git diff`) with a small Go binary using the shared `go.mod`. This removes `nushell` and `tree` from the runtime closure of `tree-diff`, ensuring `home-manager/essential.nix` (minimal server/CLI profile) does not pull in `nushell`.

## Clean-Room & Safety Rules

- Do not read or copy code from external repositories.
- Use only the Go standard library.
- Follow Plain English (Junior High Grade 2 level) in all comments, docs, and commit messages. Do not use "we".
- Do not add inline linter suppression comments.

## Background

In `home-manager/essential.nix`, line 2 states:

```nix
# Minimal CLI/Server essential module for Home Manager
# Excludes desktop/GUI applications, heavy dev toolchains (ruby, fontconfig, etc.), powershell/nushell, leaf/dust, telemetry (go toolchain), and encryption tools.
```

However, `essential.nix` includes `pkgs.local.tree-diff` (line 129), and `pkgs/by-name/tr/tree-diff/package.nix` currently pulls in `nushell`:

```bash
substituteLeafNode() {
	nu --stdin --commands 'lines | each { str replace "\u{2514}" "\u{251c}" } | to text'
}

git diff <(tree "$1" | substituteLeafNode) <(tree "$2" | substituteLeafNode)
```

Why `tree-diff` replaces `└` (`\u2514`) with `├` (`\u251c`):
In standard `tree` output, the last item in a directory uses `"└── "` while other items use `"├── "`. When a new file is added at the end of a directory, the previous last item changes from `└── prev` to `├── prev`, creating a 2-line diff (`-└── prev`, `+├── prev`, `+└── new`) instead of a 1-line addition. Using `"├── "` for all items makes tree diffs show only actual added/removed entries.

Implementing the directory tree walker and formatter directly in Go removes both `nushell` and `tree` dependencies while keeping the exact diff-friendly tree format.

## Specification

### 1. CLI Interface

```text
Usage: tree-diff <dirA> <dirB>
```

- Require exactly 2 directory arguments (`<dirA>` and `<dirB>`). Print usage to `stderr` and exit with code 2 if argument count is wrong or if either path is not a directory.
- Build normalized tree text for `<dirA>` and `<dirB>` in Go.
- Write them to two temporary files in `os.MkdirTemp("", "tree-diff-*")` (cleaned up with `defer os.RemoveAll`).
- Run `git diff --no-index -- <tmpA> <tmpB>` (or `git diff` matching the user's configured git pager/color settings when attached to a terminal):
  - Note: In the original script, `git diff <(...) <(...)` invokes `git diff` on two non-repo files (which Git automatically treats as `--no-index`).
  - Forward `os.Stdin`, `os.Stdout`, and `os.Stderr` to the `git diff` command so interactive paging (`riff`) and color settings in `programs.git` work identically.
  - Note on exit codes: `git diff --no-index` exits with code `1` when differences are found and `0` when identical (or `>1` on error). Either propagate `git diff`'s exit code or treat exit code 0 and 1 as normal completion (match standard `git diff <(...) <(...)` behavior by propagating the exit code).

### 2. Normalized Tree Rendering (`renderNormalizedTree(rootDir string) (string, error)`)

- Root line: print `.` (or the root label; using `.` at the top ensures comparing two different directory paths like `dir1` and `dir2` does not produce a noisy `-dir1` / `+dir2` header diff on line 1!).
  - Note: Check if printing `.` as the root line is cleaner than `tree "$1"` (which prints `$1` on line 1 and always diffs the root path). Using `.` makes identical directories produce an empty diff!
- Recursive traversal (`os.ReadDir`):
  - Read entries in each directory. (`os.ReadDir` already returns entries sorted by filename).
  - Follow standard `tree` default visibility: skip hidden entries starting with `.` unless `--all` / `-a` flag is passed (support `-a` / `--all` flag via `flag.NewFlagSet` for convenience!).
  - For every entry (including the last entry in a directory), use `"├── "` as the branch connector and `"│   "` as the vertical indentation prefix for children, so adding/removing entries at the end of a directory never changes the connector of sibling lines.
  - If an entry is a symlink (`entry.Type()&os.ModeSymlink != 0`), read its target with `os.Readlink` and format as `<name> -> <target>`, without recursing into symlinked directories (prevents infinite loops).
  - If an entry is a directory, append `/` (or format directory name consistently) and recurse into it with prefix `parentPrefix + "│   "`.

## Target Files

- Create: `pkgs/by-name/tr/tree-diff/main.go`
- Create: `pkgs/by-name/tr/tree-diff/main_test.go`
- Modify: `pkgs/by-name/tr/tree-diff/package.nix`
- Delete: `pkgs/by-name/tr/tree-diff/tree-diff.bash`
- Modify: `pkgs/list.toml` (add `tree-diff = { build = true, test = true, update = false }` and run `task sync-workflows`)

## Packaging Details (`pkgs/by-name/tr/tree-diff/package.nix`)

- Use `buildGo127Module` with `passthru.shared-gomod = true;` and `vendorHash = "sha256-k/qRQykTmtKBdYeT1vtKXNVTjPkhzjYeJgiXR3zQ/js=";`.
- Use `makeWrapper` to prefix `PATH` with `lib.makeBinPath [ gitMinimal ]` (or let it use `git` from environment / `gitMinimal` fallback so user's `riff` pager in `PATH` remains accessible).
  - Important: Use `--suffix PATH : "${lib.makeBinPath [ gitMinimal ]}"` instead of `--prefix`, or include `riffdiff` if needed, so `git diff` can find `riff` in the user's `PATH`.

## Unit Tests (`pkgs/by-name/tr/tree-diff/main_test.go`)

1. `TestRenderNormalizedTree`:
   - Create a temporary directory structure with nested folders, multiple files, hidden files, and a symlink.
   - Verify all entries use `"├── "` (never `"└── "`) and `"│   "` indentation.
   - Verify adding a new file `z.txt` at the end of a directory only adds `+├── z.txt` without changing the line for the previous last file.
2. `TestRenderNormalizedTree_HiddenFlag`:
   - Verify hidden files (`.gitignore`) are excluded by default and included when `-a` / `--all` is enabled.
3. `TestRunTreeDiff`:
   - Compare two identical temporary directories -> exit 0, empty output.
   - Compare two directories differing by one file -> diff output contains only the added file line.

## Verification

```console
go test ./pkgs/by-name/tr/tree-diff/...
task sync-workflows
task fmt
task lint
```

If running with Nix store access (`BypassSandbox: true`):

```console
nix build .#tree-diff --no-link
```
