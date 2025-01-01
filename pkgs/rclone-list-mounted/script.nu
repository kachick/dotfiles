# Don't use mount command to support darwin with same implementation
ps --long | where name =~ rclone and command =~ mount | select pid ppid command | upsert command { |row| $row.command | parse --regex '\A\S+rclone\S+ mount (?<remote>\S+?:) (?P<local>\S+)' } | flatten -a | select remote local pid
