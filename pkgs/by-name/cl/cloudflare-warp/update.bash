package_file="pkgs/by-name/cl/cloudflare-warp/package.nix"

target_version="${1:-}"
if [[ -z "$target_version" ]]; then
	target_version="$(
		curl --fail --silent -L ${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} \
			-H 'Accept: application/vnd.github+json' \
			-H 'X-GitHub-Api-Version: 2022-11-28' \
			'https://api.github.com/repos/cloudflare/cloudflare-docs/git/trees/production?recursive=true' |
			jq -r '[.tree[].path | select(startswith("src/content/warp-releases/linux/ga/"))] | max_by(split("/")[-1] | split(".") | map(tonumber?))' |
			rg '([^/]+)\.yaml\b' --only-matching --replace '$1'
	)"
fi

current_version="$(sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$package_file")"

if [[ "$current_version" == "$target_version" ]]; then
	echo "cloudflare-warp is already at: $current_version"
	exit 0
fi

echo "Updating cloudflare-warp: $current_version -> $target_version"

x86_64_linux_url="https://downloads.cloudflareclient.com/v1/download/noble-intel/version/$target_version"
aarch64_linux_url="https://downloads.cloudflareclient.com/v1/download/noble-arm/version/$target_version"

x86_64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$x86_64_linux_url" | jq -r .hash)"
aarch64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_linux_url" | jq -r .hash)"

sed -i "s/version = \"$current_version\";/version = \"$target_version\";/" "$package_file"

sed -i "/x86_64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$x86_64_linux_hash\";|" "$package_file"
sed -i "/aarch64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$aarch64_linux_hash\";|" "$package_file"

echo "cloudflare-warp updated to $target_version"
