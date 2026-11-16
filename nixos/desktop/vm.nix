# This file defines GUI VM management on NixOS desktop. See also home-manager/vm-host.nix

{ pkgs, ... }:
{
  # Why not other candidates?
  #
  # * quickemu: Having another definitions and release cycle than osinfo-db. And seems not actively maintained in these days.

  programs.virt-manager.enable = true;

  services.cockpit.plugins = with pkgs; [
    cockpit-machines
  ];

  # Allow libvirt-dbus service to access libvirtd without interactive polkit agent
  users.users.libvirtdbus.extraGroups = [ "libvirtd" ];
  systemd.services.libvirt-dbus.serviceConfig.SupplementaryGroups = [ "libvirtd" ];
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" && subject.user == "libvirtdbus") {
        return polkit.Result.YES;
      }
    });
  '';

  virtualisation.libvirtd = {
    enable = true;
    dbus.enable = true;
    qemu.swtpm.enable = true;
  };

  virtualisation.spiceUSBRedirection.enable = true;

  # Expose host systemd-resolved on a non-53 loopback port for user-mode VM guests.
  #
  # WHY not port 53 or hypervisor user-mode DNS relays:
  # SLiRP reads only the first nameserver in host /etc/resolv.conf, so an inactive VPN
  # entry at the top makes guest DNS time out even when the host resolves names normally.
  # libslirp also intercepts guest traffic to gateway port 53 and redirects it to that
  # same broken upstream, so port 5354 avoids SLiRP hijacking while keeping existing
  # DNSStubListener=false mDNS and Tailscale behavior intact.
  services.resolved.settings.Resolve.DNSStubListenerExtra = "127.0.0.1:5354";

  environment.systemPackages = with pkgs; [
    # Ensure existing qemu-img with lima for use of systemd.
    # Because of lima might be started with systemd, and then the Nix wrapped qemu PATH will be ignored.
    # See GH-1049 for details.
    qemu

    # Enable swtpm for user session libvirt/QEMU (e.g. virt-manager, gnome-boxes, cockpit-machines)
    # virtualisation.libvirtd.qemu.swtpm.enable only adds it to system-level libvirtd.service PATH
    swtpm

    # Use latest to apply latest osinfo-db such as https://github.com/nixos/nixpkgs/pull/414620
    # It is the actual OS information for the VM, upstream is https://gitlab.com/libosinfo/osinfo-db
    gnome-boxes
  ];
}
