if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

rclone-mount() {
	local -r remote="$1" # e.g `foo:`
	# TODO: Return the path if already mounted the remote
	local -r mount_to="$(mktemp --tmpdir --directory "rclone.${remote%:}.XXXX")"
	# Use `kill``, not `kill -9`. If exists the garbages in `mount --types fuse.rclone`, `fusermount -u THE_PATH`
	# See https://www.reddit.com/r/rclone/comments/nh576p/how_to_stop_an_rclone_daemon/
	rclone mount "$remote" "$mount_to" --vfs-cache-mode writes --daemon
	echo "$mount_to"
}

export -f rclone-mount

# Don't use rclone in fzf --preview, it runs query and be slow
rclone listremotes | fzf --query "$query" --border-label '☁️ Rclone Remotes' \
	--layout=reverse --multi --height=85% --min-height=20 --border \
	--border-label-pos=2 \
	--color='header:italic:underline,label:blue' \
	--header $'Alt-M (Mount) / Alt-A (Inspect)\n\n' \
	--preview 'rclone-list-mounted' \
	--bind 'alt-m:become(rclone-mount {})' \
	--bind 'alt-a:become(rclone about {})' \
	--bind 'enter:become(echo {})'
