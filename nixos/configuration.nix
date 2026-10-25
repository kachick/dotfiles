# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  lib,
  pkgs,
  outputs,
  overlays ? [ outputs.overlays.default ],
  ...
}:
{
  imports = [
    (import ./console.nix { inherit pkgs; })
    (import ./locale.nix { })
    ./nix.nix
    ./modules/allow-unfree.nix
  ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # GH-1255 for HDD
  # https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/hardware/iosched.nix
  hardware.block.defaultSchedulerRotational = "bfq";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy.example.com:8080/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # TODO: Reconsider to set UTC for servers
  time.timeZone = "Asia/Tokyo";

  nixpkgs = {
    inherit overlays;
  };

  systemd = {
    # https://github.com/NixOS/nixpkgs/blob/8e5e5a6add04c7f1e38e76f59ada6732947f1e55/nixos/doc/manual/release-notes/rl-2411.section.md?plain=1#L69-L76
    enableStrictShellChecks = true;
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/shells-environment.nix
  # The final definition will be put on /etc/set-environment
  # And you can custom it with /etc/profile.local and/or /etc/bashrc.local
  environment.variables = {
    DO_NOT_TRACK = "1";
    EDITOR = pkgs.helix.meta.mainProgram;
    SYSTEMD_EDITOR = pkgs.helix.meta.mainProgram;
  };

  # Support modern terminal definitions (e.g. xterm-ghostty, kitty, foot) globally for SSH clients
  environment.enableAllTerminfo = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = (
    with pkgs;
    [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      helix
      micro

      wget
      curl
      git
      bat
      coreutils
      findutils
      fd
      fzf
      ripgrep
      dig
    ]
  );

  ## systemd-resolved (Modern, not supported by CUPS)
  # - Check the behavior with `resolvectl status`
  # - https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/resolved.nix
  # - https://wiki.archlinux.org/title/Systemd-resolved
  # Use mkDefault to allow specialized environments (like WSL2) to opt-out
  # or avoid conflicts with their own network management.
  services.resolved = {
    enable = lib.mkDefault true;

    # - https://github.com/systemd/systemd/pull/40133
    # - https://www.freedesktop.org/software/systemd/man/latest/resolved.conf.html
    settings.Resolve = {
      LLMNR = false;
      DNSStubListener = false;
      MulticastDNS = lib.mkDefault false;
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # List services that you want to enable:

  # https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/networking/ssh/sshd.nix
  # https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/doc/manual/configuration/ssh.section.md
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.fail2ban.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # programs.nix-ld.enable = false;

  # https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/security/sudo-rs.nix
  security.sudo-rs.enable = true;
}
