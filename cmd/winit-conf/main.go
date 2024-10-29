package main

import (
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"

	"github.com/kachick/dotfiles"
)

const usage = `Usage: winit-conf [SUB] [OPTIONS]

Windows initialization to apply my settings for some apps

$ winit-conf.exe generate -list-path
$ winit-conf.exe generate -path="config/powershell/Profile.ps1" > "$PROFILE"
$ winit-conf.exe run
`

const configFilePermission = 0600

type provisioner struct {
	FS        embed.FS
	EmbedTree []string
	DstTree   []string
}

func newProvisioner(embedTree []string, dstTree []string) provisioner {
	return provisioner{
		FS:        dotfiles.WindowsAssets,
		EmbedTree: embedTree,
		DstTree:   dstTree,
	}
}

func (p provisioner) EmbedPath() string {
	// Should use "path", not "filepath" for embed
	// https://github.com/golang/go/issues/44305#issuecomment-780111748
	// https://github.com/golang/go/blob/f048829d706df6c1ca4d6fd22de9bd2609d3ed7c/src/io/fs/fs.go#L49
	return path.Join(p.EmbedTree...)
}

func (p provisioner) DstPath() string {
	// Should use "filepath" as other place
	// https://mattn.kaoriya.net/software/lang/go/20171024130616.htm
	return filepath.Join(p.DstTree...)
}

func provisioners() []provisioner {
	homePath, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("Failed to get home directory: %+v", err)
	}

	// https://github.com/golang/go/blob/f0d1195e13e06acdf8999188decc63306f9903f5/src/os/file.go#L500-L509
	appdataPath, err := os.UserConfigDir()
	if err != nil {
		log.Fatalln("UserConfigDir(basically APPDATA) is not found")
	}

	// Do NOT delete this tmpdir after finished, the winget files will be manually used
	tmpdirPath, err := os.MkdirTemp("", "winit")
	if err != nil {
		log.Fatalln("Cannot create temp dir")
	}

	// As I understand it, unix like permission masks will work even in windows...
	const dirPerm = 0750

	// TODO: Replace `filepath.Join(homePath, ".config"...` code with "$env.XDG_CONFIG_HOME" era even through Windows

	err = os.MkdirAll(filepath.Join(homePath, ".config", "alacritty", "themes"), dirPerm)
	if err != nil {
		log.Fatalf("Failed to create alacritty dotfiles directory: %+v", err)
	}
	err = os.MkdirAll(filepath.Join(appdataPath, "alacritty"), dirPerm)
	if err != nil {
		log.Fatalf("Failed to create path that will have alacritty.toml: %+v", err)
	}

	err = os.MkdirAll(filepath.Join(homePath, ".config", "nushell"), dirPerm)
	if err != nil {
		log.Fatalf("Failed to create nushell dotfiles directory: %+v", err)
	}

	return []provisioner{
		newProvisioner([]string{"config", "starship", "starship.toml"}, []string{homePath, ".config", "starship.toml"}),

		newProvisioner([]string{"config", "alacritty", "common.toml"}, []string{homePath, ".config", "alacritty", "common.toml"}),
		newProvisioner([]string{"config", "alacritty", "windows.toml"}, []string{homePath, ".config", "alacritty", "windows.toml"}),
		// TODO: Copy all TOMLs under themes
		newProvisioner([]string{"config", "alacritty", "themes", "iceberg-dark.toml"}, []string{homePath, ".config", "alacritty", "themes", "iceberg-dark.toml"}),
		newProvisioner([]string{"config", "alacritty", "alacritty-windows.toml"}, []string{appdataPath, "alacritty", "alacritty.toml"}),

		newProvisioner([]string{"config", "nushell", "config.nu"}, []string{homePath, ".config", "nushell", "config.nu"}),
		newProvisioner([]string{"config", "nushell", "env.nu"}, []string{homePath, ".config", "nushell", "env.nu"}),

		newProvisioner([]string{"windows", "winget", "winget-pkgs-basic.json"}, []string{tmpdirPath, "winget-pkgs-basic.json"}),
		newProvisioner([]string{"windows", "winget", "winget-pkgs-entertainment.json"}, []string{tmpdirPath, "winget-pkgs-entertainment.json"}),
		newProvisioner([]string{"windows", "winget", "winget-pkgs-storage.json"}, []string{tmpdirPath, "winget-pkgs-storage.json"}),

		// You may need to custom the memory size
		newProvisioner([]string{"windows", "WSL", ".wslconfig"}, []string{homePath, ".wslconfig"}),
	}
}

func (p provisioner) Copy() error {
	body, err := p.FS.ReadFile(p.EmbedPath())
	if err != nil {
		return err
	}
	err = os.WriteFile(p.DstPath(), body, configFilePermission)
	if err != nil {
		return err
	}
	// Make sure the permission even for umask problem
	err = os.Chmod(p.DstPath(), configFilePermission)
	if err != nil {
		return err
	}

	return nil
}

func main() {
	runCmd := flag.NewFlagSet("run", flag.ExitOnError)
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

		path := *pathFlag
		if (*listPathFlag && path != "") || (!*listPathFlag && path == "") {
			fmt.Printf("Specify one of -list-path or -path flag, not both: list-path: %+v path: %s\n", *listPathFlag, path)
			flag.Usage()
			os.Exit(1)
		}

		if *listPathFlag {
			err := fs.WalkDir(dotfiles.WindowsAssets, ".", func(path string, d fs.DirEntry, err error) error {
				if d.IsDir() {
					return nil
				}
				fmt.Println(path)
				return nil
			})
			if err != nil {
				log.Fatalf("Failed to open file: %+v", err)
			}
		}

		if path != "" {
			body, err := dotfiles.WindowsAssets.ReadFile(path)
			if err != nil {
				log.Fatalf("Failed to open file: %s %+v", path, err)
			}
			fmt.Println(string(body))
		}
	case "run":
		err := runCmd.Parse(os.Args[2:])
		if err != nil {
			log.Fatalf("Unexpected parser error in given arguments: %+v", err)
		}

		for _, p := range provisioners() {
			log.Printf("%s => %s\n", p.EmbedPath(), p.DstPath())
			err := p.Copy()
			if err != nil {
				log.Fatalf("Failed to copy file: %+v %+v", p, err)
			}
		}
	default:
		flag.Usage()

		os.Exit(1)
	}
}
