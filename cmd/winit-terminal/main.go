package main

import (
	"embed"
	"flag"
	"log"
	"os"
	"path"
	"path/filepath"

	"github.com/kachick/dotfiles/config"
)

const configFilePermission = 0600

type provisioner struct {
	FS  embed.FS
	Src []string
	Dst []string
}

func newProvisioner(src []string, dst []string) provisioner {
	return provisioner{
		FS:  config.WindowsAssets,
		Src: src,
		Dst: dst,
	}
}

func (p provisioner) SrcPath() string {
	return filepath.Join(p.Src...)
}

func (p provisioner) DstPath() string {
	return filepath.Join(p.Dst...)
}

func (p provisioner) Copy() error {
	body, err := p.FS.ReadFile(p.SrcPath())
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
	err = os.MkdirAll(filepath.Join(homePath, ".config", "alacritty", "themes"), 0750)
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

	provisioners := []provisioner{
		newProvisioner([]string{"starship", "starship.toml"}, []string{homePath, ".config", "starship.toml"}),
		newProvisioner([]string{"alacritty", "common.toml"}, []string{homePath, ".config", "alacritty", "common.toml"}),
		// TODO: Copy all TOMLs under themes
		newProvisioner([]string{"alacritty", "themes", "iceberg-dark.toml"}, []string{homePath, ".config", "alacritty", "themes", "iceberg-dark.toml"}),
		newProvisioner([]string{"alacritty", "windows.toml"}, []string{appdataPath, ".config", "alacritty", "alacritty.toml"}),
		newProvisioner([]string{"windows", "powershell", "Profile.ps1"}, []string{pwshProfilePath}),
	}

	for _, p := range provisioners {
		log.Printf("%s => %s,\n", p.SrcPath(), p.DstPath())
		err := p.Copy()
		if err != nil {
			log.Fatalf("Failed to copy file: %+v %+v", p, err)
		}
	}

	log.Printf(`Completed, you need to restart terminals

If you faced slow execution of PowerShell after this script, exclude %s from Anti Virus as Microsoft Defender
`, pwshProfilePath)
}
