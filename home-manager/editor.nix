{
  lib,
  pkgs,
  homemade-pkgs,
  ...
}:

let
  nordcolors = pkgs.stdenv.mkDerivation {
    name = "micro-nordcolors";
    src = pkgs.fetchFromGitHub {
      owner = "KiranWells";
      repo = "micro-nord-tc-colors";
      rev = "f63c855735f755704c25c958abe45f12a4b2c8d3";
      sha256 = "sha256-giCansV+9oa2OSQlt7DkLtL7B7sD00JUBaS9YsbJ9aU=";
    };
    buildPhase = ''
      mkdir $out
    '';
    installPhase = ''
      cp -rf ./colorschemes $out/colorschemes
    '';
    system = builtins.currentSystem;
  };
in
{
  xdg.configFile."micro/colorschemes/.keep".text = "";
  xdg.configFile."micro/colorschemes/nord-tc.micro".source = "${nordcolors}/colorschemes/nord-tc.micro";
  xdg.configFile."micro/colorschemes/nord-16.micro".source = "${nordcolors}/colorschemes/nord-16.micro";

  xdg.configFile."micro/plug/fzfinder".source = homemade-pkgs.micro-fzfinder;

  # Default keybinfings are https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md
  xdg.configFile."micro/bindings.json".source = ../config/micro/bindings.json;

  # TODO: Consider to extract from nix managed, because of now also using in windows
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/micro.nix
  # https://github.com/zyedidia/micro/blob/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/help/options.md
  programs.micro = {
    enable = true;

    # `micro -options` shows candidates and we can temporally change some options by giving "-OPTION_NAME VALUE"
    settings = {
      autosu = true;
      cursorline = true;
      backup = true;
      autosave = 0; # Means false
      basename = false;
      clipboard = "external";
      colorcolumn = 0; # Means false
      diffgutter = true;
      ignorecase = true;
      incsearch = true;
      hlsearch = true;
      infobar = true;
      keepautoindent = false;
      mouse = true;
      mkparents = false;
      matchbrace = true;
      multiopen = "tab";
      parsecursor = true;
      reload = "prompt";
      rmtrailingws = false;
      relativeruler = false;
      savecursor = true;
      savehistory = true;
      saveundo = true;
      softwrap = true;
      splitbottom = true;
      splitright = true;
      statusline = true;
      syntax = true;
      "ft:ruby" = {
        tabsize = 2;
      };

      # Embed candidates are https://github.com/zyedidia/micro/tree/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/colorschemes
      # But none of fit colors with other place, See #587 for further detail
      colorscheme = "nord-16";

      fzfcmd = lib.getExe pkgs.fzf;
      fzfarg = "--preview '${lib.getExe pkgs.bat} --color=always {}'";
      fzfopen = "newtab";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/vim.nix
  # https://nixos.wiki/wiki/Vim
  programs.vim = {
    enable = true;
    # nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins = [ pkgs.vimPlugins.iceberg-vim ];

    settings = {
      background = "dark";
    };
    extraConfig = ''
      colorscheme iceberg
      set termguicolors
    '';
  };

  xdg.configFile."zed/settings.json".source = ../config/zed/settings.json;

  # Don't add unfree packages like vscode here for using in containers
}
