package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"fmsxgo/pkg/msxdisk"
	"fmsxgo/pkg/tui"
)

func showDiskCLIHelp() {
	fmt.Println("MSX Floppy Disk Manager Utility (fMSXgo)")
	fmt.Println("Usage: fmsxgo disk <command> <disk_image.dsk> [arguments...]")
	fmt.Println()
	fmt.Println("Available commands:")
	fmt.Println("  create <disk.dsk> [720k|360k|180k]")
	fmt.Println("            Creates and formats a new MSX FAT12 disk image (default: 720KB).")
	fmt.Println()
	fmt.Println("  list <disk.dsk> [-l]")
	fmt.Println("            Lists all files contained on the MSX disk image.")
	fmt.Println("            Use '-l' for detailed view (size, modification date/time, clusters).")
	fmt.Println()
	fmt.Println("  add <disk.dsk> <local_file1> [local_file2 ...]")
	fmt.Println("            Adds one or more host files into the MSX disk image.")
	fmt.Println("            Supports local file wildcards (e.g. *.TXT, *.BAS).")
	fmt.Println()
	fmt.Println("  extract <disk.dsk> [-d out_dir] [mask1 mask2 ...]")
	fmt.Println("            Extracts files from the MSX disk image to the host filesystem.")
	fmt.Println("            Use '-d out_dir' to specify destination folder.")
	fmt.Println("            Optionally specify file masks (e.g. *.BAS, AUTOEXEC.BAT).")
	fmt.Println()
	fmt.Println("  delete <disk.dsk> <filename>")
	fmt.Println("            Deletes a file from the MSX disk image.")
	fmt.Println()
}

func runDiskCLI(args []string) {
	if len(args) < 2 {
		showDiskCLIHelp()
		return
	}

	cmd := strings.ToLower(args[0])
	diskPath := args[1]

	switch cmd {
	case "create", "mkdsk", "new":
		format := msxdisk.Format720K
		if len(args) > 2 {
			sizeArg := strings.ToUpper(args[2])
			switch {
			case strings.Contains(sizeArg, "360"):
				format = msxdisk.Format360K
			case strings.Contains(sizeArg, "180"):
				format = msxdisk.Format180K
			default:
				format = msxdisk.Format720K
			}
		}

		fmt.Printf("Creating MSX disk image: %s (%s)...\n", diskPath, format)
		d, err := msxdisk.Create(diskPath, format, nil)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error creating disk: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Success: Created and formatted %s (%s, %d sectors, FAT12).\n",
			filepath.Base(diskPath), d.Geometry.Description, d.Geometry.TotalSectors)

	case "list", "dir", "ls":
		detailed := false
		if len(args) > 2 && (args[2] == "-l" || args[2] == "--long" || args[2] == "/w") {
			detailed = true
		}

		d, err := msxdisk.Open(diskPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error opening disk: %v\n", err)
			os.Exit(1)
		}

		files, err := d.ListFiles()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading directory: %v\n", err)
			os.Exit(1)
		}

		if detailed {
			fmt.Printf("Volume in %s (%s)\n", filepath.Base(diskPath), d.Geometry.Description)
			fmt.Println("-----------------------------------------------------------------")
			fmt.Println("NAME             SIZE (BYTES)  MODIFIED           CLUSTERS")
			fmt.Println("-----------------------------------------------------------------")
			var totalBytes int64 = 0
			for _, f := range files {
				totalBytes += int64(f.Size)
				dt := f.ModTime.Format("2006-01-02 15:04:05")
				fmt.Printf("%-14s  %12d  %-19s  %8d\n", f.Name, f.Size, dt, f.Clusters)
			}
			fmt.Println("-----------------------------------------------------------------")
			fmt.Printf("  %d File(s)    %s (%d bytes) used\n", len(files), tui.FormatFileSize(totalBytes), totalBytes)
		} else {
			for _, f := range files {
				fmt.Println(f.Name)
			}
		}

	case "add", "put":
		if len(args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: No files specified to add.")
			os.Exit(1)
		}

		d, err := msxdisk.Open(diskPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error opening disk: %v\n", err)
			os.Exit(1)
		}

		count := 0
		for i := 2; i < len(args); i++ {
			pattern := args[i]
			matches, err := filepath.Glob(pattern)
			if err != nil || len(matches) == 0 {
				matches = []string{pattern}
			}

			for _, path := range matches {
				fi, err := os.Stat(path)
				if err != nil || fi.IsDir() {
					continue
				}

				baseName := filepath.Base(path)
				fmt.Printf("Adding %s -> %s ... ", path, baseName)
				if err := d.AddFile(path, ""); err != nil {
					fmt.Printf("FAILED: %v\n", err)
				} else {
					fmt.Println("OK")
					count++
				}
			}
		}

		if err := d.Save(); err != nil {
			fmt.Fprintf(os.Stderr, "Error saving disk: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Done: %d file(s) added successfully.\n", count)

	case "extract", "get":
		outDir := "."
		maskStart := 2
		if len(args) > 2 && args[2] == "-d" {
			if len(args) > 3 {
				outDir = args[3]
				maskStart = 4
			} else {
				fmt.Fprintln(os.Stderr, "Error: Destination directory expected after -d.")
				os.Exit(1)
			}
		}

		d, err := msxdisk.Open(diskPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error opening disk: %v\n", err)
			os.Exit(1)
		}

		files, err := d.ListFiles()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading files: %v\n", err)
			os.Exit(1)
		}

		var masks []string
		for i := maskStart; i < len(args); i++ {
			masks = append(masks, args[i])
		}

		if err := os.MkdirAll(outDir, 0755); err != nil {
			fmt.Fprintf(os.Stderr, "Cannot create destination directory %q: %v\n", outDir, err)
			os.Exit(1)
		}

		extracted := 0
		for _, f := range files {
			matched := len(masks) == 0
			for _, m := range masks {
				if msxdisk.MatchesMask(f.Name, m) {
					matched = true
					break
				}
			}

			if matched {
				dest := filepath.Join(outDir, f.Name)
				fmt.Printf("Extracting %s -> %s ... ", f.Name, dest)
				if err := d.ExtractFile(f.Name, dest); err != nil {
					fmt.Printf("FAILED: %v\n", err)
				} else {
					fmt.Println("OK")
					extracted++
				}
			}
		}
		fmt.Printf("Done: %d file(s) extracted.\n", extracted)

	case "delete", "del", "rm":
		if len(args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: No file specified to delete.")
			os.Exit(1)
		}

		d, err := msxdisk.Open(diskPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error opening disk: %v\n", err)
			os.Exit(1)
		}

		for i := 2; i < len(args); i++ {
			target := args[i]
			fmt.Printf("Deleting %s ... ", target)
			if err := d.DeleteFile(target); err != nil {
				fmt.Printf("FAILED: %v\n", err)
			} else {
				fmt.Println("OK")
			}
		}

		if err := d.Save(); err != nil {
			fmt.Fprintf(os.Stderr, "Error saving disk: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Done: File(s) deleted.")

	default:
		showDiskCLIHelp()
	}
}
