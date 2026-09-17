package theme

import (
	"testing"
)

func TestThemeRegistry(t *testing.T) {
	list := List()
	if len(list) < 8 {
		t.Fatalf("Expected at least 8 themes, got %d", len(list))
	}

	// Verify required themes exist
	required := []string{
		"system",
		"github-dark",
		"github-light",
		"vscode-dark",
		"dracula",
		"monokai-pro",
		"one-dark-pro",
		"solarized-light",
		"one-light",
	}

	for _, req := range required {
		th, ok := Get(req)
		if !ok {
			t.Errorf("Required theme %q not found in registry", req)
		}
		if th.Name == "" {
			t.Errorf("Theme %q has empty name", req)
		}
		if th.MenuBarBg.A == 0 || th.ScreenBg.A == 0 {
			t.Errorf("Theme %q has uninitialized alpha channel", req)
		}
	}
}

func TestThemeSwitchingAndEffective(t *testing.T) {
	// Set Dracula
	if !SetCurrent("dracula") {
		t.Fatal("Failed to set theme to dracula")
	}
	if GetCurrent() != "dracula" {
		t.Fatalf("Expected current theme 'dracula', got %q", GetCurrent())
	}
	eff := GetEffective()
	if eff.ID != "dracula" {
		t.Fatalf("Expected effective theme 'dracula', got %q", eff.ID)
	}

	// Set GitHub Light
	if !SetCurrent("github-light") {
		t.Fatal("Failed to set theme to github-light")
	}
	eff = GetEffective()
	if eff.ID != "github-light" {
		t.Fatalf("Expected effective theme 'github-light', got %q", eff.ID)
	}

	// Set System (Auto)
	if !SetCurrent("system") {
		t.Fatal("Failed to set theme to system")
	}
	eff = GetEffective()
	// Effective must resolve to either github-light or github-dark
	if eff.ID != "github-light" && eff.ID != "github-dark" {
		t.Fatalf("Expected system theme to resolve to github-light or github-dark, got %q", eff.ID)
	}

	// Reset to system
	SetCurrent("system")
}
