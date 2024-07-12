archive_basename="$1"
# * Basically used in container for backup use, so keep fixed file name for the archive
# * Specify the subdir of hm-gen/home-files, the dereference and recursive from generation root doesn't end
tar --create --file="${archive_basename}.tar.gz" --auto-compress --dereference --recursive --verify \
	--directory="$(home-manager generations | rg 'id \d+ -> /nix/store' | head -n1 | cut -d ' ' -f 7)/home-files" .
