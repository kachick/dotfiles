rclone-mount() {
	local -r remote="$1" # e.g `foo:`
	local -r mount_to="$XDG_DATA_HOME/mnt/rclone/${remote%:}"

	if mountpoint -q "$mount_to"; then
		echo 'Already mounted:' >&2
		echo "$mount_to"
		return 0
	fi

	mkdir --parent "$mount_to"
	# Use `kill``, not `kill -9`. If exists the garbages in `mount --types fuse.rclone`, `fusermount -u THE_PATH`
	# See https://www.reddit.com/r/rclone/comments/nh576p/how_to_stop_an_rclone_daemon/
	rclone mount "$remote" "$mount_to" --vfs-cache-mode writes --daemon
	echo 'Mmounted to:' >&2
	echo "$mount_to"
}

rclone-mount "$@"
