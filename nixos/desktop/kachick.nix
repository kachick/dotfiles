{
  ...
}:

let
  mkUser = ./mkUser.nix;
in
{
  users.users.kachick = mkUser {
    description = ":)";
  };
}
