package main

import (
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"github.com/kachick/dotfiles"
	"github.com/kachick/dotfiles/internal/configsync"
)

const usage = `Usage: winit-conf [SUB] [OPTIONS]

Windows initialization to apply my settings for some apps

$ winit-conf.exe generate -list-path
$ winit-conf.exe generate -path="config/powershell/Profile.ps1" > "$PROFILE"
$ winit-conf.exe run
`

const configFilePermission fs.FileMode = 0o600

type dstRoot uint8

const (
	rootUserHome dstRoot = iota
	rootXdgConfig
	rootAppData
	rootLocalAppData
	rootPwshProfile
	rootTempDir
)

type assetSpec struct {
	embedTree []string
	root      dstRoot
	dstTree   []string
	isDir     bool
}

func (a assetSpec) embedPath() string {
	// Should use "path", not "filepath" for embed
	// https://github.com/golang/go/issues/44305#issuecomment-780111748
	// https://github.com/golang/go/blob/f048829d706df6c1ca4d6fd22de9bd2609d3ed7c/src/io/fs/fs.go#L49
	return path.Join(a.embedTree...)
}

var assetSpecs = []assetSpec{
	{embedTree: []string{"config", "starship", "starship.toml"}, root: rootXdgConfig, dstTree: []string{"starship.toml"}},

	{embedTree: []string{"config", "alacritty", "common.toml"}, root: rootXdgConfig, dstTree: []string{"alacritty", "common.toml"}},
	{embedTree: []string{"config", "alacritty", "windows.toml"}, root: rootXdgConfig, dstTree: []string{"alacritty", "windows.toml"}},
	{embedTree: []string{"config", "alacritty", "themes"}, root: rootXdgConfig, dstTree: []string{"alacritty", "themes"}, isDir: true},
	{embedTree: []string{"config", "alacritty", "alacritty-windows.toml"}, root: rootAppData, dstTree: []string{"alacritty", "alacritty.toml"}},

	{embedTree: []string{"config", "nushell", "config.nu"}, root: rootXdgConfig, dstTree: []string{"nushell", "config.nu"}},
	{embedTree: []string{"config", "nushell", "env.nu"}, root: rootXdgConfig, dstTree: []string{"nushell", "env.nu"}},
	{embedTree: []string{"config", "nushell", "windows_config.nu"}, root: rootXdgConfig, dstTree: []string{"nushell", "windows_config.nu"}},

	{embedTree: []string{"config", "zed", "settings.jsonc"}, root: rootAppData, dstTree: []string{"Zed", "settings.json"}},

	{
		embedTree: []string{"config", "keyboards", "kanata.kbd"},
		root:      rootLocalAppData,
		dstTree:   []string{"Microsoft", "WinGet", "Packages", "jtroo.kanata_gui_Microsoft.Winget.Source_8wekyb3d8bbwe", "kanata.kbd"},
	},
	{
		embedTree: []string{"windows", "WindowsTerminal", "settings.json"},
		root:      rootLocalAppData,
		dstTree:   []string{"Packages", "Microsoft.WindowsTerminal_8wekyb3d8bbwe", "LocalState", "settings.json"},
	},

	{embedTree: []string{"config", "powershell", "Profile.ps1"}, root: rootPwshProfile},

	{embedTree: []string{"windows", "winget", "winget-pkgs-basic.json"}, root: rootTempDir, dstTree: []string{"winget-pkgs-basic.json"}},
	{embedTree: []string{"windows", "winget", "winget-pkgs-entertainment.json"}, root: rootTempDir, dstTree: []string{"winget-pkgs-entertainment.json"}},
	{embedTree: []string{"windows", "winget", "winget-pkgs-storage.json"}, root: rootTempDir, dstTree: []string{"winget-pkgs-storage.json"}},

	// You may need to custom the memory size
	{embedTree: []string{"windows", "WSL", ".wslconfig"}, root: rootUserHome, dstTree: []string{".wslconfig"}},
}

type pathResolver struct {
	homePath         string
	xdgConfigPath    string
	appDataPath      string
	localAppDataPath string
	pwshProfilePath  string
	tempDirPath      string
}

func newPathResolver(dryRun bool) (pathResolver, error) {
	homePath, err := os.UserHomeDir()
	if err != nil {
		return pathResolver{}, fmt.Errorf("getting home directory: %w", err)
	}

	// https://github.com/golang/go/blob/f0d1195e13e06acdf8999188decc63306f9903f5/src/os/file.go#L500-L509
	appDataPath, err := os.UserConfigDir()
	if err != nil {
		return pathResolver{}, fmt.Errorf("getting UserConfigDir(basically APPDATA): %w", err)
	}

	xdgConfigPath := os.Getenv("XDG_CONFIG_HOME")
	if xdgConfigPath == "" {
		xdgConfigPath = filepath.Join(homePath, ".config")
	}

	localAppDataPath := os.Getenv("LOCALAPPDATA")
	if localAppDataPath == "" {
		localAppDataPath = filepath.Join(homePath, "AppData", "Local")
	}

	pwshProfilePath := resolvePwshProfilePath(homePath)

	var tempDirPath string
	if dryRun {
		tempDirPath = filepath.Join(os.TempDir(), "winit-dry-run")
	} else {
		// Do NOT delete this tmpdir after finished, the winget files will be manually used
		tempDirPath, err = os.MkdirTemp("", "winit")
		if err != nil {
			return pathResolver{}, fmt.Errorf("creating temp dir: %w", err)
		}
	}

	return pathResolver{
		homePath:         homePath,
		xdgConfigPath:    xdgConfigPath,
		appDataPath:      appDataPath,
		localAppDataPath: localAppDataPath,
		pwshProfilePath:  pwshProfilePath,
		tempDirPath:      tempDirPath,
	}, nil
}

func resolvePwshProfilePath(homePath string) string {
	if pwshBin, err := exec.LookPath("pwsh"); err == nil {
		out, err := exec.Command(pwshBin, "-NoProfile", "-NonInteractive", "-Command", "Write-Output $PROFILE").Output()
		if err == nil {
			resolved := strings.TrimSpace(string(out))
			if resolved != "" {
				return resolved
			}
		}
	}
	return filepath.Join(homePath, "Documents", "PowerShell", "Microsoft.PowerShell_profile.ps1")
}

func (r pathResolver) resolveDst(a assetSpec) (string, error) {
	var base string
	switch a.root {
	case rootUserHome:
		base = r.homePath
	case rootXdgConfig:
		base = r.xdgConfigPath
	case rootAppData:
		base = r.appDataPath
	case rootLocalAppData:
		base = r.localAppDataPath
	case rootPwshProfile:
		if len(a.dstTree) == 0 {
			return r.pwshProfilePath, nil
		}
		base = r.pwshProfilePath
	case rootTempDir:
		base = r.tempDirPath
	default:
		return "", fmt.Errorf("unknown destination root: %d", a.root)
	}
	parts := append([]string{base}, a.dstTree...)
	return filepath.Join(parts...), nil
}

func buildSyncEntries(resolver pathResolver) ([]configsync.Entry, error) {
	entries := make([]configsync.Entry, 0, len(assetSpecs))
	for _, spec := range assetSpecs {
		dstPath, err := resolver.resolveDst(spec)
		if err != nil {
			return nil, err
		}
		entries = append(entries, configsync.Entry{
			SrcFS:   dotfiles.WindowsAssets,
			SrcPath: spec.embedPath(),
			DstPath: dstPath,
			Perm:    configFilePermission,
			IsDir:   spec.isDir,
		})
	}
	return entries, nil
}

func main() {
	runCmd := flag.NewFlagSet("run", flag.ExitOnError)
	dryRunFlag := runCmd.Bool("dry-run", false, "Show planned changes and diffs without writing files")
	forceFlag := runCmd.Bool("force", false, "Overwrite existing files that differ without prompting")
	skipFlag := runCmd.Bool("skip", false, "Skip existing files that differ without prompting")
	backupFlag := runCmd.Bool("backup", false, "Back up existing files to *.bak before overwriting without prompting")

	generateCmd := flag.NewFlagSet("generate", flag.ExitOnError)
	listPathFlag := generateCmd.Bool("list-path", false, "List all config paths included in this binary")
	pathFlag := generateCmd.String("path", "", "Specify a path to show the config text")
	flag.Usage = func() {
		// https://github.com/golang/go/issues/57059#issuecomment-1336036866
		fmt.Printf("%s", usage+"\n\n")
		flag.PrintDefaults()
	}
	flag.Parse()

	if len(os.Args) < 2 {
		flag.Usage()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "generate":
		err := generateCmd.Parse(os.Args[2:])
		if err != nil {
			log.Fatalf("Unexpected parser error in given arguments: %+v", err)
		}

		p := *pathFlag
		if (*listPathFlag && p != "") || (!*listPathFlag && p == "") {
			fmt.Printf("Specify one of -list-path or -path flag, not both: list-path: %+v path: %s\n", *listPathFlag, p)
			flag.Usage()
			os.Exit(1)
		}

		if *listPathFlag {
			err := fs.WalkDir(dotfiles.WindowsAssets, ".", func(p string, d fs.DirEntry, err error) error {
				if err != nil {
					return err
				}
				if d.IsDir() {
					return nil
				}
				fmt.Println(p)
				return nil
			})
			if err != nil {
				log.Fatalf("Failed to open file: %+v", err)
			}
		}

		if p != "" {
			body, err := dotfiles.WindowsAssets.ReadFile(p)
			if err != nil {
				log.Fatalf("Failed to open file: %s %+v", p, err)
			}
			fmt.Println(string(body))
		}
	case "run":
		err := runCmd.Parse(os.Args[2:])
		if err != nil {
			log.Fatalf("Unexpected parser error in given arguments: %+v", err)
		}

		policy, err := selectConflictPolicy(*forceFlag, *skipFlag, *backupFlag)
		if err != nil {
			log.Fatalln(err)
		}

		resolver, err := newPathResolver(*dryRunFlag)
		if err != nil {
			log.Fatalf("Failed to resolve target paths: %+v", err)
		}

		entries, err := buildSyncEntries(resolver)
		if err != nil {
			log.Fatalf("Failed to build sync entries: %+v", err)
		}

		results, err := configsync.Sync(entries, configsync.Options{
			DryRun:   *dryRunFlag,
			Conflict: policy,
		})
		if err != nil {
			log.Fatalf("Failed to sync files: %+v", err)
		}

		for _, r := range results {
			if r.BackupPath != "" {
				log.Printf("[%s] %s => %s (backup: %s)\n", r.Status, r.SrcPath, r.DstPath, r.BackupPath)
			} else {
				log.Printf("[%s] %s => %s\n", r.Status, r.SrcPath, r.DstPath)
			}
			if *dryRunFlag && r.Diff != "" {
				fmt.Print(r.Diff)
			}
		}
	default:
		flag.Usage()
		os.Exit(1)
	}
}

func selectConflictPolicy(force, skip, backup bool) (configsync.ConflictPolicy, error) {
	selected := 0
	for _, b := range []bool{force, skip, backup} {
		if b {
			selected++
		}
	}
	if selected > 1 {
		return configsync.ConflictPrompt, fmt.Errorf("specify at most one of --force, --skip, or --backup")
	}
	switch {
	case force:
		return configsync.ConflictOverwrite, nil
	case skip:
		return configsync.ConflictSkip, nil
	case backup:
		return configsync.ConflictBackup, nil
	default:
		return configsync.ConflictPrompt, nil
	}
}
