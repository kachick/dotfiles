{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "safe_quote_backtik";
  meta = {
    description = "Quote `body` without command executions";
  };
  text = builtins.readFile ./safe_quote_backtik.bash;
}
