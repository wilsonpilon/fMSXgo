# Examples

> Discover how MSXBAS2ROM transforms MSX BASIC code into playable games and demos. Explore source files, compile examples, and learn compilation tips.

---

## 📥 [MSX BASIC Projects Repository](https://github.com/amaurycarvalho/msxbasic)

Browse a selection of "**Work in Progress**" [MSX BASIC projects](https://github.com/amaurycarvalho/msxbasic) compiled with MSXBAS2ROM.

---

### 🎮 Game demonstration 1 (compiled as a 48kb ROM cartridge)

If you want to know how to develop a game with MSXBAS2ROM, give a try to the example below.

Download the game source code [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Game%20Demo%201), compile and test it.

`msxbas2rom gd1.bas`

You can watch a more detailed explanation [here](https://www.youtube.com/watch?v=oPPuFsp1CvU) (brazilian portuguese video).

---

### 🎮 Game demonstration 2 (compiled as a MegaROM cartridge)

Download the game source code [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Game%20Demo%202), compile and test it.

`msxbas2rom -x gd2.bas`

Note: to run this MegaROM compiled game on WebMSX emulator you will need to set the ROM format as ASCII8 (or KonamiSCC) after load it on the cartridge slot.

### 🎮 Tesouro Perdido (compiled as a MegaROM cartridge)

Download the game source code [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Tesouro%20Perdido), compile and test it.

`msxbas2rom -x tesperd.bas`

Note: to run this MegaROM compiled game on WebMSX emulator you will need to set the ROM format as ASCII8 (or KonamiSCC) after load it on the cartridge slot.

### 🎮 Scroll on tiled screen modes 1, 2 and 4

Repeat the process in the same way as in the previous examples.

- [Demo 1](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll1): all directions scroll (screen mode 1, text);
- [Demo 2](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll2): horizontal scroll with sprite (screen mode 2);
- [Demo 3](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll3): changing background during horizontal scroll action (screen mode 4);
- [Demo 4](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll4): all directions scroll (screen mode 2).

### 🎮 Scroll on graphical screen modes 8 and 12

Here you must use the parameters "-c -x" to compile these ones:

- [Demo 5](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll5): horizontal scroll.

---

##  How to Compile and Run

See [Getting Started](https://github.com/amaurycarvalho/msxbas2rom/wiki/Gettingstarted) page for more information.

---

## 📝 Want to Share Your Demo?

Submit your details via a [GitHub issue](https://github.com/amaurycarvalho/msxbas2rom/issues) (prefix: **[Asset]**) or [pull request](https://github.com/amaurycarvalho/msxbas2rom/wiki/Contributing#-developer-quick-start-guide), and we'll add your project to this list.

- **Title** and **Brief Description**;
- **Screenshot or demo video**;
- **ROM download link**, if available.

We'll happily feature it on this page!

---

> *MSXBAS2ROM — turning your BASIC games into ROM adventures.*