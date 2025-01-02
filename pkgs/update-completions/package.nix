{ pkgs, ... }:
pkgs.writeShellApplication (
  let
    bashDir = "./dependencies/bash";
    zshDir = "./dependencies/zsh";
  in
  {
    name = "update-completions";

    runtimeInputs = with pkgs; [
      coreutils # `cp`
      git
    ];

    text = ''
      cp -f "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh" ${bashDir}
      cp -f "${pkgs.zellij}/share/bash-completion/completions/zellij.bash" ${bashDir}

      # https://github.com/NixOS/nixpkgs/pull/362139
      cp -f "${pkgs.unstable.dprint}/share/bash-completion/completions/dprint.bash" ${bashDir}

      # Adding only in devshell is not enough
      cp -f "${pkgs.cargo-make}/share/bash-completion/completions/makers-completion.bash" ${bashDir}

      cp -f "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh" ${zshDir}
      # https://github.com/NixOS/nixpkgs/pull/362139
      cp -f "${pkgs.unstable.dprint}/share/zsh/site-functions/_dprint" ${zshDir}
      # cargo-make recommends to use bash completions for zsh
      # Update after intoducing https://github.com/sagiegurari/cargo-make/pull/1182
      cp -f "${pkgs.cargo-make}/share/bash-completion/completions/makers-completion.bash" ${zshDir}

      git add ${bashDir} ${zshDir}
      git update-index -q --really-refresh
      git diff-index --quiet HEAD || git commit -m 'Bump shell completions'
    '';
  }
)
