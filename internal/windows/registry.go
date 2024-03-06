//go:build windows

package windows

import (
	"log"

	"golang.org/x/sys/windows/registry"
)

// # https://github.com/kachick/times_kachick/issues/214
func DisableBeeps() {
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

func RegainVerboseContextMenu() {
	key, err := registry.OpenKey(registry.CURRENT_USER, `Software\Classes\CLSID`, registry.CREATE_SUB_KEY)
	if err != nil {
		log.Fatalf("Failed to open registry key: %+v", err)
	}
	defer key.Close()

	newKey, isExists, err := registry.CreateKey(key, `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`, registry.SET_VALUE)
	if err != nil {
		log.Fatalf("Failed to update registry: %+v", err)
	}
	defer newKey.Close()
	if isExists {
		log.Println("Skipped to create registry key, because it is already exists")
		return
	}

	err = newKey.SetStringValue("", "")
	if err != nil {
		log.Fatalf("Failed to set empty default value, may need to fallback manually: %+v", err)
	}

	log.Println("Completed to enable classic style of context menu, you need to restart all explorer.exe processes to activate settings")
}
