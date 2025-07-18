//go:build windows

package windows

import (
	"log"
	"time"

	"github.com/yusufpapurcu/wmi"
)

// ref:
//   - https://learn.microsoft.com/windows/win32/cimwin32prov/win32-operatingsystem
//   - https://github.com/yusufpapurcu/wmi/blob/6c94d732ac31d45ca1f62731b1682157ce85e224/wmi_test.go#L561C1-L626C2
type Win32_OperatingSystem struct {
	BootDevice                                string
	BuildNumber                               string
	BuildType                                 string
	Caption                                   *string
	CodeSet                                   string
	CountryCode                               string
	CreationClassName                         string
	CSCreationClassName                       string
	CSDVersion                                *string
	CSName                                    string
	CurrentTimeZone                           int16
	DataExecutionPrevention_Available         bool
	DataExecutionPrevention_32BitApplications bool
	DataExecutionPrevention_Drivers           bool
	DataExecutionPrevention_SupportPolicy     *uint8
	Debug                                     bool
	Description                               *string
	Distributed                               bool
	EncryptionLevel                           uint32
	ForegroundApplicationBoost                *uint8
	FreePhysicalMemory                        uint64
	FreeSpaceInPagingFiles                    uint64
	FreeVirtualMemory                         uint64
	InstallDate                               time.Time
	LargeSystemCache                          *uint32
	LastBootUpTime                            time.Time
	LocalDateTime                             time.Time
	Locale                                    string
	Manufacturer                              string
	MaxNumberOfProcesses                      uint32
	MaxProcessMemorySize                      uint64
	MUILanguages                              *[]string
	Name                                      string
	NumberOfLicensedUsers                     *uint32
	NumberOfProcesses                         uint32
	NumberOfUsers                             uint32
	OperatingSystemSKU                        uint32
	Organization                              string
	OSArchitecture                            string
	OSLanguage                                uint32
	OSProductSuite                            uint32
	OSType                                    uint16
	OtherTypeDescription                      *string
	PAEEnabled                                *bool
	PlusProductID                             *string
	PlusVersionNumber                         *string
	PortableOperatingSystem                   bool
	Primary                                   bool
	ProductType                               uint32
	RegisteredUser                            string
	SerialNumber                              string
	ServicePackMajorVersion                   uint16
	ServicePackMinorVersion                   uint16
	SizeStoredInPagingFiles                   uint64
	Status                                    string
	SuiteMask                                 uint32
	SystemDevice                              string
	SystemDirectory                           string
	SystemDrive                               string
	TotalSwapSpaceSize                        *uint64
	TotalVirtualMemorySize                    uint64
	TotalVisibleMemorySize                    uint64
	Version                                   string
	WindowsDirectory                          string
}

func mustGetCaption() string {
	var dst []Win32_OperatingSystem
	q := wmi.CreateQuery(&dst, "")
	if err := wmi.Query(q, &dst); err != nil {
		log.Fatalf("Failed to get Win32_OperatingSystem: %+v", err)
	}

	for _, v := range dst {
		return *v.Caption
	}

	return ""
}
