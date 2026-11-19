{
  pkgs,
  config,
  lib,
  ...
}:

{
  xdg.stateFile."vim/.keep".text =
    "Keep this directory because of home-manager and vim does not create the file if directory is missing";

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/vim.nix
  # https://wiki.nixos.org/wiki/Vim
  programs.vim = {
    # Enabling this may cause collisions. Do not add in packages list
    enable = true;
    packageConfigurable = lib.mkDefault pkgs.vim;

    settings = {
      background = "dark";
      hidden = true;
      ignorecase = true;
      mouse = "a";
      number = true;
      smartcase = true;
    };

    # Force 16 colors so built-in sorbet uses terminal background and palette colors instead of fixed hex values.
    # Re-apply Pmenu overrides on ColorScheme because Vim reloads sorbet during startup after vimrc runs.
    # Disable netrw history (dirhistmax = 0) so .netrwhist is not created outside XDG directories.
    extraConfig = ''
      filetype plugin indent on
      syntax on

      set hlsearch
      set scrolloff=5
      set path+=**
      set wildignore+=*/.git/*,*/.direnv/*,*/node_modules/*,*/target/*,*/dist/*
      set wildoptions=pum,fuzzy

      if executable('rg')
        set grepprg=rg\ --vimgrep\ --smart-case
        set grepformat=%f:%l:%c:%m
      endif

      let g:netrw_banner = 0
      let g:netrw_liststyle = 3
      let g:netrw_winsize = 25
      let g:netrw_dirhistmax = 0

      augroup dotfiles_vim
        autocmd!
        autocmd ColorScheme * hi Pmenu ctermfg=15 ctermbg=8 cterm=NONE
        autocmd ColorScheme * hi PmenuSel ctermfg=15 ctermbg=6 cterm=bold
        autocmd QuickFixCmdPost *grep* cwindow
      augroup END

      set t_Co=16
      colorscheme sorbet
      set viminfofile=${config.xdg.stateHome}/vim/viminfo
    '';
  };
}
