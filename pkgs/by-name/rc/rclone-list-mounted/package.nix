{ pkgs, ... }: pkgs.writers.writeNuBin "rclone-list-mounted" (builtins.readFile ./script.nu)
