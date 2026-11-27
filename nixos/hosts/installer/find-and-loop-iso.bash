# Mount the host partition that holds the loopback ISO passed via GRUB's
# `findiso=` parameter and attach it to a loop device so NixOS stage 1 can
# mount `/iso` by volume label.

findiso=""
read -r -a cmdline </proc/cmdline
for arg in "${cmdline[@]}"; do
	case "${arg}" in
	findiso=*)
		findiso="${arg#findiso=}"
		;;
	esac
done

# Fail closed when `findiso=` is absent or points outside an absolute path.
case "${findiso}" in
/*)
	case "${findiso}" in
	*../* | */.. | ..)
		echo "[loopback-iso-finder] Refusing unsafe findiso path: ${findiso}" >&2
		exit 1
		;;
	esac
	;;
*)
	exit 0
	;;
esac

echo "[loopback-iso-finder] Searching for ISO '${findiso}'..."

mkdir --parents /run/loopback-host

# Poll briefly so slow USB storage devices finish enumerating before giving up.
for _ in $(seq 1 15); do
	shopt -s nullglob
	devices=(/dev/sd[a-z][0-9]* /dev/nvme[0-9]*n[0-9]*p[0-9]* /dev/mmcblk[0-9]*p[0-9]*)
	shopt -u nullglob

	for dev in "${devices[@]}"; do
		[ -b "${dev}" ] || continue
		if mount --options ro "${dev}" /run/loopback-host 2>/dev/null; then
			target="/run/loopback-host${findiso}"
			if [ -f "${target}" ]; then
				echo "[loopback-iso-finder] Found ${target} on ${dev}; attaching loop device..."
				losetup --find --read-only --partscan "${target}"
				udevadm settle || true
				exit 0
			fi
			umount /run/loopback-host 2>/dev/null || true
		fi
	done

	sleep 1
done

echo "[loopback-iso-finder] Warning: Could not locate '${findiso}' after 15 seconds." >&2
exit 0
