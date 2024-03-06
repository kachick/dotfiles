package config

import "embed"

//go:embed windows/*
//go:embed starship/*
//go:embed alacritty/*
var WindowsAssets embed.FS
