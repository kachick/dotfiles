package_file="pkgs/by-name/an/antigravity-hub/package.nix"
manifest_base_url="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest"
download_base_url="https://storage.googleapis.com/antigravity-public/antigravity-hub"

read_manifest() {
	local manifest url
	manifest="$(curl -sSfL "${manifest_base_url}/$1.yml")"
	read -r manifest_version url < <(yq '.version + " " + .files[0].url' <<<"$manifest")
	manifest_build_id="$(cut -d/ -f6 <<<"$url" | cut -d- -f2)"
}

read_manifest latest-x64-linux
target_version="${1:-$manifest_version}"
target_build_id="$manifest_build_id"

if [[ -z "${1:-}" ]]; then
	read_manifest latest-arm64-mac
	if [[ "${manifest_version}-${manifest_build_id}" != "${target_version}-${target_build_id}" ]]; then
		echo "Linux (${target_version}-${target_build_id}) and macOS (${manifest_version}-${manifest_build_id}) releases differ, not updating" >&2
		exit 1
	fi
fi

current_version="$(sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$package_file")"
current_build_id="$(sed -n 's/.*buildId = "\([^"]*\)";.*/\1/p' "$package_file")"

if [[ "$current_version" == "$target_version" && "$current_build_id" == "$target_build_id" ]]; then
	echo "antigravity-hub is already at: $current_version ($current_build_id)"
	exit 0
fi

whole_version="${target_version}-${target_build_id}"
echo "Updating antigravity-hub: ${current_version} -> ${target_version} (${whole_version})"

sed -i "s/version = \"${current_version}\";/version = \"${target_version}\";/" "$package_file"
sed -i "s/buildId = \"${current_build_id}\";/buildId = \"${target_build_id}\";/" "$package_file"

x86_64_linux_url="${download_base_url}/${whole_version}/linux-x64/Antigravity.tar.gz"
aarch64_linux_url="${download_base_url}/${whole_version}/linux-arm/Antigravity.tar.gz"
aarch64_darwin_url="${download_base_url}/${whole_version}/darwin-arm/Antigravity.zip"

x86_64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$x86_64_linux_url" | jq -r .hash)"
aarch64_linux_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_linux_url" | jq -r .hash)"
aarch64_darwin_hash="$(nix store prefetch-file --json --hash-type sha256 "$aarch64_darwin_url" | jq -r .hash)"

sed -i "/x86_64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"${x86_64_linux_hash}\";|" "$package_file"
sed -i "/aarch64-linux = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"${aarch64_linux_hash}\";|" "$package_file"
sed -i "/aarch64-darwin = fetchurl/,/};/ s|hash = \"[^\"]*\";|hash = \"${aarch64_darwin_hash}\";|" "$package_file"

echo "antigravity-hub updated to ${target_version} (${whole_version})"
