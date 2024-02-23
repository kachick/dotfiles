{ pkgs, lib, config, ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix
  # xdg will be used in home-manager: https://github.com/nix-community/home-manager/blob/7b8d43fbaf8450c30caaed5eab876897d0af891b/modules/programs/git.nix#L417-L418
  programs.git = {
    enable = true;

    userEmail = "kachick1@gmail.com";
    userName = "Kenichi Kamiya";

    # `git config --get-regexp ^alias` will show current aliases
    aliases = {
      fixup = "commit --all --amend";
      empty = "commit --allow-empty";
      start = "empty -m 'Start project from empty'";
      current = "symbolic-ref --short HEAD";
      switch-default = "!git switch main 2>/dev/null || git switch master 2>/dev/null";
      upstream = "!git remote | grep -E '^upstream$'|| git remote | grep -E '^origin$'";
      duster = "remote update origin --prune";
      refresh = "!git switch-default && git pull \"$(git upstream)\" \"$(git current)\"";
      r = "refresh"; # all is slow, refresh is long for type. So provide faster daily alias
      all = "!git refresh && gh poi";
      gui = "!lazygit";
      pp = "log --pretty=format:'%Cgreen%cd %Cblue%h %Creset%s' --date=short --decorate --graph --tags HEAD";
    };

    # - They will be overridden by local hooks, currently I do nothing to merge global and local hooks
    #   If I want it, https://github.com/timokau/dotfiles/blob/dfee6670a42896cfb5a94fdedf96c9ed2fa1c9d2/home/git.nix#L3-L11 may be a good example
    # - I don't have confident for executable permissions are reqiored or not for them, removing it worked. :<
    hooks = {
      commit-msg = pkgs.writeShellScript "prevent_typo.bash" ''
        set -euo pipefail

        ${lib.getBin pkgs.typos}/bin/typos --config "${config.xdg.configHome}/typos/_typos.toml" "$1"
      '';
    };

    extraConfig = {
      user = {
        # - Visibility
        #   - https://stackoverflow.com/questions/48065535/should-i-keep-gitconfigs-signingkey-private
        #   - ANYONE can access the registered public key at https://github.com/kachick.gpg
        # - Append `!` suffix for subkeys
        signingkey = "9BE4016A38165CCB!";
      };

      gpg = {
        # I prefer GPG sign rather than SSH key to consider revocation and expiration usecase.
        # See https://github.com/kachick/dotfiles/issues/289 for detail.
        format = "openpgp";
      };

      commit = {
        # https://stackoverflow.com/questions/10161198/is-there-a-way-to-autosign-commits-in-git-with-a-gpg-key
        gpgsign = true;
      };

      core = {
        editor = "vim";
        quotepath = false;
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
    };
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/gh.nix
  programs.gh = {
    enable = true;

    gitCredentialHelper = {
      enable = true;

      hosts = [
        "https://github.com"
        "https://gist.github.com"
      ];
    };

    # poi is not yet registered to nixpkgs
    # extensions = [
    #   pkgs.gh-poi
    # ];
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
