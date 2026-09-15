# VSCode Integration Guide

This document describes how to integrate **MSXBAS2ROM** development with **Visual Studio Code**.

There are three different approaches available. Choose the one that best fits your workflow.

## 1. Using the `--vscode` Compiler Parameter (Recommended)

When running MSXBAS2ROM with the `--vscode` parameter, a `.vscode/` folder is automatically generated in the current directory. This folder contains a ready-to-use configuration for building, running, and debugging your project using the `openMSX` emulator.

### Example

```
msxbas2rom --vscode
```

_Note: don't forget to check and configure the correct openMSX emulator installation path in the generated `.vscode/tasks.json` file._

### Available Features in VSCode

- Compile: `Ctrl+Shift+B`;
- Run in emulator: `Ctrl+Shift+T`;
- Debug in emulator: `F5`.

### Debugging Behavior

When debugging is started, the VSCode integration automatically maps each MSX-BASIC line to corresponding Z80 breakpoints inside the emulator. This allows you to:

- Step through execution line-by-line (Z80 assembly);
- Inspect program flow in detail;
- Debug your compiled code directly within openMSX.

## 2. Manual Setup

If you prefer full control over your environment, you can configure VSCode manually.

Detailed instructions are available here:
👉 [Manual Setup Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/msxbas2rom_vscode_manual_setup)

## 3. Using a VSCode Extension

For a more advanced debugging experience, you can use a dedicated VSCode extension.

An experimental extension is available and can be tested [here](https://github.com/amaurycarvalho/vscode-msxbas2rom-debugger-extension).

------------------------------------------------------------------------

📌 See also: [Debugging with OpenMSX](https://github.com/amaurycarvalho/msxbas2rom/wiki/Debugging_with_OpenMSX) and [Reference Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Documentation).

