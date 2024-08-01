dprint completions bash >./dependencies/dprint/completions.bash
dprint completions zsh >./dependencies/dprint/completions.zsh
dprint completions fish >./dependencies/dprint/completions.fish

git add ./dependencies/dprint
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update dprint completions' ./dependencies/dprint

goldwarden completion bash >./dependencies/goldwarden/completions.bash
goldwarden completion zsh >./dependencies/goldwarden/completions.zsh
goldwarden completion fish >./dependencies/goldwarden/completions.fish

git add ./dependencies/goldwarden
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update goldwarden completions' ./dependencies/goldwarden
