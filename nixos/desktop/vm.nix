# This file defines GUI VM management on NixOS desktop. See also lima related files in home-manager

{ pkgs, ... }:
{
  # Why not other candidates?
  #
  # * cockpit: Might be the primary candidate if cockpit-machines is also available. ref: https://github.com/NixOS/nixpkgs/issues/287644
  # * quickemu: Having another definitions and release cycle than osinfo-db. And seems not actively maintained in these days.

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "kachick" ];

  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    # Ensure existing qemu-img with lima for use of systemd.
    # Because of lima might be started with systemd, and then the Nix wrapped qemu PATH will be ignored.
    # See GH-1049 for detail.
    qemu

    # Use latest to apply latest osinfo-db such as https://github.com/nixos/nixpkgs/pull/414620
    # It is the actual OS information for the VM, upstream is https://gitlab.com/libosinfo/osinfo-db
    unstable.gnome-boxes
  ];
}
