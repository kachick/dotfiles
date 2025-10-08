{
  lib,
  config,
  pkgs,
  ...
}:

{
  home = {
    sessionVariables = {
      # https://github.com/NixOS/nixpkgs/commit/a881767c939773a5f98eef7347d7ba9ba84eb531
      DO_NOT_TRACK = "1";

      # https://github.com/google-gemini/gemini-cli/blob/8ac2c6842d222c6417f6de365878b66056656e48/docs/cli/telemetry.md?plain=1#L58
      GEMINI_TELEMETRY_ENABLED = "false";
    };

    activation = {
      # go generally put on .config/go/telemetry, however using the cmd is the recommended way
      # ref: https://go.dev/doc/telemetry
      disableGoTelemetry = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        ${lib.getExe pkgs.go_1_24} telemetry off
      '';

      # GH-1228: Disable podman-desktop Telemetry.
      # podman-desktop does not provide CLI configurable features likely ENV
      # ref: https://github.com/podman-desktop/podman-desktop/blob/db85f0197406b42dc8a0bd8ef5661e8c19c30e80/.devcontainer/.parent/Containerfile#L36-L38
      disablePodmanDesktopTelemetry =
        let
          configPath = "${config.xdg.dataHome}/containers/podman-desktop/configuration/settings.json";
        in
        config.lib.dag.entryAnywhere ''
          if [[ -f '${configPath}' ]]; then
            ${lib.getExe pkgs.jq} '. "telemetry.check" = true | . "telemetry.enabled" = false' '${configPath}' | "${lib.getExe' pkgs.moreutils "sponge"}" '${configPath}'
          else
            echo '{"telemetry.enabled": false, "telemetry.check": true}' > '${configPath}'
          fi
        '';
    };
  };

  # Preparation for home.activation
  xdg.dataFile."containers/podman-desktop/configuration/.keep".text = "";
}
