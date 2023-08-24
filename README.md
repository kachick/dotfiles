# dotfiles

[![Home Status](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-home.yml?query=branch%3Amain+)
[![Nix Status](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-nix.yml?query=branch%3Amain+)
[![CI - Go Status](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml/badge.svg?branch=main)](https://github.com/kachick/dotfiles/actions/workflows/ci-go.yml?query=branch%3Amain+)

Personal dotfiles that can be placed in the public repository

Also known as [盆栽(bonsai)](https://en.wikipedia.org/wiki/Bonsai) 🌳

## Installation

1. If you are installing a Unix-like operating system, install the [Nix](https://nixos.org/) package manager first.
   \
   Typically, this should be done in **one of** the following ways.
   - `sh <(curl -L https://nixos.org/nix/install) --daemon`
   - `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
1. This repository is a flake, that includes installation steps of [home-manager](https://github.com/nix-community/home-manager) and dotfiles, you can run as follows
   - `nix run github:kachick/dotfiles#home-manager -- switch -b backup --flake github:kachick/dotfiles#kachick`
1. If you experience any problems with the installation, See https://github.com/kachick/dotfiles/wiki/Installation for more details.
1. If you are on the development of this repository, the simple reactivation just needs to run as follows.
   - `makers apply`
