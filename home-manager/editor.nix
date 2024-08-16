{
  lib,
  pkgs,
  homemade-pkgs,
  ...
}:

{
  # For temporal use
  xdg.configFile."micro/colorschemes/.keep".text = "";

  xdg.configFile."micro/plug/fzfinder".source = homemade-pkgs.micro-fzfinder;
  xdg.configFile."micro/plug/kdl".source = homemade-pkgs.micro-kdl;
  xdg.configFile."micro/plug/nordcolors".source = homemade-pkgs.micro-nordcolors;

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

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/helix.nix
  # https://docs.helix-editor.com/keymap.html
  programs.helix = {
    # Enabling this may cause colisions. Do not add in packages list
    enable = true;

    settings = {
      theme = "base16_transparent";

      editor = {
        soft-wrap = {
          enable = true;
        };

        lsp = {
          display-inlay-hints = true;
          display-messages = true;
        };
      };
    };

    # https://docs.helix-editor.com/lang-support.html
    languages = {
      language-server = {
        typos = {
          command = lib.getExe pkgs.typos-lsp;
          config.config = "${../typos.toml}";
        };
      };

      language = [
        {
          # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1563-L1570
          name = "git-commit";
          language-servers = [ "typos" ];

          # To avoid conflicting with markdown headers. Should be synced with core.commentchar
          comment-token = ";";
        }
      ];
    };

    ignores = [
      ".git/"
      ".direnv/"
      ".node_modules/"
    ];

    extraPackages = with pkgs; [ marksman ];
  };

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/vim.nix
  # https://nixos.wiki/wiki/Vim
  programs.vim = {
    # Enabling this may cause colisions. Do not add in packages list
    enable = true;
    # nix-env -f '<nixpkgs>' -qaP -A vimPlugins
    plugins =
      (with pkgs.vimPlugins; [
        iceberg-vim
        fzf-vim
      ])
      ++ [ homemade-pkgs.kdl-vim ];

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
