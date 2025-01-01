if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

rclone-mount() {
	local -r remote="$1" # e.g `foo:`
	local -r mount_to="$(mktemp --tmpdir --directory "rclone.${remote%:}.XXXX")"
	rclone mount "$remote" "$mount_to" --vfs-cache-mode writes --daemon
	echo "$mount_to"
}

export -f rclone-mount

# Don't use rclone in fzf --preview, it runs query and be slow
rclone listremotes | fzf --query "$query" --border-label '☁️ Rclone Remotes' \
	--header $'Alt-M (Mount) / Alt-A (Inspect)\n\n' \
	--bind 'alt-m:become(rclone-mount {})' \
	--bind 'alt-a:become(rclone about {})' \
	--bind 'enter:become(echo {})'
