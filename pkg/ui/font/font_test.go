package font

import (
	"image/color"
	"testing"

	"github.com/hajimehoshi/ebiten/v2"
)

func TestFontRegistry(t *testing.T) {
	families := ListFamilies()
	if len(families) == 0 {
		t.Fatalf("Expected at least embedded fonts in registry, got 0")
	}

	// Verify Ubuntu is default
	curr := GetCurrent()
	if curr != "ubuntu" {
		t.Fatalf("Expected default font to be 'ubuntu', got %s", curr)
	}

	u := GetFamily("ubuntu")
	if u == nil {
		t.Fatalf("Expected 'ubuntu' family to be registered")
	}
	if u.Name != "Ubuntu" {
		t.Fatalf("Expected family name 'Ubuntu', got %s", u.Name)
	}

	scp := GetFamily("sourcecodepro")
	if scp == nil {
		t.Fatalf("Expected 'sourcecodepro' family to be registered")
	}
	if !scp.IsMonospace {
		t.Fatalf("Expected Source Code Pro to be flagged as monospace")
	}

	// Test switching font
	if !SetCurrent("sourcecodepro") {
		t.Fatalf("Failed to switch font to 'sourcecodepro'")
	}
	if GetCurrent() != "sourcecodepro" {
		t.Fatalf("Current font not updated")
	}

	// Switch back
	SetCurrent("ubuntu")
}

func TestFontMeasureAndDraw(t *testing.T) {
	w, h := Measure("Hello MSX", 14)
	if w <= 0 || h <= 0 {
		t.Fatalf("Expected positive measure, got w=%f h=%f", w, h)
	}

	img := ebiten.NewImage(200, 50)
	Draw(img, "Test Text", 10, 10, 14, color.White)
	DrawBold(img, "Bold Text", 10, 25, 14, color.White)
	DrawCode(img, "Code Text", 10, 40, 12, color.White)
}
