path="$1"
filename=$(basename -- "$path")
extension="${filename##*.}"

case "$(file --dereference --brief --mime-type "$path")" in
text/html)
	cha "$path"
	;;
text/*)
	case "$extension" in
	md | markdown)
		renmark "$path"
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
	bat --color=always "$path"
	;;
esac
