# Do not add `--graph`, it makes it too slow in large repositories such as NixOS/nixpkgs
git log --format='format:%C(cyan)%ad %C(auto)%h %C(auto)%s %C(auto)%d' --date=short --color=always
