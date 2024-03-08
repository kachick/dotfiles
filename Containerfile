# https://github.com/kachick/containers
FROM ghcr.io/kachick/ubuntu-nix-sudoer:6a2983f2568ac3394fd175b696504fa5aafb82b6

LABEL org.opencontainers.image.source=https://github.com/kachick/dotfiles
LABEL org.opencontainers.image.description="Example by kachick/dotfiles"
LABEL org.opencontainers.image.licenses=MIT

USER user
# Docker/Podman doesn't set $USER in USER instruction, and it makes failure in home-manager activation
# https://stackoverflow.com/questions/54411218/docker-why-isnt-user-environment-variable-set
ENV USER=user

# Keep this for after login, even we don't need in build. Removing this step does not affect the image size.
WORKDIR /home/user

COPY ./ /tmp/dotfiles/

RUN mkdir -p ~/.local/state/nix/profiles \
  && nix-shell --packages git --command 'git config --global --add safe.directory /tmp/dotfiles' \
  && nix run '/tmp/dotfiles#home-manager' -- switch -b backup --flake '/tmp/dotfiles/#user' \
  && nix store gc

RUN sudo rm -rf /tmp/dotfiles

# Keep this even if you add a shell switcher as #452
CMD [ "/home/user/.nix-profile/bin/zsh" ]
