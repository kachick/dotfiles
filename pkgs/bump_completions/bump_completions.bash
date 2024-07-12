podman completion bash >./dependencies/podman/completions.bash
podman completion zsh >./dependencies/podman/completions.zsh
podman completion fish >./dependencies/podman/completions.fish

git add ./dependencies/podman
# https://stackoverflow.com/q/34807971
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update podman completions' ./dependencies/podman

dprint completions bash >./dependencies/dprint/completions.bash
dprint completions zsh >./dependencies/dprint/completions.zsh
dprint completions fish >./dependencies/dprint/completions.fish

git add ./dependencies/dprint
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update dprint completions' ./dependencies/dprint
