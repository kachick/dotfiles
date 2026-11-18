# Plan 01: Clean-Bare Clone and Flat Worktree Navigation (`getrepo` & `cdrepo` / `ghqf`)

## Goal

Update repository acquisition (`getrepo`, `gh burl`) to use `ghq get --clean-bare` with dynamic default-branch worktree initialization, and update repository navigation (`ghqf`, `cdrepo`) to present a flat list of all repositories and their worktrees while prioritizing repository names in `fzf` matching.

## Background & Constraints

1. **Clean-Bare Layout (`ghq get --clean-bare`)**:
   - `ghq get --clean-bare <repo>` clones the bare repository into `~/repos/<host>/<owner>/<repo>/.git`.
   - Because `<repo>/.git` exists, `ghq list` discovers `<repo>` identically to non-bare clones and stops descending into `<repo>/` (`filepath.SkipDir`), so sibling worktrees inside `<repo>/` never pollute `ghq list`.
2. **Git Bare Clone Traps**:
   - `git clone --bare` does not configure `remote.origin.fetch`. Without `+refs/heads/*:refs/remotes/origin/*`, subsequent `git fetch` or `git pull` inside worktrees will not update `refs/remotes/origin/*`.
   - A bare clone has no initial working tree. The default branch (`main`, `master`, `trunk`, etc.) must be detected dynamically without hardcoding.
   - Right after `git clone --bare`, `git symbolic-ref --short HEAD` inside `<repo>/.git` returns the remote's default branch name (e.g. `main`, `master`, `trunk`).
3. **Security (`direnv allow`)**:
   - `getrepo` is frequently used to inspect untrusted third-party OSS repositories.
   - NEVER run `direnv allow` by default in `getrepo`. Only run `direnv allow` when an explicit `--trust` flag is passed (`getrepo --trust <repo>`), and in `gh burl` (which creates the user's own repository).
4. **Flat Worktree Listing in `ghqf` / `cdrepo`**:
   - `ghqf` should list worktrees across all `ghq` repositories in a flat list, while still supporting non-bare legacy repositories that have not been migrated yet.
   - When searching in `fzf`, queries for a repository name (e.g. `dotfiles`) MUST rank repositories named `dotfiles` higher than a worktree branch named `feat-dotfiles` inside another repository.

## Target Files

- `pkgs/by-name/gh/ghqf/package.nix`
- `pkgs/by-name/gh/ghqf/ghqf.bash` (or replace with a Go binary / fast script if needed; see Design below)
- `pkgs/by-name/po/posix_shared_functions/package.nix`
- `pkgs/by-name/po/posix_shared_functions/posix_shared_functions.bash`
- `home-manager/git.nix`

## Detailed Design

### 1. Helper for Clean-Bare Initialization (`git-init-clean-bare` or inside `getrepo`)

When `ghq get --clean-bare <target>` finishes, locate the repository root directory `<repo_dir>`:

1. Check if `<repo_dir>/.git` is a bare repository (`git -C "<repo_dir>" rev-parse --is-bare-repository` == `true`).
2. Configure standard fetch refspec and remote HEAD:

   ```bash
   git -C "$repo_dir" config set remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
   git -C "$repo_dir" fetch --quiet origin
   git -C "$repo_dir" remote set-head origin --auto >/dev/null 2>&1 || true
   ```

3. Detect the default branch dynamically (no hardcoded `main`/`master`):

   ```bash
   default_branch="$(git -C "$repo_dir" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
   if [ -z "$default_branch" ]; then
   	default_branch="$(git -C "$repo_dir" symbolic-ref --short HEAD)"
   fi
   ```

4. If the worktree `<repo_dir>/<default_branch>` does not exist yet:

   ```bash
   git -C "$repo_dir" worktree add "$repo_dir/$default_branch" "$default_branch"
   git -C "$repo_dir/$default_branch" branch --set-upstream-to="origin/$default_branch" "$default_branch"
   ```

5. If `--trust` was passed to `getrepo` and `<repo_dir>/<default_branch>/.envrc` exists:

   ```bash
   direnv allow "$repo_dir/$default_branch"
   ```

### 2. `getrepo` Options (`pkgs/by-name/po/posix_shared_functions/posix_shared_functions.bash`)

Support `getrepo [--trust] <repo_spec>`:

- Parse optional `--trust` flag.
- Run `ghq get --clean-bare "$repo_spec"`.
- Resolve the cloned repo path via `ghq list --full-path --exact` (or using `reponame` + `ghq list`), initialize the default branch worktree if bare, optionally run `direnv allow` if `--trust` is set, and `cd` directly into `<repo_dir>/<default_branch>`.

### 3. `gh burl` Update (`home-manager/git.nix`)

Update the `burl` alias in `home-manager/git.nix` so newly created personal repositories also follow the clean-bare layout (or convert/clone via `ghq get --clean-bare` after `gh repo create --private --template=...` without `--clone`, then initialize default worktree and `direnv allow`).

### 4. Flat Worktree Discovery & Ranking in `ghqf` (`pkgs/by-name/gh/ghqf/`)

To avoid spawning `git worktree list` hundreds of times in shell loops (which would make `cdrepo` slow), `ghqf` should inspect filesystem metadata directly (either in Go or fast shell/find):

- For each `<repo>` in `ghq list` (relative path `<host>/<owner>/<repo>`, full path `<root>/<host>/<owner>/<repo>`):
  - Check `<full_path>/.git/worktrees`:
    - If `<full_path>/.git/worktrees` directory exists and has subdirectories, read `<full_path>/.git/worktrees/*/gitdir` (each file contains `/path/to/worktree/.git`). Strip trailing `/.git` to get the worktree directory `<wt_path>` and its label `<wt_name>` (relative to `<full_path>` or basename).
  - If `<full_path>` is a normal (non-bare) repository (i.e. `<full_path>/.git/HEAD` exists and `<full_path>/.git/config` does not have `bare = true` or worktrees is empty):
    - Emit the main working tree at `<full_path>`.
- **Output / `fzf` Format**:
  - Format each line as: `<host>/<owner>/<repo>\t<worktree_label>\t<target_full_path>` (for normal repos without extra worktrees, `<worktree_label>` can be `.` or omitted in display).
  - Pass to `fzf`:
    - `--delimiter='[/\t]'`
    - `--nth='3,4'` (field 3 is `<repo>`, field 4 is `<worktree_label>`)
    - `--with-nth='1..4'` (display `<host>/<owner>/<repo>  <worktree_label>`)
    - `--accept-nth='5..'` (or use `\t` delimiter and `--accept-nth=3` so `fzf` outputs `<target_full_path>` directly!)
    - **Crucial for Ranking**: Use `--tiebreak=begin,index` (and emit default branch worktrees before secondary worktrees). Because `<repo>` is at the beginning of the searched token range (`--nth=3..`), a match in `<repo>` has a smaller `begin` offset than a match in `<worktree_label>`. Thus querying `dotfiles` ranks `github.com/kachick/dotfiles  main` strictly above `github.com/other/repo  feat-dotfiles`.
  - Update `cdrepo` in `posix_shared_functions.bash` so it `cd`s directly to the path returned by `ghqf`.

## Verification Steps

1. Run unit/integration tests in a temporary `GHQ_ROOT` with both a clean-bare repository (having `trunk` and `feat-1` worktrees) and a legacy non-bare repository.
2. Verify `fzf --filter "reponame"` ranks the repo name match above a branch name match in another repo.
3. Run `git add -N` on any new files, then run `task fmt` and `task check` (or `task test-go` and `task lint`).
