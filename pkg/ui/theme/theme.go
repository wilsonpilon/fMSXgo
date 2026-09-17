package theme

import (
	"image/color"
	"strings"
	"sync"
)

// Category defines whether a theme is dark, light, or auto-system.
type Category string

const (
	CategorySystem Category = "system"
	CategoryDark   Category = "dark"
	CategoryLight  Category = "light"
)

// Theme defines the complete color palette for the fMSXgo UI.
type Theme struct {
	ID          string
	Name        string
	Category    Category
	IsDark      bool

	// Window & Menus
	MenuBarBg         color.RGBA
	MenuBarText       color.RGBA
	MenuDropdownBg     color.RGBA
	MenuDropdownHover  color.RGBA
	MenuDropdownText   color.RGBA
	MenuBorder        color.RGBA

	// Main Screen & Workstation Area
	ScreenBg          color.RGBA
	StatusTitle       color.RGBA
	StatusLabel       color.RGBA
	StatusValue       color.RGBA
	AccentColor       color.RGBA

	// Dialogs & Modals
	DialogBg          color.RGBA
	DialogBorder      color.RGBA
	DialogHeader      color.RGBA
	DialogText        color.RGBA

	// Buttons & Interactive
	ButtonBg          color.RGBA
	ButtonHover       color.RGBA
	ButtonText        color.RGBA
	SelectedBg        color.RGBA
	SelectedText      color.RGBA
}

var (
	currentThemeID = "system"
	mu             sync.RWMutex
	themeRegistry  = make(map[string]Theme)
	themeList      []Theme
)

func init() {
	themes := []Theme{
		// 1. System Theme (Auto)
		{
			ID:          "system",
			Name:        "Auto (System OS)",
			Category:    CategorySystem,
			IsDark:      true,
			MenuBarBg:   color.RGBA{22, 27, 34, 255},
			MenuBarText: color.RGBA{240, 246, 252, 255},
			ScreenBg:    color.RGBA{13, 17, 23, 255},
			StatusTitle: color.RGBA{88, 166, 255, 255},
			StatusLabel: color.RGBA{139, 148, 158, 255},
			StatusValue: color.RGBA{240, 246, 252, 255},
			AccentColor: color.RGBA{88, 166, 255, 255},
			DialogBg:    color.RGBA{22, 27, 34, 250},
			DialogBorder:color.RGBA{48, 54, 61, 255},
			DialogHeader:color.RGBA{88, 166, 255, 255},
			DialogText:  color.RGBA{201, 209, 217, 255},
			ButtonBg:    color.RGBA{35, 134, 54, 255},
			ButtonHover: color.RGBA{46, 160, 67, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{31, 111, 235, 255},
			SelectedText:color.RGBA{255, 255, 255, 255},
			MenuDropdownBg:    color.RGBA{22, 27, 34, 255},
			MenuDropdownHover: color.RGBA{33, 38, 45, 255},
			MenuDropdownText:  color.RGBA{240, 246, 252, 255},
			MenuBorder:       color.RGBA{48, 54, 61, 255},
		},

		// 2. GitHub Dark
		{
			ID:          "github-dark",
			Name:        "GitHub Dark",
			Category:    CategoryDark,
			IsDark:      true,
			MenuBarBg:   color.RGBA{22, 27, 34, 255},
			MenuBarText: color.RGBA{240, 246, 252, 255},
			MenuDropdownBg:    color.RGBA{22, 27, 34, 255},
			MenuDropdownHover: color.RGBA{33, 38, 45, 255},
			MenuDropdownText:  color.RGBA{240, 246, 252, 255},
			MenuBorder:       color.RGBA{48, 54, 61, 255},
			ScreenBg:    color.RGBA{13, 17, 23, 255},
			StatusTitle: color.RGBA{88, 166, 255, 255},
			StatusLabel: color.RGBA{139, 148, 158, 255},
			StatusValue: color.RGBA{240, 246, 252, 255},
			AccentColor: color.RGBA{88, 166, 255, 255},
			DialogBg:    color.RGBA{22, 27, 34, 250},
			DialogBorder:color.RGBA{48, 54, 61, 255},
			DialogHeader:color.RGBA{88, 166, 255, 255},
			DialogText:  color.RGBA{201, 209, 217, 255},
			ButtonBg:    color.RGBA{35, 134, 54, 255},
			ButtonHover: color.RGBA{46, 160, 67, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{31, 111, 235, 255},
			SelectedText:color.RGBA{255, 255, 255, 255},
		},

		// 3. GitHub Light
		{
			ID:          "github-light",
			Name:        "GitHub Light",
			Category:    CategoryLight,
			IsDark:      false,
			MenuBarBg:   color.RGBA{246, 248, 250, 255},
			MenuBarText: color.RGBA{36, 41, 47, 255},
			MenuDropdownBg:    color.RGBA{255, 255, 255, 255},
			MenuDropdownHover: color.RGBA{234, 238, 242, 255},
			MenuDropdownText:  color.RGBA{36, 41, 47, 255},
			MenuBorder:       color.RGBA{208, 215, 222, 255},
			ScreenBg:    color.RGBA{255, 255, 255, 255},
			StatusTitle: color.RGBA{9, 105, 218, 255},
			StatusLabel: color.RGBA{87, 96, 106, 255},
			StatusValue: color.RGBA{36, 41, 47, 255},
			AccentColor: color.RGBA{9, 105, 218, 255},
			DialogBg:    color.RGBA{255, 255, 255, 250},
			DialogBorder:color.RGBA{208, 215, 222, 255},
			DialogHeader:color.RGBA{9, 105, 218, 255},
			DialogText:  color.RGBA{36, 41, 47, 255},
			ButtonBg:    color.RGBA{31, 136, 61, 255},
			ButtonHover: color.RGBA{26, 127, 55, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{9, 105, 218, 255},
			SelectedText:color.RGBA{255, 255, 255, 255},
		},

		// 4. Modern Dark 1: VS Code Dark+
		{
			ID:          "vscode-dark",
			Name:        "VS Code Dark+",
			Category:    CategoryDark,
			IsDark:      true,
			MenuBarBg:   color.RGBA{45, 45, 45, 255},
			MenuBarText: color.RGBA{204, 204, 204, 255},
			MenuDropdownBg:    color.RGBA{37, 37, 38, 255},
			MenuDropdownHover: color.RGBA{50, 50, 50, 255},
			MenuDropdownText:  color.RGBA{204, 204, 204, 255},
			MenuBorder:       color.RGBA{69, 69, 69, 255},
			ScreenBg:    color.RGBA{30, 30, 30, 255},
			StatusTitle: color.RGBA{79, 193, 255, 255},
			StatusLabel: color.RGBA{150, 150, 150, 255},
			StatusValue: color.RGBA{220, 220, 220, 255},
			AccentColor: color.RGBA{0, 122, 204, 255},
			DialogBg:    color.RGBA{37, 37, 38, 250},
			DialogBorder:color.RGBA{69, 69, 69, 255},
			DialogHeader:color.RGBA{79, 193, 255, 255},
			DialogText:  color.RGBA{204, 204, 204, 255},
			ButtonBg:    color.RGBA{14, 99, 156, 255},
			ButtonHover: color.RGBA{17, 119, 187, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{9, 71, 113, 255},
			SelectedText:color.RGBA{255, 255, 255, 255},
		},

		// 5. Modern Dark 2: Dracula
		{
			ID:          "dracula",
			Name:        "Dracula",
			Category:    CategoryDark,
			IsDark:      true,
			MenuBarBg:   color.RGBA{33, 34, 44, 255},
			MenuBarText: color.RGBA{248, 248, 242, 255},
			MenuDropdownBg:    color.RGBA{40, 42, 54, 255},
			MenuDropdownHover: color.RGBA{68, 71, 90, 255},
			MenuDropdownText:  color.RGBA{248, 248, 242, 255},
			MenuBorder:       color.RGBA{98, 114, 164, 255},
			ScreenBg:    color.RGBA{40, 42, 54, 255},
			StatusTitle: color.RGBA{189, 147, 249, 255},
			StatusLabel: color.RGBA{139, 233, 253, 255},
			StatusValue: color.RGBA{248, 248, 242, 255},
			AccentColor: color.RGBA{80, 250, 123, 255},
			DialogBg:    color.RGBA{40, 42, 54, 250},
			DialogBorder:color.RGBA{189, 147, 249, 255},
			DialogHeader:color.RGBA{255, 121, 198, 255},
			DialogText:  color.RGBA{248, 248, 242, 255},
			ButtonBg:    color.RGBA{98, 114, 164, 255},
			ButtonHover: color.RGBA{189, 147, 249, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{68, 71, 90, 255},
			SelectedText:color.RGBA{80, 250, 123, 255},
		},

		// 6. Modern Dark 3: Monokai Pro
		{
			ID:          "monokai-pro",
			Name:        "Monokai Pro",
			Category:    CategoryDark,
			IsDark:      true,
			MenuBarBg:   color.RGBA{30, 31, 28, 255},
			MenuBarText: color.RGBA{248, 248, 242, 255},
			MenuDropdownBg:    color.RGBA{39, 40, 34, 255},
			MenuDropdownHover: color.RGBA{60, 61, 54, 255},
			MenuDropdownText:  color.RGBA{248, 248, 242, 255},
			MenuBorder:       color.RGBA{73, 72, 62, 255},
			ScreenBg:    color.RGBA{39, 40, 34, 255},
			StatusTitle: color.RGBA{166, 226, 46, 255},
			StatusLabel: color.RGBA{230, 219, 116, 255},
			StatusValue: color.RGBA{248, 248, 242, 255},
			AccentColor: color.RGBA{249, 38, 114, 255},
			DialogBg:    color.RGBA{39, 40, 34, 250},
			DialogBorder:color.RGBA{166, 226, 46, 255},
			DialogHeader:color.RGBA{253, 151, 31, 255},
			DialogText:  color.RGBA{248, 248, 242, 255},
			ButtonBg:    color.RGBA{253, 151, 31, 255},
			ButtonHover: color.RGBA{230, 219, 116, 255},
			ButtonText:  color.RGBA{30, 31, 28, 255},
			SelectedBg:  color.RGBA{73, 72, 62, 255},
			SelectedText:color.RGBA{166, 226, 46, 255},
		},

		// 7. Modern Dark 4: One Dark Pro
		{
			ID:          "one-dark-pro",
			Name:        "One Dark Pro",
			Category:    CategoryDark,
			IsDark:      true,
			MenuBarBg:   color.RGBA{33, 37, 43, 255},
			MenuBarText: color.RGBA{171, 178, 191, 255},
			MenuDropdownBg:    color.RGBA{40, 44, 52, 255},
			MenuDropdownHover: color.RGBA{53, 59, 69, 255},
			MenuDropdownText:  color.RGBA{171, 178, 191, 255},
			MenuBorder:       color.RGBA{62, 68, 81, 255},
			ScreenBg:    color.RGBA{40, 44, 52, 255},
			StatusTitle: color.RGBA{97, 175, 239, 255},
			StatusLabel: color.RGBA{152, 195, 121, 255},
			StatusValue: color.RGBA{229, 192, 123, 255},
			AccentColor: color.RGBA{224, 108, 117, 255},
			DialogBg:    color.RGBA{33, 37, 43, 250},
			DialogBorder:color.RGBA{97, 175, 239, 255},
			DialogHeader:color.RGBA{97, 175, 239, 255},
			DialogText:  color.RGBA{171, 178, 191, 255},
			ButtonBg:    color.RGBA{97, 175, 239, 255},
			ButtonHover: color.RGBA{82, 153, 212, 255},
			ButtonText:  color.RGBA{40, 44, 52, 255},
			SelectedBg:  color.RGBA{53, 59, 69, 255},
			SelectedText:color.RGBA{97, 175, 239, 255},
		},

		// 8. Modern Light 1: Solarized Light
		{
			ID:          "solarized-light",
			Name:        "Solarized Light",
			Category:    CategoryLight,
			IsDark:      false,
			MenuBarBg:   color.RGBA{238, 232, 213, 255},
			MenuBarText: color.RGBA{101, 123, 131, 255},
			MenuDropdownBg:    color.RGBA{253, 246, 227, 255},
			MenuDropdownHover: color.RGBA{238, 232, 213, 255},
			MenuDropdownText:  color.RGBA{101, 123, 131, 255},
			MenuBorder:       color.RGBA{181, 137, 0, 255},
			ScreenBg:    color.RGBA{253, 246, 227, 255},
			StatusTitle: color.RGBA{38, 139, 210, 255},
			StatusLabel: color.RGBA{88, 110, 117, 255},
			StatusValue: color.RGBA{101, 123, 131, 255},
			AccentColor: color.RGBA{203, 75, 22, 255},
			DialogBg:    color.RGBA{253, 246, 227, 250},
			DialogBorder:color.RGBA{38, 139, 210, 255},
			DialogHeader:color.RGBA{38, 139, 210, 255},
			DialogText:  color.RGBA{101, 123, 131, 255},
			ButtonBg:    color.RGBA{133, 153, 0, 255},
			ButtonHover: color.RGBA{113, 130, 0, 255},
			ButtonText:  color.RGBA{253, 246, 227, 255},
			SelectedBg:  color.RGBA{238, 232, 213, 255},
			SelectedText:color.RGBA{38, 139, 210, 255},
		},

		// 9. Modern Light 2: One Light
		{
			ID:          "one-light",
			Name:        "One Light",
			Category:    CategoryLight,
			IsDark:      false,
			MenuBarBg:   color.RGBA{234, 234, 234, 255},
			MenuBarText: color.RGBA{56, 58, 66, 255},
			MenuDropdownBg:    color.RGBA{250, 250, 250, 255},
			MenuDropdownHover: color.RGBA{229, 229, 234, 255},
			MenuDropdownText:  color.RGBA{56, 58, 66, 255},
			MenuBorder:       color.RGBA{200, 200, 205, 255},
			ScreenBg:    color.RGBA{250, 250, 250, 255},
			StatusTitle: color.RGBA{64, 120, 242, 255},
			StatusLabel: color.RGBA{110, 112, 120, 255},
			StatusValue: color.RGBA{56, 58, 66, 255},
			AccentColor: color.RGBA{228, 86, 73, 255},
			DialogBg:    color.RGBA{255, 255, 255, 250},
			DialogBorder:color.RGBA{64, 120, 242, 255},
			DialogHeader:color.RGBA{64, 120, 242, 255},
			DialogText:  color.RGBA{56, 58, 66, 255},
			ButtonBg:    color.RGBA{80, 161, 79, 255},
			ButtonHover: color.RGBA{65, 140, 65, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{229, 229, 234, 255},
			SelectedText:color.RGBA{64, 120, 242, 255},
		},

		// 10. Simple Dark
		{
			ID:          "simple-dark",
			Name:        "Simple Dark",
			Category:    CategoryDark,
			IsDark:      true,
			MenuBarBg:   color.RGBA{35, 38, 46, 255},
			MenuBarText: color.RGBA{230, 230, 230, 255},
			MenuDropdownBg:    color.RGBA{45, 48, 58, 255},
			MenuDropdownHover: color.RGBA{60, 64, 76, 255},
			MenuDropdownText:  color.RGBA{230, 230, 230, 255},
			MenuBorder:       color.RGBA{70, 75, 90, 255},
			ScreenBg:    color.RGBA{16, 18, 24, 255},
			StatusTitle: color.RGBA{100, 160, 255, 255},
			StatusLabel: color.RGBA{160, 160, 160, 255},
			StatusValue: color.RGBA{240, 240, 240, 255},
			AccentColor: color.RGBA{65, 110, 180, 255},
			DialogBg:    color.RGBA{28, 30, 38, 245},
			DialogBorder:color.RGBA{65, 110, 180, 255},
			DialogHeader:color.RGBA{100, 160, 255, 255},
			DialogText:  color.RGBA{220, 220, 220, 255},
			ButtonBg:    color.RGBA{65, 110, 180, 255},
			ButtonHover: color.RGBA{80, 130, 210, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{65, 110, 180, 255},
			SelectedText:color.RGBA{255, 255, 255, 255},
		},

		// 11. Simple Light
		{
			ID:          "simple-light",
			Name:        "Simple Light",
			Category:    CategoryLight,
			IsDark:      false,
			MenuBarBg:   color.RGBA{225, 228, 235, 255},
			MenuBarText: color.RGBA{30, 30, 30, 255},
			MenuDropdownBg:    color.RGBA{255, 255, 255, 255},
			MenuDropdownHover: color.RGBA{235, 238, 245, 255},
			MenuDropdownText:  color.RGBA{30, 30, 30, 255},
			MenuBorder:       color.RGBA{190, 195, 205, 255},
			ScreenBg:    color.RGBA{245, 245, 248, 255},
			StatusTitle: color.RGBA{25, 118, 210, 255},
			StatusLabel: color.RGBA{100, 100, 100, 255},
			StatusValue: color.RGBA{30, 30, 30, 255},
			AccentColor: color.RGBA{25, 118, 210, 255},
			DialogBg:    color.RGBA{255, 255, 255, 250},
			DialogBorder:color.RGBA{25, 118, 210, 255},
			DialogHeader:color.RGBA{25, 118, 210, 255},
			DialogText:  color.RGBA{30, 30, 30, 255},
			ButtonBg:    color.RGBA{25, 118, 210, 255},
			ButtonHover: color.RGBA{30, 136, 229, 255},
			ButtonText:  color.RGBA{255, 255, 255, 255},
			SelectedBg:  color.RGBA{25, 118, 210, 255},
			SelectedText:color.RGBA{255, 255, 255, 255},
		},
	}

	for _, t := range themes {
		themeRegistry[t.ID] = t
		themeList = append(themeList, t)
	}
}

// List returns all registered themes in display order.
func List() []Theme {
	return themeList
}

// Get returns the theme with the given ID, or default.
func Get(id string) (Theme, bool) {
	id = strings.ToLower(strings.TrimSpace(id))
	t, ok := themeRegistry[id]
	return t, ok
}

// SetCurrent changes the active theme ID.
func SetCurrent(id string) bool {
	id = strings.ToLower(strings.TrimSpace(id))
	if _, ok := themeRegistry[id]; ok {
		mu.Lock()
		currentThemeID = id
		mu.Unlock()
		return true
	}
	return false
}

// GetCurrent returns the currently configured theme ID.
func GetCurrent() string {
	mu.RLock()
	defer mu.RUnlock()
	return currentThemeID
}

// GetEffective returns the resolved Theme struct.
// If "system" is configured, it dynamically resolves to GitHub Dark or GitHub Light.
func GetEffective() Theme {
	mu.RLock()
	id := currentThemeID
	mu.RUnlock()

	if id == "system" {
		isLight := DetectOSLightTheme()
		if isLight {
			return themeRegistry["github-light"]
		}
		return themeRegistry["github-dark"]
	}

	if t, ok := themeRegistry[id]; ok {
		return t
	}
	return themeRegistry["github-dark"]
}
