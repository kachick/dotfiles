if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# Don't use --preview for this. It omits some columns, and this will not be changed with selected entry
rclone-list-mounted >&2

# Don't use rclone in fzf --preview, it runs query and be slow
rclone listremotes | fzf --query "$query" --border-label '☁️ Rclone Remotes' \
	--layout=reverse --height=85% --min-height=20 --border \
	--border-label-pos=2 \
	--color='header:italic:underline,label:blue' \
	--header $'Ctrl-/ (Mount) / Alt-A (Inspect)\n\n' \
	--bind 'ctrl-/:become(rclone-mount {})' \
	--bind 'alt-a:become(rclone about {})' \
	--bind 'enter:become(echo {})'
