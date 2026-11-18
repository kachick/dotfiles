# Plan 02: Worktree Shorthand (`git-wt` / `cdwt`) and Merged Worktree Cleanup

## Goal

Create a clean, license-free, self-contained worktree management tool and update existing branch/repository cleanup commands (`git-delete-merged-branches`, `git refresh`, `git all`) so they handle linked worktrees and merged worktrees seamlessly using modern Git 2.56 features.

## Background & Constraints

1. **No Third-Party Code Copying**:
   - Write the implementation from scratch using standard Go (`buildGo127Module`) and Git built-in commands. Do not copy code from external worktree tools.
2. **Leverage Built-In Git 2.56 Features**:
   - `git worktree add --guess-remote <path>` (or `worktree.guessRemote = true` in `home-manager/git.nix`): When `<path>` basename matches a remote-tracking branch on `origin`, Git automatically checks out that branch and tracks `origin/<branch>`; otherwise it creates a new branch from `HEAD` (or specified base).
   - `git for-each-ref --format='%(refname:short)%(00)%(worktreepath)%(00)%(upstream:short)' refs/heads/`: Directly exposes `%(worktreepath)` for each local branch without parsing `git worktree list` manually.
   - `git for-each-ref --merged=<commit>`: Lists branches whose tips are reachable from `<commit>` (e.g. the default branch).
   - `git branch --delete-merged <pattern>` (added in Git 2.56): Note that Git's built-in `--delete-merged` skips branches currently checked out in a worktree (`it is checked out in any worktree`) and only deletes branches whose `branch.<name>.merge` is still configured to `<pattern>`. Therefore, to remove **merged worktrees** (and topic branches merged into the default branch via GitHub PR), we must first `git worktree remove` merged worktrees before deleting their branches.
3. **Dynamic Default Branch & Layout**:
   - In a `--clean-bare` repository (`~/repos/<host>/<owner>/<repo>/.git`), `git rev-parse --path-format=absolute --git-common-dir` returns `/path/to/<repo>/.git`. Its parent directory `/path/to/<repo>` is the container for all worktrees.
   - Never hardcode `main` or `master`. Determine the default branch dynamically via:
     1. `git symbolic-ref --short refs/remotes/<upstream>/HEAD` (stripping `<upstream>/`)
     2. Fallback: `git -C "$(git rev-parse --git-common-dir)" symbolic-ref --short HEAD`
     3. Fallback: check existing local branches against `main`, `master`, `trunk`, `develop`, `development`.
4. **Automatic `direnv allow` for Local Worktree Creation**:
   - When creating a new worktree inside a repository where the user is already working (or when the source worktree already has an allowed `.envrc` / `--trust` flag), automatically run `direnv allow` if `.envrc` exists in the new worktree.
   - Better yet: only auto-run `direnv allow` on the new worktree if `.envrc` exists AND either `--trust` is passed OR `direnv status` in the current/default worktree shows the existing `.envrc` is already allowed (fail-closed for untrusted repos!).

## Target Files

- `home-manager/git.nix`
- `home-manager/dev.nix`
- `pkgs/by-name/gi/git-delete-merged-branches/` (upgrade to remove merged secondary worktrees as well as merged branches)
- `pkgs/by-name/gi/git-wt/` (new Go package using `buildGo127Module`, similar to `git-reset-branch`)
- `pkgs/by-name/po/posix_shared_functions/posix_shared_functions.bash` & `package.nix` (add shell wrapper `wt` / `cdwt` to `cd` into the created/selected worktree)

## Detailed Design

### 1. Git Config Additions (`home-manager/git.nix`)

- Add `worktree.guessRemote = true;` under `programs.git.settings`.
- Update `alias.switch-default` and `alias.refresh`:
  - In a `--clean-bare` setup, each worktree stays on its own branch (`main/` is already on `main`). Running `git switch main` inside a `feat-x/` worktree fails because `main` is already checked out in `../main`.
  - Update `refresh` so that if the current branch is the default branch (or if in the default worktree), it fetches and pulls; or if in a clean-bare repo, it updates the default branch ref (`git fetch origin --prune`) and fast-forwards the default branch worktree cleanly.

### 2. Worktree CLI (`pkgs/by-name/gi/git-wt/`)

Implement a Go CLI `git-wt` (`buildGo127Module`, tested with `main_test.go` without network/`git push`, following `pkgs/by-name/gi/git-reset-branch/main_test.go` conventions):

- **Subcommands / Usage**:
  - `git-wt list` (or no args): List worktrees in the current repository (`<worktree_name>\t<branch>\t<abs_path>`), suitable for `fzf`.
  - `git-wt add [--base <ref>] [--trust] <branch_or_name>`:
    1. Locate repo container directory: `commonDir := git("rev-parse", "--path-format=absolute", "--git-common-dir")`. If `filepath.Base(commonDir) == ".git"`, container dir is `filepath.Dir(commonDir)`.
    2. Sanitize directory name: replace `/` in `<branch_or_name>` with `-` for the worktree directory name `<container>/<dir_name>` so all worktrees stay flat at depth 1 under `<repo>/`.
    3. If `<container>/<dir_name>` already exists, print its path and exit 0.
    4. Check if `<branch_or_name>` exists locally (`refs/heads/<branch>`), on remote (`refs/remotes/origin/<branch>`), or is a new branch:
       - Existing local branch: `git worktree add <target_dir> <branch>`
       - Existing remote branch: `git worktree add --track -b <branch> <target_dir> origin/<branch>`
       - New branch: base it on `<base>` (defaults to `origin/<default_branch>` or `<default_branch>`), running `git worktree add --no-track -b <branch> <target_dir> <base>`.
    5. Check `.envrc`: If `<target_dir>/.envrc` exists, and (`--trust` is set OR another worktree in `<container>` already has `<other>/.direnv` directory indicating this repo is trusted), run `direnv allow <target_dir>` (writing any diagnostic output to `stderr`).
    6. Print `<target_dir>` to `stdout` (all git progress output goes to `stderr`) so shell functions can `cd "$(git-wt add ...)"`.
  - `git-wt path [<name>]`: Print the absolute path of the named worktree (or default branch worktree if omitted).

### 3. Shell Wrapper (`posix_shared_functions.bash`)

Add a concise shell function `wt`:

- `wt` (no args): Select worktree in current repo via `git-wt list | fzf ...` and `cd` into it.
- `wt <branch>` (or `wt add <branch>`): Run `target="$(git-wt add "$@")" && cd "$target"`.

### 4. Merged Worktree & Branch Cleanup (`pkgs/by-name/gi/git-delete-merged-branches/`)

Update `git-delete-merged-branches`:

1. Determine the target default branch (`main`, `master`, `trunk`, `develop`, `development`, or `origin/HEAD`).
2. Find all local branches merged into the target branch using `git for-each-ref --merged=<default_branch> --format='%(refname:short)|%(worktreepath)' refs/heads/`.
3. Exclude protected branch names (`main`, `master`, `trunk`, `develop`, `development`, and the default branch itself).
4. For each merged branch:
   - If `%(worktreepath)` is non-empty and is NOT the current working directory (`$PWD`):
     - Run `git worktree remove "<worktreepath>"` (without `--force`, so unclean worktrees with untracked/modified files fail-closed and are kept safe!).
   - Delete the merged branch with `git branch --delete "<branch>"`.
5. Run `git worktree prune`.

## Verification Steps

1. Write comprehensive Go tests in `pkgs/by-name/gi/git-wt/main_test.go` covering:
   - Creating worktrees for new branches, existing local branches, and remote branches (including `/` in branch names like `feat/foo`).
   - Dynamic default branch detection (`trunk`, `master`, `main`).
   - Fail-closed `direnv` trust check.
2. Test `git-delete-merged-branches` with merged worktrees (both clean and dirty; verify clean merged worktree is removed and dirty merged worktree is preserved).
3. Stage new files with `git add -N` and run `task fmt` and `task check`.
