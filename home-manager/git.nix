{ pkgs, edge-pkgs, lib, config, ... }:

{
  home.file."repos/.keep".text = "Put repositories here";

  # https://github.com/nix-community/home-manager/blob/release-23.11/modules/programs/git.nix
  # xdg will be used in home-manager: https://github.com/nix-community/home-manager/blob/7b8d43fbaf8450c30caaed5eab876897d0af891b/modules/programs/git.nix#L417-L418
  programs.git = {
    enable = true;

    # userEmail = "<UPDATE_ME_IN_FLAKE>";
    # userName = "<UPDATE_ME_IN_FLAKE>";

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
      r = "refresh"; # refresh is long for typing
      all = "!git refresh && git-delete-merged-branches";
      gui = "!lazygit";
      pp = "log --pretty=format:'%Cgreen%cd %Cblue%h %Creset%s' --date=short --decorate --graph --tags HEAD";
    };

    # - They will be overridden by local hooks, currently I do nothing to merge global and local hooks
    #   If I want it, https://github.com/timokau/dotfiles/blob/dfee6670a42896cfb5a94fdedf96c9ed2fa1c9d2/home/git.nix#L3-L11 may be a good example
    # - I don't have confident for executable permissions are required or not for them, removing it worked. :<
    hooks = {
      commit-msg = lib.getExe (pkgs.writeShellApplication {
        name = "prevent_typos_in_commit_mssage.bash";
        meta.description = "#325";
        runtimeInputs = [ edge-pkgs.typos ];
        text = ''
          typos --config "${config.xdg.configHome}/typos/_typos.toml" "$1"
        '';
      });

      post-checkout = lib.getExe (pkgs.writeShellApplication {
        name = "alert_typos_in_branch_name.bash";
        meta.description = "#540";
        runtimeInputs = with pkgs; [ git edge-pkgs.typos ];
        # What arguments: https://git-scm.com/docs/githooks#_post_checkout
        text = ''
          is_file_checkout="$3" # 0: file, 1: branch
          if [[ "$is_file_checkout" -eq 0 ]]; then
            exit 0
          fi

          branch_name="$(git rev-parse --abbrev-ref 'HEAD')"

          # Checkout to no branch and no tag
          if [[ "$branch_name" = 'HEAD' ]]; then
            exit 0
          fi

          (echo "$branch_name" | typos --config "${config.xdg.configHome}/typos/_typos.toml" -) || true
        '';
      });
    };

    extraConfig = {
      user = {
        # - Visibility
        #   - https://stackoverflow.com/questions/48065535/should-i-keep-gitconfigs-signingkey-private
        #   - ANYONE can access the registered public key at https://github.com/kachick.gpg
        # - Append `!` suffix for subkeys
        # signingkey = "<UPDATE_ME_IN_FLAKE>!";
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
        # For git commit message 50/72 convention
        editor = "micro -colorcolumn 72";
        quotepath = false;
      };

      # Affect in rebase -i
      sequence = {
        # - For git commit message 50/72 convention
        # - Consider prefixed 5 + 1 + 7 + 1 chars as "pick c290ca9 "
        editor = "micro -colorcolumn 64";
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

      branch = {
        # Candidates: https://github.com/git/git/blob/3c2a3fdc388747b9eaf4a4a4f2035c1c9ddb26d0/ref-filter.c#L902-L959
        # Append `-` prefix if you want to reverse the order: https://gfx.hatenablog.com/entry/2016/06/10/153747
        sort = "-committerdate";
      };

      url = {
        # Why?
        # - ghq default is https, this omit -p option for the ssh push
        # - https://blog.n-z.jp/blog/2013-11-28-git-insteadof.html
        "git@github.com:" = {
          pushInsteadOf = [
            "git://github.com/"
            "https://github.com/"
          ];
        };
      };

      # https://github.com/Songmu/ghq-handbook/blob/97d02519598835f635260988cfa45e58ec4afe35/ja/04-command-get.md
      ghq = {
        root = "~/repos";
      };
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-23.11/modules/programs/gh.nix
  programs.gh = {
    enable = true;

    settings = {
      aliases = {
        # https://github.com/kachick/wait-other-jobs/blob/b576def89f0816aab642bed952817a018e99b373/docs/examples.md#github_token-vs-pat
        setup = ''!gh repo edit --enable-auto-merge && \
          gh api --method PUT --verbose \
          --header 'Accept: application/vnd.github+json' \
          --header 'X-GitHub-Api-Version: 2022-11-28' \
          '/repos/{owner}/{repo}/actions/permissions/workflow' \
          --field 'can_approve_pull_request_reviews=true' \
          --raw-field 'default_workflow_permissions=write'
        '';

        # https://www.collinsdictionary.com/dictionary/english/burl
        burl = ''!cd "$(${pkgs.ghq}/bin/ghq root)/github.com/$(git config --global ghq.user)" && \
          gh repo create "$1" --private --clone --template='kachick/anylang-template' --description='🚧' && \
          cd "$1" && \
          gh setup && \
          ${pkgs.direnv}/bin/direnv allow && \
          ${pkgs.neo-cowsay}/bin/cowsay -W 100 --rainbow "cdg $1"
        '';
      };
    };

    gitCredentialHelper = {
      enable = true;

      hosts = [
        "https://github.com"
        "https://gist.github.com"
      ];
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-23.11/modules/programs/lazygit.nix
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
