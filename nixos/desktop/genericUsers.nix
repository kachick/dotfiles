{
  ...
}:

let
  mkUser = import ./mkUser.nix;
in
{
  users.users = {
    user = mkUser { };
  };
}
