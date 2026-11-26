let
  getFlake = builtins.getAttr "getFlake" builtins;
  flake = getFlake (toString ../.);
  hm = flake.homeConfigurations."visitor@container";
  pkgs = hm.pkgs;
  hmConfig = hm.config;
in
pkgs.runCommand "test-shell-delegation"
  {
    nativeBuildInputs = with pkgs; [
      bashInteractive
      coreutils
      expect
      gnugrep
      herdr
      procps
      util-linux
      zellij
      zsh
    ];

    BASHRC_FILE = hmConfig.home.file.".bashrc".source;
    BASH_PROFILE_FILE = hmConfig.home.file.".bash_profile".source;
    HERDR_CONFIG_FILE = ../config/herdr/config.toml;
    ZELLIJ_CONFIG_FILE = ../config/zellij/config.kdl;
    BASH_BIN = pkgs.lib.getExe pkgs.bashInteractive;
    ZSH_BIN = pkgs.lib.getExe pkgs.zsh;
  }
  ''
    bash ${./test-shell-delegation.bash}
    touch $out
  ''
