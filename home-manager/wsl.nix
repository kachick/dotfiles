{ pkgs, lib, ... }:

let
  commonSystemd = import ./systemd.nix { inherit pkgs lib; };
in

{
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/systemd.nix#L161-L173
  # Originally "system" should be better than "user", but it is not a home-manager role
  systemd.user = commonSystemd.systemd.user // {
    # - This name should be same of Mount.Where. Do not use `-` except path separator
    # - You can manually enable with `sudo systemctl enable ~/.config/systemd/user/mnt-wsl-instances-ubuntu24.mount --now`
    mounts.mnt-wsl-instances-ubuntu24 =
      # https://superuser.com/questions/1659218/is-there-a-way-to-access-files-from-one-wsl-2-distro-image-in-another-one
      {
        Unit = {
          Description = "Apply path that can be accessed from another WSL instance";
        };
        Mount = {
          What = "/";
          Where = "/mnt/wsl/instances/ubuntu24";
          Type = "none";
          Options = "defaults,bind,X-mount.mkdir";
        };
        Install = {
          WantedBy = [ "multi-user.target" ];
        };
      };

    # - Set same name of Mount definition
    # - You can manually enable with `systemctl enable --now mount-point.automount`
    automounts.mnt-wsl-instances-ubuntu24 = {
      Mount = {
        Where = "/mnt/wsl/instances/ubuntu24";
      };
      Install = {
        WantedBy = [ "multi-user.target" ];
      };
    };
  };

  home.packages = [ pkgs.wslu ];
}
