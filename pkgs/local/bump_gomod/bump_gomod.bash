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

# Find packages which depends on the root go.mod and update their vendorHash
shared_gomod_pkgs=$(nix run .#list-shared-gomod-pkgs)
sample_pkg=$(echo "$shared_gomod_pkgs" | head --lines 1)

nix-update "$sample_pkg" --version=skip --flake

new_hash=$(grep --only-matching --perl-regexp 'vendorHash = "\K[^"]+' "pkgs/local/$sample_pkg/package.nix")

for pkg in $shared_gomod_pkgs; do
	if [ "$pkg" != "$sample_pkg" ]; then
		sed -i -E 's|vendorHash = "[^"]+"|vendorHash = "'"$new_hash"'"|' "pkgs/local/$pkg/package.nix"
	fi
done

git ls-files --modified 'pkgs/**.nix' | xargs git add
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Bump vendorHash in go packages'
