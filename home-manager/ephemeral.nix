{ lib, ... }:

{
  imports = [ ./dev.nix ];

  home.username = lib.mkDefault "visitor";

  # Ephemeral environments do not have gopass or GPG keys, so keep SSH prompts interactive.
  home.sessionVariables.SSH_ASKPASS_REQUIRE = lib.mkForce "never";

  programs.git = {
    settings = {
      commit.gpgsign = lib.mkForce false;

      user = {
        # https://datatracker.ietf.org/doc/html/rfc6761
        email = "foobar@example.com";
        name = "Foo Bar";
      };

      git-x.user = "github";
    };
  };
}
