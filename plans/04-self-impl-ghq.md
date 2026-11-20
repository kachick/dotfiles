# Plan 04: Replace `ghq` with Native `gitx` Implementation

## Goal

Replace all uses of `ghq` (`ghq root --all`, `ghq list --full-path`, and `ghq get --clean-bare`) with pure Go implementations inside `gitx`, and remove `ghq` from package dependencies.

## Clean-Room & Safety Rules

- Do not read or copy code from external repositories (including the upstream `ghq` repository).
- Implement strictly from the specification in this document, standard Git behavior, and the existing code in `pkgs/by-name/gi/gitx/`.
- Follow Plain English (Junior High Grade 2 level) in all comments, docs, and commit messages. Do not use "we".
- Do not add inline linter suppression comments.

## Background

In this repository, `gitx` already implements almost all worktree and repository management logic:

- `pkgs/by-name/gi/gitx/init_clean_bare.go` already configures `remote.origin.fetch`, fetches `origin`, sets `origin/HEAD`, detects the default branch, creates the initial flat worktree (including `--orphan` for empty repos), and runs `direnv allow`.
- `pkgs/by-name/gi/gitx/ghq_fzf.go` already inspects `<repo>/.git/HEAD`, `<repo>/.git/config` (`bare = true`), and `<repo>/.git/worktrees/*/gitdir` directly from the filesystem.
- `ghq_fzf.go` explicitly targets the 3-level `<root>/<host>/<owner>/<repo>` directory hierarchy (`--delimiter=[/\t]`, `--nth=3,4`, `--with-nth=1..4`, `--accept-nth=5..`).

The external `ghq` binary is only called for:

1. `ghq root --all` and `ghq list --full-path` in `pkgs/by-name/gi/gitx/ghq_fzf.go`.
2. `ghq get --clean-bare <spec>` in `posix_dev_functions.bash` (`getrepo`) and `home-manager/git.nix` (`gh burl`), both immediately followed by `gitx init-clean-bare`.

## Specification

### Part A: Native Repository Root Resolution and Listing (`ghq_fzf.go`)

#### 1. Resolving Repository Roots (`resolveRepoRoots() ([]string, error)`)

1. Check environment variable `GHQ_ROOT`:
   - If non-empty, split with `filepath.SplitList(envRoot)`, expand leading `~/` to the user's home directory, clean paths with `filepath.Clean`, and return them.
2. Otherwise, run `git config --path --get-all ghq.root` (using an isolated `gitcmd.Runner` or `exec.Command("git", "config", "--path", "--get-all", "ghq.root")`):
   - If one or more non-empty lines are returned, expand `~/` if any remain, clean paths, and return them.
3. Fallback default:
   - If `ghq.root` is not configured, return `[]string{filepath.Join(homeDir, "repos")}`.

#### 2. Listing Repositories (`listReposInRoots(roots []string) ([]string, error)`)

For each `root` in `roots`:

- If `root` does not exist on disk, skip it without error.
- Walk up to depth 3 (`<root>/<host>/<owner>/<repo>`) or up to depth 4 using `os.ReadDir`:
  - At depth 1 (`<host>`), skip hidden directories starting with `.`.
  - At depth 2 (`<owner>`), skip hidden directories starting with `.`.
  - At depth 3 (`<repo>`), check if `<root>/<host>/<owner>/<repo>/.git` exists (via `os.Stat`). If it exists, record the full path `<root>/<host>/<owner>/<repo>` and do not descend into worktree subdirectories.
- Sort and deduplicate the resulting full paths.
- Replace `runCommandLines("ghq", "root", "--all")` and `runCommandLines("ghq", "list", "--full-path")` in `collectAllWorktrees()` with `resolveRepoRoots()` and `listReposInRoots(roots)`.

### Part B: `gitx get` Subcommand (`get.go`)

Add a new subcommand:

```text
Usage: gitx get [--trust] <repo_spec>
```

#### 1. Parsing `<repo_spec>` (`resolveRepoSpec(spec, defaultUser string) (host, owner, repo, cloneURL string, err error)`)

Supported input formats for `<repo_spec>`:

1. **Full URL with scheme** (`https://github.com/owner/repo`, `https://github.com/owner/repo.git`, `http://...`, `ssh://git@github.com/owner/repo.git`, `git://github.com/owner/repo.git`):
   - Parse with `net/url.Parse`.
   - Extract `host = u.Hostname()`.
   - Trim leading/trailing `/` and `.git` suffix from `u.Path`, split into `owner` and `repo` (reject if missing owner/repo or contains extra path segments or `..`).
   - If scheme is `ssh` or `git`, preserve or normalize `cloneURL`; for `http`/`https`, set `cloneURL = fmt.Sprintf("https://%s/%s/%s.git", host, owner, repo)`.
2. **SCP-like SSH syntax** (`git@github.com:owner/repo.git` or `git@github.com:owner/repo`):
   - Extract `host` between `@` and `:`, and `owner/repo` after `:`.
   - Set `cloneURL = fmt.Sprintf("git@%s:%s/%s.git", host, owner, repo)`.
3. **Host-prefixed path** (`github.com/owner/repo` - 3 segments where the first segment contains a `.`):
   - Extract `host`, `owner`, `repo`.
   - Set `cloneURL = fmt.Sprintf("https://%s/%s/%s.git", host, owner, repo)`.
4. **Owner and repo** (`owner/repo` - 2 segments):
   - Set `host = "github.com"`, extract `owner` and `repo`.
   - Set `cloneURL = fmt.Sprintf("https://github.com/%s/%s.git", owner, repo)`.
5. **Short repo name only** (`repo` - 1 segment without `/` or `:`):
   - Require `defaultUser` (from `git config --get ghq.user`). If `defaultUser == ""`, return a clear error: `cannot resolve short repository name %q without git config ghq.user`.
   - Set `host = "github.com"`, `owner = defaultUser`, `repo = spec`.
   - Set `cloneURL = fmt.Sprintf("https://github.com/%s/%s.git", owner, repo)`.

Validation:

- Reject any `host`, `owner`, or `repo` that is empty, `"."`, `".."`, or contains path traversal.

#### 2. Cloning and Initializing (`runGet`)

1. Resolve primary root directory (first entry of `resolveRepoRoots()`).
2. Target repository container directory: `repoDir := filepath.Join(primaryRoot, host, owner, repo)`.
3. Check if `filepath.Join(repoDir, ".git")` already exists:
   - If it does **not** exist:
     - Create `repoDir` with `os.MkdirAll(repoDir, 0o755)`.
     - Run `git clone --bare <cloneURL> <repoDir>/.git` (streaming git output to `stderr` so `stdout` stays clean for the final worktree path). If clone fails, remove `repoDir` if empty and return the error.
4. Call the existing `init-clean-bare` initialization logic on `repoDir` with `--trust` if requested:
   - Configures `remote.origin.fetch = +refs/heads/*:refs/remotes/origin/*`, fetches `origin`, sets `origin/HEAD`, creates or reuses the default branch worktree, runs `direnv allow` if `--trust`, and prints the resulting worktree path to `stdout`.
   - Note: Keep `gitx init-clean-bare` working as a subcommand (or alias to the shared helper) so existing tests and manual invocations continue to work.

### Part C: Caller Updates and Dependency Removal

1. `pkgs/by-name/po/posix_dev_functions/posix_dev_functions.bash`:
   - Simplify `getrepo()` to delegate to `'@gitx@' get "$@"`:

     ```bash
     getrepo() {
     	local target_dir
     	target_dir="$('@gitx@' get "$@")" || return 1
     	if [ -n "$target_dir" ]; then
     		cd "$target_dir" || return 1
     	fi
     }
     ```

2. `pkgs/by-name/po/posix_dev_functions/package.nix`:
   - Remove `ghq = lib.getExe pkgs.ghq;`.
3. `home-manager/git.nix`:
   - In `programs.gh.settings.aliases.burl`, replace `repo_dir="$(${lib.getExe pkgs.ghq} get --clean-bare "$owner/$1")"; wt_dir="$(${gitx} init-clean-bare --trust "$repo_dir")";` with:
     `wt_dir="$(${gitx} get --trust "$owner/$1")";`
   - Keep `programs.git.settings.ghq.root = "~/repos";` and `ghq.user` in `kachick.nix` / `ephemeral.nix` because `gitx` reads `ghq.root` and `ghq.user` from Git config (and third-party tools or habits may still check it).
4. Remove `pkgs.ghq` from:
   - `pkgs/by-name/gi/gitx/package.nix` (function args, `nativeCheckInputs`, `wrapperPath`)
   - `home-manager/dev.nix` (`home.packages`)
   - `devShells.nix` (`buildInputs`)

## Target Files

- Modify: `pkgs/by-name/gi/gitx/ghq_fzf.go`
- Modify: `pkgs/by-name/gi/gitx/ghq_fzf_test.go`
- Create: `pkgs/by-name/gi/gitx/get.go`
- Create: `pkgs/by-name/gi/gitx/get_test.go`
- Modify: `pkgs/by-name/gi/gitx/init_clean_bare.go` (expose reusable initialization function if needed)
- Modify: `pkgs/by-name/gi/gitx/main.go`
- Modify: `pkgs/by-name/gi/gitx/package.nix`
- Modify: `pkgs/by-name/po/posix_dev_functions/posix_dev_functions.bash`
- Modify: `pkgs/by-name/po/posix_dev_functions/package.nix`
- Modify: `home-manager/git.nix`
- Modify: `home-manager/dev.nix`
- Modify: `devShells.nix`

## Unit Tests (`pkgs/by-name/gi/gitx/get_test.go` & `ghq_fzf_test.go`)

1. `TestResolveRepoSpec`:
   - Table-driven tests covering:
     - `"dotfiles"` with `defaultUser="kachick"` -> `github.com`, `kachick`, `dotfiles`, `https://github.com/kachick/dotfiles.git`
     - `"dotfiles"` with `defaultUser=""` -> error
     - `"kachick/dotfiles"` -> `github.com`, `kachick`, `dotfiles`, `https://github.com/kachick/dotfiles.git`
     - `"gitlab.com/owner/repo"` -> `gitlab.com`, `owner`, `repo`, `https://gitlab.com/owner/repo.git`
     - `"https://github.com/kachick/dotfiles"` and `"https://github.com/kachick/dotfiles.git"`
     - `"git@github.com:kachick/dotfiles.git"` -> `github.com`, `kachick`, `dotfiles`, `git@github.com:kachick/dotfiles.git`
     - Invalid specs (`""`, `"../evil"`, `"a/b/c/d"`) -> error
2. `TestRunGet_LocalCloneAndRepeatRun`:
   - Set `GHQ_ROOT` to `t.TempDir()`.
   - Create a local seed repository (using `file://` URL or local path helper) and run `gitx get`.
   - Verify `<root>/<host>/<owner>/<repo>/.git` is bare, `remote.origin.fetch` is configured, and the default branch worktree `<root>/<host>/<owner>/<repo>/<defaultBranch>` is checked out and printed to `stdout`.
   - Run `gitx get` a second time on the already-cloned repository and verify it succeeds cleanly and prints the worktree path.
3. `TestCollectAndGhqFzfRanking`:
   - Confirm existing tests in `ghq_fzf_test.go` pass without the `ghq` binary installed in `PATH`.

## Verification

```console
go test ./pkgs/by-name/gi/gitx/...
task fmt
task lint
```

If running with Nix store access (`BypassSandbox: true`):

```console
nix build .#gitx --no-link
task check-nixos
task test-home-session-vars
task test-shell-delegation
```
