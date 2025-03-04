{
  ...
}:

let
  mkUser = ./mkUser.nix;
in
{
  users.users = {
    user = mkUser { };
  };
}
