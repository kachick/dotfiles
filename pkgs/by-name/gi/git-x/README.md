# git-x

Unified CLI combining local Git and GitHub helper subcommands.

## Architecture & Entry Points

```mermaid
flowchart LR
    subgraph Shell ["Shell Functions & Keybinds (posix_dev_functions / dev.nix)"]
        repo_fn["repo (Alt-R)"]
        wt_fn["wt"]
        gx_fn["gx (Ctrl-G)"]
        gch["gch"]
    end

    subgraph Aliases ["Git Aliases (home-manager/git.nix)"]
        git_x["git x <subcommand>"]
        git_all["git all"]
        git_lf["git lf"]
    end

    subgraph Hooks ["Git 2.54+ Config Hooks"]
        pre_push["pre-push"]
    end

    subgraph Subcommands ["git-x Subcommands"]
        subgraph Launcher ["Interactive Launcher"]
            cmd_menu["menu"]
        end

        subgraph Repo ["Repository & Clean-Bare Layout"]
            cmd_get["get"]
            cmd_sprout["sprout"]
            cmd_init["init-clean-bare"]
            cmd_migrate["migrate-clean-bare"]
            cmd_repofzf["repo-fzf"]
            cmd_reponame["gh-reponame"]
        end

        subgraph Worktree ["Worktree & Branch Lifecycle"]
            cmd_wt["wt"]
            cmd_refresh["refresh"]
            cmd_dmb["delete-merged-branches"]
            cmd_reset["reset-branch"]
        end

        subgraph Review ["Log, Translation & Conflict"]
            cmd_logfzf["log-fzf"]
            cmd_show["show"]
            cmd_conflict["resolve-conflict"]
            cmd_hist["commit-from-history"]
        end

        subgraph HookCmd ["Hook Runner"]
            cmd_hooks["hooks pre-push"]
        end
    end

    subgraph External ["External Tools & Services"]
        ext_git["git / internal/gitcmd"]
        ext_tui["fzf / gum / eza"]
        ext_diff["riff / bat / rg / hx"]
        ext_gh["gh (GraphQL / browse)"]
        ext_plamo["llama-server (PLaMo-3)"]
        ext_lint["betterleaks / typos"]
    end

    repo_fn --> cmd_reponame
    repo_fn --> cmd_repofzf
    repo_fn -->|"repo get"| cmd_get
    wt_fn -->|"wt _cd-helper"| cmd_wt
    gx_fn --> cmd_menu
    gch --> cmd_hist

    git_x --> Subcommands
    git_all --> cmd_refresh
    git_all --> cmd_dmb
    git_lf --> cmd_logfzf
    pre_push --> cmd_hooks

    cmd_menu -->|"^W / ^B / ^L / ^T / ^R / ^X"| ext_tui
    cmd_menu --> cmd_wt
    cmd_menu --> cmd_repofzf
    cmd_menu --> cmd_refresh
    cmd_menu --> cmd_dmb
    cmd_sprout --> cmd_get
    cmd_sprout --> ext_gh
    cmd_get -->|"git clone --bare"| cmd_init
    cmd_wt -->|"ctrl-l"| cmd_logfzf
    cmd_logfzf -->|"--ja"| cmd_show

    Repo --> ext_git
    Worktree --> ext_git
    cmd_repofzf --> ext_tui
    cmd_wt --> ext_tui
    cmd_migrate --> ext_tui
    cmd_dmb -->|"--pr"| ext_gh
    cmd_logfzf --> ext_tui
    cmd_logfzf --> ext_diff
    cmd_logfzf --> ext_gh
    cmd_show --> ext_diff
    cmd_show -->|"--ja"| ext_plamo
    cmd_conflict --> ext_diff
    cmd_hist --> ext_tui
    cmd_hooks --> ext_lint
```

## Subcommands

| Category            | Subcommand                                                         | Caller / Alias                            | Purpose                                                                                           |
| ------------------- | ------------------------------------------------------------------ | ----------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Launcher            | `menu [--mode <view>] [query]`                                     | `gx`, `Ctrl-G`                            | Single-entry `fzf`/`gum` launcher switching across worktrees, branches, commits, tags, repos      |
| Repository & Layout | `get [--trust] <spec>`                                             | `repo get`, `git x sprout`                | Clone into `<root>/<host>/<owner>/<repo>/.git` and initialize the default worktree                |
| Repository & Layout | `sprout <repo>`                                                    | `git x sprout`                            | Create a private template repo on GitHub, clone in clean-bare layout, and enable auto-merge       |
| Repository & Layout | `init-clean-bare [--trust] <dir>`                                  | `git x init-clean-bare`, `git x get`      | Configure origin fetch refspec and create the default branch worktree                             |
| Repository & Layout | `migrate-clean-bare [--dry-run] [--trust] [--interactive] [<dir>]` | `git x migrate-clean-bare`                | Convert a standard Git repository into clean-bare layout in place                                 |
| Repository & Layout | `repo-fzf [--list] [query]`                                        | `repo`, `Alt-R`                           | List worktrees under `GIT_X_ROOT` or `git-x.root` (`~/repos`) and select via `fzf`                |
| Repository & Layout | `gh-reponame`                                                      | `repo`                                    | Extract repository name from `OWNER/REPO` or GitHub URL on stdin                                  |
| Worktree & Branch   | `wt [list\|select\|add\|pr\|promote\|path]`                        | `wt`, `git x wt`                          | Manage flat depth-1 worktrees (`/` in branch names replaced with `-`)                             |
| Worktree & Branch   | `refresh`                                                          | `git x refresh`, `git all`                | Update `upstream` or `origin` and fast-forward the default branch                                 |
| Worktree & Branch   | `delete-merged-branches [--dry-run] [--pr]`                        | `git x delete-merged-branches`, `git all` | Remove merged local branches and clean worktrees (`--pr` checks merged GitHub PRs)                |
| Worktree & Branch   | `reset-branch [--remote <name>] [--dry-run] [branch]`              | `git x reset-branch`                      | Rename local branch to `backup-<branch>-<uuid>` and recreate it from remote                       |
| Log & Review        | `show [--ja] [git-show-args...]`                                   | `git x show`, `git x log-fzf`             | Run `git show` through `riff` (`--ja` injects Japanese translation via local `llama-server`)      |
| Log & Review        | `log-fzf [--ja] [query]`                                           | `git lf`                                  | Search `git log` in `fzf` with `riff`/`bat` preview, `Alt-J` translation toggle, and `Alt-F` zoom |
| Log & Review        | `resolve-conflict`                                                 | `git x resolve-conflict`                  | Find `<<<<<< HEAD` markers in unmerged files with `rg` and open them in Helix (`hx --hsplit`)     |
| Log & Review        | `commit-from-history`                                              | `gch`                                     | Pick a shell history line via `fzf` and commit all changes with `` `<command>` ``                 |
| Hooks               | `hooks pre-push <subcommand>`                                      | Git `hook.*` config                       | Run `betterleaks`, `typos-commits`, or `typos-branch` before pushing                              |
| Shell               | `completion <bash\|zsh>`                                           | Nix `installShellCompletion` (`git-x`)    | Print shell completion wrappers backed by `git-x __complete`                                      |

## Clean-Bare Worktree Layout & Lifecycle

`git-x` organizes repositories in a clean-bare layout where `.git` holds the bare repository and every branch lives in a flat sibling directory at depth 1 (`feat/foo` becomes `feat-foo`).

Commands that return a directory path (`menu`, `get`, `sprout`, `init-clean-bare`, `migrate-clean-bare`, `repo-fzf`, `wt add`, `wt select`, `wt path`) send all Git progress and TUI prompts to `stderr` so `stdout` only prints the target path for shell `cd` wrappers.

```mermaid
flowchart TD
    subgraph Layout ["<root>/<host>/<owner>/<repo>/"]
        bare[".git/ (bare repository)"]
        wt_main["main/ (default branch worktree)"]
        wt_feat["feat-topic/ (feature worktree)"]
    end

    clone["git x get <spec>"] -->|"git clone --bare"| bare
    std["Standard Repo (.git/ + working files)"] -->|"git x migrate-clean-bare"| bare
    bare -->|"git x init-clean-bare"| wt_main
    bare -->|"git x wt add / wt select"| wt_feat
    wt_main -->|"git x refresh"| wt_main
    wt_feat -->|"git x delete-merged-branches [--pr]"| prune["Remove clean worktree & branch"]
```

## `git x log-fzf` Asynchronous Translation Flow

`log-fzf` starts with plain preview by default (`--ja` starts with translation on). Pressing `Alt-J` toggles Japanese translation on or off inside the same `fzf` session without losing the cursor position or query, pressing `Alt-F` toggles a larger preview pane (`down,80%`) while keeping the `fzf` list visible, and pressing `Enter` prints the selected log line(s). When the preview pane is wide enough (100+ columns), the original commit message and Japanese translation are shown side by side above the diff. While translation is on, a background worker watches the focused commit in `fzf`, translates it first, prefetches adjacent commits, and tells `fzf` to refresh its preview over a Unix socket. Translated commit messages are cached under `$XDG_CACHE_HOME/git-x/translations/` (shared with `git x show --ja`), so previously translated commits render right away across sessions.

```mermaid
sequenceDiagram
    participant User
    participant FZF as fzf (--listen fzf.sock)
    participant Preview as git x log-fzf _preview
    participant Cache as Temp Cache Dir
    participant Worker as Background Worker
    participant Show as git x show --ja
    participant Plamo as llama-server (127.0.0.1:18080)

    User->>FZF: Move cursor to commit <rev>
    FZF->>Preview: Run preview for <rev>
    Preview->>Cache: Write <rev> to current_focus
    alt Cached (<rev>.out exists)
        Preview->>FZF: Print cached ANSI output
    else Not cached yet
        Preview->>Show: Render with placeholder
        Show->>FZF: Print diff + placeholder via riff & bat
    end

    loop Every 30ms (after 100ms debounce)
        Worker->>Cache: Read current_focus
        Worker->>Show: Translate focused <rev> (then prefetch neighbors)
        Show->>Plamo: POST /v1/chat/completions (commit msg + changed file names)
        Plamo-->>Show: Japanese translation
        Show->>Cache: Write <rev>.out
        Worker->>FZF: POST "refresh-preview" to fzf.sock
        FZF->>Preview: Re-run preview for <rev>
        Preview->>Cache: Read <rev>.out
        Preview->>FZF: Print translated commit + diff
    end
```

## `git x hooks pre-push`

A helper command for Git 2.54+ config based hooks (`git hook`). It checks git commits and branch names before pushing.

### Subcommands

- `betterleaks`: Scan commit logs and diffs for secrets.
- `typos-commits`: Scan commit logs and diffs for typos.
- `typos-branch`: Check branch names for typos.

### Why Not Skip Single Commits in the Hook

This hook does not support skipping a single commit by revision flag or environment variable:

- Parsing revisions and excluding commits inside the hook adds complexity. Bugs in revision filtering or tool options (such as `--no-walk`) could let secrets pass quietly.
- Tools like `git log --no-walk` do not show diffs for merge commits by default. Handling merge commits in custom hook code is easy to get wrong.

### How to Skip a Hook for a Single Push

Hooks are split in Git config so each check can be toggled without disabling all hooks:

```console
# Skip typo checks for one push (betterleaks still runs)
git -c hook.pre-push-no-typos-in-commits.enabled=false push
```

### How to Skip a Hook for Only One Commit

If you have multiple commits to push (e.g., `A -> B -> C`) and only commit `B` has a false positive:
Push commits one by one with Git refspecs:

```console
# 1. Push commit A with all checks
git push origin <commit-A>:my-branch

# 2. Push commit B while skipping typo checks (betterleaks still checks B)
git -c hook.pre-push-no-typos-in-commits.enabled=false push origin <commit-B>:my-branch

# 3. Push remaining commit C with all checks
git push origin HEAD:my-branch
```

This uses standard Git features without risk of silent check failures.
