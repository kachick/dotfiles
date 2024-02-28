FROM kachick/sandbox-ubuntu-nix:13a7788

USER user

RUN mkdir -p ~/.local/state/nix/profiles

RUN nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user'
