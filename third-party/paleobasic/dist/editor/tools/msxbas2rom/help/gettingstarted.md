# Getting Started with MSXBAS2ROM

> This guide will walk you through installing MSXBAS2ROM, creating a simple MSX BASIC program, compiling it into a ROM, and running it on an emulator or real MSX hardware.

---

## 📥 1. Install MSXBAS2ROM

Before starting, make sure you have MSXBAS2ROM installed on your system.

- **Windows** and **Linux** installation steps are detailed here: [Installation Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Install)

Once installed, you can verify the tool is available by running:

```bash
msxbas2rom -v
```

If the command displays a version number, you’re ready to continue.

---

## 📝 2. Create Your First MSX BASIC Program

Open your favorite text editor and create a plain text file named **hello.bas** with the following content:

```basic
10 PRINT "HELLO WORLD!"
20 END
```

Save the file in a working folder.

---

## ⚙️ 3. Compile the Program

MSXBAS2ROM supports **4 compilation modes**:

1. **Plain ROM compiled mode** *(default)* — generates a binary compiled Z80 code plain ROM for better performance (32K or 48K);
   - ExecROM is not compatible with 48K Plain ROM mode, so use SofaRUN or [ODO](http://msxbanzai.tni.nl/dev/software.html) loaders.
2. **ASCII8 MegaROM compiled mode** — generates a binary compiled Z80 code [MegaROM in ASCII8 format](https://www.msx.org/wiki/MegaROM_Mappers#ASCII_8K) (+128K, with a 2048K size limit);
3. **Konami SCC MegaROM compiled mode** — generates a binary compiled Z80 code [MegaROM in Konami SCC format](https://www.msx.org/wiki/MegaROM_Mappers#Konami_MegaROMs_with_SCC) (+128K, with a 2048K size limit);
4. **P-code mode** (DEPRECATED) — generates a p-coded MSX-BASIC ROM: program remains editable and listable in MSX BASIC interpreter but it will run slower (32K or 48K).

### Plain ROM compiled mode (default)
```bash
msxbas2rom hello.bas
```

### ASCII8 MegaROM compiled mode
```bash
msxbas2rom -x hello.bas
```

### Konami SCC MegaROM compiled mode
```bash
msxbas2rom -x --scc hello.bas
```

### P-code mode (deprecated)
```bash
msxbas2rom -p hello.bas
```

After running the command, you will get a file named **hello.rom** in the same folder.

---

## ▶️ 4. Run Your ROM

### Using an Emulator

You can quickly run your ROM in popular emulators:

- **[WebMSX](https://webmsx.org)** — just drag and drop the ROM file into emulator screen;
- **[OpenMSX](https://openmsx.org/)**:
```bash
openmsx hello.rom
```

### On Real Hardware

Copy the ROM file to an SD card or storage device supported by your MSX setup and use a loaders such as **[SofaRUN](https://www.louthrax.net/mgr/sofarun.html)** or **[ODO](http://msxbanzai.tni.nl/dev/ODOV04.LZH)**.

---

## 🧠 5. Tips & Notes

- **File names**: Keep your file names MSX-compatible (8.3 format) to ensure proper loading on all systems;
- **Testing**: Run your ROM on both emulator and real hardware for compatibility;
- **Compilation mode choice**:
  - Use **Plain ROM compiled mode** for small or medium projects;
  - Use **ASCII8 MegaROM compiled mode** for larger projects;
  - Use **Konami SCC MegaROM compiled mode** for projects that need native SCC support.

See [Compiler Architecture](https://github.com/amaurycarvalho/msxbas2rom/wiki/Compiler-Architecture) for more information.

---

## 📚 Next Steps

- Learn more commands and options in the [Usage Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Usage);
- Read the [Reference Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Documentation) for more detailed information; 
- Explore the [Examples](https://github.com/amaurycarvalho/msxbas2rom/wiki/Examples) page for code examples;
- Check out [Games published](https://github.com/amaurycarvalho/msxbas2rom/wiki/Games) to see what’s possible.

---

> *MSXBAS2ROM — Bringing MSX BASIC into the ROM era.*