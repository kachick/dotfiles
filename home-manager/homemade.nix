{ pkgs, lib, ... }:

# - Tiny tools by me, they may be rewritten with another language.
{
  xdg.dataFile."homemade/bin/bench_shells".source = pkgs.writeShellScript "bench_shells.bash" ''
    set -euo pipefail

    # ~ my feeling ~
    # 50ms : blazing fast!
    # 110ms : acceptable
    # 150ms : slow
    # 200ms : 1980s?
    # 300ms : much slow!

    # zsh should be first, because it often makes much slower with the completion
    ${lib.getBin pkgs.hyperfine}/bin/hyperfine --warmup 1 --runs 5 \
      '${lib.getExe pkgs.zsh} --interactive -c exit' \
      '${lib.getExe pkgs.bashInteractive} -i -c exit' \
      '${lib.getExe pkgs.fish} --interactive --command exit'
  '';

  xdg.dataFile."homemade/bin/updeps".source = pkgs.writeShellScript "updeps.bash" ''
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

    ${lib.getExe pkgs.mise} plugins update
  '';

  xdg.dataFile."homemade/bin/la".source = pkgs.writeShellScript "la.bash" ''
    set -euo pipefail

    ${lib.getBin pkgs.eza}/bin/eza --long --all --group-directories-first "$@"
  '';

  xdg.dataFile."homemade/bin/zj".source = pkgs.writeShellScript "zj.bash" ''
    set -euo pipefail

    name="$(${lib.getBin pkgs.coreutils}/bin/basename "$PWD")"

    ${lib.getBin pkgs.zellij}/bin/zellij attach "$name" || ${lib.getBin pkgs.zellij}/bin/zellij --session "$name"
  '';
}
