package_file="pkgs/by-name/an/antigravity-cli/package.nix"
base_url="https://storage.googleapis.com/antigravity-public/antigravity-cli"

target_version="${1:-}"
if [[ -z "$target_version" ]]; then
	target_version="$(curl -sSfL "$base_url/latest")"
fi

current_version="$(sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$package_file")"

if [[ "$current_version" == "$target_version" ]]; then
	echo "antigravity-cli is already at: $current_version"
	exit 0
fi

echo "Updating antigravity-cli: $current_version -> $target_version"

manifest_url="$base_url/$target_version/manifest.json"
manifest="$(curl -sSfL "$manifest_url")"

latest_whole_version="$(echo "$manifest" | jq -r '.platforms."linux-x64".url' | cut -d/ -f6)"
latest_build_id="${latest_whole_version#*-}"
current_build_id="$(sed -n 's/.*buildId = "\([^"]*\)";.*/\1/p' "$package_file")"

sed -i "s/version = \"$current_version\";/version = \"$target_version\";/" "$package_file"
sed -i "s/buildId = \"$current_build_id\";/buildId = \"$latest_build_id\";/" "$package_file"

x86_64_linux_url="$(echo "$manifest" | jq -r '.platforms."linux-x64".url')"
aarch64_linux_url="$(echo "$manifest" | jq -r '.platforms."linux-arm".url')"
aarch64_darwin_url="$(echo "$manifest" | jq -r '.platforms."darwin-arm".url')"

x86_64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$x86_64_linux_url" | jq -r .hash)"
aarch64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_linux_url" | jq -r .hash)"
aarch64_darwin_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_darwin_url" | jq -r .hash)"

sed -i "/x86_64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$x86_64_linux_hash\";|" "$package_file"
sed -i "/aarch64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$aarch64_linux_hash\";|" "$package_file"
sed -i "/aarch64-darwin = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"$aarch64_darwin_hash\";|" "$package_file"

echo "antigravity-cli updated to $target_version ($latest_whole_version)"
