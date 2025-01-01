mount --types fuse.rclone | lines | split column ' ' | rename remote _ local _ type | select remote local | sort-by remote
