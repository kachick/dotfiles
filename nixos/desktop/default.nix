{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    (import ./font.nix { inherit pkgs; })
    (import ./vm.nix { inherit pkgs; })
    ./kanata.nix
  ];

  # `wpa_cli`. I don't know what is the `wpa_gui`
  networking.wireless.userControlled.enable = true;

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/xserver.nix
  services.xserver = {
    enable = true;

    # Don't use other DM like SDDM, LightDM, lemurs for now. They don't start GNOME for now... (AFAIK)
    # And when I was using KDE, GDM only worked, SDDM didn't work
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/display-managers/gdm.nix
    displayManager.gdm.enable = true;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/display-managers/lightdm.nix
    # displayManager.lightdm.enable = false;

    desktopManager.gnome = {
      enable = true;
      # https://github.com/NixOS/nixpkgs/issues/114514
      extraGSettingsOverridePackages = [ pkgs.mutter ];
    };

    # Configure keymap in X11
    xkb = {
      layout = "us,jp"; # multiple specifier is available
      variant = "";
    };

    # Make it possible to use `localectl list-keymaps`. See https://github.com/NixOS/nixpkgs/issues/19629
    exportConfiguration = true;

    excludePackages = [ pkgs.xterm ];
  };

  services.udev.packages = with pkgs; [
    gnome-settings-daemon
    sane-airscan
  ];

  # To avoid unexpected overriding with the NixOS module. I prefer gpg-agent or another way for that.
  programs.ssh.enableAskPassword = false;

  programs = {
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/dconf.nix#L39-L42
    dconf.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-connections
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-calendar
    gnome-music # does not support flac by defaults
    gnome-terminal # It seems enabling "Open In Terminal" in Nautilus. ref: https://github.com/NixOS/nixpkgs/blob/56b033fe4f9da755b1872466f24b32df7cfc229e/pkgs/by-name/gn/gnome-terminal/package.nix#L65
    gnome-console # Newer and better than gnome-terminal, however I don't have reasons to have this than ghostty
  ];

  # I need gnome-keyring to use gnome-online-accounts even though recommended to be uninstalled by gnupg. pass-secret families didn't work on goa. See GH-1034 and GH-1036
  # https://wiki.gnupg.org/GnomeKeyring
  #
  # Require mkforce if you want to disable. See https://discourse.nixos.org/t/gpg-smartcard-for-ssh/33689/3
  services.gnome.gnome-keyring.enable = true;
  # On the otherhand, I should avoid deprecated gnome-keyring for ssh integrations even if it looks working.
  # gnome-keyring enables pam.sshAgentAuth, and it sets the $SSH_AUTH_SOCK, and following modules skips to override this variable. But just disabling security.pam.sshAgentAuth does not resolve it. It should be done in package build phase.
  # The workaround might be updated with https://github.com/NixOS/nixpkgs/issues/140824

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    mouse.naturalScrolling = true;
    touchpad.naturalScrolling = true;
  };

  services.dbus.packages = [ config.i18n.inputMethod.package ];

  services.blueman.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr2 ];
  };

  # To setup a wireless printer
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # If adding unstable packages here, you should also add it into home-manager/linux-ci.nix
  environment.systemPackages =
    (with pkgs; [
      firefox

      # https://github.com/NixOS/nixpkgs/issues/33282
      xdg-user-dirs

      # Prefer MoreWaita for consistency with Adwaita where possible
      # However, the default Adwaita has only a few icons and does not meet file manager needs such as Nautilus.
      patched.morewaita-icon-theme
      # (papirus-icon-theme.override { color = "adwaita"; }) # overriding color takes about 5 minutes

      cyme
      lshw
      pciutils # `lspci`

      # Don't use `buildFHSEnv` even through want to apply LSP smart. See GH-809
      # Don't use unstable. This package had been frequently broken the build in updating. See GH-1085 and GH-1134.
      zed-editor

      gdm-settings
      desktop-file-utils # `desktop-file-validate`

      ghostty # ghostty package now always be backported.

      alacritty

      lapce # IME is not working on Windows, but stable even around IME on Wayland than vscode

      mission-center

      # Don't use launchers such as walker which depend on gtk-layer-shell or gtk4-layer-shell. They does not support GNOME on Wayland. See https://github.com/abenz1267/walker/issues/180#issuecomment-2540630523
      wofi

      # Add LSP global for zed-editor. Prefer external package for helix
      unstable.typos-lsp
      nixd
      vscode-langservers-extracted
      # bash-language-server # Don't use, less benefit and old in nixpkgs https://github.com/NixOS/nixpkgs/issues/374172

      # gnome-music does not support flac.
      # tramhao/termusic and tsirysndr/music-player does not figure how to use.
      rhythmbox

      evtest # To debug keyremapper as GH-786
      psmisc # e.g. `fuser -v /dev/input/event17` when want to know event17 is grabbed by which process

      newsflash # `io.gitlab.news_flash.NewsFlash`

      calibre
      readest # ebook(epub) reader. Prefer this than unstable Alexandria

      dconf-editor

      podman-desktop

      # Don't use "papers" for PDF reader, which is a fork of evince, however much heavy to run rather than browsers.

      loupe # image viewer

      contrast # Check two color contrast. Also using as a color-picker

      # Clipboard
      #
      # Don't use clipcat, copyq for wayland problem
      # Dont' use cliphist for electron problem: https://www.reddit.com/r/NixOS/comments/1d57zbj/problem_with_cliphist_and_electron_apps/
      # Don't use clipse it made flickers on GNOME
      #
      # So prefer clipboard gnome extension except below tools
      #
      # Don't use `wl-clipboard-rs`, it doesn't work on GNOME.
      #   - "Error: A required Wayland protocol (zwlr_data_control_manager_v1 version 2) is not supported by the compositor"
      #   - https://github.com/YaLTeR/wl-clipboard-rs/issues/8#issuecomment-2396212342
      wl-clipboard # `wl-copy` and `wl-paste`

      # commandLineArgs is available since https://github.com/NixOS/nixpkgs/commit/6ad174a6dc07c7742fc64005265addf87ad08615
      # Prefer GUI rather than gurk-rs for now, gurk-rs update is stopped. I guess it is hard until merging https://github.com/NixOS/nixpkgs/pull/387337
      (unstable.signal-desktop.override {
        commandLineArgs = [
          "--wayland-text-input-version=3"
        ];
      })

      my.bitsnpicas

      ## Shogi packages

      # Install yaneuraou for each host with the optimized label if required
      # If installing at here, it should be "SSE2"

      # shogihome does not provide configuration schema and ENV, so manually setup the foollowing NNUE evaluation files for the engine
      # Related issue: https://github.com/sunfish-shogi/shogihome/issues/1017
      (unstable.shogihome.override {
        commandLineArgs = [
          "--wayland-text-input-version=3"
        ];
      })

      my.tanuki-hao # NNUE evaluation file. It put under /run/current-system/sw/share/eval

      ## Unfree packages

      # Don't use unstable channel since nixos-25.05. It frequently backported to stable channel
      #   - https://github.com/NixOS/nixpkgs/commits/nixos-24.11/pkgs/applications/editors/vscode/vscode.nix
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/applications/editors/vscode/generic.nix#L207-L217
      (
        (vscode.override {
          # https://wiki.archlinux.org/title/Wayland#Electron
          # https://github.com/NixOS/nixpkgs/blob/3f8b7310913d9e4805b7e20b2beabb27e333b31f/pkgs/applications/editors/vscode/generic.nix#L207-L214
          commandLineArgs = [
            "--wayland-text-input-version=3"
            # https://github.com/microsoft/vscode/blob/5655a12f6af53c80ac9a3ad085677d6724761cab/src/vs/platform/encryption/common/encryptionService.ts#L28-L71
            # https://github.com/microsoft/vscode/blob/5655a12f6af53c80ac9a3ad085677d6724761cab/src/main.ts#L244-L253
            "--password-store=gnome-libsecret" # Required for GitHub Authentication. For example gnome-keyring, kwallet5, KeepassXC, pass-secret-service
          ];
        }).overrideAttrs
        (prevAttrs: {
          # https://incipe.dev/blog/post/using-visual-studio-code-insiders-under-home-manager/#an-os-keyring-couldnt-be-identified-for-storing-the-encryption-related-data-in-your-current-desktop-environment
          runtimeDependencies = prevAttrs.runtimeDependencies ++ [ pkgs.libsecret ];
        })
      )

      # NOTE: Google might extract chrome from themself with `Antitrust` penalties
      #       https://edition.cnn.com/2024/11/20/business/google-sell-chrome-justice-department/
      #
      # Don't use chromium, it does not provide built-in cloud translations
      #
      # Don't use unstable channel. It frequently backported to stable channel
      #  - https://github.com/NixOS/nixpkgs/commits/nixos-24.11/pkgs/by-name/go/google-chrome/package.nix
      #  - Actually unstable is/was broken. See GH-776
      #
      # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
      # `rm -rf ~/.config/google-chrome/Singleton*`
      #
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/go/google-chrome/package.nix#L244-L253
      (google-chrome.override {
        # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
        # Similar as https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/chromium.nix
        commandLineArgs = [
          "--wayland-text-input-version=3"
        ];
      })

      my.chrome-with-profile-by-name

      my.ludii
    ])
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      clipboard-history
      dash-to-dock
    ]);

  # https://askubuntu.com/a/88947
  # Don't add unstable or long or waiting(interactive) CLI here such as warp-cli.
  # See GH-1110 for detail
  # environment.etc."gdm/PostLogin/Default".source = lib.getExe (
  #   pkgs.writeShellApplication {
  #   }
  # );

  environment.variables = {
    # Avoid absolute path for $EDITOR and $VISUAL to make applying easy new package with current $PATH.
    VISUAL = "${pkgs.zed-editor.meta.mainProgram} --wait";
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";

    # Avoiding hidden or unstable mouse cursors when using Alacritty on Wayland
    #
    # https://github.com/NixOS/nixpkgs/issues/22652
    # https://github.com/alacritty/alacritty/issues/6703#issuecomment-2222503206
    XCURSOR_THEME = "Adwaita";

    __HM_SESS_VARS_SOURCED = ""; # Workaround for GH-755 and GH-890
  };

  # https://github.com/NixOS/nixpkgs/issues/33282#issuecomment-523572259
  environment.etc."xdg/user-dirs.defaults".text = ''
    DESKTOP=Desktop
    DOCUMENTS=Documents
    DOWNLOAD=Downloads
    MUSIC=Music
    PICTURES=Pictures
    PUBLICSHARE=Public
    TEMPLATES=Templates
    VIDEOS=Videos
  '';

  # Require add-on for built-in Japanese translations and multiple containers. It is a disadvantage than Chrome
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/programs/firefox.nix
  programs.firefox = {
    enable = true;
    languagePacks = [
      "en-US"
      "ja"
    ];
  };

  i18n = {
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/i18n/input-method/ibus.nix
    inputMethod = {
      enable = true;
      # Don't use fcitx5. It always made systemd-coredump. See GH-1114
      type = "ibus";

      # mozc and ibus config files will be put on `$XDG_CONFIG_HOME/mozc`
      ibus.engines = with pkgs.ibus-engines; [ mozc ];
    };
  };

  # Workaround for https://discourse.nixos.org/t/unsetting-gtk-im-module-environment-variable/49331/
  # Replace with https://github.com/NixOS/nixpkgs/pull/384689 if merged to a stable channel. TODO: Update this or this config or comment since nixos-25.11
  environment.variables = {
    GTK_IM_MODULE = lib.mkForce ""; # Make better experience in FireFox even if QT_IM_MODULE cannot be updated
    QT_IM_MODULE = lib.mkForce ""; # FIXME: Did not work even through applied in /etc/set-environment, and cannot be override in home-manager systemd module.
  };

  # TODO: Consider to use headscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
  };
  # Workaround for `systemd[1]: Failed to start Network Manager Wait Online`
  # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-2541381489
  systemd.services.tailscaled.after = [ "systemd-networkd-wait-online.service" ];

  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/xdg/terminal-exec.nix
  # https://gitlab.gnome.org/GNOME/glib/-/issues/338
  #
  # NOTE:
  #   This section actually generating /etc/xdg/xdg-terminals.list, however ~/.config/xdg-terminals.list will be prefferred if exists.
  xdg.terminal-exec = {
    enable = true;
    # https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/5276
    settings = {
      default = [
        "com.mitchellh.ghostty.desktop"
        "Alacritty.desktop"
      ];
    };
  };
}
