# `modRoot` in buildGoModule did not fit for this purpose
# https://github.com/NixOS/nixpkgs/blob/086b448a5d54fd117f4dc2dee55c9f0ff461bdc1/pkgs/build-support/go/module.nix#L12-L13
for dir in "$@"; do
	cd "$dir" || exit
	go get "go@$(go version | grep -oP '(?<=go)\d\S+')"
done

git ls-files '**go.mod' '**go.sum' | xargs git add
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update go.mod and go.sum'
