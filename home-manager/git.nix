{
  pkgs,
  lib,
  ...
}:

# tig
#
# tig cannot be used as a standard UNIX filter tools, it prints with ncurses, not to STDOUT

let
  mkPassthruHook = (
    hook_name:
    pkgs.writeShellApplication {
      name = "passthru-hook-for-the-local-hook";
      text = ''
        run_local_hook '${hook_name}' "$@"
      '';
      meta.description = "GH-545";
      runtimeInputs = [ pkgs.my.run_local_hook ];
    }
  );
  # NOTE: Don't use the home-manager module. Enabling it forces to set programs.git.iniContent.pager.log, it makes much slower in large repositories https://github.com/nix-community/home-manager/pull/5748
  riff = lib.getExe pkgs.riffdiff;
in
{
  home.file."repos/.keep".text = "Put repositories here";

  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/git.nix
  # xdg will be used in home-manager: https://github.com/nix-community/home-manager/blob/7b8d43fbaf8450c30caaed5eab876897d0af891b/modules/programs/git.nix#L417-L418
  programs.git = {
    enable = true;

    # userEmail = "<UPDATE_ME_IN_FLAKE>";
    # userName = "<UPDATE_ME_IN_FLAKE>";

    # `git config --get-regexp ^alias` will show current aliases
    aliases = {
      fixup = "commit --all --amend";
      current = "symbolic-ref --short HEAD";
      switch-default = "!git switch main 2>/dev/null || git switch master 2>/dev/null";
      upstream = "!git remote | grep -E '^upstream$'|| git remote | grep -E '^origin$'";
      refresh = "!git remote update origin --prune && git switch-default && git pull --prune \"$(git upstream)\" \"$(git current)\"";
      all = "!git refresh && git-delete-merged-branches";
      lf = "!${lib.getExe pkgs.my.git-log-fzf}";
      reset-main = ''
        !git fetch origin && \
          git switch main && \
          git branch -m "backup-main-$(${lib.getExe pkgs.nushell} --commands 'random uuid')" && \
          git checkout origin/main && \
          git checkout -b main
      '';
      resolve-conflict = "!${lib.getExe pkgs.my.git-resolve-conflict}";
    };

    # Required to provide all global hooks to respect local hooks even if it is empty. See GH-545 for detail
    # Candidates: https://github.com/git/git/tree/v2.44.1/templates
    hooks = {
      commit-msg = lib.getExe pkgs.my.git-hooks-commit-msg;

      # Git does not provide hooks for renaming branch, so using in checkout phase is not enough
      pre-push = lib.getExe pkgs.my.git-hooks-pre-push;

      pre-merge-commit = lib.getExe (mkPassthruHook "pre-merge-commit");
      pre-applypatch = lib.getExe (mkPassthruHook "pre-applypatch");
      post-update = lib.getExe (mkPassthruHook "post-update");
      pre-receive = lib.getExe (mkPassthruHook "pre-receive");
      push-to-checkout = lib.getExe (mkPassthruHook "push-to-checkout");
      pre-commit = lib.getExe (mkPassthruHook "pre-commit");
      prepare-commit-msg = lib.getExe (mkPassthruHook "prepare-commit-msg");
      fsmonitor-watchman = lib.getExe (mkPassthruHook "fsmonitor-watchman");
      update = lib.getExe (mkPassthruHook "update");
      applypatch-msg = lib.getExe (mkPassthruHook "applypatch-msg");
      pre-rebase = lib.getExe (mkPassthruHook "pre-rebase");
      sendemail-validate = lib.getExe (mkPassthruHook "sendemail-validate");
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
        # I prefer PGP sign rather than SSH key to consider revocation and expiration usecase.
        # See https://github.com/kachick/dotfiles/issues/289 for detail.
        format = "openpgp";

        program = "${pkgs.lib.getBin pkgs.sequoia-chameleon-gnupg}/bin/gpg-sq"; # GH-830
      };

      commit = {
        # https://stackoverflow.com/questions/10161198/is-there-a-way-to-autosign-commits-in-git-with-a-gpg-key
        gpgsign = true;
      };

      core = {
        # Helix considers git commit message 50/72 convention by default
        # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1569
        editor = pkgs.helix.meta.mainProgram;
        quotepath = false;

        # To avoid conflicting with markdown headers
        commentchar = ";";
      };

      # Affect in rebase -i
      sequence = {
        editor = pkgs.helix.meta.mainProgram;
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

      log = {
        date = "iso-local";
      };

      # For `git log --patch`
      pager = {
        diff = riff;
        show = riff;
        # log = riff; # Don't set this. It makes much slow in large repositories such as NixOS/nixpkgs
      };

      interactive = {
        diffFilter = "${riff} --color=on";
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

  # If you encounter .config/gh/config.yml readonly permission errors, attempt after `rm -rf ~/.config/gh`
  # https://github.com/cli/cli/pull/5378#issuecomment-2252558180
  #
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/gh.nix
  programs.gh = {
    enable = true;

    settings = {
      # Without this, gh prefer $VISUAL
      editor = pkgs.helix.meta.mainProgram;

      aliases = {
        # https://github.com/kachick/wait-other-jobs/blob/b576def89f0816aab642bed952817a018e99b373/docs/examples.md#github_token-vs-pat
        setup = ''
          !gh repo edit --enable-auto-merge && \
            gh api --method PUT --verbose \
              --header 'Accept: application/vnd.github+json' \
              --header 'X-GitHub-Api-Version: 2022-11-28' \
              '/repos/{owner}/{repo}/actions/permissions/workflow' \
              --field 'can_approve_pull_request_reviews=true'
        '';

        # https://www.collinsdictionary.com/dictionary/english/burl
        burl = ''
          !cd "$(${pkgs.ghq}/bin/ghq root)/github.com/$(git config --global ghq.user)" && \
            gh repo create "$1" --private --clone --template='kachick/anylang-template' --description='🚧' && \
              cd "$1" && \
                gh setup && \
                  ${pkgs.direnv}/bin/direnv allow && \
                    ${pkgs.neo-cowsay}/bin/cowsay -W 100 --rainbow "cdrepo $1"
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

    extensions = (with pkgs; [ gh-poi ]) ++ (with pkgs.my; [ gh-prs ]);
  };
}
