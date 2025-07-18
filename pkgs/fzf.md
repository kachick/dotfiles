# fzf

- `--preview`: the placeholder will be quoted by singlequote, so do not add excess double quote as "{}". This will be evaluated the given `` and $()
- `--nth`: Match there
- `--with-nth`: Whole display and outputs.
- `--bind 'enter:become(...)'`: Replace process, and no execution if not match
- `--ansi`: Handle colored input, but remember the output is dirty with the ANSI for another tools. You may need strip them before use.

## Traps

- Cannot copy from preview window
- `become` with `export -f the_func` is broken in darwin. Create another command and inejct it
- [No feature to output only nth](https://github.com/junegunn/fzf/issues/1323)
- [No multiple modifiers for binding](https://github.com/junegunn/fzf/pull/3996)
