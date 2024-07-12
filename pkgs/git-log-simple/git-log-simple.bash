# Do not add `--graph`, it makes too slow in large repository as NixOS/nixpkgs
git log --format='format:%C(cyan)%ad %C(auto)%h %C(auto)%s %C(auto)%d' --date=short --color=always
