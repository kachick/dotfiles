{ pkgs, edge-pkgs, ... }:
{
  bump_completions = pkgs.writeShellScriptBin "bump_completions" ''
    set -euo pipefail

    ${edge-pkgs.podman}/bin/podman completion bash > ./dependencies/podman/completions.bash
    ${edge-pkgs.podman}/bin/podman completion zsh > ./dependencies/podman/completions.zsh
    ${edge-pkgs.podman}/bin/podman completion fish > ./dependencies/podman/completions.fish

    ${edge-pkgs.dprint}/bin/dprint completions bash > ./dependencies/dprint/completions.bash
    ${edge-pkgs.dprint}/bin/dprint completions zsh > ./dependencies/dprint/completions.zsh
    ${edge-pkgs.dprint}/bin/dprint completions fish > ./dependencies/dprint/completions.fish
  '';

  check_no_dirty_xz_in_nix_store = pkgs.writeShellApplication {
    name = "check_no_dirty_xz_in_nix_store";
    runtimeInputs = with pkgs; [ fd ];
    text = ''
      # nix store should have xz: https://github.com/NixOS/nixpkgs/blob/b96bc828b81140dd3fb096b4e66a6446d6d5c9dc/doc/stdenv/stdenv.chapter.md?plain=1#L177
      # You can't use --max-results instead of --has-results even if you want the log, it always returns true
      fd '^\w+-xz-[0-9\.]+\.drv' --search-path /nix/store --has-results

      # Why toggling errexit and return code here: https://github.com/kachick/times_kachick/issues/278
      set +o errexit
      fd '^\w+-xz-5\.6\.[01]\.drv' --search-path /nix/store --has-results
      fd_return_code="$?" # Do not directly use the $? to prevent feature broken if inserting another command before check
      set -o errexit
      [[ "$fd_return_code" -eq 1 ]]
    '';
    meta = {
      description = "Prevent #530 (around CVE-2024-3094)";
    };
  };
}
