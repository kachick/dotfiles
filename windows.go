package dotfiles

import "embed"

//go:embed windows/*
//go:embed config/starship/*
//go:embed config/alacritty/*
var WindowsAssets embed.FS
