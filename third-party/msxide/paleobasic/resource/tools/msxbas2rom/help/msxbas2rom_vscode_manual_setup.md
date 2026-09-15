# VSCode Manual Setup

This document describes how to manually integrate **MSXBAS2ROM** development with **Visual Studio Code** using:

-   `Makefile` for using with **make** tool;
-   **VSCode** `tasks.json` and `launch.json`;
-   **openMSX** debug automation using `debug.tcl` script;
-   `.gitignore` for using with **git** repositories.

This setup allows a streamlined workflow for compiling, running, and debugging MSX BASIC programs converted to ROM using **MSXBAS2ROM**.

------------------------------------------------------------------------

# Overview

The development workflow becomes:

    VSCode Build (Ctrl+Shift+B)
            ↓
    Makefile executes MSXBAS2ROM
            ↓
    ROM and NOI debug symbols generated
            ↓
    VSCode Test task launches openMSX (Ctrl+Shift+T)
            ↓
    debug.tcl loads symbols and configures debugging

Artifacts produced during compilation:

| File | Purpose |
|--------|--------------------------|
| `.rom` | Compiled MSX ROM |
| `.noi` | Symbol/debug information |
| `.bas` | Original BASIC source |

The `.noi` file allows the debugger in **openMSX** to map addresses to labels and symbols.

------------------------------------------------------------------------

# Project Structure

Recommended project layout:

    project/
    │
    ├── program.bas
    ├── program.rom
    ├── program.noi
    │
    ├── Makefile
    ├── debug.tcl
    ├── .gitignore
    └── .vscode/
        ├── launch.json
        └── tasks.json

------------------------------------------------------------------------

# Makefile

The Makefile controls the build pipeline and emulator execution.

Targets included:

-   `all` → compile BASIC into ROM
-   `run` → launch emulator
-   `test` → launch emulator with debugging
-   `clean` → remove generated files

## Example Makefile

``` makefile
# MSXBAS2ROM Project Makefile

BAS := $(firstword $(wildcard *.bas))
BASE := $(basename $(BAS))

COMPILER := msxbas2rom
EMULATOR := openmsx

ROM := $(firstword $(wildcard $(BASE)*.rom))
NOI := $(BASE).noi

.PHONY: all clean run test

all:
	$(COMPILER) $(BAS) -a --noi

run: all 
	@ROM_FILE=$$(ls $(BASE)*.rom | head -n 1); \
	echo "Running $$ROM_FILE"; \
	exec $(EMULATOR) -cart $$ROM_FILE

test: all
	@ROM_FILE=$$(ls $(BASE)*.rom | head -n 1); \
	echo "Debugging $$ROM_FILE"; \
	exec $(EMULATOR) -cart $$ROM_FILE -script debug.tcl

clean:
	rm -f *.rom *.noi *.omds *.symbol *.cdb
```

## Explanation

### Build

    make all

Runs:

    msxbas2rom program.bas -a --noi

Which generates:

    program.rom
    program.noi

### Test

    make test

Launches the emulator:

    openmsx -cart program.rom -script debug.tcl

------------------------------------------------------------------------

# Git repositories

Example `.gitignore` for using with git repositories.

```
# binaries and symbols
.rom
.noi
.omds
.symbol
.cdb
```

------------------------------------------------------------------------

# VSCode Integration

VSCode uses **tasks.json** and **launch.json** to run build and test commands.

This allows:

-   build via **Ctrl+Shift+B** with problem highlighting
-   run via **F5** with quick emulator launch
-   test via **Ctrl+Shift+T** with quick emulator launch for debugging

------------------------------------------------------------------------

# .vscode/tasks.json

``` json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build",
      "type": "shell",
      "command": "make all",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": {
        "owner": "msxbas2rom",
        "fileLocation": ["relative", "${workspaceFolder}"],
        "pattern": {
          "regexp": "^(.+\\.bas):(\\d+): ERROR: (.+)$",
          "file": 1,
          "line": 2,
          "message": 3
        }
      }
    },
    {
      "label": "clean",
      "type": "shell",
      "command": "make clean",
      "problemMatcher": []
    },
    {
      "label": "test",
      "type": "shell",
      "command": "make test",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "problemMatcher": []
    }
  ]
}
```

# .vscode/launch.json

``` json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run",
      "type": "node-terminal",
      "request": "launch",
      "command": "make run; exit",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

------------------------------------------------------------------------

# Problem Matcher

The **problemMatcher** allows VSCode to detect compiler errors and jump
directly to the corresponding source line.

Example compiler output:

    test1.bas:5: ERROR: FOR without a NEXT

The matcher extracts:

| Field   | Value |
|---------|--------------------|
| file    | test1.bas |
| line    | 5 |
| message | FOR without a NEXT |

VSCode will highlight the error in the editor automatically.

------------------------------------------------------------------------

# openMSX Debug Automation

The **openMSX emulator** supports automation through **Tcl scripts**.

Using:

    openmsx -cart program.rom -script debug.tcl

The emulator will execute the script after startup.

This enables:

-   automatic loading of debug symbols
-   breakpoints
-   debugger initialization
-   execution tracing

------------------------------------------------------------------------

# debug.tcl

The `debug.tcl` file configures the debugging environment.

## Example debug.tcl

``` tcl
# debug.tcl

puts "==== MSXBAS2ROM Debug Session ===="

# find first .noi file in current directory
set noi_files [glob -nocomplain *.noi]

if {[llength $noi_files] == 0} {
    puts "No .noi file found."
    return
}

# get first file
set noi_file [lindex $noi_files 0]

# remove extension to get ROM name
set rom [file rootname $noi_file]

puts "ROM base name: $rom"

proc load_symbols {} {
    global noi_file

    puts "Loading debug symbols: $noi_file"
    debug symbols load $noi_file NoICE

    # resolve symbol
    if {[catch {debug symbols lookup -name START_PGM} result]} {
        puts "Symbol START_PGM not found."
        return
    }

    # extract address
    set entry [lindex $result 0]
    set addr [dict get $entry value]
    
    puts "Setting breakpoint at start of the program: $addr"
    debug breakpoint create -address $addr

    puts "Debugger ready."
}

# run after emulator startup
after 1000 load_symbols
```

------------------------------------------------------------------------

# Development Workflow

Typical cycle during development:

1. Compile: Ctrl+Shift+B
2. Run: F5
3. Test debugging: Ctrl+Shift+T

This integration provides:

-   fast compile/test cycle
-   automated emulator launch
-   integrated error navigation
-   debugger automation
-   reproducible builds

It brings a **modern development workflow** to **MSX BASIC ROM development**.

------------------------------------------------------------------------

📌 See also: [Debugging with OpenMSX](https://github.com/amaurycarvalho/msxbas2rom/wiki/Debugging_with_OpenMSX) and [Reference Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Documentation).

