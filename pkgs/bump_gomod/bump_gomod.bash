working_dir="$PWD"
# `modRoot` in buildGoModule did not fit for this purpose
# https://github.com/NixOS/nixpkgs/blob/086b448a5d54fd117f4dc2dee55c9f0ff461bdc1/pkgs/build-support/go/module.nix#L12-L13
for dir in "$@"; do
	cd "$dir" || exit
	go get "go@$(go version | grep -oP '(?<=go)\d\S+')"
	cd "$working_dir" || exit
done

git ls-files '**go.mod' '**go.sum' | xargs git add
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update go.mod and go.sum'

# See https://github.com/kachick/dotfiles/issues/1174
# This logics might be extracted. Put at here is my laziness
nix-update git-hooks-commit-msg --version=skip --flake
nix-update git-hooks-pre-push --version=skip --flake
nix-update reponame --version=skip --flake
nix-update run_local_hook --version=skip --flake
git ls-files --modified 'pkgs/**.nix' | xargs git add
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Bump vendorHash in go packages'
