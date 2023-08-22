//go:build windows

package main

import (
	"log"

	"golang.org/x/sys/windows/registry"
)

// # https://github.com/kachick/times_kachick/issues/214
func main() {
	key, err := registry.OpenKey(registry.CURRENT_USER, `Control Panel\Sound`, registry.SET_VALUE)
	if err != nil {
		log.Fatalf("Failed to open registry key: %+v", err)
	}
	defer key.Close()

	err = key.SetStringValue("Beep", "no")
	if err != nil {
		log.Fatalf("Failed to update registry: %+v", err)
	}

	log.Println("Completed to disable beeps, you need to restart Windows to activate settings")
}
