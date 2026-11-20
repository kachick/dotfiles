# Plan 03: Migrate `fzf-bind-posix-shell-history-to-git-commit-message` and `safe_quote_backtik` to `gitx`

## Goal

Replace the `fzf-bind-posix-shell-history-to-git-commit-message` (Nushell + fzf) and `safe_quote_backtik` (Bash) packages with a `gitx commit-from-history` subcommand in Go. This eliminates spawning Nushell on `gch`, avoids passing untrusted shell history strings through `become(...)` shell command expansion, and deletes two micro-packages.

## Clean-Room & Safety Rules

- Do not read or copy code from external repositories.
- Use only the Go standard library and existing `internal/gitcmd` helpers.
- Follow Plain English (Junior High Grade 2 level) in all comments, docs, and commit messages. Do not use "we".
- Do not add inline linter suppression comments.

## Background

Currently, typing `gch` in bash or zsh runs:

```bash
gch() {
	fc -nrl 1 | '@fzf_bind_shell_hist@'
}
```

Where `fzf-bind-posix-shell-history-to-git-commit-message` does:

```bash
nu --stdin --commands 'lines | each { str trim } | to text' |
	fzf --height ${FZF_TMUX_HEIGHT:-40%} ${FZF_DEFAULT_OPTS-} \
		-n2..,.. --scheme=history \
		--bind 'enter:become(safe_quote_backtik {} | git commit -a -F -)'
```

Problems with the current implementation:

1. Spawns `nu` just to run `strings.TrimSpace` on stdin lines.
2. Uses `fzf --bind 'enter:become(safe_quote_backtik {} | git commit -a -F -)'`, which invokes a subshell to expand `{}` and calls a separate 3-line package `safe_quote_backtik` just to wrap the string in backticks (`` `...` ``).
3. Requires two separate Nix packages (`fzf-bind-posix-shell-history-to-git-commit-message` and `safe_quote_backtik`).

In Go, `gitx commit-from-history` can trim lines from `stdin`, pass them to `fzf`, read the selected line from `fzf` stdout, wrap it in backticks in memory, and invoke `git commit --all --file=-` with the message fed via `Stdin` (zero shell quoting issues).

## Target Files

- Create: `pkgs/by-name/gi/gitx/commit_from_history.go`
- Create: `pkgs/by-name/gi/gitx/commit_from_history_test.go`
- Modify: `pkgs/by-name/gi/gitx/main.go`
- Modify: `pkgs/by-name/po/posix_dev_functions/posix_dev_functions.bash`
- Modify: `pkgs/by-name/po/posix_dev_functions/package.nix`
- Modify: `home-manager/dev.nix`
- Delete: `pkgs/by-name/fz/fzf-bind-posix-shell-history-to-git-commit-message/package.nix`
- Delete: `pkgs/by-name/fz/fzf-bind-posix-shell-history-to-git-commit-message/fzf-bind-posix-shell-history-to-git-commit-message.bash`
- Delete: `pkgs/by-name/sa/safe_quote_backtik/package.nix`
- Delete: `pkgs/by-name/sa/safe_quote_backtik/safe_quote_backtik.bash`

## Step-by-Step Implementation

### 1. Implement `pkgs/by-name/gi/gitx/commit_from_history.go`

1. `trimHistoryLines(r io.Reader) string`:
   - Scan lines from `r` using `bufio.Scanner`.
   - Apply `strings.TrimSpace(line)` to each line.
   - Skip empty lines.
   - Join non-empty trimmed lines with `"\n"` (ending with `"\n"`).
2. `formatBacktickCommitMessage(selected string) string`:
   - Return ``"`" + strings.TrimSpace(selected) + "`\n"``.
3. `commitFromHistoryFzfArgs() []string`:
   - Determine height from `os.Getenv("FZF_TMUX_HEIGHT")`; if empty, default to `"40%"`.
   - Return:

     ```go
     []string{
         "--height=" + height,
         "-n2..,..",
         "--scheme=history",
     }
     ```

4. `runCommitFromHistory(args []string, workDir string, stdin io.Reader, stdout, stderr io.Writer) error`:
   - Parse flags with `flag.NewFlagSet("gitx commit-from-history", flag.ContinueOnError)`. Reject positional arguments.
   - Read and trim lines from `stdin` via `trimHistoryLines(stdin)`. If empty, return `nil`.
   - Run `fzf` with `commitFromHistoryFzfArgs()`, feeding the trimmed history to `cmd.Stdin`, capturing `fzf` output buffer, and forwarding `stderr`.
   - If `fzf` exits with code 1 or 130 (`isCancelExitError(err)`), return `nil`.
   - Extract the selected line (`strings.TrimSpace(fzfOut.String())`). If empty, return `nil`.
   - Format the commit message with `formatBacktickCommitMessage(selected)`.
   - Run `git commit --all --file=-` in `workDir` with `cmd.Stdin = strings.NewReader(msg)`, `cmd.Stdout = stdout`, `cmd.Stderr = stderr`.

### 2. Register subcommand in `pkgs/by-name/gi/gitx/main.go`

Add to `allGitxSubcommands()`:

```go
{
	name:        "commit-from-history",
	description: "Commit all changes using a shell history entry selected via fzf",
	run: func(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
		return runCommitFromHistory(args, "", stdin, stdout, stderr)
	},
},
```

### 3. Add unit tests in `pkgs/by-name/gi/gitx/commit_from_history_test.go`

1. `TestTrimHistoryLines`:
   - Verify leading tabs/spaces from `fc -nrl 1` output (e.g. `"\t git status  \n  \n  cargo test\n"`) are trimmed and blank lines are dropped.
2. `TestFormatBacktickCommitMessage`:
   - Verify a command with backticks, dollar signs, or quotes (e.g. `echo "$HOME"` or `nix build .#gitx`) is wrapped as ``"`echo \"$HOME\"`\n"`` without shell evaluation.
3. Integration test with a temporary git repository:
   - Verify committing a modified tracked file using the commit helper logic creates a commit whose subject is wrapped in backticks.

### 4. Update Shell Functions and Nix Packages

1. In `pkgs/by-name/po/posix_dev_functions/posix_dev_functions.bash`:
   - Update `gch()`:

     ```bash
     gch() {
     	fc -nrl 1 | '@gitx@' commit-from-history
     }
     ```

2. In `pkgs/by-name/po/posix_dev_functions/package.nix`:
   - Remove `fzf_bind_shell_hist = ...;`.
3. In `home-manager/dev.nix`:
   - Remove `fzf-bind-posix-shell-history-to-git-commit-message` from `home.packages`.
4. Delete `pkgs/by-name/fz/fzf-bind-posix-shell-history-to-git-commit-message` and `pkgs/by-name/sa/safe_quote_backtik`.

## Verification

```console
go test ./pkgs/by-name/gi/gitx/...
task fmt
task lint
```

If running with Nix store access (`BypassSandbox: true`):

```console
nix build .#gitx --no-link
task test-shell-delegation
```
