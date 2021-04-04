# What is this repository

Personal dotfiles for @kachick. Excluded sensitive commands/histories :yum:.

## Maintenance policy

I would keep `not heavy` to lunch shell.

So do not forget to measure. If any loading changes are added.

Below useful benchmark script is taken from https://qiita.com/vintersnow/items/7343b9bf60ea468a4180. Thanks!

```zsh
for i in $(seq 1 10); do time zsh -i -c exit; done
```
