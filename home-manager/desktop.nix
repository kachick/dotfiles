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
  ];

  xdg = {
    # How to get the mimetype: `xdg-mime query filetype path`
    #
    # https://github.com/nix-community/home-manager/blob/release-25.11/modules/misc/xdg-mime-apps.nix - different of  https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/xdg/mime.nix
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
        ] (_: plainTextEditor))

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
          ] (_: codeEditor))

        //

          (lib.genAttrs [
            "text/html"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "x-scheme-handler/about"
            "x-scheme-handler/unknown"
          ] (_: webBrowser))

        //

          (lib.genAttrs [
            "application/pdf"
          ] (_: pdfReader))

        //

          (lib.genAttrs [
            "application/x-terminal-emulator"
            "x-scheme-handler/terminal"
          ] (_: terminalEmulator))

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
          ] (_: imageViewer));

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

  home = {
    packages = with pkgs; [
      unstable.kanata # Don't require kanata-with-cmd for now
      patched.kanata-tray
    ];

    sessionVariables = {
      # https://github.com/rszyma/kanata-tray/pull/68
      # https://github.com/NixOS/nixpkgs/pull/458994#discussion_r2506875784
      KANATA_TRAY_LOG_DIR = "${config.xdg.cacheHome}/kanata-tray";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-25.11/modules/misc/xdg-autostart.nix
  xdg.autostart = {
    enable = true;
    entries = [
      ../config/keyboards/kanata-tray.desktop
      ../config/cloudflare-warp/connect.desktop
    ];
  };
}
