package dotfiles

import "embed"

//go:embed all:windows/*
//go:embed config/powershell/*
//go:embed config/nushell/*
//go:embed config/starship/*
//go:embed config/alacritty/*
//go:embed config/keyboards/kanata.kbd
//go:embed config/zed/settings.jsonc
//go:embed config/fresh/config.jsonc
var WindowsAssets embed.FS
