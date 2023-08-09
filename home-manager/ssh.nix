{ config, pkgs, ... }:

let
  # SSH files cannot use XDG Base Directory.
  # I don't have permission to read https://bugzilla.mindrot.org/show_bug.cgi?id=2050, but several sources tells us, it is the answer
  #   - https://wiki.archlinux.jp/index.php/XDG_Base_Directory
  #   - https://superuser.com/a/1606519/120469
  sshDir = "${config.home.homeDirectory}/.ssh";

  # - id_*: Do NOT share in different machines, do NOT tell to anyone. They are secrets.
  # - id_*.pub: I CAN register them for different services.
in
{
  # These hosts are taken from the public resources of each provider.
  #   - https://docs.github.com/ja/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
  #   - https://docs.gitlab.com/ee/user/gitlab_com/#ssh-known_hosts-entries
  #   - https://bitbucket.org/site/ssh
  home.file.".ssh/known_hosts".text = ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
    github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
    gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
    gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
    gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
    bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQeJzhupRu0u0cdegZIa8e86EG2qOCsIsD1Xw0xSeiPDlCr7kq97NLmMbpKTX6Esc30NuoqEEHCuc7yWtwp8dI76EEEB1VqY9QJq6vk+aySyboD5QF61I/1WeTwu+deCbgKMGbUijeXhtfbxSxm6JwGrXrhBdofTsbKRUsrN1WoNgUa8uqN1Vx6WAJw1JHPhglEGGHea6QICwJOAr/6mrui/oB7pkaWKHj3z7d1IC4KWLtY47elvjbaTlkN04Kc/5LFEirorGYVbt15kAUlqGM65pk6ZBxtaO3+30LVlORZkxOh+LKL/BvbZ/iRNhItLqNyieoQj/uh/7Iv4uyH/cV/0b4WDSd3DptigWq84lJubb9t/DnZlrJazxyDCulTmKdOR7vs9gMTo+uoIrPSb8ScTtvw65+odKAlBj59dhnVp9zd7QUojOpXlL62Aw56U4oO+FALuevvMjiWeavKhJqlR7i5n9srYcrNV7ttmDw7kf/97P5zauIhxcjX+xHv4M=
    bitbucket.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPIQmuzMBuKdWeF4+a2sjSSpBK0iqitSQ+5BM9KhpexuGt20JpTVM7u5BDZngncgrqDMbWdxMWWOGtZ9UgbqgZE=
    bitbucket.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO
  '';

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/ssh.nix
  programs.ssh = {
    enable = true;

    # https://groups.google.com/g/opensshunixdev/c/e5-kTKpxcaI/m/bdVNyL4BBAAJ
    hashKnownHosts = false;
    userKnownHostsFile = "${sshDir}/known_hosts";

    # unit: seconds
    serverAliveInterval = 60;

    forwardAgent = true;

    controlMaster = "auto";
    controlPersist = "10m";

    # Enable custom or temporary config without `home-manager switch`
    includes = [
      "${sshDir}/config.local"
    ];

    # https://www.clear-code.com/blog/2023/4/3/recommended-ssh-config.html
    # https://gitlab.com/clear-code/ssh.d/-/blob/main/global.conf?ref_type=heads
    extraConfig = ''
      AddKeysToAgent yes

      PasswordAuthentication no

      # default: "ask" - I'm disabling it for now
      StrictHostKeyChecking yes

      # https://serverfault.com/a/1109184/112217
      CheckHostIP no

      # `UseKeychain` only provided by darwin ssh agent, in Linux and pkgs.openssh, it isn't
      IgnoreUnknown UseKeychain
      UseKeychain yes
    '';

    # No problem to register the same *.pub in different services
    matchBlocks = {
      "github.com" = {
        identityFile = "${sshDir}/id_ed25519";
        identitiesOnly = true;
        user = "git";
      };

      "gitlab.com" = {
        identityFile = "${sshDir}/id_ed25519";
        identitiesOnly = true;
        user = "git";
      };

      "bitbucket.org" = {
        identityFile = "${sshDir}/id_ed25519";
        identitiesOnly = true;
        user = "git";
      };
    };
  };
}
