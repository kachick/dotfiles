# NixOS Host Definitions

This directory contains configurations for specific NixOS hosts.

---

## Host Naming Convention

A consistent naming scheme for hosts is still under consideration.

**TODO:** Revisit and decide on a naming convention.

**Inspiration and References:**

- [RFC 1178: Choosing a Name for Your Computer](https://www.rfc-editor.org/rfc/rfc1178)
- Book: 『[美しい苔の図鑑](https://www.natsume.co.jp/books/11126)』 (A Beautiful Moss Picture Book)
- Reference: [日本のコケ](https://hosho.ees.hokudai.ac.jp/tsuyu/top/dct/moss-j.html) (Mosses of Japan)

---

## `services.fstrim` on SSDs

Enabling `services.fstrim.enable` is generally recommended for systems with Solid State Drives (SSDs) to maintain performance.

However, before enabling this option, you **must** verify that your drive supports the TRIM command. You can do this by running `lsblk --discard` and checking for non-zero values in the `DISC-GRAN` and `DISC-MAX` columns.

**Further Reading:**

- [Reddit: If you have a SSD, don't forget to enable fstrim](https://www.reddit.com/r/NixOS/comments/rbzhb1/if_you_have_a_ssd_dont_forget_to_enable_fstrim/)
- [nixos-hardware: ssd/default.nix](https://github.com/NixOS/nixos-hardware/blob/master/common/pc/ssd/default.nix)
- [ArchWiki: Solid state drive](https://wiki.archlinux.org/title/Solid_state_drive)
