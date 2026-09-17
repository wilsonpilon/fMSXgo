package tui

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"time"

	"golang.org/x/term"
)

var (
	// ErrCancelled is returned when the user presses ESC or 'q' to cancel selection.
	ErrCancelled = errors.New("file selection cancelled by user")

	// ErrNonInteractive is returned when attempting to run interactive TUI without a TTY.
	ErrNonInteractive = errors.New("interactive file browser requires a terminal (TTY)")
)

// FilePickerOptions configures the interactive TUI file browser.
type FilePickerOptions struct {
	Title        string    // Dialog title (e.g. "Select MSX Disk Image (.DSK)")
	Extensions   []string  // Supported file extensions (e.g. []string{".dsk", ".di1", ".di2", ".img"})
	StartPath    string    // Starting directory or file path
	FilterActive bool      // Whether extension filter is initially active (default true)
	ShowHidden   bool      // Show dotfiles/hidden files (default false)
	In           io.Reader // Input stream (must be *os.File for interactive terminal mode)
	Out          io.Writer // Output stream (must be *os.File or terminal writer)
}

// FileItem represents a single filesystem entry (directory or file).
type FileItem struct {
	Name    string
	Path    string
	IsDir   bool
	Size    int64
	ModTime time.Time
}

// OpenFilePicker opens an interactive full-screen terminal file browser.
// Returns the absolute path of the selected file, or ErrCancelled if aborted.
func OpenFilePicker(opts FilePickerOptions) (string, error) {
	in := opts.In
	if in == nil {
		in = os.Stdin
	}
	out := opts.Out
	if out == nil {
		out = os.Stdout
	}

	file, ok := in.(*os.File)
	if !ok || !term.IsTerminal(int(file.Fd())) {
		return "", ErrNonInteractive
	}

	// Resolve initial directory
	curDir := opts.StartPath
	if curDir == "" {
		var err error
		curDir, err = os.Getwd()
		if err != nil {
			curDir = "."
		}
	}

	absDir, err := filepath.Abs(curDir)
	if err == nil {
		if fi, err := os.Stat(absDir); err == nil && !fi.IsDir() {
			absDir = filepath.Dir(absDir)
		}
		curDir = absDir
	}

	filterActive := opts.FilterActive
	if len(opts.Extensions) > 0 && !filterActive {
		filterActive = true
	}

	// Put terminal into raw mode
	oldState, err := term.MakeRaw(int(file.Fd()))
	if err != nil {
		return "", fmt.Errorf("failed to initialize terminal raw mode: %w", err)
	}
	defer func() {
		_ = term.Restore(int(file.Fd()), oldState)
		fmt.Fprint(out, "\033[?25h\n") // Restore cursor visibility and emit newline
	}()

	// Hide cursor during navigation
	fmt.Fprint(out, "\033[?25l")

	items, _ := LoadDirectoryEntries(curDir, opts.Extensions, filterActive, opts.ShowHidden)
	selected := 0
	topIndex := 0
	viewportHeight := 14

	render := func() {
		var sb strings.Builder
		sb.WriteString("\033[H\033[2J") // Clear screen and move to home position
		RenderFilePicker(&sb, opts, curDir, items, selected, topIndex, viewportHeight, filterActive)
		fmt.Fprint(out, sb.String())
	}

	buf := make([]byte, 16)
	for {
		render()

		n, err := file.Read(buf)
		if err != nil || n == 0 {
			return "", ErrCancelled
		}

		key := buf[0]

		// ESC key
		if key == 0x1B {
			if n == 1 {
				// Bare ESC key -> Cancel
				return "", ErrCancelled
			}
			// Escape sequence (Arrow keys, Page Up/Down, Home, End)
			if n >= 3 && (buf[1] == '[' || buf[1] == 'O') {
				switch buf[2] {
				case 'A': // Up
					if selected > 0 {
						selected--
						if selected < topIndex {
							topIndex = selected
						}
					}
				case 'B': // Down
					if selected < len(items)-1 {
						selected++
						if selected >= topIndex+viewportHeight {
							topIndex = selected - viewportHeight + 1
						}
					}
				case '5', 'V', 'Z': // Page Up
					selected -= viewportHeight
					if selected < 0 {
						selected = 0
					}
					if selected < topIndex {
						topIndex = selected
					}
				case '6', 'U': // Page Down
					selected += viewportHeight
					if selected >= len(items) {
						selected = len(items) - 1
					}
					if selected >= topIndex+viewportHeight {
						topIndex = selected - viewportHeight + 1
					}
				case 'H', '1': // Home
					selected = 0
					topIndex = 0
				case 'F', '4': // End
					if len(items) > 0 {
						selected = len(items) - 1
						if selected >= viewportHeight {
							topIndex = selected - viewportHeight + 1
						}
					}
				}
			}
			continue
		}

		// 'q' or 'Q' -> Cancel
		if key == 'q' || key == 'Q' {
			return "", ErrCancelled
		}

		// TAB (0x09) or 'f' or 'F' -> Toggle Extension Filter
		if key == 0x09 || key == 'f' || key == 'F' {
			filterActive = !filterActive
			items, _ = LoadDirectoryEntries(curDir, opts.Extensions, filterActive, opts.ShowHidden)
			selected = 0
			topIndex = 0
			continue
		}

		// Backspace (0x08 or 0x7F) -> Go to parent directory
		if key == 0x08 || key == 0x7F {
			parent := filepath.Dir(curDir)
			if parent != curDir {
				curDir = parent
				items, _ = LoadDirectoryEntries(curDir, opts.Extensions, filterActive, opts.ShowHidden)
				selected = 0
				topIndex = 0
			}
			continue
		}

		// ENTER key (0x0D or 0x0A) -> Open Directory or Select File
		if key == '\r' || key == '\n' {
			if len(items) == 0 {
				continue
			}
			sel := items[selected]
			if sel.IsDir {
				curDir = sel.Path
				items, _ = LoadDirectoryEntries(curDir, opts.Extensions, filterActive, opts.ShowHidden)
				selected = 0
				topIndex = 0
				continue
			}
			// User confirmed file selection!
			return sel.Path, nil
		}
	}
}

// LoadDirectoryEntries reads the directory and returns sorted directories and filtered files.
func LoadDirectoryEntries(dir string, exts []string, filterActive, showHidden bool) ([]FileItem, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	var items []FileItem

	// Add parent directory entry ".." if not at system root
	parentDir := filepath.Dir(dir)
	if parentDir != dir {
		items = append(items, FileItem{
			Name:    "..",
			Path:    parentDir,
			IsDir:   true,
			Size:    0,
			ModTime: time.Time{},
		})
	} else if runtime.GOOS == "windows" {
		// At root on Windows (e.g. C:\) -> provide other drive roots
		for _, drv := range GetWindowsDrives() {
			drvRoot := drv + "\\"
			if !strings.EqualFold(drvRoot, dir) && !strings.EqualFold(drv, dir) {
				items = append(items, FileItem{
					Name:    drv,
					Path:    drvRoot,
					IsDir:   true,
					Size:    0,
					ModTime: time.Time{},
				})
			}
		}
	}

	var dirItems []FileItem
	var fileItems []FileItem

	for _, e := range entries {
		name := e.Name()
		if !showHidden && strings.HasPrefix(name, ".") {
			continue
		}

		fullPath := filepath.Join(dir, name)
		info, err := e.Info()
		var size int64
		var modTime time.Time
		if err == nil {
			size = info.Size()
			modTime = info.ModTime()
		}

		if e.IsDir() {
			dirItems = append(dirItems, FileItem{
				Name:    name,
				Path:    fullPath,
				IsDir:   true,
				Size:    size,
				ModTime: modTime,
			})
		} else {
			if !filterActive || MatchesExtension(name, exts) {
				fileItems = append(fileItems, FileItem{
					Name:    name,
					Path:    fullPath,
					IsDir:   false,
					Size:    size,
					ModTime: modTime,
				})
			}
		}
	}

	// Sort directories alphabetically (case-insensitive)
	sort.Slice(dirItems, func(i, j int) bool {
		return strings.ToLower(dirItems[i].Name) < strings.ToLower(dirItems[j].Name)
	})

	// Sort files alphabetically (case-insensitive)
	sort.Slice(fileItems, func(i, j int) bool {
		return strings.ToLower(fileItems[i].Name) < strings.ToLower(fileItems[j].Name)
	})

	items = append(items, dirItems...)
	items = append(items, fileItems...)

	return items, nil
}

// MatchesExtension checks whether filename matches one of the specified extensions.
func MatchesExtension(name string, exts []string) bool {
	if len(exts) == 0 {
		return true
	}
	fileExt := strings.ToLower(filepath.Ext(name))
	for _, ext := range exts {
		norm := strings.ToLower(ext)
		if !strings.HasPrefix(norm, ".") {
			norm = "." + norm
		}
		if fileExt == norm {
			return true
		}
	}
	return false
}

// FormatFileSize formats a byte size into a compact human-readable string.
func FormatFileSize(bytes int64) string {
	if bytes < 1024 {
		return fmt.Sprintf("%d B", bytes)
	}
	if bytes < 1024*1024 {
		return fmt.Sprintf("%d KB", (bytes+512)/1024)
	}
	return fmt.Sprintf("%.1f MB", float64(bytes)/(1024*1024))
}

// GetWindowsDrives scans drive letters A..Z on Windows platforms.
func GetWindowsDrives() []string {
	if runtime.GOOS != "windows" {
		return nil
	}
	var drives []string
	for c := 'A'; c <= 'Z'; c++ {
		d := fmt.Sprintf("%c:\\", c)
		if _, err := os.Stat(d); err == nil {
			drives = append(drives, fmt.Sprintf("%c:", c))
		}
	}
	return drives
}

// RenderFilePicker writes the complete TUI frame into the provided string builder.
func RenderFilePicker(sb *strings.Builder, opts FilePickerOptions, curDir string, items []FileItem, selected, topIndex, viewportHeight int, filterActive bool) {
	title := opts.Title
	if title == "" {
		title = "File Browser"
	}

	filterDesc := "*.* (All Files)"
	if filterActive && len(opts.Extensions) > 0 {
		var formatted []string
		for _, e := range opts.Extensions {
			if !strings.HasPrefix(e, "*") {
				formatted = append(formatted, "*"+e)
			} else {
				formatted = append(formatted, e)
			}
		}
		filterDesc = strings.Join(formatted, ", ")
	}

	sb.WriteString("=================================================================\n")
	sb.WriteString(fmt.Sprintf("  fMSXgo TUI - %s\n", title))
	sb.WriteString(fmt.Sprintf("  Directory: %s\n", curDir))
	sb.WriteString(fmt.Sprintf("  Filter:    [%s] (Press TAB or F to toggle)\n", filterDesc))
	sb.WriteString("=================================================================\n")
	sb.WriteString("   NAME                             SIZE        MODIFIED\n")
	sb.WriteString("-----------------------------------------------------------------\n")

	if len(items) == 0 {
		sb.WriteString("   (No files matching the active filter)\n")
	} else {
		// Scroll up indicator
		if topIndex > 0 {
			sb.WriteString("   ▲ ... [More items above] ...\n")
		} else {
			sb.WriteString("\n")
		}

		end := topIndex + viewportHeight
		if end > len(items) {
			end = len(items)
		}

		for i := topIndex; i < end; i++ {
			item := items[i]
			isSelected := (i == selected)

			prefix := "  "
			if isSelected {
				prefix = "> "
			}

			icon := "💾 "
			sizeStr := FormatFileSize(item.Size)
			if item.IsDir {
				icon = "📁 "
				sizeStr = "<DIR>"
				if item.Name == ".." {
					icon = "  "
					sizeStr = "<UP>"
				}
			}

			name := item.Name
			if len(name) > 30 {
				name = name[:27] + "..."
			}

			dateStr := ""
			if !item.ModTime.IsZero() {
				dateStr = item.ModTime.Format("2006-01-02 15:04")
			}

			line := fmt.Sprintf("%s%s%-30s %10s   %-16s", prefix, icon, name, sizeStr, dateStr)

			if isSelected {
				sb.WriteString("\033[7m") // Inverse video
				sb.WriteString(line)
				sb.WriteString("\033[0m\n")
			} else {
				sb.WriteString(line)
				sb.WriteString("\n")
			}
		}

		// Fill empty lines if items fewer than viewportHeight
		renderedRows := end - topIndex
		for r := renderedRows; r < viewportHeight; r++ {
			sb.WriteString("\n")
		}

		// Scroll down indicator
		if end < len(items) {
			sb.WriteString("   ▼ ... [More items below] ...\n")
		} else {
			sb.WriteString("\n")
		}
	}

	sb.WriteString("-----------------------------------------------------------------\n")
	sb.WriteString("[↑/↓]: Navigate  [ENTER]: Open / Select  [BKSP]: Parent  [TAB/F]: Filter  [ESC]: Cancel\n")
}

// SavePickerOptions configures the interactive TUI location/save picker.
type SavePickerOptions struct {
	Title       string    // Dialog title (e.g. "Create New MSX Disk Image (.DSK)")
	DefaultName string    // Default filename (e.g. "newdisk.dsk")
	StartPath   string    // Starting directory or file path
	Extension   string    // Default extension (e.g. ".dsk")
	In          io.Reader // Input stream
	Out         io.Writer // Output stream
}

// OpenSavePicker opens an interactive full-screen terminal directory and save picker.
// Returns the full absolute path of the chosen file destination, or ErrCancelled if aborted.
func OpenSavePicker(opts SavePickerOptions) (string, error) {
	in := opts.In
	if in == nil {
		in = os.Stdin
	}
	out := opts.Out
	if out == nil {
		out = os.Stdout
	}

	file, ok := in.(*os.File)
	if !ok || !term.IsTerminal(int(file.Fd())) {
		return "", ErrNonInteractive
	}

	curDir := opts.StartPath
	if curDir == "" {
		var err error
		curDir, err = os.Getwd()
		if err != nil {
			curDir = "."
		}
	}

	absDir, err := filepath.Abs(curDir)
	if err == nil {
		if fi, err := os.Stat(absDir); err == nil && !fi.IsDir() {
			absDir = filepath.Dir(absDir)
		}
		curDir = absDir
	}

	fileName := opts.DefaultName
	if fileName == "" {
		fileName = "newdisk.dsk"
	}

	oldState, err := term.MakeRaw(int(file.Fd()))
	if err != nil {
		return "", fmt.Errorf("failed to initialize terminal raw mode: %w", err)
	}
	defer func() {
		_ = term.Restore(int(file.Fd()), oldState)
		fmt.Fprint(out, "\033[?25h\n")
	}()

	fmt.Fprint(out, "\033[?25l")

	editingName := false
	nameBuffer := []rune(fileName)

	loadItems := func() []FileItem {
		baseItems, _ := LoadDirectoryEntries(curDir, nil, false, false)
		var res []FileItem
		res = append(res, FileItem{
			Name:  fmt.Sprintf("[+] SAVE HERE as %q", fileName),
			Path:  filepath.Join(curDir, fileName),
			IsDir: false,
		})
		res = append(res, baseItems...)
		return res
	}

	items := loadItems()
	selected := 0
	topIndex := 0
	viewportHeight := 14

	render := func() {
		var sb strings.Builder
		sb.WriteString("\033[H\033[2J")
		RenderSavePicker(&sb, opts, curDir, fileName, items, selected, topIndex, viewportHeight, editingName, string(nameBuffer))
		fmt.Fprint(out, sb.String())
	}

	buf := make([]byte, 16)
	for {
		render()

		n, err := file.Read(buf)
		if err != nil || n == 0 {
			return "", ErrCancelled
		}

		key := buf[0]

		if editingName {
			if key == '\r' || key == '\n' {
				// Confirm edited name
				trimmed := strings.TrimSpace(string(nameBuffer))
				if trimmed != "" {
					if opts.Extension != "" && !strings.HasSuffix(strings.ToLower(trimmed), strings.ToLower(opts.Extension)) {
						trimmed += opts.Extension
					}
					fileName = trimmed
				}
				editingName = false
				items = loadItems()
				continue
			}
			if key == 0x1B { // ESC while editing cancels editing
				editingName = false
				continue
			}
			if key == 0x08 || key == 0x7F { // Backspace
				if len(nameBuffer) > 0 {
					nameBuffer = nameBuffer[:len(nameBuffer)-1]
				}
				continue
			}
			if key >= 32 && key <= 126 { // Printable character
				nameBuffer = append(nameBuffer, rune(key))
				continue
			}
			continue
		}

		// Not in editing mode
		if key == 0x1B {
			if n == 1 {
				return "", ErrCancelled
			}
			if n >= 3 && (buf[1] == '[' || buf[1] == 'O') {
				switch buf[2] {
				case 'A': // Up
					if selected > 0 {
						selected--
						if selected < topIndex {
							topIndex = selected
						}
					}
				case 'B': // Down
					if selected < len(items)-1 {
						selected++
						if selected >= topIndex+viewportHeight {
							topIndex = selected - viewportHeight + 1
						}
					}
				case '5', 'V', 'Z': // Page Up
					selected -= viewportHeight
					if selected < 0 {
						selected = 0
					}
					if selected < topIndex {
						topIndex = selected
					}
				case '6', 'U': // Page Down
					selected += viewportHeight
					if selected >= len(items) {
						selected = len(items) - 1
					}
					if selected >= topIndex+viewportHeight {
						topIndex = selected - viewportHeight + 1
					}
				case 'H', '1': // Home
					selected = 0
					topIndex = 0
				case 'F', '4': // End
					if len(items) > 0 {
						selected = len(items) - 1
						if selected >= viewportHeight {
							topIndex = selected - viewportHeight + 1
						}
					}
				}
			}
			continue
		}

		if key == 'q' || key == 'Q' {
			return "", ErrCancelled
		}

		// 's' or 'S' -> Save immediately in current directory
		if key == 's' || key == 'S' {
			return filepath.Join(curDir, fileName), nil
		}

		// 'n' or 'N' or 'r' or 'R' -> Rename / edit filename
		if key == 'n' || key == 'N' || key == 'r' || key == 'R' {
			editingName = true
			nameBuffer = []rune(fileName)
			continue
		}

		// Backspace -> Parent directory
		if key == 0x08 || key == 0x7F {
			parent := filepath.Dir(curDir)
			if parent != curDir {
				curDir = parent
				items = loadItems()
				selected = 0
				topIndex = 0
			}
			continue
		}

		// ENTER key
		if key == '\r' || key == '\n' {
			if len(items) == 0 {
				continue
			}
			sel := items[selected]
			if selected == 0 {
				// Clicked on "[+] SAVE HERE as ..."
				return filepath.Join(curDir, fileName), nil
			}
			if sel.IsDir {
				curDir = sel.Path
				items = loadItems()
				selected = 0
				topIndex = 0
				continue
			}
			// Selected an existing file -> use that filename (overwrite prompt/confirmation)
			fileName = filepath.Base(sel.Path)
			return sel.Path, nil
		}
	}
}

// RenderSavePicker writes the Save Picker UI into the string builder.
func RenderSavePicker(sb *strings.Builder, opts SavePickerOptions, curDir, fileName string, items []FileItem, selected, topIndex, viewportHeight int, editingName bool, currentInput string) {
	title := opts.Title
	if title == "" {
		title = "Choose Disk Save Location"
	}

	sb.WriteString("=================================================================\n")
	sb.WriteString(fmt.Sprintf("  fMSXgo TUI - %s\n", title))
	sb.WriteString(fmt.Sprintf("  Target Directory: %s\n", curDir))
	if editingName {
		sb.WriteString(fmt.Sprintf("  File Name:        [\033[1;32m%s_\033[0m] (Type new name, ENTER to confirm)\n", currentInput))
	} else {
		sb.WriteString(fmt.Sprintf("  File Name:        [\033[1;36m%s\033[0m] (Press N to edit name, S to save)\n", fileName))
	}
	sb.WriteString("=================================================================\n")
	sb.WriteString("   NAME                             SIZE        MODIFIED\n")
	sb.WriteString("-----------------------------------------------------------------\n")

	if len(items) == 0 {
		sb.WriteString("   (Directory is empty)\n")
	} else {
		if topIndex > 0 {
			sb.WriteString("   ▲ ... [More items above] ...\n")
		} else {
			sb.WriteString("\n")
		}

		end := topIndex + viewportHeight
		if end > len(items) {
			end = len(items)
		}

		for i := topIndex; i < end; i++ {
			item := items[i]
			isSelected := (i == selected)

			prefix := "  "
			if isSelected {
				prefix = "> "
			}

			icon := "💾 "
			sizeStr := FormatFileSize(item.Size)
			if i == 0 {
				icon = "⭐ "
				sizeStr = "<SAVE>"
			} else if item.IsDir {
				icon = "📁 "
				sizeStr = "<DIR>"
				if item.Name == ".." {
					icon = "  "
					sizeStr = "<UP>"
				}
			}

			name := item.Name
			if len(name) > 30 {
				name = name[:27] + "..."
			}

			dateStr := ""
			if !item.ModTime.IsZero() {
				dateStr = item.ModTime.Format("2006-01-02 15:04")
			}

			line := fmt.Sprintf("%s%s%-30s %10s   %-16s", prefix, icon, name, sizeStr, dateStr)

			if isSelected {
				sb.WriteString("\033[7m")
				sb.WriteString(line)
				sb.WriteString("\033[0m\n")
			} else {
				sb.WriteString(line)
			}
		}

		renderedRows := end - topIndex
		for r := renderedRows; r < viewportHeight; r++ {
			sb.WriteString("\n")
		}

		if end < len(items) {
			sb.WriteString("   ▼ ... [More items below] ...\n")
		} else {
			sb.WriteString("\n")
		}
	}

	sb.WriteString("-----------------------------------------------------------------\n")
	if editingName {
		sb.WriteString("[TYPE]: New Name  [ENTER]: Apply  [ESC]: Cancel Name Edit\n")
	} else {
		sb.WriteString("[↑/↓]: Navigate  [ENTER]: Open/Save  [S]: Save Here  [N]: Edit Name  [ESC]: Cancel\n")
	}
}

