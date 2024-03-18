package main

import (
	"embed"
	"flag"
	"fmt"
	"log"
	"os"
	"path"
	"path/filepath"

	"github.com/kachick/dotfiles/config"
)

const configFilePermission = 0600

type provisioner struct {
	FS        embed.FS
	EmbedTree []string
	DstTree   []string
}

func newProvisioner(embedTree []string, dstTree []string) provisioner {
	return provisioner{
		FS:        config.WindowsAssets,
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

func provisioners(pwshProfilePath string) []provisioner {
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
	err = os.MkdirAll(filepath.Join(homePath, ".config", "alacritty", "themes"), 0750)
	if err != nil {
		log.Fatalf("Failed to create dotfiles directory: %+v", err)
	}
	err = os.MkdirAll(filepath.Join(appdataPath, "alacritty"), 0750)
	if err != nil {
		log.Fatalf("Failed to create path that will have alacritty.toml: %+v", err)
	}
	err = os.MkdirAll(filepath.Dir(pwshProfilePath), 0750)
	if err != nil {
		log.Fatalf("Failed to create path that will have PowerShell profiles: %+v", err)
	}

	return []provisioner{
		newProvisioner([]string{"starship", "starship.toml"}, []string{homePath, ".config", "starship.toml"}),
		newProvisioner([]string{"alacritty", "common.toml"}, []string{homePath, ".config", "alacritty", "common.toml"}),
		// TODO: Copy all TOMLs under themes
		newProvisioner([]string{"alacritty", "themes", "iceberg-dark.toml"}, []string{homePath, ".config", "alacritty", "themes", "iceberg-dark.toml"}),
		newProvisioner([]string{"alacritty", "windows.toml"}, []string{appdataPath, "alacritty", "alacritty.toml"}),
		newProvisioner([]string{"powershell", "Profile.ps1"}, []string{pwshProfilePath}),
		newProvisioner([]string{"windows", "winget", "winget-pkgs-basic.json"}, []string{tmpdirPath, "winget-pkgs-basic.json"}),
		newProvisioner([]string{"windows", "winget", "winget-pkgs-entertainment.json"}, []string{tmpdirPath, "winget-pkgs-entertainment.json"}),
		newProvisioner([]string{"windows", "winget", "winget-pkgs-storage.json"}, []string{tmpdirPath, "winget-pkgs-storage.json"}),
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

func usage() string {
	return `Usage: winit-conf [SUB] [OPTIONS]

Windows initialization to apply my settings for some apps

$ winit-conf.exe list
$ winit-conf.exe generate
$ winit-conf.exe run -pwsh_profile_path "$PROFILE"
`
}

func main() {
	runCmd := flag.NewFlagSet("run", flag.ExitOnError)
	pwshProfilePathFlag := runCmd.String("pwsh_profile_path", "", "Specify PowerShell profile path")
	flag.Usage = func() {
		// https://github.com/golang/go/issues/57059#issuecomment-1336036866
		fmt.Printf("%s", usage()+"\n\n")
		flag.PrintDefaults()
	}
	flag.Parse()

	if len(os.Args) < 2 {
		flag.Usage()

		os.Exit(1)
	}

	switch os.Args[1] {
	case "list":
		for _, p := range provisioners("dummy_path") {
			fmt.Println(p.EmbedPath())
		}
	case "generate":
		for _, p := range provisioners("dummy_path") {
			body, err := config.WindowsAssets.ReadFile(p.EmbedPath())
			if err != nil {
				log.Fatalf("Failed to copy file: %+v %+v", p, err)
			}
			fmt.Println(p.EmbedPath())
			fmt.Println("--------------------------------------------------")
			fmt.Println(string(body))
		}
	case "run":
		runCmd.Parse(os.Args[2:])
		if *pwshProfilePathFlag == "" {
			flag.Usage()
			log.Fatalf("called with wrong arguments")
		}
		// $PROFILE is an "Automatic Variables", not ENV
		// https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4
		pwshProfilePath := filepath.Clean(*pwshProfilePathFlag)

		for _, p := range provisioners(pwshProfilePath) {
			log.Printf("%s => %s\n", p.EmbedPath(), p.DstPath())
			err := p.Copy()
			if err != nil {
				log.Fatalf("Failed to copy file: %+v %+v", p, err)
			}
		}

		log.Printf(`Completed, you need to restart terminals

If you faced slow execution of PowerShell after this script, exclude %s from Anti Virus as Microsoft Defender
`, pwshProfilePath)
	default:
		flag.Usage()

		os.Exit(1)
	}
}
