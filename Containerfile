FROM kachick/sandbox-ubuntu-nix:sudoer-e6a4f3d

USER user
# Docker/Podman doesn't set $USER in USER instruction, and it makes failure in home-manager activation
# https://stackoverflow.com/questions/54411218/docker-why-isnt-user-environment-variable-set
ENV USER=user

WORKDIR /home/user

COPY ./ /tmp/dotfiles/

# Keep cleaning tmp files after nix store gc
# to avoid "removing stale link from..."
RUN mkdir -p ~/.local/state/nix/profiles \
  && nix-shell --packages git --command 'git config --global --add safe.directory /tmp/dotfiles' \
  && nix run '/tmp/dotfiles#home-manager' -- switch -b backup --flake '/tmp/dotfiles/#user' \
  && nix run '/tmp/dotfiles#sudo_enable_nix_login_shells' -- --dry_run=false \
  && sudo chsh user -s "$HOME/.nix-profile/bin/zsh" \
  && nix store gc \
  && sudo rm -rf /tmp/dotfiles

CMD [ "/home/user/.nix-profile/bin/zsh" ]
