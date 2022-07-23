# public_dotfiles

[![Build Status](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)

dotfiles. Excluded sensitive information like command histories :yum:.

## Installation

At first, install one of terminal. (Or use vscode terminal.)

- Windows - Windows Terminal
- Mac OS - iTerm2 or tabby
- Linux - tabby

Manually install belows

1. "Ubuntu" or "Ubuntu on WSL2 or lima"
1. [`./bootstrap.sh`](bootstrap.sh)

See [.zshrc](.config/.zshrc) for overview and create symlinks to my $HOME
And do below

1. `zprezto-update`
1. Sync vscode config with cloud account

## Remember!

I would keep `not heavy` to lunch shell.

So do not forget to measure. If any loading changes are added.

Below useful benchmark script is taken from https://qiita.com/vintersnow/items/7343b9bf60ea468a4180. Thanks!

```zsh
for i in $(seq 1 10); do time zsh -i -c exit; done
```

## Dependent tools

- [Homebrew/brew](https://github.com/Homebrew/brew)
- [zsh-users/zsh](https://github.com/zsh-users/zsh)
- [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto)
- [git/git](https://github.com/git/git)
- [microsoft/vscode](https://github.com/microsoft/vscode)
- [asdf-vm/asdf](https://github.com/asdf-vm/asdf)
- [asdf-vm/asdf-ruby](https://github.com/asdf-vm/asdf-ruby) (includes [rbenv/ruby-build](https://github.com/rbenv/ruby-build))
- [asdf-vm/asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs)
- [asdf-community/asdf-dprint](https://github.com/asdf-community/asdf-dprint)
- [asdf-community/asdf-crystal](https://github.com/asdf-community/asdf-crystal)
- [asdf-community/asdf-deno](https://github.com/asdf-community/asdf-deno)
- [asdf-community/asdf-elm](https://github.com/asdf-community/asdf-elm)
- [ruby/irb](https://github.com/ruby/irb)
- [kachick/irb-power_assert](https://github.com/kachick/irb-power_assert)
- [gnachman/iTerm2](https://github.com/gnachman/iTerm2)

## Might add the dependency...

- [Eugeny/tabby](https://github.com/Eugeny/tabby)

## Note

- Do not manage rust with asdf. Prefer [official steps and rustup](https://www.rust-lang.org/ja/tools/install).
- [Which shell? zsh? bash? fish? nushell?](https://github.com/kachick/times_kachick/issues/184)
- [docker => singularity](https://github.com/kachick/times_kachick/issues/186)
- [Linux - Pop! OS](https://github.com/kachick/times_kachick/issues/174)
- [Colorize](https://github.com/kachick/times_kachick/issues/93)
