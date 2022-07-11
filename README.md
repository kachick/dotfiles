# What is this repository

Personal dotfiles for @kachick. Excluded sensitive commands/histories :yum:.

## Installation

At first, install one of terminal. (Or use vscode terminal.)

- Windows - Windows Terminal
- Mac OS - iTerm2 or tabby
- Linux - tabby

Manually install belows

1. vscode
1. (if windows) WSL2
1. brew
1. asdf-vm
1. `asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git`
1. `asdf install nodejs 16.15.1` ref: [LTS](https://nodejs.org/en/download/)
1. chruby
1. ruby-install
1. `ruby-install ruby-3.1.2` ref: [News(ja)](https://www.ruby-lang.org/ja/news/)

See .zshrc for overview and copy them to my $HOME
And do below

1. `zprezto-update`
1. Sync vscode config with cloud account

## Maintenance policy

I would keep `not heavy` to lunch shell.

So do not forget to measure. If any loading changes are added.

Below useful benchmark script is taken from https://qiita.com/vintersnow/items/7343b9bf60ea468a4180. Thanks!

```zsh
for i in $(seq 1 10); do time zsh -i -c exit; done
```

## Other references

- [Linux - Pop! OS](https://github.com/kachick/times_kachick/issues/174)
- [Colorize](https://github.com/kachick/times_kachick/issues/93)
