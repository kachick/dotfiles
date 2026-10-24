# This file defines GUI VM management on NixOS desktop. See also lima related files in home-manager

{ pkgs, ... }:
{
  # Why not other candidates?
  #
  # * quickemu: Having another definitions and release cycle than osinfo-db. And seems not actively maintained in these days.

  programs.virt-manager.enable = true;

  services.cockpit = {
    enable = true;
    plugins = with pkgs; [
      cockpit-machines
    ];
  };

  users.groups.libvirtd.members = [ "kachick" ];

  virtualisation.libvirtd = {
    enable = true;
    dbus.enable = true;
  };

  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    # Ensure existing qemu-img with lima for use of systemd.
    # Because of lima might be started with systemd, and then the Nix wrapped qemu PATH will be ignored.
    # See GH-1049 for details.
    qemu

    # Use latest to apply latest osinfo-db such as https://github.com/nixos/nixpkgs/pull/414620
    # It is the actual OS information for the VM, upstream is https://gitlab.com/libosinfo/osinfo-db
    unstable.gnome-boxes
  ];
}
