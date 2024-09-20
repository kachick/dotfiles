path="$1"
filename=$(basename -- "$path")
extension="${filename##*.}"

IFS='; ' read -r -a mime <<<"$(file --dereference --brief --mime "$path")"

case "${mime[0]}" in
text/html)
	cha "$path"
	;;
text/*)
	case "$extension" in
	md | markdown)
		mdcat "$path"
		;;
	*)
		bat --color=always "$path"
		;;
	esac
	;;
inode/directory)
	la "$path"
	;;
application/x-executable)
	hexyl "$path"
	;;
# image/*)
# # TODO: Support images/PDF after using sixel supported terminals for main. Alacritty isn't
# # https://github.com/alacritty/alacritty/issues/910
# 	img2sixel "$path"
# 	;;
*)
	case "${mime[1]}" in
	charset=binary)
		hexyl "$path"
		;;
	*)
		bat --color=always "$path"
		;;
	esac
	;;
esac
