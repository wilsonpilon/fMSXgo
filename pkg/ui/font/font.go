package font

import (
	"bytes"
	_ "embed"
	"image/color"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/text/v2"
)

// Embedded default fonts
//
//go:embed assets/Ubuntu-Regular.ttf
var ubuntuRegularBytes []byte

//go:embed assets/Ubuntu-Bold.ttf
var ubuntuBoldBytes []byte

//go:embed assets/SourceCodePro-Regular.ttf
var sourceCodeProRegularBytes []byte

//go:embed assets/SourceCodePro-Bold.ttf
var sourceCodeProBoldBytes []byte

// Family represents a selectable TrueType font family.
type Family struct {
	ID            string // Unique identifier (e.g. "ubuntu", "sourcecodepro")
	Name          string // Display name (e.g. "Ubuntu (Default)")
	Path          string // Path if loaded from disk, or "(embedded)"
	IsMonospace   bool
	RegularSource *text.GoTextFaceSource
	BoldSource    *text.GoTextFaceSource
}

var (
	mu            sync.RWMutex
	currentFontID = "ubuntu"
	families      = make(map[string]*Family)
	familyOrder   []string

	// Cached face objects per size
	faceCache     = make(map[string]*text.GoTextFace)
	faceCacheMu   sync.Mutex
)

func init() {
	// Initialize embedded default fonts
	uRegSource, err := text.NewGoTextFaceSource(bytes.NewReader(ubuntuRegularBytes))
	if err == nil {
		uBoldSource, errB := text.NewGoTextFaceSource(bytes.NewReader(ubuntuBoldBytes))
		if errB != nil {
			uBoldSource = uRegSource
		}
		RegisterFamily(&Family{
			ID:            "ubuntu",
			Name:          "Ubuntu",
			Path:          "(embedded)",
			IsMonospace:   false,
			RegularSource: uRegSource,
			BoldSource:    uBoldSource,
		})
	}

	scpRegSource, err := text.NewGoTextFaceSource(bytes.NewReader(sourceCodeProRegularBytes))
	if err == nil {
		scpBoldSource, errB := text.NewGoTextFaceSource(bytes.NewReader(sourceCodeProBoldBytes))
		if errB != nil {
			scpBoldSource = scpRegSource
		}
		RegisterFamily(&Family{
			ID:            "sourcecodepro",
			Name:          "Source Code Pro",
			Path:          "(embedded)",
			IsMonospace:   true,
			RegularSource: scpRegSource,
			BoldSource:    scpBoldSource,
		})
	}

	// Scan directories for additional fonts
	ScanFontDirectories([]string{
		"fonts",
		filepath.Join("dist", "fonts"),
		filepath.Join("third-party", "fonts"),
	})
}

// RegisterFamily adds or updates a font family in the registry.
func RegisterFamily(f *Family) {
	mu.Lock()
	defer mu.Unlock()

	if _, exists := families[f.ID]; !exists {
		familyOrder = append(familyOrder, f.ID)
	}
	families[f.ID] = f
}

// ScanFontDirectories scans directories for custom .ttf and .otf files.
func ScanFontDirectories(dirs []string) {
	for _, dir := range dirs {
		if fi, err := os.Stat(dir); err == nil && fi.IsDir() {
			entries, err := os.ReadDir(dir)
			if err != nil {
				continue
			}
			for _, entry := range entries {
				if entry.IsDir() {
					continue
				}
				ext := strings.ToLower(filepath.Ext(entry.Name()))
				if ext != ".ttf" && ext != ".otf" {
					continue
				}

				fontPath := filepath.Join(dir, entry.Name())
				baseName := strings.TrimSuffix(entry.Name(), filepath.Ext(entry.Name()))
				id := strings.ToLower(strings.ReplaceAll(baseName, " ", "-"))

				// Skip if standard Ubuntu/SourceCodePro which are already embedded
				if id == "ubuntu-regular" || id == "ubuntu" ||
					id == "sourcecodepro-regular" || id == "sourcecodepro" ||
					id == "ubuntu-bold" || id == "sourcecodepro-bold" {
					continue
				}

				data, err := os.ReadFile(fontPath)
				if err != nil {
					continue
				}

				src, err := text.NewGoTextFaceSource(bytes.NewReader(data))
				if err != nil {
					continue
				}

				isMono := strings.Contains(strings.ToLower(baseName), "mono") ||
					strings.Contains(strings.ToLower(baseName), "code")

				displayName := strings.ReplaceAll(baseName, "-", " ")
				displayName = strings.ReplaceAll(displayName, "_", " ")

				RegisterFamily(&Family{
					ID:            id,
					Name:          displayName,
					Path:          fontPath,
					IsMonospace:   isMono,
					RegularSource: src,
					BoldSource:    src,
				})
			}
		}
	}
}

// GetCurrent returns the active font family ID.
func GetCurrent() string {
	mu.RLock()
	defer mu.RUnlock()
	return currentFontID
}

// SetCurrent sets the active font family ID.
func SetCurrent(id string) bool {
	mu.Lock()
	defer mu.Unlock()

	id = strings.ToLower(id)
	if _, ok := families[id]; ok {
		currentFontID = id
		return true
	}
	return false
}

// ListFamilies returns the list of available font families.
func ListFamilies() []*Family {
	mu.RLock()
	defer mu.RUnlock()

	res := make([]*Family, 0, len(familyOrder))
	for _, id := range familyOrder {
		if f, ok := families[id]; ok {
			res = append(res, f)
		}
	}
	return res
}

// GetFamily retrieves a font family by ID.
func GetFamily(id string) *Family {
	mu.RLock()
	defer mu.RUnlock()
	return families[strings.ToLower(id)]
}

// ActiveFamily returns the currently active font family.
func ActiveFamily() *Family {
	mu.RLock()
	defer mu.RUnlock()

	if f, ok := families[currentFontID]; ok {
		return f
	}
	if f, ok := families["ubuntu"]; ok {
		return f
	}
	return nil
}

// getFace retrieves or creates a cached GoTextFace for the given source and size.
func getFace(source *text.GoTextFaceSource, size float64) *text.GoTextFace {
	if source == nil {
		return nil
	}
	return &text.GoTextFace{
		Source: source,
		Size:   size,
	}
}

// Draw renders text at (x, y) with the active regular font, specified size, and color.
func Draw(dst *ebiten.Image, str string, x, y float64, size float64, col color.Color) {
	fam := ActiveFamily()
	if fam == nil || fam.RegularSource == nil {
		return
	}
	face := getFace(fam.RegularSource, size)
	op := &text.DrawOptions{}
	op.GeoM.Translate(x, y)
	op.ColorScale.ScaleWithColor(col)
	text.Draw(dst, str, face, op)
}

// DrawBold renders text at (x, y) with the active bold font, specified size, and color.
func DrawBold(dst *ebiten.Image, str string, x, y float64, size float64, col color.Color) {
	fam := ActiveFamily()
	if fam == nil {
		return
	}
	src := fam.BoldSource
	if src == nil {
		src = fam.RegularSource
	}
	if src == nil {
		return
	}
	face := getFace(src, size)
	op := &text.DrawOptions{}
	op.GeoM.Translate(x, y)
	op.ColorScale.ScaleWithColor(col)
	text.Draw(dst, str, face, op)
}

// DrawCode renders text with Source Code Pro (monospace) at (x, y), size, and color.
func DrawCode(dst *ebiten.Image, str string, x, y float64, size float64, col color.Color) {
	fam := GetFamily("sourcecodepro")
	if fam == nil {
		fam = ActiveFamily()
	}
	if fam == nil || fam.RegularSource == nil {
		return
	}
	face := getFace(fam.RegularSource, size)
	op := &text.DrawOptions{}
	op.GeoM.Translate(x, y)
	op.ColorScale.ScaleWithColor(col)
	text.Draw(dst, str, face, op)
}

// Measure returns width and height for text rendered in the active regular font.
func Measure(str string, size float64) (float64, float64) {
	fam := ActiveFamily()
	if fam == nil || fam.RegularSource == nil {
		return 0, 0
	}
	face := getFace(fam.RegularSource, size)
	return text.Measure(str, face, 0)
}

// MeasureCode returns width and height for text rendered in monospace code font.
func MeasureCode(str string, size float64) (float64, float64) {
	fam := GetFamily("sourcecodepro")
	if fam == nil {
		fam = ActiveFamily()
	}
	if fam == nil || fam.RegularSource == nil {
		return 0, 0
	}
	face := getFace(fam.RegularSource, size)
	return text.Measure(str, face, 0)
}

// LoadFromReader loads a custom TTF/OTF from any io.Reader.
func LoadFromReader(r io.Reader) (*text.GoTextFaceSource, error) {
	return text.NewGoTextFaceSource(r)
}
