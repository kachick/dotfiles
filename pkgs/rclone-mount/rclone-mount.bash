rclone-mount() {
	local -r remote="$1" # e.g `foo:`
	# TODO: Return the path if already mounted the remote
	local -r mount_to="$(mktemp --tmpdir --directory "rclone.${remote%:}.XXXX")"
	# Use `kill``, not `kill -9`. If exists the garbages in `mount --types fuse.rclone`, `fusermount -u THE_PATH`
	# See https://www.reddit.com/r/rclone/comments/nh576p/how_to_stop_an_rclone_daemon/
	rclone mount "$remote" "$mount_to" --vfs-cache-mode writes --daemon
	echo "$mount_to"
}

rclone-mount "$@"
