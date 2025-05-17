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
      # Clean up except directory

      rm -f ${bashDir}/*
      rm -f ${zshDir}/*

      # Begins for bash

      cp -f "${pkgs.zellij}/share/bash-completion/completions/zellij.bash" ${bashDir}

      cp -f "${pkgs.tailscale}/share/bash-completion/completions/tailscale.bash" ${bashDir}

      # https://github.com/NixOS/nixpkgs/pull/362139
      cp -f "${pkgs.unstable.dprint}/share/bash-completion/completions/dprint.bash" ${bashDir}

      # Adding only in devshell is not enough
      cp -f "${pkgs.go-task}/share/bash-completion/completions/task.bash" ${bashDir}

      # Begins for zsh

      cp -f "${pkgs.tailscale}/share/zsh/site-functions/_tailscale" ${zshDir}

      # https://github.com/NixOS/nixpkgs/pull/362139
      cp -f "${pkgs.unstable.dprint}/share/zsh/site-functions/_dprint" ${zshDir}
      cp -f "${pkgs.go-task}/share/zsh/site-functions/_task" ${zshDir}

      # Commit them

      git add ${bashDir} ${zshDir}
      git update-index -q --really-refresh
      git diff-index --quiet HEAD || git commit -m 'Bump shell completions'
    '';

    meta = {
      description = "Putting intermediate files for stable shell completions";
    };
  }
)
