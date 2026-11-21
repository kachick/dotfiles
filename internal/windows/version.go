//go:build windows

package windows

import (
	"log"

	"golang.org/x/sys/windows/registry"
)

// Why not WMI (Win32_OperatingSystem):
// Reading ProductName from the registry reuses golang.org/x/sys/windows/registry
// and avoids pulling in third-party WMI and COM/OLE libraries.
func mustGetProductName() string {
	key, err := registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\Microsoft\Windows NT\CurrentVersion`, registry.QUERY_VALUE)
	if err != nil {
		log.Fatalf("Failed to open CurrentVersion registry key: %+v", err)
	}
	defer key.Close()

	val, _, err := key.GetStringValue("ProductName")
	if err != nil {
		log.Fatalf("Failed to read ProductName from registry: %+v", err)
	}

	return val
}
