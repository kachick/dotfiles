{
  config,
  lib,
  ...
}:

let
  # Module to make a config file writable by initializing it once from the Nix store.
  #
  # ## Why not use `impureConfigMerger`?
  #
  # Some Home Manager modules (like `programs.zed-editor`) have started using `impureConfigMerger`,
  # which merges Nix-managed settings with local changes. However, we intentionally avoid this for the following reasons:
  #
  # - **Predictability**: The `HomeManagerInit` pattern (copy + chmod) is simpler and its behavior is clearer.
  # - **Portability**: This allows us to reuse the same config files (like `settings.json`) directly on non-Nix systems (Windows, etc.) with comments and schema validation intact.
  # - **Control**: Avoids the "impure" state where Nix might silently merge or conflict with local manual changes in a way that's hard to debug.
  #
  # ## How it works
  #
  # 1. Define a "Init" file in the Nix store (prefixed with "HomeManagerInit_").
  # 2. Use `onChange` to `rm`, `cp`, and `chmod +w` the file to its final destination.
  # 3. This ensures that after a `home-manager switch`, the file is writable but initialized with our managed content.
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
  # - `xdg.writableConfigFile."zed/settings.json".source = ../config/zed/settings.json;`
  # - `home.writableFile.".ssh/authorized_keys" = { source = authorizedKeys; perm = "600"; };`

  # Inserts "HomeManagerInit_" before the filename in a path
  mkInitPath =
    path:
    let
      parts = lib.splitString "/" path;
      dir = lib.concatStringsSep "/" (lib.init parts);
      file = lib.last parts;
    in
    if dir == "" then "HomeManagerInit_${file}" else "${dir}/HomeManagerInit_${file}";

  fileType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.path;
        description = "Path of the source file or directory.";
      };

      perm = lib.mkOption {
        type = lib.types.str;
        default = "u+w";
        description = "Permission mode passed to chmod after copying the init file.";
      };
    };
  };
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

  config = {
    xdg.configFile = lib.mapAttrs' (
      target: cfg:
      let
        initRelPath = mkInitPath target;
      in
      lib.nameValuePair initRelPath {
        inherit (cfg) source;
        onChange = ''
          dest="${config.xdg.configHome}/${target}"
          init="${config.xdg.configHome}/${initRelPath}"
          rm -f "$dest"
          cp "$init" "$dest"
          chmod ${cfg.perm} "$dest"
        '';
      }
    ) config.xdg.writableConfigFile;

    home.file = lib.mapAttrs' (
      target: cfg:
      let
        initPath = mkInitPath target;
        dest = if lib.hasPrefix "/" target then target else "${config.home.homeDirectory}/${target}";
        init = if lib.hasPrefix "/" initPath then initPath else "${config.home.homeDirectory}/${initPath}";
      in
      lib.nameValuePair initPath {
        inherit (cfg) source;
        onChange = ''
          dest="${dest}"
          init="${init}"
          rm -f "$dest"
          cp "$init" "$dest"
          chmod ${cfg.perm} "$dest"
        '';
      }
    ) config.home.writableFile;
  };
}
