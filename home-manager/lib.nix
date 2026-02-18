{ config, lib, ... }:

{
  # Helper to make a config file writable by initializing it once from the Nix store.
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
  # - `mkWritableConfig.xdg "zed/settings.json" ../config/zed/settings.json { }`
  # - `mkWritableConfig.file "${sshDir}/authorized_keys" authorizedKeys { perm = "600"; }`

  mkWritableConfig =
    let
      # Inserts "HomeManagerInit_" before the filename in a path
      mkInitPath =
        path:
        let
          parts = lib.splitString "/" path;
          dir = lib.concatStringsSep "/" (lib.init parts);
          file = lib.last parts;
        in
        if dir == "" then "HomeManagerInit_${file}" else "${dir}/HomeManagerInit_${file}";
    in
    {
      # For xdg.configFile (relative to ~/.config)
      xdg =
        target: source:
        {
          perm ? "u+w",
        }:
        let
          initRelPath = mkInitPath target;
        in
        {
          "${initRelPath}" = {
            inherit source;
            onChange = ''
              dest="${config.xdg.configHome}/${target}"
              init="${config.xdg.configHome}/${initRelPath}"
              rm -f "$dest"
              cp "$init" "$dest"
              chmod ${perm} "$dest"
            '';
          };
        };

      # For home.file (can be absolute path)
      file =
        target: source:
        {
          perm ? "u+w",
        }:
        let
          initPath = mkInitPath target;
        in
        {
          "${initPath}" = {
            inherit source;
            onChange = ''
              rm -f "${target}"
              cp "${initPath}" "${target}"
              chmod ${perm} "${target}"
            '';
          };
        };
    };
}
