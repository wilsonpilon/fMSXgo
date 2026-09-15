# Installation Guide — MSXBAS2ROM

> Get MSXBAS2ROM up and running on your system—whether through package managers or manual downloads.

---

## 📦 Available Installation Methods

### 1. Linux via PPA (recommended)

For Ubuntu and derivatives, install directly from the official PPA:

```bash
sudo add-apt-repository ppa:amaurycarvalho/msxbas2rom
sudo apt-get update
sudo apt-get install msxbas2rom
```

This ensures MSXBAS2ROM will receive updates automatically.

---

### 2. Linux via .DEB or .RPM packages

For most Linux distributions you can install it using Debian or RPM packages downloaded from [Releases Page](https://github.com/amaurycarvalho/msxbas2rom/releases).

1. Debian package:

```bash
sudo dpkg -i msxbas2rom.deb
```

2. RPM package:

```bash
sudo rpm -ivh msxbas2rom.rpm
```

---

### 3. Windows, Linux & macOS via Pre-built Releases

Pre-built binaries are available on the GitHub [Releases Page](https://github.com/amaurycarvalho/msxbas2rom/releases).

1. Navigate to the "Assets" section of the latest release;
2. Download the appropriate `msxbas2rom` executable for your platform;
3. (Optional) Extract the archive if needed;
4. Place the executable in your system’s PATH—for example:
   - **Linux/macOS:** `/usr/bin/`
   - **Windows:** `%USERPROFILE%\msxbas2rom\` (then add to PATH)


---

## ✅ Verification

After installation, confirm everything is working:

```bash
msxbas2rom -v
```

For parameters help:

```bash
msxbas2rom -h
```

You can also view all available command-line documentation via:

```bash
msxbas2rom --doc
```

These commands verify that the tool is properly installed.

---

## 🍏 macOS / Source Build Instructions

If no pre-built binaries are available for your system—or you prefer building from source—follow these steps:

1. [Clone the repository](https://github.com/amaurycarvalho/msxbas2rom.git) and ensure development dependencies are installed;
2. On **macOS**, remove or wrap out deprecated includes like `malloc.h` to avoid build errors;
3. Run the following:

```bash
make all
```

4. Upon success, find the binary under the `bin/Release/` directory.

---

## 📊 Summary Table

| Method                     | Platforms          | Notes                                       |
|----------------------------|-------------------|---------------------------------------------|
| PPA (apt)                  | Ubuntu/Linux      | Auto-updates, simplest for Linux users      |
| DEB or RPM                 | Linux      | Easy way for Linux users      |
| Pre-built Release          | Windows/Linux/macOS     | Manual download, flexible placement         |
| Build from Source (macOS)  | macOS (+ others)  | Recommended if no binaries are available    |

---

## 📚 What’s Next?

Proceed to the [Getting Started](https://github.com/amaurycarvalho/msxbas2rom/wiki/Gettingstarted) guide to write, compile, and run your first MSX BASIC program using MSXBAS2ROM.

---

> *MSXBAS2ROM — Bridging MSX BASIC and ROM development with ease.*
