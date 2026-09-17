package shell

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	"fmsxgo/pkg/msxdisk"
	"fmsxgo/pkg/tui"
)

// cmdDiskCreate creates a new formatted MSX FAT12 disk image.
// If a filename is supplied on the command line (e.g. "diskcreate blank.dsk [size]"),
// it creates the disk directly in the current directory (or path).
// If no arguments are provided, it launches the interactive TUI directory/save browser.
func (sh *Shell) cmdDiskCreate(args []string) {
	var targetPath string
	fmtChoice := msxdisk.Format720K

	if len(args) > 0 {
		// 1. Direct filename specified on command line
		targetPath = strings.Trim(args[0], "\"' ")
		if len(args) > 1 {
			sizeArg := strings.ToUpper(args[1])
			switch {
			case strings.Contains(sizeArg, "360"):
				fmtChoice = msxdisk.Format360K
			case strings.Contains(sizeArg, "180"):
				fmtChoice = msxdisk.Format180K
			default:
				fmtChoice = msxdisk.Format720K
			}
		}

		if !strings.HasSuffix(strings.ToLower(targetPath), ".dsk") {
			targetPath += ".dsk"
		}
	} else {
		// 2. No argument given -> open interactive TUI save/location picker
		opts := tui.SavePickerOptions{
			Title:       "Create New MSX Disk Image (.DSK)",
			DefaultName: "newdisk.dsk",
			StartPath:   sh.LastPath,
			Extension:   ".dsk",
			In:          sh.In,
			Out:         sh.Out,
		}

		selected, err := tui.OpenSavePicker(opts)
		if err != nil {
			if errors.Is(err, tui.ErrCancelled) {
				fmt.Fprintln(sh.Out, "Disk creation cancelled.")
				return
			}
			if errors.Is(err, tui.ErrNonInteractive) {
				// Non-interactive fallback: create default newdisk.dsk in current directory
				targetPath = "newdisk.dsk"
				fmt.Fprintln(sh.Out, "Non-interactive shell: defaulting to 'newdisk.dsk' in current directory.")
			} else {
				fmt.Fprintf(sh.Out, "Error in disk save browser: %v\n", err)
				return
			}
		} else {
			targetPath = selected
		}
	}

	if targetPath == "" {
		fmt.Fprintln(sh.Out, "No disk path specified.")
		return
	}

	// Make path absolute for clarity and consistency
	absPath, err := filepath.Abs(targetPath)
	if err == nil {
		targetPath = absPath
	}

	// Create and format the disk image using pkg/msxdisk
	d, err := msxdisk.Create(targetPath, fmtChoice, nil)
	if err != nil {
		fmt.Fprintf(sh.Out, "Error creating MSX disk image: %v\n", err)
		return
	}

	// Auto-mount the newly created disk into Drive A:
	mountErr := sh.Machine.LoadDisk(0, targetPath)
	sh.LastPath = filepath.Dir(targetPath)
	sh.LastDiskDrive = 0
	sh.LastSector = 0

	fmt.Fprintln(sh.Out, "=================================================================")
	fmt.Fprintln(sh.Out, "  MSX Floppy Disk Created & Formatted Successfully")
	fmt.Fprintln(sh.Out, "=================================================================")
	fmt.Fprintf(sh.Out, "  File:         %s\n", filepath.Base(targetPath))
	fmt.Fprintf(sh.Out, "  Full Path:    %s\n", targetPath)
	fmt.Fprintf(sh.Out, "  Format:       %s\n", d.Geometry.Description)
	fmt.Fprintf(sh.Out, "  Total Size:   %s (%d bytes)\n", tui.FormatFileSize(int64(len(d.Data))), len(d.Data))
	fmt.Fprintf(sh.Out, "  Geometry:     %d tracks, %d sides, %d sectors/track (512B/sector)\n",
		d.Geometry.Tracks, d.Geometry.Sides, d.Geometry.SecPerTrack)
	fmt.Fprintf(sh.Out, "  Filesystem:   MSX FAT12 (Media ID %02Xh, %d root entries, %d sectors/FAT)\n",
		d.Geometry.MediaID, d.Geometry.RootDirEnts, d.Geometry.SecPerFat)

	if mountErr != nil {
		fmt.Fprintf(sh.Out, "  Warning: Could not auto-mount into Drive A: %v\n", mountErr)
	} else {
		fmt.Fprintln(sh.Out, "  Mount Status: Mounted in Drive A: (Ready for ZAP, files, or booting)")
	}
	fmt.Fprintln(sh.Out, "=================================================================")
}
