package constants

func GetTyposTargetedRoots() []string {
	return []string{
		".",
		".github", ".vscode",
		"home/.config", "home/.stack",
	}
}
