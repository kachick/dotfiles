{
  lib,
  pkgs,
  homemade-pkgs,
  ...
}:

{
  home.sessionVariables = {
    MICRO_TRUECOLOR = "1";
  };

  # For temporal use
  xdg.configFile."micro/colorschemes/.keep".text = "";

  xdg.configFile."micro/plug/fzfinder".source = homemade-pkgs.micro-fzfinder;
  xdg.configFile."micro/plug/kdl".source = homemade-pkgs.micro-kdl;
  xdg.configFile."micro/plug/nordcolors".source = homemade-pkgs.micro-nordcolors;
  xdg.configFile."micro/colorschemes" = {
    source = "${homemade-pkgs.micro-catppuccin}/colorschemes";
    recursive = true;
  };
  xdg.configFile."micro/colorschemes/everforest.micro".source = "${homemade-pkgs.micro-everforest}/colorschemes/everforest.micro";

  # Default keybinfings are https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md
  xdg.configFile."micro/bindings.json".source = ../config/micro/bindings.json;

  # TODO: Consider to extract from nix managed, because of now also using in windows
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/micro.nix
  # https://github.com/zyedidia/micro/blob/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/help/options.md
  # keybinds: https://github.com/zyedidia/micro/blob/c15abea64c20066fc0b4c328dfabd3e6ba3253a0/runtime/help/defaultkeys.md
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
      # Candidates: nord-16, everforest, catppuccin-mocha-transparent
      colorscheme = "catppuccin-mocha-transparent";

      fzfcmd = lib.getExe pkgs.fzf;
      fzfarg = "--preview '${lib.getExe pkgs.bat} --color=always {}'";
      fzfopen = "newtab";
    };
  };
}
