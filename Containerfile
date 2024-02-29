FROM kachick/sandbox-ubuntu-nix:sudoer-e6a4f3d

USER user
# Docker/Podman doesn't set $USER in USER instruction, and it makes failure in home-manager activation
# https://stackoverflow.com/questions/54411218/docker-why-isnt-user-environment-variable-set
ENV USER=user

WORKDIR /home/user

COPY ./ /home/user/dotfiles/

RUN mkdir -p ~/.local/state/nix/profiles \
  && nix-shell --packages git --command 'git config --global --add safe.directory /home/user/dotfiles' \
  && nix run '/home/user/dotfiles#home-manager' -- switch -b backup --flake '/home/user/dotfiles/#user' \
  && nix run '/home/user/dotfiles#sudo_enable_nix_login_shells' -- --dry_run=false \
  && sudo chsh user -s "$HOME/.nix-profile/bin/zsh" \
  && rm -rf /home/user/dotfiles \
  && nix store gc

CMD [ "/home/user/.nix-profile/bin/zsh" ]
