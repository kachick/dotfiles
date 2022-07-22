# public_dotfiles

[![Build Status](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/kachick/public_dotfiles/actions/workflows/lint.yml?query=branch%3Amain+)

dotfiles. Excluded sensitive information like command histories :yum:.

## Installation

At first, install one of terminal. (Or use vscode terminal.)

- Windows - Windows Terminal
- Mac OS - iTerm2 or tabby
- Linux - tabby

Manually install belows

1. vscode
1. (if windows) WSL2
1. `./install.bash`

See .zshrc for overview and create symlinks to my $HOME
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

## Other references

- [Linux - Pop! OS(ja)](https://github.com/kachick/times_kachick/issues/174)
- [Colorize(ja)](https://github.com/kachick/times_kachick/issues/93)

## Dependent tools

- [zsh-users/zsh](https://github.com/zsh-users/zsh)
- [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto)
- [git/git](https://github.com/git/git)
- [microsoft/vscode](https://github.com/microsoft/vscode)
- [Homebrew/brew](https://github.com/Homebrew/brew)
- [asdf-vm/asdf](https://github.com/asdf-vm/asdf)
- [asdf-vm/asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs)
- [asdf-community/asdf-dprint](https://github.com/asdf-community/asdf-dprint)
- [asdf-community/asdf-crystal](https://github.com/asdf-community/asdf-crystal)
- [asdf-community/asdf-deno](https://github.com/asdf-community/asdf-deno)
- [asdf-community/asdf-elm](https://github.com/asdf-community/asdf-elm)
- [asdf-community/asdf-haskell](https://github.com/asdf-community/asdf-haskell)
- [postmodern/chruby](https://github.com/postmodern/chruby)
- [postmodern/ruby-install](https://github.com/postmodern/ruby-install)
- [ruby/irb](https://github.com/ruby/irb)
- [kachick/irb-power_assert](https://github.com/kachick/irb-power_assert)
- [gnachman/iTerm2](https://github.com/gnachman/iTerm2)

## Might add the dependency...

- [Eugeny/tabby](https://github.com/Eugeny/tabby)
