{
  pkgs,
  homeConfigurations,
  corePackages,
  lastModifiedDate,
}:

let
  hmConfig = homeConfigurations."user@container";
  hmFiles = "${hmConfig.activationPackage}/home-files";
  hmPath = "${hmConfig.activationPackage}/home-path";

  # Convert flake lastModifiedDate (YYYYMMDDHHMMSS) to ISO-8601 UTC so the
  # image timestamp is human-readable while staying reproducible per commit.
  created =
    let
      s = builtins.substring;
    in
    "${s 0 4 lastModifiedDate}-${s 4 2 lastModifiedDate}-${s 6 2 lastModifiedDate}T${s 8 2 lastModifiedDate}:${s 10 2 lastModifiedDate}:${s 12 2 lastModifiedDate}Z";

  baseImage = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/kachick/ubuntu-26.04-nix-systemd";
    imageDigest = "sha256:8297d9b421eaa96d22334818e6b6a24ba0173011b55974ac1d49b9b6ca46bc6e";
    finalImageName = "ghcr.io/kachick/ubuntu-26.04-nix-systemd";
    finalImageTag = "latest";
    hash = "sha256-O8GCfajqr1DKo2ArYZpA79452IMMC1c90JYL8lOVBBc=";
  };

  nixSettings = (import ../nixos/nix.nix).nix.settings;
  nixConf = pkgs.writeText "nix.conf" (
    pkgs.lib.concatStringsSep "\n" (
      (pkgs.lib.mapAttrsToList (
        k: v:
        if builtins.isList v then
          "${k} = ${builtins.concatStringsSep " " v}"
        else if builtins.isBool v then
          "${k} = ${if v then "true" else "false"}"
        else
          "${k} = ${toString v}"
      ) nixSettings)
      ++ [
        "sandbox = false"
        "extra-trusted-users = user"
      ]
    )
  );
in
pkgs.dockerTools.buildLayeredImage {
  name = "home";
  tag = "latest";
  inherit created;
  fromImage = baseImage;
  compressor = "zstd";
  includeNixDB = true;

  # Automatically split packages and dependencies into up to 100 layers
  maxLayers = 100;

  # Keep contents minimal so symlinkJoin does not link /bin, /usr, /lib, or /etc
  # into the root filesystem on top of Ubuntu's base directories.
  # hmConfig.activationPackage does not expose top-level /bin or /etc, so only
  # its /nix/store closure is distributed across the 100 store layers.
  contents = [
    hmConfig.activationPackage
    pkgs.glibcLocales
    pkgs.nix
  ]
  ++ corePackages;

  extraCommands = ''
    rm -rf bin etc lib lib64 sbin share usr var home-files home-path activate
  '';

  fakeRootCommands = ''
    mkdir -p \
      ./etc/containers \
      ./etc/default \
      ./etc/nix \
      ./etc/ssh \
      ./etc/systemd/system/sockets.target.wants \
      ./usr/lib/locale \
      ./nix/var/nix/daemon-socket \
      ./nix/var/nix/profiles/per-user/user \
      ./nix/var/nix/gcroots/per-user/user \
      ./home/user/.local/state/nix/profiles \
      ./home/user/.local/state/home-manager/gcroots \
      ./home/user/.local/state/dot-writable-sync \
      ./home/user/.local/share/gnupg \
      ./home/user/.ssh

    # System-level adjustments matching apply-system
    touch ./etc/ssh/ssh_config
    chmod 0600 ./etc/ssh/ssh_config
    ln -sf ${pkgs.glibcLocales}/lib/locale/locale-archive ./usr/lib/locale/locale-archive
    ln -sf ${../config/containers/policy.json} ./etc/containers/policy.json
    ln -sf ${../config/tailscaled/defaults.conf} ./etc/default/tailscaled
    ln -sf ${pkgs.local.tailscaled-service} ./etc/systemd/system/tailscaled.service

    # Point nix-daemon and default profile to pkgs.nix registered in this image's Nix DB
    ln -sf ${nixConf} ./etc/nix/nix.conf
    ln -sfn ${pkgs.nix} ./nix/var/nix/profiles/default
    ln -sf ${pkgs.nix}/lib/systemd/system/nix-daemon.service ./etc/systemd/system/nix-daemon.service
    ln -sf ${pkgs.nix}/lib/systemd/system/nix-daemon.socket ./etc/systemd/system/nix-daemon.socket
    ln -sf ${pkgs.nix}/lib/systemd/system/nix-daemon.socket ./etc/systemd/system/sockets.target.wants/nix-daemon.socket

    # Home Manager profile and GC root registration
    ln -sfn ${hmPath} ./home/user/.nix-profile
    ln -sfn ${hmConfig.activationPackage} ./home/user/.local/state/nix/profiles/home-manager-1-link
    ln -sfn home-manager-1-link ./home/user/.local/state/nix/profiles/home-manager
    ln -sfn ${hmConfig.activationPackage} ./home/user/.local/state/home-manager/gcroots/current-home

    # Populate home directory files from home-manager-files
    ${pkgs.coreutils}/bin/cp -dPR ${hmFiles}/. ./home/user/
    ${pkgs.coreutils}/bin/chmod -R u+w ./home/user/
    chmod 0700 ./home/user/.local/share/gnupg
    touch ./home/user/.ssh/known_hosts.local

    # Initialize writable config files managed by dot-writable-sync
    ${pkgs.lib.getExe pkgs.local.dot-writable-sync} sync \
      --manifest "${
        pkgs.writeText "writable-config-manifest.json" (
          builtins.toJSON (
            (pkgs.lib.mapAttrsToList (target: cfg: {
              source = "${cfg.source}";
              dest = "./home/user/.config/${target}";
              inherit (cfg) perm;
            }) hmConfig.config.xdg.writableConfigFile)
            ++ (pkgs.lib.mapAttrsToList (target: cfg: {
              source = "${cfg.source}";
              dest =
                if pkgs.lib.hasPrefix "/home/user/" target then
                  ".${target}"
                else if pkgs.lib.hasPrefix "/" target then
                  target
                else
                  "./home/user/${target}";
              inherit (cfg) perm;
            }) hmConfig.config.home.writableFile)
          )
        )
      }" \
      --state "./home/user/.local/state/dot-writable-sync/state.json"

    # Extract files from the latest baseImage layer that contains them
    extract_from_base() {
      local target="$1"
      local layer
      for layer in $(
        ${pkgs.gnutar}/bin/tar -xOf ${baseImage} manifest.json \
          | ${pkgs.jq}/bin/jq -r '.[0].Layers | reverse | .[]'
      ); do
        if ${pkgs.gnutar}/bin/tar -xOf ${baseImage} "$layer" \
          | ${pkgs.gnutar}/bin/tar -xOf - "$target" 2>/dev/null; then
          return 0
        fi
        if ${pkgs.gnutar}/bin/tar -xOf ${baseImage} "$layer" \
          | ${pkgs.gnutar}/bin/tar -xOf - "./$target" 2>/dev/null; then
          return 0
        fi
      done
      return 1
    }

    base_passwd="$(extract_from_base etc/passwd)"
    base_group="$(extract_from_base etc/group)"

    # Add nixbld group and build users (30001..30032) when the base image does not include Nix
    if ! printf '%s\n' "$base_group" | ${pkgs.gnugrep}/bin/grep -q '^nixbld:'; then
      mkdir -p ./var/empty
      chmod 0555 ./var/empty
      nixbld_members="$(${pkgs.coreutils}/bin/seq -s, -f 'nixbld%g' 1 32)"
      {
        printf '%s\n' "$base_group"
        printf 'nixbld:x:30000:%s\n' "$nixbld_members"
      } > ./etc/group
      {
        printf '%s\n' "$base_passwd"
        for i in $(${pkgs.coreutils}/bin/seq 1 32); do
          printf 'nixbld%d:x:%d:30000:Nix build user %d:/var/empty:/usr/sbin/nologin\n' "$i" "$((30000 + i))" "$i"
        done
      } > ./etc/passwd
    fi

    # Extract UID and GID of 'user' dynamically from baseImage /etc/passwd
    base_uid_gid="$(
      printf '%s\n' "$base_passwd" \
        | ${pkgs.gawk}/bin/awk -F: '$1 == "user" { print $3 ":" $4 }'
    )"
    if [ -z "$base_uid_gid" ]; then
      echo "Error: Could not find 'user' entry in baseImage /etc/passwd" >&2
      exit 1
    fi
    ${pkgs.coreutils}/bin/chown -R "$base_uid_gid" \
      ./home/user \
      ./nix/var/nix/profiles/per-user/user \
      ./nix/var/nix/gcroots/per-user/user
  '';

  config = {
    Cmd = [
      "/usr/lib/systemd/systemd"
      "--system"
    ];
    User = "root";
    Env = [
      "PATH=/home/user/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ];
  };
}
