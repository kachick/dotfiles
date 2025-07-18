# Definitions for each host

## Naming

TODO:

Update naming after read <https://www.natsume.co.jp/books/11126>

- <https://hosho.ees.hokudai.ac.jp/tsuyu/top/dct/moss-j.html>
- <https://www.rfc-editor.org/rfc/rfc1178>

## services.fstrim

Basically required. However ensure the `lsblk --discard` result before enabling this option.

- <https://www.reddit.com/r/NixOS/comments/rbzhb1/if_you_have_a_ssd_dont_forget_to_enable_fstrim/>
- <https://github.com/NixOS/nixos-hardware/blob/7ced9122cff2163c6a0212b8d1ec8c33a1660806/common/pc/ssd/default.nix#L4>
- <https://wiki.archlinux.org/title/Solid_state_drive>
