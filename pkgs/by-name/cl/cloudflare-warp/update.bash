package_file="pkgs/by-name/cl/cloudflare-warp/package.nix"

target_version="${1:-}"
if [[ -z "$target_version" ]]; then
	target_version="$(
		curl --fail --silent --show-error -L ${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} \
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

url="https://downloads.cloudflareclient.com/v1/download/noble-intel/version/$target_version"
hash="$(nix store prefetch-file --json --hash-type sha256 "$url" | jq -r .hash)"

sed -i "s/version = \"$current_version\";/version = \"$target_version\";/" "$package_file"
sed -i "s|hash = \"[^\"]*\";|hash = \"$hash\";|" "$package_file"

echo "cloudflare-warp updated to $target_version"
