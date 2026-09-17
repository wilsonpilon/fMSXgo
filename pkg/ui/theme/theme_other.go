//go:build !windows

package theme

import (
	"os"
	"strings"
)

// DetectOSLightTheme checks environment variables on Linux/macOS.
func DetectOSLightTheme() bool {
	gtkTheme := strings.ToLower(os.Getenv("GTK_THEME"))
	if strings.Contains(gtkTheme, "light") {
		return true
	}
	if strings.Contains(gtkTheme, "dark") {
		return false
	}
	return false // Default to dark on non-Windows
}
