# fzf Tips and Tricks

This document contains a collection of notes on using `fzf`, covering useful options and common pitfalls.

## Useful Options

- `--preview`
  - The `{}` placeholder is automatically quoted. Avoid adding extra quotes like `"{}"`.
  - The preview command will evaluate backticks (``) and `$()`.

- `--nth`
  - Specifies which fields to use for searching.

- `--with-nth`
  - Specifies which fields to display in the `fzf` list and include in the output.

- `--bind 'enter:become(...)'`
  - Replaces the `fzf` process with the specified command upon pressing `Enter`.
  - If there is no match, no command is executed.

- `--ansi`
  - Enables `fzf` to interpret ANSI color codes in the input.
  - **Note:** The output will also contain these ANSI codes, which might be problematic for other tools. You may need to strip them before piping the output elsewhere.

## Common Pitfalls and Limitations

- **Copying from Preview:** You cannot directly copy text from the preview window.
- **`become` on macOS:** Using `become` with an exported shell function (`export -f my_func`) is broken on macOS (Darwin). The workaround is to create a separate executable script and call that instead.
- **Outputting Specific Fields:** There is no built-in feature to output only a specific field (like `awk '{print $2}'`). See [fzf issue #1323](https://github.com/junegunn/fzf/issues/1323).
- **Multiple Keybind Modifiers:** Bindings do not support multiple modifiers (e.g., `ctrl-alt-s`). See [fzf PR #3996](https://github.com/junegunn/fzf/pull/3996).
