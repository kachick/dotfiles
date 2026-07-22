# Care these traps if you change this code
#   - Prefer git built-in features to filter as possible, handling correct regex is often hard for human
#   - grep returns false if empty, it does not fit for pipefail use. --no-run-if-empty as xargs does not exists in the grep options
#   - Always specify --sort to ensure it can be used in comm command. AFAIK, refname is most fit key here.
#     Make sure, this result should not be changed even if you changed in global git config with git.nix
#     Candidates: https://github.com/git/git/blob/3c2a3fdc388747b9eaf4a4a4f2035c1c9ddb26d0/ref-filter.c#L902-L959
git branch --sort=refname --format='%(refname:short)' --list main master trunk develop development |
	comm --check-order -13 - <(git branch --sort=refname --format='%(refname:short)' --merged) |
	xargs --no-run-if-empty --max-lines=1 git branch --delete
