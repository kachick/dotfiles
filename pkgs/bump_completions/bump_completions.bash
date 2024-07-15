dprint completions bash >./dependencies/dprint/completions.bash
dprint completions zsh >./dependencies/dprint/completions.zsh
dprint completions fish >./dependencies/dprint/completions.fish

git add ./dependencies/dprint
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update dprint completions' ./dependencies/dprint
