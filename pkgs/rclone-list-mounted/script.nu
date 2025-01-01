def list-rclone-mount-includes-garbage [] {
  mount --types fuse.rclone | lines | split column ' ' | rename remote _ local _ type | select remote local | sort-by remote
}

def list-rclone-process [] {
  ps --long | where name =~ rclone and command =~ mount | select pid ppid command | insert local { |row| $row.command | parse --regex '\A\S+rclone\S+ mount \S+?: (?P<local>\S+)' | first | get local | into string }
}

list-rclone-mount-includes-garbage | join --left (list-rclone-process) local | reject command
