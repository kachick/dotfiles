//go:build windows

package main

import (
	"flag"
	"log"
	"os"
	"path"
	"path/filepath"

	"github.com/kachick/dotfiles/internal/fileutils"
)

func main() {
	dotsPathFlag := flag.String("dotfiles_path", "", "Specify dotfiles repository path in your local")
	pwshProfilePathFlag := flag.String("pwsh_profile_path", "", "Specify PowerShell profile path")
	flag.Parse()
	dotsPath := filepath.Clean(*dotsPathFlag)
	pwshProfilePath := filepath.Clean(*pwshProfilePathFlag)

	if dotsPath == "" || pwshProfilePath == "" || len(os.Args) < 2 {
		flag.Usage()
		log.Fatalf("called with wrong arguments")
	}

	homePath, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("Failed to get home directory: %+v", err)
	}

	appdataPath, ok := os.LookupEnv("APPDATA")
	if !ok {
		log.Fatalln("ENV APPDATA is not found")
	}

	// As I understand it, unix like permission masks will work even in windows...
	err = os.MkdirAll(filepath.Join(homePath, ".config", "alacritty"), 0750)
	if err != nil {
		log.Fatalf("Failed to create dotfiles directory: %+v", err)
	}
	err = os.MkdirAll(path.Join(appdataPath, "alacritty"), 0750)
	if err != nil {
		log.Fatalf("Failed to create path that will have alacritty.toml: %+v", err)
	}
	err = os.MkdirAll(path.Dir(pwshProfilePath), 0750)
	if err != nil {
		log.Fatalf("Failed to create path that will have PowerShell profiles: %+v", err)
	}

	copies := []fileutils.Copy{
		{Src: filepath.Join(dotsPath, "config", "starship", "starship.toml"), Dst: filepath.Join(homePath, ".config", "starship.toml")},
		{Src: filepath.Join(dotsPath, "config", "alacritty", "common.toml"), Dst: filepath.Join(homePath, ".config", "alacritty", "common.toml")},
		{Src: filepath.Join(dotsPath, "config", "alacritty", "windows.toml"), Dst: filepath.Join(appdataPath, ".config", "alacritty", "alacritty.toml")},
		{Src: filepath.Join(dotsPath, "config", "windows", "powershell", "Profile.ps1"), Dst: pwshProfilePath},
	}

	for _, copy := range copies {
		err := copy.Run()
		if err != nil {
			log.Fatalf("Failed to copy file: %+v %+v", copy, err)
		}
	}

	log.Printf(`Completed, you need to restart terminals

If you faced slow execution of PowerShell after this script, exclude %s from Anti Virus as Microsoft Defender
`, pwshProfilePath)
}
