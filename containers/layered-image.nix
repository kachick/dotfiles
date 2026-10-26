{
  pkgs,
  homeConfigurations,
  corePackages,
}:

let
  hmConfig = homeConfigurations."user@container";
  hmFiles = "${hmConfig.activationPackage}/home-files";
  hmPath = "${hmConfig.activationPackage}/home-path";

  # Common libraries needed by typical dynamically linked binaries
  nixLdLibraries = pkgs.buildEnv {
    name = "nix-ld-libraries";
    pathsToLink = [ "/lib" ];
    paths = with pkgs; [
      zlib
      zstd
      stdenv.cc.cc.lib
      curl
      openssl
      util-linux
      xz
    ];
    ignoreCollisions = true;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "home-layered";
  tag = "latest";
  compressor = "zstd";

  # Automatically split packages and dependencies into up to 100 layers
  maxLayers = 100;

  contents = [
    # Include activationPackage closure so all tools and dependencies are in image layers
    hmConfig.activationPackage
    pkgs.cacert
    pkgs.nix-ld
    nixLdLibraries
  ]
  ++ corePackages;

  fakeRootCommands = ''
    mkdir -p ./tmp ./etc ./etc/ssl/certs ./bin ./usr/bin ./lib64 ./home/user
    chmod 1777 ./tmp

    # User & Group setup
    cat << 'EOF' > ./etc/passwd
    root:x:0:0:root:/root:/bin/sh
    user:x:1000:1000:user:/home/user:${hmPath}/bin/zsh
    EOF

    cat << 'EOF' > ./etc/group
    root:x:0:
    user:x:1000:
    EOF

    # Standard shell and env
    ln -sf ${pkgs.bashInteractive}/bin/sh ./bin/sh
    ln -sf ${pkgs.coreutils}/bin/env ./usr/bin/env

    # nix-ld dynamic linker stub for FHS binary compatibility
    ln -sf ${pkgs.nix-ld}/libexec/nix-ld ./lib64/ld-linux-x86-64.so.2

    # Symlink profile directory
    ln -sf ${hmPath} ./home/user/.nix-profile

    # Populate home directory files from home-manager-files
    # cp -dPR preserves symlinks to the Nix store and recreates directory hierarchies
    ${pkgs.coreutils}/bin/cp -dPR ${hmFiles}/. ./home/user/
    ${pkgs.coreutils}/bin/chmod -R u+w ./home/user/

    # Ensure correct ownership
    ${pkgs.coreutils}/bin/chown -R 1000:1000 ./home/user
  '';

  config = {
    Cmd = [ "${hmPath}/bin/zsh" ];
    User = "user";
    WorkingDir = "/home/user";
    Env = [
      "USER=user"
      "HOME=/home/user"
      "PATH=/home/user/.nix-profile/bin:/bin:/usr/bin"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NIX_LD=${pkgs.stdenv.cc.bintools.dynamicLinker}"
      "NIX_LD_LIBRARY_PATH=${nixLdLibraries}/lib"
      "TERM=xterm-256color"
    ];
  };
}
