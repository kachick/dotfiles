# Extracts upstream packages declared in this repository for hydra-check.
#
# WHY NOT nixpkgs' `maintainers/scripts/rebuild-amount.sh`?
# - `rebuild-amount.sh` measures rebuild impact between two git commits
#   by evaluating `pkgs/top-level/release.nix` with `nix-env -qaP`.
# - It requires a git-controlled nixpkgs checkout (fails on /nix/store paths).
# - It takes several minutes and gigabytes of RAM.
# - It cannot take arbitrary package names to query if they are leaves.
#
# WHY NOT 100% dynamic without `pnameToAttr` mappings?
# - Module options (`home.packages`, `systemPackages`) only store derivation objects.
#   Derivations hold `pname` (e.g. "du-dust", "fresh", "7zz"), but `hydra-check`
#   queries nixpkgs by attribute name (e.g. "dust", "fresh-editor", "_7zz").
# - Finding the attribute name for a given derivation requires searching all
#   top-level attributes in nixpkgs (tens of thousands of items), which is very slow.
# - A small explicit map for known name differences keeps evaluation instant.
#
# Usage examples:
#   # Print package list separated by space
#   nix eval --raw --file ./scripts/list-leaf-packages.nix
#
#   # Feed directly into hydra-check for unstable channel
#   hydra-check --channel unstable $(nix eval --raw --file ./scripts/list-leaf-packages.nix)
#
#   # Check on a specific stable release channel before bumping
#   hydra-check --channel 26.05 $(nix eval --raw --file ./scripts/list-leaf-packages.nix)

let
  getFlake = builtins.getAttr "getFlake" builtins;
  flake = getFlake (toString ./..);
  flakePath = toString flake.outPath;
  repoRoot = toString ./..;
  system = "x86_64-linux";
  pkgs = flake.inputs.nixpkgs.legacyPackages.${system};

  # Check if a definition location comes from this dotfiles repo
  isRepoFile =
    loc:
    builtins.isString loc
    && (
      (builtins.substring 0 (builtins.stringLength flakePath) loc) == flakePath
      || (builtins.substring 0 (builtins.stringLength repoRoot) loc) == repoRoot
    );

  # 1. Collect packages from Home Manager configurations
  hmPackages = builtins.concatLists (
    builtins.attrValues (
      builtins.mapAttrs (
        _: hmCfg:
        let
          defs = hmCfg.options.home.packages.definitionsWithLocations or [ ];
          repoDefs = builtins.filter (d: isRepoFile d.file) defs;
        in
        builtins.concatMap (
          d:
          let
            val = (builtins.tryEval d.value).value or [ ];
          in
          map (p: p.pname or (p.name or "unknown")) val
        ) repoDefs
      ) flake.outputs.homeConfigurations
    )
  );

  # 2. Collect packages from NixOS configurations (systemPackages + fonts)
  nixosPackages = builtins.concatLists (
    builtins.attrValues (
      builtins.mapAttrs (
        _: osCfg:
        let
          defs = osCfg.options.environment.systemPackages.definitionsWithLocations or [ ];
          repoDefs = builtins.filter (d: isRepoFile d.file) defs;

          fontDefs = osCfg.options.fonts.packages.definitionsWithLocations or [ ];
          repoFontDefs = builtins.filter (d: isRepoFile d.file) fontDefs;
          fonts = builtins.concatMap (
            d:
            let
              val = (builtins.tryEval d.value).value or [ ];
            in
            map (p: p.pname or (p.name or "unknown")) val
          ) repoFontDefs;
        in
        fonts
        ++ builtins.concatMap (
          d:
          let
            val = (builtins.tryEval d.value).value or [ ];
          in
          map (p: p.pname or (p.name or "unknown")) val
        ) repoDefs
      ) flake.outputs.nixosConfigurations
    )
  );

  # 3. Collect inputs from devShell
  devShellPackages =
    let
      ds = flake.outputs.devShells.${system}.default;
      allInputs = (ds.buildInputs or [ ]) ++ (ds.nativeBuildInputs or [ ]);
    in
    map (p: p.pname or (p.name or "unknown")) allInputs;

  # Dynamically collect all in-repo local packages from flake outputs to exclude
  localPackages = builtins.attrNames flake.outputs.packages.${system};

  # Common mappings where pname differs from the nixpkgs top-level attribute name
  pnameToAttr = {
    "du-dust" = "dust";
    "fresh" = "fresh-editor";
    "7zz" = "_7zz";
    "ShellCheck" = "shellcheck";
    "gnome-shell-extension-clipboard-history" = "gnomeExtensions.clipboard-history";
    "gnome-shell-extension-dash-to-dock" = "gnomeExtensions.dash-to-dock";
    "gnome-shell-extension-lock-keys" = "gnomeExtensions.lock-keys-2";
    "gnome-shell-extension-appindicator-support" = "gnomeExtensions.appindicator";
    "ibm-plex-mono" = "ibm-plex.mono";
    "ibm-plex-sans-japanese" = "ibm-plex.sans-jp";
    "ibm-plex-serif-variable" = "ibm-plex.serif-variable";
  };

  allRaw = hmPackages ++ nixosPackages ++ devShellPackages;

  # Remove local in-repo packages dynamically
  upstreamOnly = builtins.filter (p: !(builtins.elem p localPackages)) allRaw;

  # Normalize to attribute names when applicable
  mapped = map (p: pnameToAttr.${p} or p) upstreamOnly;

  # Deduplicate and sort
  unique = pkgs.lib.sort (a: b: a < b) (pkgs.lib.unique mapped);
in
builtins.concatStringsSep " " unique + "\n"
