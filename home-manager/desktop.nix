{
  lib,
  ...
}:

let
  # It should be ordered with IME support.
  plainTextEditor = [
    "org.gnome.TextEditor.desktop"
  ] ++ codeEditor;

  codeEditor = [
    "dev.zed.Zed.desktop"
    "code.desktop"
    "Helix.desktop"
  ];

  webBrowser = [
    "google-chrome.desktop"
    "firefox.desktop"
  ];

  terminalEmulator = [
    "com.mitchellh.ghostty.desktop"
    "Alacritty.desktop"
  ];

  # Loupe is faster than browsers to open images, and can simply edit
  imageViewer = [
    # https://gitlab.gnome.org/GNOME/loupe/-/blob/47.2/data/meson.build#L54
    "org.gnome.Loupe.desktop"
  ] ++ webBrowser;
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
            "application/pdf" # I prefer to open PDF with reader, editor is not frequently used. And native readers Papers is much heavy than browsers
          ] (_: webBrowser))

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
}
