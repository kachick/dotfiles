name="$(basename "$PWD")"

zellij attach "$name" || zellij --session "$name"
