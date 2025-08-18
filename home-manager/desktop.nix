{
  lib,
  config,
  pkgs,
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
  imports = [ ./gnome.nix ];

  xdg = {
    # How to get the mimetype: `xdg-mime query filetype path`
    #
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/xdg-mime-apps.nix - different of  https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/xdg/mime.nix
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

  # https://github.com/nix-community/home-manager/commit/4c8647b1ed35d0e1822c7997172786dfa18cd7da
  services.trayscale.enable = true;

  # GH-1228: Disable podman-desktop Telemetry
  # podman-desktop does not provide CLI configurable features likely ENV
  # ref: https://github.com/podman-desktop/podman-desktop/blob/db85f0197406b42dc8a0bd8ef5661e8c19c30e80/.devcontainer/.parent/Containerfile#L36-L38
  xdg.dataFile."containers/podman-desktop/configuration/.keep".text = "";
  home.activation.disablePodmanDesktopTelemetry =
    let
      configPath = "${config.xdg.dataHome}/containers/podman-desktop/configuration/settings.json";
    in
    config.lib.dag.entryAnywhere ''
      if [[ -f '${configPath}' ]]; then
        jq '. "telemetry.check" = true | . "telemetry.enabled" = false' '${configPath}' | "${pkgs.moreutils}/bin/sponge" '${configPath}'
      else
        echo '{"telemetry.enabled": false, "telemetry.check": true}' > '${configPath}'
      fi
    '';
}
