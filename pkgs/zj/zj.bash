name="$(basename "$PWD")"

zellij attach "$name" || zellij --session "$name" --layout "$ZELLIJ_LAYOUT_BPS_PATH"
