{
  pkgs,
  declaredRunner,
}:

pkgs.writeShellApplication {
  name = "microvm-sandbox";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.iproute2
    pkgs.openssh
  ];
  text = ''
    export MICROVM_RUN=${pkgs.lib.escapeShellArg "${declaredRunner}/bin/microvm-run"}
    exec ${pkgs.lib.getExe pkgs.bash} ${./microvm-sandbox.bash} "$@"
  '';
}
