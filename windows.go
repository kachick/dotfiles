package dotfiles

import "embed"

//go:embed all:windows/*
//go:embed config/powershell/*
//go:embed config/nushell/*
//go:embed config/starship/*
//go:embed config/alacritty/*
//go:embed config/ox/*
var WindowsAssets embed.FS
