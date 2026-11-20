# Plan 01: Remove `colorized-logs` and `findutils` from `gitx`

## Goal

Replace the shell pipeline (`echo {} | cut | ansi2txt | xargs`) in `gitx log-fzf` (non-`--ja` mode) with an internal Go subcommand (`gitx log-fzf _preview-plain {2}`). This removes `colorized-logs` (`ansi2txt`) and `findutils` (`xargs`) from `gitx` runtime dependencies.

## Clean-Room & Safety Rules

- Do not read or copy code from external repositories.
- Use only the Go standard library and existing code in this repository.
- Follow Plain English (Junior High Grade 2 level) in all comments, docs, and commit messages. Do not use "we".
- Do not add inline linter suppression comments.

## Background

In `pkgs/by-name/gi/gitx/log_fzf.go`, `buildLogFzfArgs` currently uses two different preview implementations:

1. `--ja` mode: calls `gitx log-fzf _preview <cacheDir> {2}` and `gitx log-fzf _detail <cacheDir> {2}`. Both strip ANSI sequences in Go via `cleanRev()` and pipe `git show` through `riff` and `bat`.
2. Plain (non-`--ja`) mode: runs a shell pipeline:
   `echo {} | cut --delimiter " " --fields 2 --only-delimited | ansi2txt | xargs --no-run-if-empty --max-lines=1 git show --color=always | riff --color=on | bat --language=gitlog --color=always --style=plain --wrap=character`

Because `cleanRev()` and the `riff` + `bat` pipe setup already exist in `log_fzf.go`, routing plain mode through a Go subcommand removes the only use of `ansi2txt` (`colorized-logs`) and `xargs` (`findutils`) in `gitx`.

## Target Files

- Modify: `pkgs/by-name/gi/gitx/log_fzf.go`
- Modify: `pkgs/by-name/gi/gitx/log_fzf_test.go`
- Modify: `pkgs/by-name/gi/gitx/package.nix`

## Step-by-Step Implementation

### 1. Add plain commit rendering in `pkgs/by-name/gi/gitx/log_fzf.go`

1. Extract or generalize the `cmd1 -> riff -> bat` pipeline in `renderCommit` so it can run either:
   - `selfExe show --ja [--placeholder ...] --color=always <rev>` (for `--ja` mode)
   - `git show --color=always <rev>` (for plain mode)
2. Add a helper function `renderPlainCommit(revRaw string, stdout, stderr io.Writer) error`:
   - Call `rev := cleanRev(revRaw)`.
   - If `rev == ""` (empty selection), return `nil`.
   - Run `git show --color=always <rev>` piped through `riff --color=on` and `bat --language=gitlog --color=always --style=plain --wrap=character` (falling back to direct `git show --color=always <rev>` to `stdout` if `riff` or `bat` is not found in `PATH`, matching `renderCommit`).
3. In `runLogFzf`:
   - Handle `_preview-plain` when `len(args) > 0`:

     ```go
     case "_preview-plain":
         if len(args) < 2 {
             return nil
         }
         return renderPlainCommit(args[1], stdout, stderr)
     ```

4. In `buildLogFzfArgs`:
   - Ensure `selfExe` is always resolved in `runLogFzfMain` (move `os.Executable()` outside `if opts.ja` so `selfExe` is available in both modes).
   - Change plain `previewCmd` and `detailBind` to use `selfExe`:

     ```go
     previewCmd := fmt.Sprintf("%q log-fzf _preview-plain {2}", selfExe)
     detailBind := fmt.Sprintf("enter:become(%q log-fzf _preview-plain {2})", selfExe)
     ```

### 2. Update unit tests in `pkgs/by-name/gi/gitx/log_fzf_test.go`

1. Update `TestParseAndBuildLogFzfArgs`:
   - Verify that plain mode `buildLogFzfArgs("/bin/gitx", "", "", plainOpts)` includes `"/bin/gitx" log-fzf _preview-plain {2}` for both `--preview` and `enter:become(...)`, and no longer contains `ansi2txt` or `xargs`.
2. Add a test for `runLogFzf([]string{"_preview-plain", ""}, ...)` verifying it returns `nil` cleanly on empty input.

### 3. Remove unused dependencies in `pkgs/by-name/gi/gitx/package.nix`

1. Remove `colorized-logs` and `findutils` from the function arguments at the top of `pkgs/by-name/gi/gitx/package.nix`.
2. Remove `colorized-logs` and `findutils` from `wrapperPath`.

## Verification

Run the following commands and confirm all checks pass:

```console
go test ./pkgs/by-name/gi/gitx/...
task fmt
task lint
```

If running with Nix store access (`BypassSandbox: true`):

```console
nix build .#gitx --no-link
```
