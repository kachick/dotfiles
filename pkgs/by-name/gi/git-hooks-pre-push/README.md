# git-hooks-pre-push

A helper command for Git 2.54+ config based hooks (`git hook`). It checks git commits and branch names before pushing.

## Subcommands

- `betterleaks`: Scan commit logs and diffs for secrets.
- `typos-commits`: Scan commit logs and diffs for typos.
- `typos-branch`: Check branch names for typos.

## Why Not Skip Single Commits in the Hook

This hook does not support skipping a single commit by revision flag or environment variable.

- **Silent Leaks Are the Worst Risk**:
  A false positive blocks a push, but a false negative leaks secrets.
  Parsing revisions and excluding commits inside the hook adds complexity. Bugs in revision filtering or tool options (such as `--no-walk`) could let secrets pass quietly.
- **Merge Commit Diff Quirks**:
  Tools like `git log --no-walk` do not show diffs for merge commits by default. Handling merge commits correctly in custom hook code is easy to get wrong.
- **Keep Hooks Simple**:
  Hooks should stay simple, fast, and hard to break.

## How to Skip a Hook for a Single Push

Hooks are split in Git config so each check can be toggled without disabling all hooks:

```console
# Skip typo checks for one push (betterleaks still runs)
git -c hook.pre-push-no-typos-in-commits.enabled=false push
```

## How to Skip a Hook for Only One Commit

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
