{
  pkgs,
  inputs,
  outputs,
  ...
}:

{
  networking.hostName = "sandbox";

  imports = [
    inputs.microvm.nixosModules.microvm
    outputs.nixosModules.home-manager
  ];

  system.stateVersion = "26.05";

  # Allow unfree packages such as antigravity-cli
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ outputs.overlays.default ];

  microvm = {
    hypervisor = "qemu";
    mem = 4096;
    vcpu = 4;

    # Share host nix-store and repos directory
    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        proto = "9p";
        readOnly = true;
      }
      {
        tag = "repos";
        source = "/home/kachick/repos/github.com/kachick";
        mountPoint = "/home/user/repos/github.com/kachick";
        proto = "9p";
      }
    ];

    # Volatile writable overlay for /nix/store
    writableStoreOverlay = "/nix/.rw-store";

    preStart = ''
      rm -f sandbox.sock
    '';

    # Safe rootless user networking (SLiRP)
    interfaces = [
      {
        type = "user";
        id = "net0";
        mac = "02:00:00:01:01:01";
      }
    ];
  };

  # Ephemeral writable overlay for /nix/store backed by tmpfs
  fileSystems."/nix/.rw-store" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=2G"
      "mode=0755"
    ];
    neededForBoot = true;
  };

  # Ensure user state directories exist in tmpfs before home-manager activation
  systemd.tmpfiles.rules = [
    "d /home/user/.local/state/nix/profiles 0755 user users -"
    "d /home/user/.local/state/home-manager/gcroots 0755 user users -"
  ];

  # Autologin to user on serial console after home-manager finishes setup
  services.getty.autologinUser = "user";
  systemd.services."serial-getty@ttyS0" = {
    after = [ "home-manager-user.service" ];
    wants = [ "home-manager-user.service" ];
  };

  # Ensure user account with UID 1000 matching host kachick
  users.users.user = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  # Suppress zsh-newuser-install wizard and export ZDOTDIR for instant shell readiness
  programs.zsh = {
    enable = true;
    shellInit = ''
      zsh-newuser-install() { :; }
    '';
  };
  environment.etc."zshenv".text = ''
    export ZDOTDIR="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  '';

  # Include antigravity-cli (agy) in system packages
  environment.systemPackages = [
    pkgs.local.antigravity-cli
    pkgs.git
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.user = {
      imports = [
        ../../../home-manager/ephemeral.nix
      ];
    };
    extraSpecialArgs = {
      inherit pkgs;
    };
  };
}
