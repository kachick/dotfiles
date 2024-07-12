# fzf

- `--preview`: the placeholder will be quoted by singlequote, so do not add excess double quote as "{}". This will be evaluated the given `` and $()
- `--nth`: Match there
- `--with-nth`: Whole display and outputs. None of only outputs: See https://github.com/junegunn/fzf/issues/1323
- `--bind 'enter:become(...)'`: Replace process, and no execution if not match
- `--ansi`: Handle colored input, but remember the output is dirty with the ANSI for another tools. You may need strip them before use.
