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
	kdl)
		# Use vim or micro to preview KDL.
		# - bat does not support KDL
		# - Helix does not have readonly mode and the KDL highlighting is not correct
		#   https://github.com/helix-editor/helix/discussions/9245
		# - micro https://github.com/kachick/micro-kdl
		# - vim https://github.com/imsnif/kdl.vim
		micro -readonly on "$path"
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
# # Support images/PDF after using sixel supported terminals for main. Alacritty isn't
# # https://github.com/alacritty/alacritty/issues/910
# 	img2sixel "$path"
# 	;;
*)
	bat --color=always "$path"
	;;
esac
