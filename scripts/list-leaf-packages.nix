# Heuristic extraction of "leaf" packages used in this repository.
#
# WHY NOT a strict reverse-dependency analysis on nixpkgs?
# A complete nixpkgs dependency graph traversal (checking if reverse dependencies == 0)
# takes huge memory and several minutes to evaluate.
#
# WHY NOT nixpkgs' `maintainers/scripts/rebuild-amount.sh`?
# - `rebuild-amount.sh` is designed to count rebuild impact between two git commits
#   (e.g., HEAD^ and HEAD) by evaluating `pkgs/top-level/release.nix` with `nix-env -qaP`.
# - It requires a git-controlled nixpkgs checkout (fails on /nix/store source paths).
# - It takes several minutes and gigabytes of RAM.
# - It cannot take arbitrary package names to check whether they are leaves.
#
# Instead, this script uses a lightweight heuristic:
# 1. Collect all packages declared directly in this dotfiles repository
#    (Home Manager, NixOS modules, devShells, programs.*) using
#    `definitionsWithLocations` from the module system.
# 2. Filter out internal packages (`pkgs.local`, `pkgs/by-name`).
# 3. Filter out well-known shared infrastructure (glibc, systemd, git, bash, etc.)
#    because upstream breakage on those core tools is caught quickly by nixpkgs CI.
# 4. Map package names (pnames) to nixpkgs attribute names for `hydra-check`.
#
# The result is a list of user-facing CLI/TUI tools, LSPs, desktop apps, and extensions
# that rarely break other packages, but often break silently across nixpkgs updates.
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

  # 4. Programs enabled in HM or NixOS configs that install packages
  programPackages = [
    "helix"
    "micro"
    "vim"
    "television"
    "fzf"
    "bat"
    "starship"
    "zoxide"
    "direnv"
    "gh"
    "git"
    "virt-manager"
    "steam"
    "coolercontrol"
    "nautilus-open-any-terminal"
    "dconf-editor"
    "wireshark"
  ];

  # List of local in-repo packages to exclude
  localPackages = [
    "antigravity-cli"
    "apply-system"
    "bench_shells"
    "bump_gomod"
    "chrome-with-profile-by-name"
    "cloudflare-warp"
    "cntr"
    "conoha-cli"
    "container-layered"
    "envs"
    "filen-cli-rs"
    "fzf-bind-posix-shell-history-to-git-commit-message"
    "gen-nix-cache-conf"
    "gh-actions-lock"
    "gh-prs"
    "ghadiag"
    "ghqf"
    "git-delete-merged-branches"
    "git-hooks-pre-push"
    "git-log-fzf"
    "git-log-fzf-ja"
    "git-log-simple"
    "git-reset-branch"
    "git-resolve-conflict"
    "git-show-ja"
    "hcpu_shogi"
    "home-manager"
    "ibus-engine-selector"
    "ir"
    "kanata-tray"
    "la"
    "lat"
    "lima"
    "lima-additional-guestagents"
    "lima-full"
    "ludii-bin"
    "micro-catppuccin"
    "micro-everforest"
    "micro-fzfinder"
    "micro-kdl"
    "micro-nordcolors"
    "microvm-sandbox"
    "nix-hash-url"
    "nix-update"
    "p"
    "plamo-trans"
    "podman-cntr"
    "posix_shared_functions"
    "preview"
    "rclone-fzf"
    "rclone-list-mounted"
    "rclone-mount"
    "renmark"
    "reponame"
    "rg-fzf"
    "safe_quote_backtik"
    "tailscaled-service"
    "tanuki-hao"
    "task-completions"
    "todo"
    "tree-diff"
    "wait-and-squashmerge"
    "walk"
    "yaneuraou-avx2"
    "zed-editor"
  ];

  # Core infrastructure tools that are NOT leaf packages (heavily depended on by nixpkgs)
  coreInfra = [
    "glibc"
    "bash-interactive"
    "bash"
    "zsh"
    "coreutils"
    "less"
    "procps"
    "findutils"
    "diffutils"
    "gnugrep"
    "libressl"
    "bind"
    "openssh"
    "iputils"
    "tailscale"
    "git"
    "curl"
    "wget"
    "jq"
    "tree"
    "file"
    "fontconfig"
    "gnumake"
    "glibc-locales"
    "iptables"
    "udisks"
    "upower"
    "fwupd"
    "bolt"
    "bluez"
    "dbus"
    "dbus-broker"
    "xorg-server"
    "systemd"
    "shadow"
    "util-linux"
    "kmod"
    "kexec-tools"
    "lvm2"
    "dosfstools"
    "bcache-tools"
    "xdg-user-dirs"
    "xdg-utils"
    "desktop-file-utils"
    "pciutils"
    "usbutils"
    "dmidecode"
    "smartmontools"
    "nvme-cli"
    "evtest"
    "psmisc"
    "wl-clipboard"
    "go"
    "ruby"
    "typescript"
    "qemu"
    "podman"
    "kubectl"
    "docker-compose"
  ];

  # Map pname to nixpkgs attribute name when they differ
  pnameToAttr = {
    "du-dust" = "dust";
    "fresh" = "fresh-editor";
    "7zz" = "_7zz";
    "ShellCheck" = "shellcheck";
    "gnome-shell-extension-clipboard-history" = "gnomeExtensions.clipboard-history";
    "gnome-shell-extension-dash-to-dock" = "gnomeExtensions.dash-to-dock";
    "gnome-shell-extension-lock-keys" = "gnomeExtensions.lock-keys";
    "gnome-shell-extension-appindicator-support" = "gnomeExtensions.appindicator";
    "ibm-plex-mono" = "ibm-plex.mono";
    "ibm-plex-sans-japanese" = "ibm-plex.sans-jp";
    "ibm-plex-serif-variable" = "ibm-plex.serif-variable";
  };

  rawAll = hmPackages ++ nixosPackages ++ devShellPackages ++ programPackages;

  # Remove local and core packages
  filtered = builtins.filter (
    p: !(builtins.elem p localPackages) && !(builtins.elem p coreInfra)
  ) rawAll;

  # Normalize to attribute names
  mapped = map (p: pnameToAttr.${p} or p) filtered;

  # Deduplicate and sort
  unique = pkgs.lib.sort (a: b: a < b) (pkgs.lib.unique mapped);
in
builtins.concatStringsSep " " unique + "\n"
