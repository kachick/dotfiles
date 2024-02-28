FROM kachick/sandbox-ubuntu-nix:13a7788

# gosu didn't resolve
#   - error: could not set permissions on '/nix/var/nix/profiles/per-user' to 755: Operation not permitted
RUN apt-get update \
 && apt-get install --no-install-recommends -y sudo=1.9.9-1ubuntu2.4 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# RUN usermod -aG sudo user
RUN echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN echo 'Defaults env_keep += "PATH"' >> /etc/sudoers

ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

USER user

ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

RUN mkdir -p ~/.local/state/nix/profiles

RUN sudo /nix/var/nix/profiles/default/bin/nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user'
