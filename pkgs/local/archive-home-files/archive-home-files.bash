if [ $# -eq 0 ]; then
	echo "Usage: archive-home-files <archive_basename>"
	exit 1
fi

archive_basename="$1"

# Try to find the home-manager profile path without relying on the 'home-manager' command.
# 1. Standard modern path
# 2. Legacy/User profile path
# 3. Fallback to 'home-manager' command if available in PATH
if [ -L "$HOME/.local/state/nix/profiles/home-manager" ]; then
	hm_generation_path=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager")
elif [ -L "$HOME/.nix-profile" ] && [ -d "$(readlink -f "$HOME/.nix-profile")/home-files" ]; then
	hm_generation_path=$(readlink -f "$HOME/.nix-profile")
elif command -v home-manager >/dev/null 2>&1; then
	hm_generation_path=$(home-manager generations | rg 'id \d+ -> /nix/store' | head -n1 | cut -d ' ' -f 7)
else
	echo "Error: Could not find home-manager profile at ~/.local/state/nix/profiles/home-manager or ~/.nix-profile"
	echo "Ensure you have successfully run 'home-manager switch' at least once."
	exit 1
fi

home_files_path="${hm_generation_path}/home-files"

if [ ! -d "$home_files_path" ]; then
	echo "Error: Home files path not found: $home_files_path"
	exit 1
fi

echo "Running gitleaks check on $home_files_path..."
gitleaks detect --source "$home_files_path" --config "$GITLEAKS_CONFIG" --follow-symlinks --verbose --redact=100

echo "Creating tarball..."
tar --create --file="${archive_basename}.tar.gz" --auto-compress --dereference --recursive \
	--directory="$home_files_path" .

echo "Encrypting with age using all recipients..."
age "${AGE_RECIPIENTS_ARGS[@]}" --output "${archive_basename}.tar.gz.age" "${archive_basename}.tar.gz"
rm "${archive_basename}.tar.gz"

echo "Successfully created encrypted archive: ${archive_basename}.tar.gz.age"
