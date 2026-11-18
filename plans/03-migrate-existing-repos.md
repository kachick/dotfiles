# Plan 03: Migrate Existing Local Repositories to `--clean-bare` Layout (`git-migrate-clean-bare`)

## Goal

Provide a safe, idempotent CLI tool (`git-migrate-clean-bare`) to convert existing standard (non-bare) Git clones under `~/repos` into the `--clean-bare` worktree layout (`<repo>/.git` + `<repo>/<default_branch>/` + any existing linked worktrees) without losing uncommitted changes, untracked files (`.env`, `.envrc`), stashes, or local branches.

## Background & Constraints

1. **Zero Data Loss (Fail-Closed)**:
   - Local repositories often contain uncommitted modifications, untracked ignored files (`.env`, `.gitconfig.local`, `.direnv`), local branches, and stashes.
   - Moving the working tree into `<repo>/<branch>/` rather than re-cloning from the remote preserves all local refs, stashes, config, hooks, and untracked files.
2. **Dynamic Branch Handling**:
   - Do not assume the currently checked-out branch is `main`. Detect the currently checked-out branch name (via `git symbolic-ref --short HEAD`). If the repository is in detached HEAD state, abort and ask the user to switch to a branch first (fail-closed).
3. **Name Collision Edge Case**:
   - A repository might contain a top-level file or directory with the same name as the branch (e.g. a directory named `main/` or `trunk/` inside the working tree).
   - Moving files via a temporary sibling directory inside `<repo>/` (e.g. `<repo>/.tmp-migrate-<uuid>/`) and then renaming `.tmp-migrate-<uuid>` to `<repo>/<branch>` avoids colliding with a top-level file/directory named `<branch>`.
4. **Trust Preservation (`direnv`)**:
   - Do NOT unconditionally run `direnv allow`.
   - Before migration, check if `<repo>/.direnv` exists (or if `--trust` is explicitly passed). Only run `direnv allow <repo>/<branch>` after migration if `.envrc` exists AND `.direnv` was previously present (or `--trust` was passed). Remove the old `<repo>/<branch>/.direnv` cache before re-allowing so hardcoded absolute paths in `.direnv` are regenerated cleanly.

## Target Files

- `pkgs/by-name/gi/git-migrate-clean-bare/package.nix`
- `pkgs/by-name/gi/git-migrate-clean-bare/main.go`
- `pkgs/by-name/gi/git-migrate-clean-bare/main_test.go`
- `home-manager/dev.nix` (add `git-migrate-clean-bare` to `pkgs.local` list)

## Detailed Design

### 1. Pre-flight Safety Checks (`main.go`)

Accept target repository directory `<repo_dir>` (defaults to current repository root via `git rev-parse --show-toplevel` if omitted) and flags `--dry-run`, `--trust`:

1. Verify `<repo_dir>/.git` is a directory (not a `.git` file from a linked worktree).
2. Check `git -C <repo_dir> rev-parse --is-bare-repository`:
   - If already `true`, report that `<repo_dir>` is already a bare repository and exit 0 (idempotent).
3. Check current branch:
   - `branch := git -C <repo_dir> symbolic-ref --short HEAD`
   - If error or empty (detached HEAD), fail-closed with an error.
4. Check if `<repo_dir>/.direnv` exists (`wasTrusted := isDir(filepath.Join(repoDir, ".direnv"))`).

### 2. In-Place Conversion Steps

To convert `<repo_dir>` (currently a normal clone on `<branch>`) into `<repo_dir>/.git` (bare) + `<repo_dir>/<branch_dir>` (linked worktree):

1. **Move working tree files into a temporary directory**:
   - Create `<repo_dir>/.git-migrate-tmp-<uuid>`.
   - Move every entry in `<repo_dir>` EXCEPT `.git` and `.git-migrate-tmp-<uuid>` into `<repo_dir>/.git-migrate-tmp-<uuid>/`.
   - Remove `<repo_dir>/.git-migrate-tmp-<uuid>/.direnv` if present (since absolute paths inside `.direnv` point to `<repo_dir>` instead of `<repo_dir>/<branch_dir>`).
2. **Rename temporary directory to target worktree path**:
   - Determine `<branch_dir>` (replace `/` with `-` in `<branch>`).
   - Rename `<repo_dir>/.git-migrate-tmp-<uuid>` to `<repo_dir>/<branch_dir>`.
3. **Convert `<repo_dir>/.git` to bare and register the worktree**:
   - Use Git's built-in worktree registration and preserve the original staging index:
     1. Move `<repo_dir>/<branch_dir>` temporarily to `<tmp_wt>`.
     2. Set `git -C <repo_dir> config set core.bare true`.
     3. Ensure `remote.origin.fetch` is set to `+refs/heads/*:refs/remotes/origin/*` if remote `origin` exists.
     4. Run `git -C <repo_dir> worktree add --no-checkout "<repo_dir>/<branch_dir>" "<branch>"`.
     5. Move `<repo_dir>/<branch_dir>/.git` (the gitdir pointer file created by Git) into `<tmp_wt>/.git`.
     6. Remove the empty `<repo_dir>/<branch_dir>` directory and rename `<tmp_wt>` to `<repo_dir>/<branch_dir>`.
     7. Resolve `wtGitDir := git -C "<repo_dir>/<branch_dir>" rev-parse --path-format=absolute --git-dir` and move `<repo_dir>/.git/index` (if it exists) to `<wtGitDir>/index` so both tracked file states and staged changes are preserved intact without touching working tree files.
4. **Repair any pre-existing linked worktrees**:
   - Run `git -C <repo_dir> worktree repair`.
5. **Restore `direnv` if previously trusted**:
   - If `<repo_dir>/<branch_dir>/.envrc` exists and (`wasTrusted` || `--trust`), run `direnv allow "<repo_dir>/<branch_dir>"`.
6. Print the new worktree path `<repo_dir>/<branch_dir>` to `stdout`.

## Verification Steps

1. Write unit tests in `pkgs/by-name/gi/git-migrate-clean-bare/main_test.go` covering:
   - Standard repo with tracked files, uncommitted changes, untracked `.env` file, and a directory named `main/` inside the repo (collision test).
   - Repo with non-`main` default branch (`trunk`).
   - Idempotency when run on an already migrated `--clean-bare` repo.
   - Detached HEAD rejection (fail-closed).
2. Stage new files with `git add -N` and run `task fmt` and `task check`.
