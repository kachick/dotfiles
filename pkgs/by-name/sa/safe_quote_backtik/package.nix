{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "safe_quote_backtik";
  meta = {
    description = "Quote `body` without command executions";
  };
  text = builtins.readFile ./${name}.bash;
}
