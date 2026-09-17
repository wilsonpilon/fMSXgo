//go:build windows

package theme

import (
	"golang.org/x/sys/windows/registry"
)

// DetectOSLightTheme queries Windows registry for system theme preference.
// Returns true if the OS is in Light mode, false if Dark mode.
func DetectOSLightTheme() bool {
	k, err := registry.OpenKey(registry.CURRENT_USER, `Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`, registry.QUERY_VALUE)
	if err != nil {
		return false // Default to dark on error
	}
	defer k.Close()

	val, _, err := k.GetIntegerValue("AppsUseLightTheme")
	if err != nil {
		return false
	}
	return val != 0
}
