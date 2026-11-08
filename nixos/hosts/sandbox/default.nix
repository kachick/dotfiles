{
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:

{
  networking.hostName = "sandbox";

  imports = [
    inputs.microvm.nixosModules.microvm
    outputs.nixosModules.dev-headless
  ];

  system.stateVersion = "26.05";

  # Quiet kernel and initrd boot logs for fast startup
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "systemd.show_status=auto"
  ];

  # Disable background daemons not needed in ephemeral sandbox
  services.fail2ban.enable = false;
  services.openssh.enable = false;
  services.logrotate.enable = false;

  # Auto-optimise store does not work with writableStoreOverlay
  nix.optimise.automatic = lib.mkForce false;
  nix.settings.auto-optimise-store = lib.mkForce false;

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

    # Avoid dropping socket files into current working directory
    socket = null;

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

  # Autologin directly to user on serial console after home-manager finishes setup
  systemd.services."serial-getty@" = {
    after = [ "home-manager-user.service" ];
    wants = [ "home-manager-user.service" ];
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.util-linux}/sbin/agetty --autologin user --noclear --keep-baud 115200,38400,9600 - linux"
      ];
    };
  };

  # Ensure user state directories exist and owned by user before home-manager activation script runs
  # The '+' prefix runs commands with full root privileges even when Service.User is 'user'.
  systemd.services."home-manager-user".serviceConfig = {
    ExecStartPre = [
      "+${pkgs.coreutils}/bin/mkdir -p /home/user/.local/state/nix/profiles /home/user/.local/state/home-manager/gcroots /home/user/repos"
      "+${pkgs.coreutils}/bin/chown user:users /home/user /home/user/repos"
      "+${pkgs.coreutils}/bin/chown -R user:users /home/user/.local"
    ];
    StandardOutput = "journal+console";
    StandardError = "journal+console";
  };

  # Ensure user account with UID 1000 matching host kachick
  users.users.user = {
    isNormalUser = true;
    createHome = true;
    home = "/home/user";
    uid = 1000;
    extraGroups = [ "wheel" ];
    password = "";
    shell = pkgs.zsh;
  };

  security.sudo.enable = lib.mkForce false;
  security.sudo-rs = {
    enable = lib.mkForce true;
    wheelNeedsPassword = false;
  };
  security.pam.services.login.allowNullPassword = true;

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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.user = {
      imports = [
        outputs.homeManagerModules.ephemeral
        outputs.homeManagerModules.dev
        outputs.homeManagerModules.containers
        outputs.homeManagerModules.storage
        ({ ... }: {
          # The host repos mount creates /home/user/repos before HM activation.
          # Disable repos/.keep to avoid permission errors when managing repos directory.
          home.file."repos/.keep".enable = false;

          # Disable 9p-slow compinit in sandbox for instant shell startup
          programs.zsh.enableCompletion = lib.mkForce false;
        })
      ];
    };
    extraSpecialArgs = {
      inherit pkgs outputs;
    };
  };
}
