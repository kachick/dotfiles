FROM kachick/sandbox-ubuntu-nix:sudoer-e6a4f3d

USER user
# Docker doesn't set $USER in USER instruction, and it makes failure in home-manager activation
# https://stackoverflow.com/questions/54411218/docker-why-isnt-user-environment-variable-set
ENV USER=user

RUN mkdir -p ~/.local/state/nix/profiles

RUN nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user'

CMD [ "/bin/bash" ]
