{
  ...
}:

let
  mkUser = import ./mkUser.nix;
in
{
  users.users.kachick = mkUser {
    description = "foolish";
  };
}
