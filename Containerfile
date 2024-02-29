FROM kachick/sandbox-ubuntu-nix:sudoer-e6a4f3d

USER user
# Docker/Podman doesn't set $USER in USER instruction, and it makes failure in home-manager activation
# https://stackoverflow.com/questions/54411218/docker-why-isnt-user-environment-variable-set
ENV USER=user

RUN mkdir -p ~/.local/state/nix/profiles

COPY ./ /dotfiles/
WORKDIR /dotfiles

RUN nix-shell --packages git --command 'git config --global --add safe.directory /dotfiles'

RUN nix run '.#home-manager' -- switch -b backup --flake '.#user'
RUN nix run '.#sudo_enable_nix_login_shells' -- --dry_run=false
RUN sudo chsh user -s "$HOME/.nix-profile/bin/zsh"

WORKDIR /home/user
RUN sudo rm -rf /dotfiles
RUN nix store gc

CMD [ "/home/user/.nix-profile/bin/zsh" ]
