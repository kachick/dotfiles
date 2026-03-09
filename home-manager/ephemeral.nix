{ lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = lib.mkDefault "user";

  programs.git = {
    settings = {
      user = {
        # https://datatracker.ietf.org/doc/html/rfc6761
        email = "foobar@example.com";
        name = "Foo Bar";
      };

      ghq.user = "github";
    };
  };
}
