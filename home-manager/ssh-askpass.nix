# Configure SSH_ASKPASS with gopass for environments with encryption tools.
{
  pkgs,
  lib,
  ...
}:

{
  home.sessionVariables = {
    # 'force' ignores $DISPLAY. 'prefer' is not enough
    SSH_ASKPASS_REQUIRE = "force";
    SSH_ASKPASS = pkgs.lib.getExe (
      pkgs.writeShellApplication {
        name = "ssh-ask-pass";
        text = "gopass show ssh-pass";
        meta.description = "GH-714. Required to be wrapped with one command because of SSH_ASKPASS does not accept arguments.";
        runtimeInputs = with pkgs; [
          gopass
          sequoia-chameleon-gnupg
        ];
        runtimeEnv = {
          GOPASS_GPG_BINARY = lib.getExe pkgs.sequoia-chameleon-gnupg;
        };
      }
    );
  };
}
