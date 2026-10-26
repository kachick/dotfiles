let
  getFlake = builtins.getAttr "getFlake" builtins;
  flake = getFlake (toString ../.);
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  sessionVars = flake.homeConfigurations."user@container".config.home.sessionVariablesPackage;
in
pkgs.runCommand "test-home-session-vars" { } ''
  export HOME=/home/user USER=user
  . ${sessionVars}/etc/profile.d/hm-session-vars.sh
  if [[ ":$PATH:" != *":$HOME/.nix-profile/bin:"* ]]; then
    echo "ERROR: PATH does not contain \$HOME/.nix-profile/bin" >&2
    exit 1
  fi
  touch $out
''
