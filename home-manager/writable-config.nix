{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Module to make a config file writable by initializing and syncing it from the Nix store.
  #
  # ## Why not use `impureConfigMerger`?
  #
  # Some Home Manager modules (like `programs.zed-editor`) have started using `impureConfigMerger`,
  # which merges Nix-managed settings with local changes. However, we intentionally avoid this for the following reasons:
  #
  # - **Predictability**: Copying the raw file with `u+w` is simpler and its behavior is clearer.
  # - **Portability**: This allows us to reuse the same config files (like `settings.json`) directly on non-Nix systems (Windows, etc.) with comments and schema validation intact.
  # - **Control**: Avoids the "impure" state where Nix might silently merge or conflict with local manual changes in a way that's hard to debug.
  #
  # ## How it works
  #
  # 1. Build a JSON manifest of `{ source, dest, perm }` entries in the Nix store.
  # 2. Run `dot-writable-sync` during `home.activation` after `writeBoundary` without leaving `HomeManagerInit_*` symlinks behind.
  # 3. Track the last synced source SHA-256 in XDG_STATE_HOME; warn with a unified diff before overwriting locally edited files.
  #
  # ## References
  #
  # - https://github.com/nix-community/home-manager/issues/3090
  # - https://github.com/nix-community/home-manager/issues/6835
  # - https://github.com/nix-community/home-manager/blob/77c47a454236cede268990eb3e457f062014f414/modules/programs/zed-editor.nix#L20-L38
  # - https://github.com/nix-community/home-manager/blob/77c47a454236cede268990eb3e457f062014f414/modules/programs/prismlauncher.nix#L79-L87
  #
  # ## Usage
  #
  # - `xdg.writableConfigFile."zed/settings.json".source = ../config/zed/settings.jsonc;`
  # - `home.writableFile.".ssh/authorized_keys" = { source = authorizedKeys; perm = "600"; };`

  fileType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.path;
        description = "Path of the source file or directory.";
      };

      perm = lib.mkOption {
        type = lib.types.str;
        default = "u+w";
        description = "Permission mode applied after copying the source file.";
      };
    };
  };

  manifestEntries =
    (lib.mapAttrsToList (target: cfg: {
      source = "${cfg.source}";
      dest = "${config.xdg.configHome}/${target}";
      inherit (cfg) perm;
    }) config.xdg.writableConfigFile)
    ++ (lib.mapAttrsToList (target: cfg: {
      source = "${cfg.source}";
      dest = if lib.hasPrefix "/" target then target else "${config.home.homeDirectory}/${target}";
      inherit (cfg) perm;
    }) config.home.writableFile);

  manifestFile = pkgs.writeText "writable-config-manifest.json" (builtins.toJSON manifestEntries);
in
{
  options = {
    xdg.writableConfigFile = lib.mkOption {
      type = lib.types.attrsOf fileType;
      default = { };
      description = "Configuration files to be initialized as writable in XDG_CONFIG_HOME.";
    };

    home.writableFile = lib.mkOption {
      type = lib.types.attrsOf fileType;
      default = { };
      description = "Files to be initialized as writable in HOME.";
    };
  };

  config = lib.mkIf (manifestEntries != [ ]) {
    home.activation.syncWritableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.getExe pkgs.local.dot-writable-sync} sync \
        ''${DRY_RUN:+--dry-run} \
        --manifest "${manifestFile}" \
        --state "${config.xdg.stateHome}/dot-writable-sync/state.json"
    '';
  };
}
