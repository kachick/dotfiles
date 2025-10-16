if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# - Don't use rclone in fzf --preview, it runs query and be slow
filen-rclone listremotes | fzf --query "$query" --border-label '☁️ Filen Rclone Remotes' \
	--layout=reverse --height=85% --min-height=20 --border \
	--border-label-pos=2 \
	--color='header:italic:underline,label:blue' \
	--header $'Ctrl-/ (Mount) / Alt-A (Inspect)\n\n' \
	--bind 'ctrl-/:become(filen-rclone-mount {})' \
	--bind 'alt-a:become(filen-rclone about {})' \
	--bind 'enter:become(echo {})'
