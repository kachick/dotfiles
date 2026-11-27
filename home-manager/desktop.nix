{
  lib,
  pkgs,
  config,
  ...
}:

let
  # It should be ordered with IME support.
  plainTextEditor = [
    "org.gnome.TextEditor.desktop"
  ]
  ++ codeEditor;

  codeEditor = [
    "dev.zed.Zed.desktop"
    "code.desktop"
    "Helix.desktop"
  ];

  webBrowser = [
    "google-chrome.desktop"
    "firefox.desktop"
  ];

  # I prefer using a PDF reader over an PDF editor, which I use infrequently. Native readers like Papers are also heavier than browsers.
  # This list is not the same as the `webBrowser` list. The order matters; Firefox is preferred for its speed.
  pdfReader = [
    "firefox.desktop"
    # Chrome is heavy when open large PDF files
    "google-chrome.desktop"

    "org.gnome.Papers.desktop"
  ];

  terminalEmulator = [
    "com.mitchellh.ghostty.desktop"
    "Alacritty.desktop"
  ];

  # Loupe is faster than browsers to open images, and can simply edit
  imageViewer = [
    # https://gitlab.gnome.org/GNOME/loupe/-/blob/47.2/data/meson.build#L54
    "org.gnome.Loupe.desktop"
  ]
  ++ webBrowser;
in
{
  imports = [
    ./gnome.nix
    ./terminal.nix
  ];

  xdg = {
    # How to get the mimetype: `xdg-mime query filetype path`
    #
    # https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/xdg-mime-apps.nix - different of  https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/xdg/mime.nix
    mimeApps = rec {
      enable = true;
      # Don't use `xdg-settings set default-web-browser`.
      # https://github.com/nix-community/home-manager/issues/96#issuecomment-343650659 is old. Using both made errors such as https://github.com/kachick/dotfiles/pull/1038#discussion_r1910360832
      # So use only xdg.mimeApps
      associations.added =
        (lib.genAttrs [
          "text/plain"
          "text/markdown"
          "application/x-cue"
        ] (lib.const plainTextEditor))

        //

          (lib.genAttrs [
            "application/x-shellscript"
            "text/x-nix" # *.nix is handled as text/plain for now
            "application/x-nix"
            "text/rust"
            "text/x-go"
            "application/x-go"
            "text/javascript"
            "text/x-typescript" # *.ts is handled as text/vnd.trolltech.linguist for now. See https://stackoverflow.com/questions/14230396/ts-files-always-get-recognized-as-text-vnd-trolltech-linguist-and-never-as-vide
            "text/x-ruby"
            "application/x-ruby"
            "text/json"
            "application/json"
            "text/x-yaml"
            "text/x-toml"
            "text/x-perl"
            "text/x-python"
            "text/x-c"
            "text/x-c++"
            "text/x-makefile"
            "application/xml"
          ] (lib.const codeEditor))

        //

          (lib.genAttrs [
            "text/html"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "x-scheme-handler/about"
            "x-scheme-handler/unknown"
          ] (lib.const webBrowser))

        //

          (lib.genAttrs [
            "application/pdf"
          ] (lib.const pdfReader))

        //

          (lib.genAttrs [
            "application/x-terminal-emulator"
            "x-scheme-handler/terminal"
          ] (lib.const terminalEmulator))

        //

          (lib.genAttrs [
            # Supported mime-types: https://gitlab.gnome.org/GNOME/loupe/-/blob/47.2/data/meson.build

            "image/jpeg"
            "image/png"
            "image/gif"
            "image/webp"
            "image/tiff"
            "image/bmp"
            "image/vnd.microsoft.icon"
            "image/svg+xml"
            "image/svg+xml-compressed"
          ] (lib.const imageViewer));

      defaultApplications = associations.added;
    };
  };

  services.tailscale-systray = {
    enable = true;
  };

  xdg.configFile."kanata/kanata.kbd".source = ../config/keyboards/kanata.kbd;
  xdg.configFile."kanata-tray/kanata-tray.toml".source = ../config/keyboards/kanata-tray.toml;

  xdg.cacheFile."kanata-tray/.keep".text =
    "kanata-tray exits if the specified directory does not exist";

  # xdg.userDirs creates GUI folders like ~/Desktop and ~/Music.
  # Keep this in desktop.nix because CUI environments (VPS, containers) do not need them.
  #
  # xdg-user-dirs NixOS module does not work or is not enough for me to keep English dirs even in Japanese locale.
  # Check your `~/.config/user-dirs.dirs` if you faced any trouble
  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/xdg-user-dirs.nix
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # https://github.com/NixOS/nixpkgs/issues/222925#issuecomment-1514112861
  xdg.configFile."autostart/userdirs.desktop".text = ''
    [Desktop Entry]
    Exec=xdg-user-dirs-update
    TryExec=xdg-user-dirs-update
    NoDisplay=true
    StartupNotify=false
    Type=Application
    X-KDE-AutostartScript=true
    X-KDE-autostart-phase=1
  '';

  # mozc_tool can be run with `/run/current-system/sw/lib/mozc/mozc_tool --mode=config_dialog` on NixOS
  # Alternatively, it can also be launched via desktop entry: `gtk-launch ibus-setup-mozc-jp`
  #
  # See https://github.com/google/mozc/blob/master/docs/configurations.md for details
  xdg.configFile."mozc/ibus_config.textproto".source = ../config/mozc/ibus_config.textproto;
  xdg.writableConfigFile."mozc/config1.db".source =
    "${pkgs.local.mozc-config}/share/mozc-config/config1.db";

  home = {
    # Putting files into xdg.userDirs.templates enables new file menu on Nautilus
    # https://askubuntu.com/a/209669
    file."Templates/blank.md".text = "";

    activation.reloadMozcConfig = lib.hm.dag.entryAfter [ "syncWritableConfig" ] ''
      if [ -z "''${DRY_RUN:-}" ]; then
        ${lib.getExe pkgs.local.mozc-config} reload --if-running
      fi
    '';

    packages = with pkgs; [
      kanata # Don't require kanata-with-cmd for now
      pinned.kanata-tray
      local.ibus-engine-selector
      local.mozc-config
      # https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/iw/iw/package.nix
      iw # replacement of wireless-tools(iwconfig)
    ];

    sessionVariables = {
      # https://github.com/rszyma/kanata-tray/pull/68
      # https://github.com/NixOS/nixpkgs/pull/458994#discussion_r2506875784
      KANATA_TRAY_LOG_DIR = "${config.xdg.cacheHome}/kanata-tray";
    };

    shellAliases = {
      # https://github.com/NixOS/nixpkgs/pull/344193
      "zed" = "zeditor";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/xdg-autostart.nix
  xdg.autostart = {
    enable = true;
    entries = [
      ../config/keyboards/kanata-tray.desktop
    ];
  };
}
