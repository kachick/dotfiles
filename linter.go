package dotfiles

func GetTyposTargetedRoots() []string {
	return []string{
		".",
		".github", ".vscode",
		"home/.config", "home/.local", "home/.stack",
	}
}
