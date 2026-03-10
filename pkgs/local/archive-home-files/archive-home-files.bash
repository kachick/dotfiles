if [ $# -eq 0 ]; then
	echo "Usage: archive-home-files <archive_basename>"
	exit 1
fi

archive_basename="$1"
home_files_path="$(home-manager generations | rg 'id \d+ -> /nix/store' | head -n1 | cut -d ' ' -f 7)/home-files"

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
