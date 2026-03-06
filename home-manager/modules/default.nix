{ overlays }:
let
  # Explicitly list the module files.
  # This avoids complex readDir logic while keeping the attribute mapping clean.
  modules = [
    "bash"
    "common"
    "darwin"
    "desktop"
    "editors"
    "encryption"
    "ephemeral"
    "firefox"
    "fzf"
    "genericLinux"
    "git"
    "gnome"
    "helix"
    "kachick"
    "lima-guest"
    "lima-host"
    "linux"
    "micro"
    "packages"
    "ssh"
    "systemd"
    "telemetry"
    "television"
    "terminals"
    "vim"
    "wsl"
    "zsh"
  ];

  autoModules = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = ../. + "/${name}.nix";
    }) modules
  );
in
autoModules
// {
  inherit overlays;
}
