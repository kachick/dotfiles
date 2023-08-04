{ pkgs, lib, ... }:

# FAQ
#
# A. How to make executable? .text= makes syms, that links to non executable file
# Q. https://github.com/nix-community/home-manager/blob/15043a65915bcc16ad207d65b202659e4988066b/modules/xsession.nix#L195C1-L197

# - Tiny tools by me, they may be rewritten with another language.
{
  # - Keep *.bash in shellscript naming in this repo for maintainability, the extname should be trimmed in the symlinks
  xdg.dataFile."homemade/bin/add_nix_channels".source = ../home/.local/share/homemade/bin/add_nix_channels.bash;

  xdg.dataFile."homemade/bin/bench_shells" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      set -euxo pipefail

      # ~ my feeling ~
      # 50ms : blazing fast!
      # 110ms : acceptable
      # 150ms : slow
      # 200ms : 1980s?
      # 300ms : much slow!

      # zsh should be first, because it often makes much slower with the completion
      ${lib.getExe pkgs.hyperfine} --warmup 1 '${lib.getExe pkgs.zsh} --interactive -c exit'

      ${lib.getExe pkgs.hyperfine} --warmup 1 '${lib.getExe pkgs.bashInteractive} -i -c exit'
      ${lib.getExe pkgs.hyperfine} --warmup 1 '${lib.getExe pkgs.fish} --interactive --command exit'
    '';
  };

  xdg.dataFile."homemade/bin/updeps" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      case ''${OSTYPE} in
      linux*)
      	sudo apt update --yes && sudo apt upgrade --yes
      	;;
      darwin*)
      	softwareupdate --install --recommended
      	;;
      esac

      nix-channel --update

      ${lib.getExe pkgs.rtx} plugins update
    '';
  };

  xdg.dataFile."homemade/bin/la" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      ${lib.getExe pkgs.exa} --long --all --group-directories-first "$@"
    '';
  };

  xdg.dataFile."homemade/bin/zj" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      name="$(${lib.getBin pkgs.coreutils}/bin/basename "$PWD")"

      ${lib.getExe pkgs.zellij} attach "$name" || ${lib.getExe pkgs.zellij} --session "$name"
    '';
  };
}
