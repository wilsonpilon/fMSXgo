# Usage Guide — MSXBAS2ROM

> Learn how to compile MSX BASIC programs into ROM files.

---

## 🖥 Basic Syntax

The simplest way to use **MSXBAS2ROM** is via the command line:

```bash
msxbas2rom program.bas
```

This will convert `program.bas` into `program.rom` using default settings.

When compiling, ensure that:

- **Source file** is in plain text MSX BASIC format (`.BAS`);
- **Assets** (images, sprites, sounds) are in accessible paths if referenced;
- **Output path** is writable.

---

## ⚙️ Syntax and Options

```bash
msxbas2rom [options] <filename.bas>
```

- **General options**:

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -h or --help | help |
| -q or --quiet | quiet (no verbose) |
| -d or --debug | debug mode (show details) |
| -D or --doc | display quick reference guide |
| -H or --history | display app history |
| -v or --version | display app version |

- **Compile options** (optional):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -c | plain ROM compile mode (DEFAULT) |
| -a or --auto | auto mode (fallback to ASCII8 when plain ROM overflows) |
| -x or -8 or --ascii8 | [ASCII8](https://www.msx.org/wiki/MegaROM_Mappers#ASCII_8K) MegaROM mapper |
| -6 or --ascii16 | [ASCII16](https://www.msx.org/wiki/MegaROM_Mappers#ASCII_16K) MegaROM mapper (limited support) |
| -7 or --ascii16x | [ASCII16-X](https://www.grauw.nl/projects/ascii-x/ascii16-x/) MegaROM mapper (limited support) |
| -4 or --konami | [Konami](https://www.msx.org/wiki/MegaROM_Mappers#Konami_MegaROMs_without_SCC) MegaROM mapper |
| -k or --scc | [Konami SCC MegaROM](https://www.msx.org/wiki/MegaROM_Mappers#Konami_MegaROMs_with_SCC) MegaROM mapper |

- **Path options** (optional):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -i | input path (default=source file path) |
| -o | output path (default=source file path) |

- **Special options** (optional):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -s | generate [symbols](https://github.com/amaurycarvalho/msxbas2rom/wiki/Usage#7-compile-and-generate-symbols-for-openmsx-debugger) for Z80 debugging (default format: .noi) |
| --noi or --noice | generate symbols in .noi format ([OpenMSX](https://openmsx.org/)) |
| --cdb | generate symbols in .cdb format (sdcc) |
| --symbol | generate symbols in .symbol format (pasmo) |
| --omds | generate symbols in .omds format (openMSX deprecated) |
| --lin | write the MSX-BASIC line numbers in the binary code |
| --vscode | initialize a VSCode MSX-BASIC project in the current path |

- **P-code options** (DEPRECATED):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -p | tokenized p-code mode |
| -t | turbo mode (or use CALL TURBO instructions) |
| --nsr | no strip remark lines (tokenized/turbo mode) |

Output:

`<filename.rom>`

You can combine multiple options in a single command.

---

## 🚀 Examples

### 1. Show help

```bash
msxbas2rom -h
```

### 2. Show version

```bash
msxbas2rom -v
```

### 3. Show documentation

```bash
msxbas2rom --doc
```

### 4. Compile with Default Settings

```bash
msxbas2rom program.bas
```

It's equivalent to code below:

```bash
msxbas2rom -c program.bas
```

Also, you can send the ROM output to a target folder:

```bash
msxbas2rom -o /target_folder/subfolder program.bas
```

### 5. Compile to ASCII8 MegaROM

```bash
msxbas2rom -x program.bas
```

### 6. Compile to Konami SCC MegaROM

```bash
msxbas2rom -x --scc program.bas
```

### 7. Compile and generate symbols for OpenMSX debugger

Command lines below will generate the following symbols files:

- **.symbol**: [pasmo assembler](https://pasmo.speccy.org/) symbol format;
- **.omds**: xml format for use with the [old OpenMSX standalone debugger](https://github.com/openMSX/debugger) or import it in another tools;
- **.noi**: NoICE format for use with the [new OpenMSX integrated debugger](https://openmsx.org/).

```bash
msxbas2rom -s program.bas
msxbas2rom -x -s program.bas
msxbas2rom -x -s --scc program.bas
```

Learn more about debugging your MSX-BASIC program [here](https://github.com/amaurycarvalho/msxbas2rom/wiki/Debugging_with_OpenMSX).

---

## 📚 Next Steps

- Read the [Reference Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Documentation) for more detailed information; 
- Explore the [Examples](https://github.com/amaurycarvalho/msxbas2rom/wiki/Examples) page for code examples;
- Check out [Games published](https://github.com/amaurycarvalho/msxbas2rom/wiki/Games) to see what’s possible.

---

> *MSXBAS2ROM — From BASIC to ROM in a single command.*