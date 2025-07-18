profile_name="$1"
shift

# I got the path from https://superuser.com/a/1663491/120469
get_profile_id_by_name() {
	jq --arg profile_name "$profile_name" -r '.profile.info_cache | to_entries | .[] | select(.value.name == $profile_name) | .key' "$XDG_CONFIG_HOME/google-chrome/Local State"
}

google-chrome-stable "--profile-directory=$(get_profile_id_by_name)" "$@"
