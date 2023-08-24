//go:build linux

package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/internal/fileutils"

	"golang.org/x/sys/unix"
)

func freeze(path string) error {
	// Using IoctlSetPointerInt changed as immutable, but it returns "operation not supported" error. I don't know the detail
	_, err := exec.Command("chattr", "+i", path).Output()
	return err
}

// Exists for remember https://github.com/kachick/dotfiles/pull/264#discussion_r1289600371
func mustActivateSystemDOnWSL() {
	const path = "/etc/wsl.conf"

	const systemdEnablingEntry = `[boot]
systemd=true`

	wslConfigBytes, err := os.ReadFile(path)
	if err != nil && !os.IsNotExist(err) {
		log.Fatalf("%v\n", err)
	}

	wslConfig := ""

	if wslConfigBytes != nil {
		wslConfig = string(wslConfigBytes) + "\n"
	}

	if strings.Contains(wslConfig, "systemd") {
		log.Println("Skip - enabling syetemd - Looks areleady exists the systemd config")
		return
	}

	dirty := strings.Clone(wslConfig)

	dirty += fmt.Sprintln(systemdEnablingEntry)

	if dirty != wslConfig {
		err = os.WriteFile(path, []byte(dirty), os.ModePerm)
		if err != nil {
			log.Fatalf("failed - could you correctly run this with sudo? - %v\n", err)
		}

		fmt.Printf(`Done! Restart wsl.exe as follows in your Windows PowerShell

wsl.exe --shutdown

See https://learn.microsoft.com/ja-jp/windows/wsl/systemd for further detail
`)
	}
}

// https://github.com/docker/for-win/issues/8336#issuecomment-718369597
func mustPersistDockerZshCompletions() {
	const completionLoadablePath = "/usr/share/zsh/vendor-completions/_docker"
	err := os.Remove(completionLoadablePath)
	if err != nil {
		if os.IsNotExist(err) {
			log.Println("info - zsh completions files for docker not found, docker-desktop may not be executed")
		} else {
			log.Panicf("%+v\n", err)
		}
	}
	// Can't make immutable symlink, so copy and make immutable here
	// https://unix.stackexchange.com/questions/586430/how-to-make-a-symlink-read-only-chattr-i-location-symlink
	err = fileutils.Copy{Src: "dependencies/docker/zsh-vendor-completions.zsh", Dst: completionLoadablePath}.Run()
	if err != nil {
		log.Panicf("%+v\n", err)
	}

	err = freeze(completionLoadablePath)
	if err != nil {
		log.Panicf("%+v\n", err)
	}

	fmt.Printf("Done! docker comletions for zsh %s has been replaced to immutable file", completionLoadablePath)
}

// This script requires sudo execution
func main() {
	// wsl.exe returns non English even in called on the VM https://github.com/microsoft/WSL/issues/9242
	// And always having non ASCII, annoy to depend with the output :<
	uname := unix.Utsname{}
	err := unix.Uname(&uname)
	if err != nil {
		log.Fatalf("cannot get uname: %+v\n", err)
	}
	unameStr := ""
	// So here, using uname, as I understand it is same as `uname -r`
	for _, i8 := range uname.Release {
		unameStr += string(rune(int(i8)))
	}
	if !strings.Contains(unameStr, "microsoft-standard-WSL2") {
		log.Fatalf("Looks executed on non WSL systems: %s", unameStr)
	}

	mustActivateSystemDOnWSL()
	mustPersistDockerZshCompletions()
}
