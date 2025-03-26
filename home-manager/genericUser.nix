{ lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = lib.mkDefault "user";

  programs.git = {
    # https://datatracker.ietf.org/doc/html/rfc6761
    userEmail = "foobar@example.com";
    userName = "Foo Bar";

    extraConfig = {
      ghq.user = "github";
    };
  };
}
