{ config, pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix
  # xdg will be used in home-manager: https://github.com/nix-community/home-manager/blob/7b8d43fbaf8450c30caaed5eab876897d0af891b/modules/programs/git.nix#L417-L418
  programs.git = {
    enable = true;

    userEmail = "kachick1@gmail.com";
    userName = "Kenichi Kamiya";

    aliases = {
      fixup = "commit --all --amend";
      empty = "commit --allow-empty -m 'Add an empty commit'";
      current = "symbolic-ref --short HEAD";
      switch-default = "!git checkout main 2>/dev/null || git checkout master 2>/dev/null";
      upstream = "!git remote | grep -E '^upstream$'|| git remote | grep -E '^origin$'";
      duster = "remote update origin --prune";
      refresh = "!git switch-default && git pull \"$(git upstream)\" \"$(git current)\"";
      all = "!git refresh && gh poi";
      gui = "!lazygit";
    };

    extraConfig = {
      user = {
        # https://stackoverflow.com/questions/48065535/should-i-keep-gitconfigs-signingkey-private
        # TODO: Share code to get the path with ./ssh.nix
        signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      };

      core = {
        editor = "vim";
        quotepath = false;
      };

      gpg = {
        format = "ssh";
      };

      commit = {
        # https://stackoverflow.com/questions/10161198/is-there-a-way-to-autosign-commits-in-git-with-a-gpg-key
        gpgsign = true;
      };

      init = {
        defaultBranch = "main";
      };

      color = {
        ui = true;
      };

      grep = {
        lineNumber = true;
      };

      pull = {
        ff = "only";
      };

      credential = {
        "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
    };
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/lazygit.nix
  programs.lazygit = {
    enable = true;

    # https://dev.classmethod.jp/articles/eetann-lazygit-config-new-option/
    settings = {
      gui = {
        language = "ja";
        showIcons = true;
        theme = {
          lightTheme = true;
        };
      };
    };
  };
}
