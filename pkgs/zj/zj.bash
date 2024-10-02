name="$(basename "$PWD")"

zellij attach "$name" || zellij --session "$name" --layout "$ZELLIJ_DEFAULT_LAYOUT_PATH"
