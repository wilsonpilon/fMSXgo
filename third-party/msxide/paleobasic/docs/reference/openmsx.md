# openMSX - Referencia (Ajuda -> openMSX...)

Gerado a partir dos 5 manuais originais do openMSX (docs/openmsx-*.html - Setup Guide, User's Manual, Using Diskmanipulator, Controlling openMSX from External Applications, Console Command Reference) e da mesma base de dados usada pela janela Ajuda -> openMSX... do editor.

## Indice

- [Guia de Configuracao - 1. Introduction](#guia-de-configuracao---1-introduction)
- [Guia de Configuracao - 2. Machines and Extensions](#guia-de-configuracao---2-machines-and-extensions)
- [Guia de Configuracao - 3. System ROMs](#guia-de-configuracao---3-system-roms)
- [Guia de Configuracao - 4. Palcom Laserdiscs](#guia-de-configuracao---4-palcom-laserdiscs)
- [Guia de Configuracao - 5. User Preferences](#guia-de-configuracao---5-user-preferences)
- [Guia de Configuracao - 6. Performance Tuning](#guia-de-configuracao---6-performance-tuning)
- [Guia de Configuracao - 7. Writing Hardware Descriptions](#guia-de-configuracao---7-writing-hardware-descriptions)
- [Guia de Configuracao - 8. Contact Info](#guia-de-configuracao---8-contact-info)
- [Manual do Usuario - 1. Introduction](#manual-do-usuario---1-introduction)
- [Manual do Usuario - 2. Starting the Emulator](#manual-do-usuario---2-starting-the-emulator)
- [Manual do Usuario - 3. The Console and Settings](#manual-do-usuario---3-the-console-and-settings)
- [Manual do Usuario - 4. The Graphical User Interface](#manual-do-usuario---4-the-graphical-user-interface)
- [Manual do Usuario - 5. Running MSX Software and Using Media](#manual-do-usuario---5-running-msx-software-and-using-media)
- [Manual do Usuario - 6. Input Devices](#manual-do-usuario---6-input-devices)
- [Manual do Usuario - 7. Video](#manual-do-usuario---7-video)
- [Manual do Usuario - 8. Audio](#manual-do-usuario---8-audio)
- [Manual do Usuario - 9. Useful Extras](#manual-do-usuario---9-useful-extras)
- [Manual do Usuario - 10. Contact Info](#manual-do-usuario---10-contact-info)
- [Diskmanipulator - General Syntax](#diskmanipulator---general-syntax)
- [Diskmanipulator - Commands](#diskmanipulator---commands)
- [Diskmanipulator - Examples](#diskmanipulator---examples)
- [Controle Externo - Introduction](#controle-externo---introduction)
- [Controle Externo - Connecting](#controle-externo---connecting)
- [Controle Externo - Communication](#controle-externo---communication)
- [Referencia de Comandos - Introduction](#referencia-de-comandos---introduction)
- [Referencia de Comandos - Commands](#referencia-de-comandos---commands)
- [Referencia de Comandos - Settings](#referencia-de-comandos---settings)

## Guia de Configuracao - 1. Introduction

### 1.1 New Versions of this Document

The latest version of the openMSX manual can be found on the openMSX home page:

http://openmsx.org/manual/ (http://openmsx.org/manual/)

You can also use this URL to get up-to-date versions of the hyper links
if you printed out this manual.

### 1.2 Purpose

This guide is about openMSX, the open source MSX emulator that tries to achieve
near-perfect emulation by using a novel emulation model.
You can find more information about openMSX on the
openMSX home page (http://openmsx.org/).
You can also download the emulator itself from there.

This guide describes the setup of openMSX.
After installation, openMSX is ready to run using C-BIOS and the default
settings. In this guide you can read how to configure openMSX to emulate actual
MSX machines (such as Panasonic FS-A1GT). It also describes how you can have
openMSX start up with your personal settings, how you can configure openMSX and
your system for optimal performance, and several other configuration related
topics.

Disclaimer:
We do not claim this guide is complete or even correct.
What you do with the information in it is entirely at your own risk.
We just hope it helps you enjoy openMSX more.

### 1.3 Revision History

For the revision history, please refer to the commit log (https://github.com/openMSX/openMSX/commits/master/doc/manual/setup.html).

## Guia de Configuracao - 2. Machines and Extensions

### 2. Machines and Extensions

We use the word machine to refer to a specific
MSX model. For example, the Sony HB-75P is a machine.
openMSX does not have a fixed machine hardcoded into it.
Instead, many different MSX machines can be emulated.
The details of a machine are described in an XML file.
This file describes how much memory a machine has,
what video processor it has, in which slots its system ROMs are located,
whether the machine has a built-in disk drive etc.
openMSX reads the machine description XML and will then emulate exactly
that MSX machine, which can be anything from an MSX1 with 16 kB of RAM
to the Panasonic FS-A1GT MSX turboR.

The openMSX distribution contains XML files describing many existing MSX
models.
You can find them in the `share/machines` directory.
If you want to run one of those machines,
you also need the system ROMs for that machine.
See the next chapter for more
information on system ROMs.
You can also create your own machine descriptions,
to expand existing MSX models or to create your own fantasy MSX. There are
currently some of such fantasy MSX machines, based on real MSX machines,
shipped with openMSX. Examples of such machines are "Boosted_MSX2_EN" (a
European MSX2 with loads of hardware built-in) and
"Boosted_MSX2+_JP" (a Japanese MSX2+ with loads of hardware built-in). You can
find some more information about them in their accompanying txt file in
`share/machines/`. More about creating fantasy MSX machines in a
later chapter.

An extension is a piece of MSX hardware that can be
inserted into a cartridge slot to extend the capabilities of an MSX.
Examples of extensions are the Panasonic FMPAC, the Sunrise IDE interface
and an external 4MB memory mapper.
Extensions, like machines, are described in XML files.
You can find a lot of predefined extensions
in the `share/extensions` directory.
Some extensions need ROM images in order to run, similar to system ROMs.

In general, the XML files that describe the hardware configuration are called
"hardware configuration XML files".

If you want to be able to run a combination of a machine and plugged in extensions at a later time, you can store this combination as a setup with the GUI via Main menu bar
â†’ Machine â†’ Save setup or the `store_setup` command.

## Guia de Configuracao - 3. System ROMs

### 3. System ROMs

An MSX machine consists of a lot of hardware, but also contains some software.
Such software includes the BIOS, MSX-BASIC, software controlling disk drives
and built-in applications (firmware).
openMSX emulates the MSX hardware, but it needs MSX system software to emulate
a full MSX system.
Because the internal software is located in ROM chips, it is referred to as
system ROMs.

The software in the system ROMs, like most software, is copyrighted.
Depending on your local laws, there are certain things you are allowed to
do with copyrighted software and certain things you are not allowed to do.
In this manual, a couple of options are listed for providing system ROMs
to your openMSX installation.
It is up to you, the user, to select an option that is legal in your country.

### 3.1 C-BIOS

C-BIOS stands for "Compatible BIOS".
It aims to be compatible with the MSX BIOS found in real MSX machines,
but it was written from scratch, so all copyrights belong to its authors.
BouKiChi, the original author of C-BIOS, was kind enough to allow
distribution of C-BIOS with openMSX.
When Reikan took over maintenance of C-BIOS, the license
was changed to give users and developers even more freedom in using C-BIOS.
Later still, C-BIOS was moved to a SourceForge.net project, with several new
maintainers. Every now and then, an updated version of C-BIOS is released.
You can wait for it to be included in the next openMSX release,
or download it directly from the
C-BIOS web site (http://cbios.sourceforge.net/).

C-BIOS can be used to run most MSX1, MSX2 and MSX2+ cartridge-based games.
It does not include support for MSX-BASIC or disk drives yet,
so software that comes on tape, disk or any other media than ROM cartridges
will not run on standard openMSX C-BIOS machines.

openMSX contains several machine configurations using C-BIOS.
The machine `C-BIOS_MSX1` is an MSX1 with 64 kB RAM.
The machine `C-BIOS_MSX2` is an MSX2 with 512 kB RAM and 128 kB VRAM.
The machine `C-BIOS_MSX2+` is an MSX2+ with 512 kB RAM, 128 kB VRAM and MSX-MUSIC.
The latter is the default machine for openMSX after
installation, so if you change nothing to the openMSX configuration,
then `C-BIOS_MSX2+` is the machine that will be booted. The
mentioned machines have a US English (international) keyboard layout and
character set and run at 60Hz (like NTSC) interrupt frequency. Since C-BIOS
0.25, some localized versions are also available: Japanese, European (like US,
but 50Hz), and Brazilian. You can easily recognize them.

It is always legal for you to run the C-BIOS ROMs in openMSX.
You are allowed to use C-BIOS and its source code in various other ways
as well, read the C-BIOS license for details.
It is located in the file `README.cbios` in the Contrib directory.

### 3.2 Dumping ROMs

If you own a real MSX machine, you can dump the contents of its system ROMs
to create ROM images you can run in openMSX.
This way, you can emulate the MSX machines you are familiar with.

## 3.2.1 Tools

The easiest way to dump system ROMs is to run a special dumping tool on your
real MSX, which copies the contents of the system ROMs to disk.
Sean Young has made such tools, you can find the
tools and documentation (http://bifi.msxnet.org/msxnet/utils/saverom.html)
on BiFi's web site.
These tools can also be used to dump cartridge ROMs, which may be useful later,
if you want to use certain extensions or play games.

## 3.2.2 Legal Issues

Using ROMs dumped from machines you own is generally speaking not frowned upon in the MSX community.
When the MSX machine was bought in a shop years ago, you or the person that
originally bought it paid money for the MSX machine.
A small part of that money paid for the software in the system ROMs.
However, we are no legal experts, so it is up to you to check whether it
is legal in your country to use dumped ROMs of machines you own.

### 3.3 Downloading ROMs

Some WWW and FTP sites offer MSX system ROMs as a download.
Some MSX emulators include system ROMs in their distribution.
Downloaded system ROMs can be used in the same way as
system ROMs you dumped yourself, see the previous section.

It may be illegal in your country to download system ROMs.
Please inform yourself of the legal aspects before considering this option.
Whatever you decide is your own responsibility.

### 3.4 Installing ROMs

If you want to emulate real MSX machines next to the default C-BIOS based
machines, you will have to install system ROMs that did not come with openMSX.
This section explains how to install these, once you obtained them in one of
the ways that are explained in the previous sections.

## 3.4.1 ROM Locations

The easiest way is to copy the ROM files in a so-called file pool: a special
directory where openMSX will look for files (system ROMs, other ROMs, disks,
tapes, etc.). The default file pool for system ROMs is the
`systemroms` sub directory. The best way is to make a
`systemroms` sub directory in your own user directory, which is
platform dependent:

**Platform | User directory**
- Windows (e.g. Windows 7) -- `C:\Users\<user name>\Documents\openMSX\share` whereby `<user name>` stands for your Windows login name
- Unix and Linux -- `~/.openMSX/share`

Please note that the path part which comes before `share` can be
overridden by setting the `OPENMSX_HOME` environment variable, see the chapter about User Preferences.

That way, you do not need special privileges. Furthermore, the (Windows) installer
won't touch them for sure.

A template for the `systemroms` sub directory is present in the
installation directory of openMSX, which is also platform dependent:

**Platform | Typical openMSX file pool installation directory**
- Windows (any version) -- `C:\Program Files\openMSX\share`
- Unix and Linux -- `/opt/openMSX/share` or `/usr/share/openmsx`

The quickest way to see where openMSX is searching for system ROMs on your
installation is via the GUI under Main menu bar
â†’ Machine â†’ Test MSX hardware. At the bottom of this dialog
you can find buttons to quickly open a (native) file browser on the locations
where the ROMs are searched for, both for the user folder and the system wide
folder. The main function of this window is to verify whether your system ROMs
have been installed properly.

In short: you can just copy all your system ROMs to the
`share/systemroms` directory of your user account. The ROM files can
be zipped (or gzipped), but only one file can be in a ZIP file. If multiple ROM
files are in a single ZIP file, openMSX will not find them. The directory
structure below `share/systemroms` is not relevant, openMSX will
search it completely.

More info about file pools is in the documentation of the `filepool` command. If
you can't get this working, please read one of the next sections.

For advanced users, it is also possible to let openMSX load a specific set
of ROM images for a machine, independent of any file pool or the checksums of
the ROM images. For that you copy the ROM file with the name and path as
mentioned in the hardware configuration XML file that describes the machine,
relative to the path of that machine description file. For example, if you
dumped the ROMs of a Philips NMS 8250 machine, copy them to
`share/machines`, because in the machine description file (in
`share/machines/Philips_NMS_8250.xml`) the name of the ROMs is like
this: `nms8250_msx2sub.rom`. We recommend to not use this feature,
but use the file pools as mentioned above.

## 3.4.2 How openMSX knows which ROM files to use

All necessary system ROM files used in machines and extensions are
primarily identified with a checksum: a sha1sum. This enables openMSX to find
the right ROM file from one of the file pools of type `system_rom`,
regardless of the file name. So the actual content is guaranteed to be
what was intended. If the ROM is explicitly specified in the configuration file
(which is also supported) and the sha1sum doesn't match, a warning will be
printed.

If you are trying to run an MSX machine and get an error like `Fatal
error: Error in "broken" machine: Couldn't find ROM file for "MSX BIOS with
BASIC ROM" (sha1: 12345c041975f31dc2ab1019cfdd4967999de53e).` it means
that the required system ROM for that machine with the given sha1sum cannot be
found in one of the file pools as mentioned above (typically
`share/systemroms`). This is the primary way to know that you are
missing required system ROMs and therefore something went wrong installing them
(typically either not a file with the proper content or you put the file in the
wrong place, or you put it in a large ZIP file with multiple files).

The quickest way to see which machine and extensions work (i.e.: openMSX
can find the required system ROMs the configuration is referring to) is by
using the GUI under Main menu bar â†’ Machine
â†’ Test MSX hardware. It will quickly check all machines and
extensions and will show which are working and which are not, and which error
occurred when trying to use it. Besides this, when selecting to run a machine
using the GUI under Main menu bar â†’ Machine
â†’ Select MSX machine..., you can also see which are working and
which not and why. Likewise for extensions via Main menu bar â†’ Media â†’ Extensions â†’
Insert for instance.

You can also manually check whether you have the correct ROM images. The
value in the <sha1> tag(s) in the hardware configuration XML files
contain checksums of ROM images that are known to work. You can compare the
checksums of your ROM images to the ones in the hardware configuration XML
files with the `sha1sum` tool. It is installed by default on most
UNIX systems, on Windows you will have to download it separately. If the
checksums match, it is almost certain you have correct system ROMs. If the
checksums do not match, it could mean something went wrong dumping the ROMs, or
it could mean you have a slightly older/newer model which contains different
system ROMs.

A typical case in which you can have problems with checksums (or ROMs not
getting found in a file pool) is disk ROMs. The ROM dump can be correct, and
still have a different checksum. This is because part of the ROM is not
actually ROM, but mapped on the registers of the floppy controller. When you
are sure it is correct, don't put it in a file pool, but put it in the proper
directory, which is explained above. Alternatively, you could add the checksum
in the XML file that describes the machine you made the ROM dump for (multiple
checksums can be present, they will be checked in the same order as they are in
the file).

## 3.4.3 How to handle split ROMs

The machine configurations bundled with openMSX often refer to ROM files
that span multiple 16 kB pages. For example, in the NMS 8250 configuration, the
BIOS and MSX-BASIC are expected in a single 32 kB ROM image. If you created two
16 kB images when dumping or got those from downloading, you can concatenate
them using tools included with your OS. In Linux and other Unix(-like) systems
you can do it like this:

`cat bios.rom basic.rom
> nms8250_basic-bios2.rom`

In Windows, open a command prompt and
issue this command:

`copy /b bios.rom + basic.rom
nms8250_basic-bios2.rom`

## Guia de Configuracao - 4. Palcom Laserdiscs

### 4. Palcom Laserdiscs

The Pioneer PX-7 and Pioneer PX-V60 are both emulated including an emulated
Laserdisc Player, making it possible to run Palcom Laserdisc software.

The laserdisc must be captured before it can be used with an emulator. The
file must adhere to the following rules:

- Use the Ogg container format
- Use the Vorbis codec for audio
- Use the Theora codec for video
- Captured at 640Ã—480, YUV420
- A bitrate of at least 200kpbs for audio, otherwise the computer code
encoded on the right audio channel will degrade too much for it to be
readable
- Theora frame numbers must correspond to laserdisc frame numbers
- Some laserdiscs have chapters and/or stop frames. This is encoded in the
VBI signal (http://www.daphne-emu.com/mediawiki/index.php/VBIInfo), and must be converted to plain text. This must be added to the
Theora meta data

The metadata for chapters and stop frames has the form "chapter:
<chapter-no>,<first-frame>-<last-frame>" and stop frames are
"stop: <frame-no>". For example:

chapter: 0,1-360 chapter: 1,361-4500 chapter: 2,4501-9450 chapter:
3,9451-18660 chapter: 4,18661-28950 chapter: 5,28951-38340 chapter:
6,38341-39432 stop: 4796 stop: 9089 stop: 9178 stop: 9751 stop: 14818 stop:
14908 stop: 18270 stop: 18360 stop: 18968 stop: 24815 stop: 24903 stop: 28553
stop: 28641 stop: 29258 stop: 34561 stop: 34649 stop: 38095 stop: 38181 stop:
38341 stop: 39127

Note that the emulated Pioneer PX-7 and Pioneer PX-V60 are virtually
identical, except that the Pioneer PX-7 has pseudo-stereo for its PSG.

## Guia de Configuracao - 5. User Preferences

### 5. User Preferences

Almost all user preferences can be set via the GUI menu and the openMSX
console, at openMSX run time. This is more thoroughly explained in the User's Manual.

By using the `bind` command you can create custom key
bindings. These bindings will also be saved as settings in your settings file
if you issue a `save_settings` command.

Many important settings are discussed in the User's Manual and there is an overview in
the Console Command Reference.

If you're a power user and want to specify commands which are executed at
the start of each openMSX start up, put those commands in a text file, one
command per line (i.e. a script) and put it in the `share/scripts`
directory. You can also explicitly specify a Tcl file to be loaded and executed
on the openMSX command line. For this, use the `-script` command line
option, which has the filename of the Tcl script as argument.

If you're a power user and want to tweak where openMSX reads and writes
files from, you can use these hacky environment variables. Hacky, because we
don't really expect anyone to change them, but when the urge is stronger than yourself, do
so at your own risk... Be warned that they may change without notice in a next
release.

**variable | meaning**
- `OPENMSX_HOME` -- The user's home folder, where all
data will get stored that openMSX produces.
- `OPENMSX_USER_DATA` -- The user's personal
`share` folder, where amongst others, system ROMs are
searched
- `OPENMSX_SYSTEM_DATA` -- The system
wide `share` folder in the openMSX installation directory

In the section about ROM locations
you get an idea about the default values of these on different platforms.

## Guia de Configuracao - 6. Performance Tuning

### 6. Performance Tuning

This chapter contains some tips for tuning the performance of openMSX
on your system.

### 6.1 OpenGL

As openMSX is using the SDLGL-PP `renderer`, it needs hardware acceleration to run at a
decent speed, with support for OpenGL 2.0.

Getting OpenGL running hardware accelerated used to be a little cumbersome in some situations.
However, nowadays there is a big chance that your system already has hardware
accelerated OpenGL supported in the default installation of your Xorg/Wayland
or Windows environment.

You can verify hardware acceleration on your Linux system by typing
`glxinfo` on the command line. If you have everything working, this
command should output a line like this: `direct rendering: Yes`.

### 6.2 Various Tuning Tips

CPU and graphics performance varies a lot, depending on the openMSX
settings and the MSX hardware and software you're emulating.
Some things run fine on a 200MHz machine, others are slow on a 2GHz
machine.

If openMSX is running slow, you can try the following measures:

- Disable the `reverse` feature
(especially if the platform you're running on has a low amount of RAM), which
is enabled by default on most platforms: `set auto_enable_reverse off`
- Make sure there are no CPU or I/O heavy background processes is running.
Downloads, P2P software, distributed calculation efforts, search indexers etc. may grab
the CPU from time to time, leaving less time for openMSX to do its job.
Even if they only do so only once in a while, it may be enough to cause
emulation to stutter.
- Increase the number of frames that may be skipped (`set maxframeskip 10`,
for example).
- Use the blip resampler instead of the hq one.
- Emulate MSX software that uses fewer sound channels, for example MSX-MUSIC
(maximum 9 channels) instead of MoonSound (maximum 18+24 channels). Or run
simpler software altogether (e.g. MSX1 software instead of turboR software).

## Guia de Configuracao - 7. Writing Hardware Descriptions

### 7. Writing Hardware Descriptions

There are two ways to use extra devices in your emulated MSX: you can use a
shipped extension (which is similar to inserting a cartridge with the device
into the MSX) or you can modify the hardware configuration file (the same as
opening the MSX and building in the device). As in the real world,
extensions are easier to use, but modifying the machine gives you more
possibilities.
Normal usage of machines and extensions is covered in the User's Manual; this chapter tells you how you can create
or modify these hardware descriptions, which is a topic for advanced users and
definitely something very few people will (want to) do.
By editing the hardware configuration XML files, you can for example increase
the amount of RAM, add built-in MSX-MUSIC, a disk drive, extra
cartridge slots, etc.

You can modify an MSX machine (e.g. to add devices) by editing its hardware
configuration XML file. So, let's make a copy of
`share/machines/Philips_NMS_8250.xml` and put it in
`share/machines/mymsx.xml`.
It's the config we are going to play with; our custom MSX.
Note: it is convenient to use the user directory (see above)
to store your home-made machines, instead of the openMSX installation directory.

The easiest thing to do is to copy and modify fragments from other existing
configurations that can be found in `share/machines` or
`share/extensions`. For example, to add an FMPAC to the 8250, just
copy it from the `share/extensions/fmpac.xml` to some place in your
`mymsx.xml` file (between the `<devices>` and
`</devices>` tags!):

<primary slot="2">
<secondary slot="1">
<FMPAC id="PanaSoft SW-M004 FMPAC">
<io base="0x7C" num="2" type="O"/>
<mem base="0x4000" size="0x4000"/>
<sound>
<volume>13000</volume>
<balance>-75</balance>
</sound>
<rom>
<sha1>9d789166e3caf28e4742fe933d962e99618c633d</sha1>
<filename>roms/fmpac.rom</filename>
</rom>
<sramname>fmpac.pac</sramname>
</FMPAC>
</secondary>
</primary>

Don't forget to add the `fmpac.rom` file to one of your `system_rom` file pools.

Because we changed the FMPAC from extension to built-in device, we have to
specify in which slot the FMPAC is residing inside the modified 8250. So, we
should replace the `slot="any"` stuff, with a specified slot as you
can see in the above fragment.
The number in the `slot` attribute of the
`<primary>` tag indicates the
primary slot of the emulated MSX you're editing. In this case the second
cartridge slot of the NMS-8250 is used. `<secondary>` means
sub slot. If we leave it out, the slot is not expanded and the primary slot is
used. If we use it like in the above example, it means that slot 1 (of the
`<primary>` tag) will be an expanded slot. If a
`<primary>` tag has the attribute
`external="true"`, this means that the slot is visible on the
outside of the machine and can thus be used for external cartridges like
extensions and ROM software. As explained above, the parameter filename can be
adjusted to the name of your (64 kB!) FMPAC ROM file (note: if the file is not
65536 bytes in size, it won't work).
"balance" defines to what channel the FMPAC's sound will be routed by
default: in this case most of the sound goes to the left channel and a little
bit goes to the right channel. "sramname" specifies the file name for file in
which the SRAM contents will be saved to or loaded from. The saved files are
compatible with the files that are saved by the (real) FMPAC commander's save
option.

After saving your config and running openMSX again, you should be able to get
the FMPAC commander with `CALL FMPAC` in the emulated MSX!

In a similar fashion, you can also add an MSX-Audio device
(`<MSX-AUDIO>`, note that some programs also need the
`MusicModuleMIDI` device to
detect the Music Module, an empty SCC cartridge (`<SCC>`),
etc. Just browse the existing extensions, check the Boosted_MSX2_EN
configuration file and see what you can find.

Devices that contain ROM or RAM will have to be put inside a slot of the MSX,
using the `<primary>` and `<secondary>` tags
as demonstrated with the above mentioned FMPAC example. Other devices don't
need this.
Remember that you cannot put two devices that have a ROM in the same (sub)slot!
Just use a new free subslot if you need to add such a device and all your
primary slots are full. If a device does not need a slot, like the MSX-Audio
device, you can add as many as you like.

Another thing you may want to change: the amount of RAM of the MSX: change the
"size" parameter in the `<MemoryMapper>` device config.

In principle all of the above mentioned things are also valid for extensions.
The main difference is the fact that you should use `"any"` for the
slot specification as was already mentioned above. Just compare the fragment
above with the original FMPAC extension we based it on.

If you understand the basics of XML, you should be able to compose your MSX now!
You can use the ready-made configurations in `share/machines` as
examples.

## Guia de Configuracao - 8. Contact Info

### 8. Contact Info

Because openMSX is still in heavy development, feedback and bug reports are very
welcome!

If you encounter problems, you have several options:

1. Go to our IRC channel: #openMSX on libera.chat and ask your question there. Also reachable via webchat (https://web.libera.chat/#openMSX)! If you
don't get a reply immediately, please stick around for a while, or use one of
the other contact options. The majority of the developers lives in time zone
GMT+1. You may get no response if you contact them in the middle of the
night...
2. Post a message on the openMSX forum on MRC (http://www.msx.org/forum/semi-msx-talk/openmsx).
3. Create a new issue in the
openMSX issue tracker (https://github.com/openMSX/openMSX/issues)
on GitHub.
You need a (free) log-in on GitHub to get access.
4. Contact us and other users via one of the mailing lists. If you're a regular
user and want to discuss openMSX and possible problems, join our
`openmsx-user` mailing list. If you want to address the openMSX
developers directly,
post a message to the `openmsx-devel` mailing list.
More info on the openMSX mailing lists (https://sourceforge.net/p/openmsx/mailman),
including an archive of old messages, can be found at SourceForge.

For experienced users: if you get a crash, try to provide a `gdb`
backtrace. This will only work if you did not strip the openMSX binary of its
debug symbols.

In any case, try to give as much information as possible when you describe your
bug or request.

## Manual do Usuario - 1. Introduction

### 1.1 New Versions of This Document

The manual for the latest openMSX release can be found on the openMSX home page:

http://openmsx.org/manual/ (http://openmsx.org/manual/)

### 1.2 Purpose

This manual is about openMSX, the open source MSX emulator that tries to achieve
near-perfect emulation by using a novel emulation model.
You can find more information about openMSX on the
openMSX home page (http://openmsx.org/).
You can also download the emulator itself from there.

openMSX is not complete yet, which means that most things work but not all
features have been implemented yet.
Many emulation features are implemented, but not all of them are represented
yet in the built-in Graphical User Interface. To get the most out of openMSX,
we have written this guide.

This manual tells you how you can use openMSX, once it has been installed and
properly set up. You should be able to use most of the features of openMSX if
you have read it.
If you are only using the GUI menus of openMSX, you don't have to pay attention
to the exact command and setting names. However it is still useful to read this
document to find out how openMSX works and learn its terminology.

Disclaimer:
We do not claim this guide is complete or even correct.
What you do with the information in it is entirely at your own risk.
We just hope it helps you enjoy openMSX more.

### 1.3 Revision History

For the revision history, please refer to the commit log (https://github.com/openMSX/openMSX/commits/master/doc/manual/user.html).

### 1.4 Important Terms

First some terms. Users of real MSX computers will probably not find it hard to understand these, but we'll explain what we mean with them to make sure the terms used in openMSX are clear for everyone.

**Machine:** With a machine we denote a single instance of a particular MSX computer. The bare computer, with a manufacturer name and a type name, just as they were sold.
**Extensions:** All standard MSX computers have cartridge slots in which extension cartridges can be plugged into. They can be anything, like external disk drives, sound cartridges, serial interfaces, video cards, and multi-cartridges like the Carnivore 2 or the MegaFlashROM SCC+ SD.
**Connectors:** The bare MSX machine has connectors to which equipment can be plugged of which the plug matches the connector (called "pluggables" here and there).
**Media:** These are containers with software on them. For example: ROM cartridges, floppy disks, and cassette tapes.
**Setups:** A setup is the combination of a bare MSX machine, with its plugged-in extensions, plugged-in equipment via the machine's connectors and the media in the available media slots.

## Manual do Usuario - 2. Starting the Emulator

### 2. Starting the Emulator

In this chapter we will tell you how to select MSX machines and how to use extension cartridges, when starting up openMSX.

### 2.1 Machines

If you start openMSX without any command-line parameters, you will get the
default machine, which is stored in the `default_machine` setting. If you did
not change the default machine, the C-BIOS MSX2+ machine will be started.

However, if you created a setup earlier and marked it as the default setup (via the `default_setup` setting), that setup
will be loaded instead. This can be useful to always start up with your favourite
setup.

To select machines from the GUI, click Main menu
bar â†’ Machine â†’ Select MSX machine... This will
give a window in which you can see an overview of all available machines to
select from and hovering on items in the list shows you the most important
properties of these machines. You can also filter on type, region or any part
of the machine names. You can replace the current machine, or run another
machine along the existing running machines. An overview of the running
machines is shown at the top of the machine selection window, where you can
also change the default machine.

To select a different MSX machine from the command line, you can use the
`-machine` argument:

`openmsx -machine Panasonic_FS-A1GT`

It is also possible to use the `machine` command to switch at run time
in the `console`, which is explained in
the next chapter.

The C-BIOS machines come with ROMs installed; for other machines you will have
to install system ROMs yourself, see the Setup Guide for details.
You can always use Main menu bar â†’ Machine
â†’ Test MSX hardware to verify which system ROMs have been (correctly)
installed.

If you have saved a setup earlier (using the GUI via Main menu bar
â†’ Machine â†’ Save setup or the `store_setup` command) you can also use the GUI via Main menu
bar â†’ Machine â†’ Load setup to go from that setup. But also
here you can use the command line (via the `-setup` command line
option) or the console (via the `setup` command).

### 2.2 Extensions

Extensions are simply MSX cartridges (extensions to the MSX system) that you
can plug into the emulated MSX. openMSX ships with many predefined
extensions. Note that many of them require firmware ROMs (called system ROMs);
see the Setup Guide for
details.

Using the GUI, use the Main menu bar â†’
Media menu where you can either first select the MSX cartridge slot to
put the extension into, or directly select the Extensions menu option to insert
an extension in the first free slot or remove extensions from the slot they're
in.

Let's now go into details using the FMPAC as an example. openMSX ships with a
definition (XML file) for the FMPAC extension, but you will have to `add` the
`fmpac.rom` firmware ROM yourself. When you have done so, you can
insert an FMPAC into the emulated MSX machine with the following command line:

`openmsx -ext fmpac`

Similar to machines, you can also use the `ext` command in the console to do it at run
time. You can also use something like `-extb` to explicitly specify
cartridge slot B.

If you look in the `share/extensions` directory (or when using the
console, type the TAB key with the `ext` command, see next chapter),
you will see all the extensions known to openMSX. For example `-ext
mbstereo` gives you the MoonBlaster stereo effect: FMPAC on the left
speaker and MSX-AUDIO on the right speaker.

### 2.3 Other Command-line Options

Some of the most used command-line options will be discussed later in this manual.
For a complete list of them, type the following command:

`openmsx -h`

## Manual do Usuario - 3. The Console and Settings

### 3.1 Console Introduction

Most functionality can now be controlled via the built-in GUI, using the
main menu bar as a starting point. This will be sufficient for most users.
Originally, this GUI wasn't available and most functionality had to be
controlled differently. This way of control is still available (and will remain
so); this section will tell you more about it. You don't need to care about any
of these commands if the GUI is sufficient for you, but we still recommend having a look at the sections about "Settings"
and "Plugging in devices in connectors".

openMSX has a built-in command interface called the console,
which allows you to control almost all aspects of openMSX while it is running.
To access the console, make sure to have the main emulator window selected, and then press F10
(with default key mapping; Cmd+L on
Mac). This will
open a window with a command line inside the main openMSX window.

Typing `help`
gives a list of commands. Using PageUp you can see all of them. If you type
`help [command]` you will get help for the specified command. This
manual describes a few important commands; a full list can be found in the Console Command Reference. The
console can be used to change disk images, plug in `joysticks` or `mice`, change settings at run time and to change key bindings,
among others. It actually gives you full control of openMSX: if it can't be
done via the console, it's probably impossible!

One very practical feature of the console command line is that you can use
"completion" features. Just try typing half a command and then press the TAB
key; openMSX will then try to finish the word you were typing or show the
possibilities in case of ambiguities. You can use it also for file names,
connectors, pluggables and settings, and even for machine and extension names.

The console has very common keyboard controls, similar to most text editors.
It also supports copy/paste. Some other controls may be less obvious:

**key(s) | function**
- Up -- show previous command from history (starting with current command line)
- Down -- show next command from history (starting with current command line)
- Tab -- attempt completion of current command
- Enter/Return -- execute command line

### 3.2 Some Simple Console Commands

You can reset your MSX with the console command `reset` and exit openMSX with the command
`exit`. As
explained in the previous chapter, you can change machines with the `machine` command and
you can insert extensions with the `ext` command (use tab-completion to see the
list of possible extension names). Remove extensions with the `remove_extension` command or
get a list of the currently inserted extensions with the `list_extensions` command. Other
commands will be discussed later on in this manual.

### 3.3 Settings

There are many settings in openMSX for customization, changing preferences or
enabling extras. The most important ones are in the Main menu bar â†’ Settings menu in the GUI.
There is also an Advanced item in that menu that will give a huge window with
all possible settings. Usually, you can revert a setting to its default value
via right click â†’ Restore default in
the context-menu of that setting.

Using the console, you can use the command `set` to change any setting. E.g., you can
use it to set the current `scaler`. Issuing
`set` with only the setting name (like `set scale_algorithm`), queries
the current value of that setting.
Settings that have only two possible values can also be toggled with the
`toggle`
command (an example is the default key binding of F11 to `toggle
fullscreen`, see also below). A (hopefully) complete list of settings can
also be found in the Console Command Reference. Note that using the "tab completion" feature can help you a lot
in getting an idea of what settings are possible, as it will only complete
possible options. Just try that.

Let's give a few examples of common settings and how to change them.

If the MSX goes too fast or too slow, adjust the emulation speed with the
`speed` setting,
which has the speed percentage as parameter. So, typing `set
speed 120`, will run the emulated MSX at 120% of normal MSX speed.
This is useful for debugging purposes (slow down) or when you want to skip
certain parts of a demo for example (speed up). The GUI has this setting under
Main menu bar â†’ Settings â†’ Speed â†’ Emulation.

Some MSX machines like the Panasonic FS-A1GT have built-in software (called
firmware) which can be switched on and off via a switch on the machine itself.
In openMSX the internal software is switched off by default, but you can switch
it on with the following setting: `set firmwareswitch on`. If the
currently running machine has a firmware switch, a toggle option will show up in
the Main menu bar â†’ Machine menu to control it.

If you're not really interested in how long a real MSX would take to load
from diskette, cassette or laserdisc, you could enable the full speed when
loading feature: `set fullspeedwhenloading on`,
or from the GUI at Main menu bar â†’ Settings
â†’ Speed â†’ Go full speed when loading. It
runs openMSX at maximum speed whenever it thinks that the MSX is loading. The
drawbacks: it might detect a bit too late that the MSX isn't loading anymore,
so sometimes the first notes of music played right after loading might be
fast. Also, when loading openMSX will use all available CPU power to get
maximum speed; the feature has no influence on the state of the MSX, of course.

You can save all your current settings with the `save_settings` command. At start
up, alternative settings files can be loaded by using the `-setting`
command-line option. You can also use the `load_settings` command to load
settings at run time. Settings that are not mentioned in the saved settings
file that you are loading will be untouched. By default, openMSX will
automatically save your settings on exit (whichever way they were changed).

### 3.4 Plugging in devices in connectors

The Main menu bar â†’ Connectors menu
will show you all connectors of the currently running
machine and which (pluggable) device is currently plugged in. You can easily
plug in other devices there, e.g. a mouse in a joystick port.

Examples of connectors are the joystick ports, the printer port, the MIDI in
and out connector, the cassette port, etc. Examples of pluggables are `joysticks` and `mice`, but also printers and MIDI equipment.

In the console, you can use the command `plug` to do this. The command
`plug`
without any parameters will show a list of connectors and what pluggables are
plugged into them. Using `plug [connector]` will only show what is
plugged into [connector]. It will come as no surprise that the command `plug
[connector] [pluggable]` will plug the [pluggable] into the [connector].

Note that using the "tab completion" feature can help you a lot in getting an
idea of what plug commands are possible, as it will only complete possible
connectors and their possible pluggables. Just give it a try.

## Manual do Usuario - 4. The Graphical User Interface

### 4.1 Overview

The Graphical User Interface (GUI) in openMSX has been built with the Dear ImGui library (https://github.com/ocornut/imgui). It allows the developers to relatively easily build and extend the
GUI for all supported platforms. The price we have to pay is that it only works
on systems with 3D hardware acceleration support and that it does not look (a
lot) like the native GUIs of well-known desktop environments like Windows,
macOS, GNOME or KDE.

General help on basic usage of the Dear ImGui features can be found in the
Main menu bar â†’ Help â†’ Dear ImGui user
guide menu option.

The current GUI is intended for mouse control. It can (at least
partially) also be controlled with a keyboard, but so far this has not been a major focus of development,
so this will definitely not be optimal. Control via a game controller is
currently disabled, but that may change in future versions.

Although the current openMSX release already has a lot of functionality
available via the GUI, it is still incomplete and the user experience could use some love. We appreciate feedback on the GUI a lot and we will try to
improve it in later releases based on your input. Please see section 10. Contact Info for more
information on how to provide feedback.

Almost all commands and settings available in the GUI have an underlying
console command and setting accessible via the console. In several places
these underlying commands are mentioned in this manual. Power users especially
will appreciate all the ways they can manipulate openMSX with external programs, scripts,
or other more advanced methods.

### 4.2 Main menu bar

As already mentioned before in this manual, the GUI has a Main menu bar at the
top of the openMSX main window. The menu bar fades out when the MSX screen has
focus. To get it back, move the mouse cursor to the top of the openMSX window.

The Main menu bar contains the following top level menus:

**Machine:** Selecting the different machines (computer models)
**Media:** Inserting and removing media: ROM or extension cartridges, disks, cassette
tapes, laserdiscs, ...
**Connectors:** Controlling which devices are plugged into which connectors:
printers, joysticks, mice, dongles, MIDI equipment, ...
**Save state:** All save state and replay related functionality, plus some related settings.
**Tools:** Several tools that can make your life easier, like virtual keyboard,
copying and pasting, audio and video capture, disk manipulation/management,
trainers and cheats, audio chip tools and gadgets, etc..
**Settings:** A collection of the most important settings for Video, Sound,
Speed, Input, the GUI and Misc settings.
**Debugger:** A set of powerful debugging tools for the developer. Practically all
functionality from the old, standalone openMSX debugger has been included.
**Help:** Links to get (more) help on using openMSX.

If you like, you can even undock the main menu bar from the main openMSX
window. This is especially useful if you want to stream the openMSX main
window, without showing your interaction with the openMSX menus.
Use the triangular icon on the left in the Main menu bar to undock or redock
it.

### 4.3 Other default GUI elements

Besides the Main menu bar, some other main GUI elements you are likely to see.
Here is a small overview.

**Reverse bar:** 
**OSD icons:** 
**Status bar:** 

### 4.4 Advanced topics

The GUI allows you to put any window inside the main openMSX window, or outside
of it. But windows can also be docked together, at the (left/right/top/bottom)
edge of any window except the main window, even in a tab bar.

The GUI also has specific settings, like shortcuts that can be used in the GUI only.

Also, you can save and load layouts of windows that are combined with each
other. This is still a rather rough feature, as it also saves and loads other
data, like the history information from some menus.

As an example of a layout, we created one with a debugger focus. The image below shows:

- docking with split windows horizontal/vertical, sometimes multiple times
- docking with tab bar (e.g. memory/VRAM/PSG regs),
- hiding the (sub)window title, as it is often quite obvious. For "stack" this wasn't done on purpose, to show the difference.

### 4.4.1 Some tips and tricks

Docking windows can be done in two main ways. Both start by dragging a window
over another one. If you do that a popup will appear with 5 sections (middle,
east, west, north, south).

- If you drop the window in the middle, then you dock both windows into a tab-bar. This is useful if you don't need to see both windows at once (and when both have approx the same size). As an alternative you can also drag two title bars onto each other.
- If you drop on one of the 4 directions, the window will split in two (horizontally/vertically) and the two windows are shown next to each other. (The two sections can be resized via dragging the divider line).

In both cases the windows are now grouped, they will move together and minimize together.

The debugger features can require a lot of screen space. Showing everything at
once won't be possible (unless maybe if you have a 4K monitor). To accomodate
for this, we do try to pay attention to making all openMSX windows compact.

Here are some tips focused on that:

- Create groups of windows (via docking) that you always use together. Then you can minimize/restore such groups.
- You'll soon be familiar with the different debug windows, and then a title like "CPU flags" isn't very useful anymore. You can hide the title via the window menu (the downwards triangle in the top-left corner of a (docked) window). This does save some space.
- Use tab-bars for windows that you don't (often) need together. For example (depending on your use case) you may not need the console together with the memory view, then dock these two in a tab-bar instead of next to each other. Similar for the bitmap and tile viewer, you'll not often need these together, Or just close those windows you don't currently/often need.
- Some (sub)windows have a configurable layout. E.g. right click in the "CPU flags" window, then in the context window choose between horizontal/vertical layout. Depending on how you arrange your other windows, one of these two layouts may fit better. Or hide the undocumented XY flags, you don't often need these.
- In many tables you can hide columns that you don't (currently) need. For example in the "Disassembly" window right-click on the table header, then you can e.g. hide the "opcode" column to save some space. (In most tables you can also drag the columns into a different order). On the other hand, some columns are hidden by default, like the "Action" and "Once" column in the "Breakpoints" window, unhide these if you need them.
- Some windows have collapsible sections. For example the "Tile viewer", once you've chosen the correct settings, you can collapse the "Settings" section to make more room for the "Pattern Table" and "Name Table" sections. And maybe you don't always need to see both these tables? Same for the "Sprite viewer", "VDP register", etc.

- You can sometimes more easily navigate between them via CTRL-TAB. This also works for docked windows. And you can also use this to bring window to the front.
- If you want to move them around without accidentally docking them, then grab the window on some empty region (rather than the title bar) to move them.

## Manual do Usuario - 5. Running MSX Software and Using Media

### 5. Running MSX Software and Using Media

With this information, you can run most of the existing MSX software. If you
use the GUI, refer to the Main menu bar â†’
Media menu.

For all supported media files, there is a list of filename extensions that are
recognized by openMSX. If you run openMSX from the command line, adding a file
name (with path if necessary) as a command-line option, openMSX will insert the
file as the proper type of media. The list of supported extensions for each
media type can be easily retrieved with `-h` option on the command
line. For some media, examples of command-line usage are given below.

If you drag and drop a file with one of these supported extensions
into the main openMSX window, openMSX will try to handle it accordingly.

### 5.1 Running ROM software

In the GUI you can choose which ROM software you want to run by selecting a
Cartridge Slot from the Main menu bar â†’ Media menu. This will open a
window where you can tell openMSX exactly what you want to put in the slot,
like a ROM image, which mapper to use if the automatically selected one isn't
correct, and whether the MSX should be reset after inserting.

And finally, you can
also browse for and select (multiple) IPS patches to apply to the selected ROM
image. IPS patches are files that describe a modification of the ROM you are
applying it to, e.g. a translation or a cheat. This way you do not need to
alter the original files.

## Command line and console

Using the command line, suppose you want to run the ROM file
`galious.rom`. Then you simply type:

`openmsx galious.rom`

and the emulated MSX will run the game. (Of course,
in this case, the file `galious.rom` should be in the current directory.
You can also explicitly indicate that the thing is a ROM image like this:

`openmsx -cart galious.gam`

This lets openMSX know that the file `galious.gam` is a ROM
cartridge and that openMSX should insert it in the first available free
cartridge slot. You can also use `-carta` to explicitly specify
cartridge slot A.

In the event openMSX doesn't have the ROM in the ROM database and fails auto
detection of the mapper type, you can specify the mapper to `Konami`
(for instance) like this:

`openmsx galious.rom -romtype Konami`

Note that in practice you won't need this, because most ROM images are in the
database or auto detected if they are not. The `-romtype` option
should follow the ROM it applies to immediately on the command line.

To apply an IPS patch using the command line, provide the IPS
filename like this:

`openmsx -cart galious.rom -ips galiouspatch.ips`

As with the `-romtype` option, the `-ips` option on the
command line must follow the ROM file it applies to directly. You can also use
multiple `-ips` options if you want to apply multiple patches.

If you already have openMSX running and want to insert cartridges at runtime
(maybe even when the MSX is powered on), you can use the `carta` command in the `console` as well, which is just as
powerful.

### 5.2 Running Disk Software

## 5.2.1 Using Disk Images

Of course, this can only be done if the running machine has one or more disk
drives. From the GUI, simply select the Disk Drive you want to change the disk
image for. This will open a Disk Drive window where you can specify what must
be in the drive: a disk image (select a disk image file, or create a new disk
image), a directory to be used as disk (see next section), a RAM disk
(temporary disk image in RAM), or nothing at all. As with ROM images,
IPS patches can be selected to be applied.

Disk images in compressed format ((g)zip, xsa) can be used as regular disk images,
but do note that they are read-only.
Note that in zipped disk images, the first file that is packed into the zip file
will be used as disk image.

To specify disk images on the command line, you can type:

`openmsx relax.dsk`

for example. Or, if you use a disk image with a filename extension that is
unknown to openMSX:

`openmsx -diska relax.di`

You can also change disks at run-time of course. Just type

``diska` <diskimage>`

in the `console` to put the specified
disk image in drive A. To eject the disk from drive A, use:

``diska` eject`

Note that inserting another disk image automatically ejects the previous one.

To apply an IPS patch, provide the IPS filename like this:

`openmsx SDSNAT1C.DSK -ips sdsnat1-eng.ips`

On the command line, the `-ips` option must immediately follow the disk image
it applies to. You can also use multiple `-ips` options if you
want to apply multiple patches.

You can also apply the patches when changing disks at run-time in the console.
Just type something like

``diska` SDSNAT1C.DSK.gz
sdsnat1-eng.ips sd-cheat.ips`

in the console to put the specified gzipped disk image SDSNAT1C.DSK.gz in drive
A, with both IPS patches applied.

## 5.2.2 Using Directories as Disks

The DirAsDsk feature permits you to use a directory on your host computer's
file system as a disk image for your emulated MSX. Note that this has nothing
to do with harddisk emulation. It simply creates a
virtual disk structure in memory from the files that are in the directory
that you specified as if it were a disk image. So, on the command line:

`openmsx -diska .`

will try to put all files of the current directory on a disk image in memory and
start openMSX with it. The actual data is still read from/written to the files
in your directory so that if you change the contents of the files, these changes
are immediately visible in the emulated MSX. This way you can for instance
edit source files with your favourite text editor but compile them immediately in
the emulated MSX.

Using the default value of the setting `DirAsDSKmode` (full), all changes to the
directory on the host system and on the MSX system are performed, so
that they are immediately visible to the other side. If this is not the desired
behaviour, please check the documentation of that setting.

Be careful when writing to files from your emulated MSX. In the
default 'full' mode, you can change/overwrite/delete/corrupt files on your host
system, if you made them accessible for the emulated MSX! Still, this is the
behaviour what most people want/expect and it's very useful if you know what
you are doing.

Note that MSX disks only have a limited capacity, typically 720kB. If the
host directory contains more data, then some host files will be ignored and
they will not appear in the virtual disk image.

## 5.2.3 Using Real Disks

We do not recommend using real disks (e.g. with a USB floppy drive)
with openMSX. There is no specific support for this.

## 5.2.4 Managing Disk Images

openMSX has a special command to perform file imports and
exports, with support for normal disk images, Sunrise IDE harddisk images with partitions (FAT12
only), and Nextor harddisk images with partitions (FAT12 and FAT16).

In the GUI, you can find this tool under Main menu
bar â†’ Tools â†’ Disk Manipulator. This will open a big window,
which has many powerful options. On the left side you select the emulated
machine drive (any existing drive, or the "Virtual drive" which only exists in
memory). On the right side, you see the host directories with their file
content. Use the arrows in the middle to transfer files, the plus button on the
left side to create a new (hard) disk image and the directory button to browse
for a disk image to insert.

For the console commands that are behind this window, please see the separate manual called
Using diskmanipulator.

### 5.3 Running Tape Software

First thing you need to be aware of: this can only be done on machines that
have a cassette port. Most do, but the MSX turboR machines do not, so tape
software cannot be used on these machines.

Cassette/tape image file formats that are supported are WAV files (raw digitized
recordings of real tapes) and CAS/TSX files. Differences are explained below.

In the GUI select Main menu bar â†’ Media â†’ Tape
Deck to open the virtual cassette player control window, which allows
you to insert a cassette tape image.

To insert a tape image from the `console`, type:

``cassetteplayer` insert <file>.wav`

Once inserted, in MSX Basic, type:

`run"cas:"`

(or another command to load the program on 'tape'.)

The cassetteplayer related commands/settings that are controlled in the tape deck window are:

- `cassetteplayer rewind`, to rewind the tape
- `cassetteplayer eject`, to eject the tape
- `cassetteplayer new <filename>`, to create a new WAV cassette image to record to; also sets the cassette player in record mode
- `cassetteplayer play`, to set the cassette player in play mode (when you've just recorded to the cassette)
- `cassetteplayer record`, to set the cassette player in record mode, to append to existing cassette images (NOT IMPLEMENTED YET)
- `set cassetteplayer_volume`, to set the volume of the cassette player sound (yeah, the screeching tape sounds!)

As you can see in this list, appending to existing cassette images (or
(partially) overwriting them) is not supported (yet). If you want to save
again, just insert a blank tape by using the `cassetteplayer new`
command again (or the Record button with the circle icon in the Tape Deck
window).

## 5.3.1 Using CAS and TSX files

You can also use the so-called CAS files and also TSX files. Use them exactly as you would use WAV
files, described in the previous section.

We don't support using CAS files by patching a BIOS natively, because it is not
really something we want: we prefer a more authentic emulation without hacks
like this.
So, the CAS (and also TSX) files are automatically converted to WAV files, internally. Note
that the loading time is drastically longer this way (but the Main menu bar â†’ Settings â†’ Speed â†’ Go full speed when loading `setting`
will help a lot). On the other hand, you will be able to hear the cassette
sounds also with these file formats... Admit it, using cassettes with an MSX
without those characteristic sounds just wouldn't be the same.

To make it even more comfortable to run software from cassette tapes, check the Main menu bar â†’ Media â†’ Tape Deck â†’ Controls â†’ (try to) Auto Run `setting`, that will attempt to
type the loading instruction for you after the MSX has started up.

Note that saving to existing cassette images is not possible; you can
only save to new cassette images in WAV format.

### 5.4 Emulating MSX Harddisks and CD-ROM

The Sunrise IDE interface was the first one to be emulated in openMSX, so by now it's thoroughly supported.
Later support for two types of SCSI interfaces was added:
the Gouda/Novaxis SCSI interface and the MEGA-SCSI, followed by support for
the MegaFlashROM SCC+ SD, the Carnivore 2, and the Beer IDE interfaces. Not all harddisk management tools may support these newer mass storage devices.

The extensions that enable this have a built-in mass storage (harddisk, SD card, etc.) configuration, in the
form of a 100MB disk image. This is the default size: if the harddisk
image is not present, a file is created with this size. The image will end up
in your openMSX user
directory`/persistent/NAME/untitled1/IMAGENAME.dsk`, where NAME is
the name of the extension used and IMAGENAME is a name that is configured in
the extension's XML file (e.g. default `hd.dsk` for the Sunrise IDE).

When using these extensions for the first time, you have to treat them as if
they were real interfaces with a blank harddisk connected. How they should be initialised
depends on the type. We advise you read the manuals, the sections
below give some hints. The `diskmanipulator` may be helpful, as it
supports harddisk images with both Sunrise IDE and Nextor compatible partition
table formats.

For clarity's sake: since the emulation is done on a big disk image, data corruption of your PC's harddisk is impossible. You will need free
disk space for this image, however (default size: 100MB). In other words, you cannot use a normal PC harddisk as an MSX harddisk for these extensions.

The way to use files from your real PC harddisk on an emulated MSX,
is by using the DirAsDsk feature. See the DirAsDsk section for more details.

In the GUI under Main menu bar â†’ Media
you can find entries like "Hard Disk A" or "CDROM Drive
A" if such devices are connected to the (IDE/SCSI/SD) extension in your
currently active machine. If wanted, you can also change the used image,
but note that media like harddisks require the machine
to be powered off first (see the Main menu
bar â†’ Machine menu for the `power`
setting).

To specify the harddisk image to be used on the command line, use the applicable command-line option, e.g. for Sunrise IDE:

`openmsx -ext ide -hda symbos.dsk`

This command gives you the ide extension with symbos.dsk as harddisk
image. You can also change the harddisk image at run time in the `console`, with a command similar to the `diska` command:

``hda` <diskimage>`

Please read the following sections for details about the specific extensions.

## 5.4.1 Sunrise IDE

The extension for this is called 'ide' (shown with the full name Sunrise
ATA-IDE in the extension selector). By default it has a harddisk connected to
the master port and a CD-ROM player connected to the slave port.

The 'ide' extension needs the BIOS that can be flashed into the Sunrise IDE
interface. It can be downloaded from the Sunrise for MSX web site (http://www.msx.ch/sunformsx/download/dl-ide.html).

The initialisation of a Sunrise IDE harddisk is described in the text files
that come with the FDISK program for IDE, downloadable from the Sunrise for MSX web site (http://www.msx.ch/sunformsx/download/dl-ide.html). There are also some (https://www.msx.org/forum/semi-msx-talk/emulation/how-get-sunrise-ide-working-openmsx)
threads (https://www.msx.org/forum/semi-msx-talk/emulation/openmsx-harddisk-emulation)
on the MSX Resource Center forum that may give you valuable hints.

You can sidestep these procedures by using the `diskmanipulator` to create an initial hd
image complete with any desired files and subdirectories. For
instance to create a harddisk with 3 partitions of 32 megabyte on it, and have
each partition filled with files and subdirectories, proceed as follows:

Start openMSX with the ide extension, then type in the `console`:

`set `power` off`
``diskmanipulator` `create` /tmp/new-hd.dsk 32M 32M 32M`
``hda` /tmp/new-hd.dsk`
``diskmanipulator` `import` hda1 /home/david/msxdostools/`
``diskmanipulator` `import` hda2 /home/david/msxdemos/`
``diskmanipulator` `import` hda3 /home/david/msxdrawings/`
`set `power` on`

As announced above, there is (limited) support for CD-ROM with the 'ide'
extension. You can insert an ISO image in that virtual CD-ROM player with the
`-cda` command-line option and change it at run time with the
`cda` console
command, all similar to the aforementioned `hda` and `diska` commands and options.

## 5.4.2 Beer IDE

The Beer IDE interface, as brought to us by SOLID, is emulated by openMSX, too.
This interface only offers a single device (no master and slave) and can only
handle up to 4 (version 1.9) or 5 (version 1.8) partitions of 32MB. On the
upside, it doesn't need MSX-DOS2, and thus it can run on any MSX (with
64kB RAM to run MSX-DOS). Emulation of this interface should be considered
experimental.

Usage is identical to using the Sunrise harddisk interface: you can use the
GUI, the `hda` command and the
matching command-line parameter `-hda` to control which image will
be used.

By default, the image is 128MB, so that it can fit 4 partitions of 32MB. Firmware
version 1.9RC1 is selected by default, because we could not get the 1.8
firmware to work: the MSXFDISK program didn't create partitions which actually
worked with the 1.8 firmware. If you want to experiment with it, you can change
the firmware to use by editing the extension file in
`share/extensions/Beer_IDE.xml`.

With the 1.9RC1 firmware, you can use `diskmanipulator` to create a harddisk
image and import from and export to them. To get started, partition the default
drive with `diskmanipulator partition hda -dos1 32M 32M 32M 32M`.
Then import MSX-DOS system files onto the first partition using
`diskmanipulator import hda1 <host-path>`, and now you should
be able to boot into MSX-DOS.

Unfortunately, the Beer IDE is hardly documented and the software is hard to
find. So, it's for experts only!

## 5.4.3 SCSI devices

First of all: the SCSI emulation is experimental! There is a lot bigger chance
that you may lose data on your emulated harddisk images with SCSI than with
Sunrise IDE! When we tried it, everything seemed fine, but you have been warned.

The SCSI extensions (currently Gouda_SCSI, ESE_MEGA-SCSI and ESE_WAVE-SCSI)
have the default 100 MB harddisk image connected on target ID 1 and an (even
more experimental) LS-120 device (basically a harddisk like media that can be
changed/ejected when the power is on) on target ID 2.

Specifying or changing harddisk images works the same as with IDE, see above.

To change the disk image of the LS-120 device, use the `lsa` (LS
drive A) command, exactly the same as the `hda` command. Of course you do not need to have the
power turned off to do this, as this is the whole point of the LS-120 device.
You can also just eject it, with the `eject` subcommand. At the time
of writing there seems to be a bug when doing this: the device isn't listed in
the device list if there is no media inserted. It is currently not possible to specify an
LS-120 device on the command line.

Initialisation for the ESE SCSI devices needs tools like `MGINST`,
which can be found on Takamichi's web site (http://www.msxnet.org/gtinter/nogame-e.htm).
They include small manuals in English. This manual is not the place to explain
the procedure, but the idea is as follows. First, install the MSX-DOS 2 kernel
in the SRAM of the device, using the `MGINST` program (you might
want to use `KSAVER` first to save the kernel of your DOS 2
cartridge). After this, the MSX will boot from the SRAM disk. Use the
`SFORM-1` (for MSX-DOS) or the `SFORM-2` (for MSX-DOS 2)
to format the drive (use a physical format, for now). Use `ESET` to
assign drive letters to partitions.

For the Gouda (Novaxis) SCSI interface, you need the Novaxis ROM, see also Hans Otten's Page (http://msx.hansotten.com/index.php?page=msxscsi) or The Ultimate MSX FAQ (http://faq.msxnet.org/scsi.html). Those sites
also contain manuals for the Novaxis ROM. Initialisation is done with the
`NFDISK` utility, which can be found on Marcel Delorme's site (https://web.archive.org/web/20200315110709/http://members.chello.nl/m.delorme/) (archived).

## 5.4.4 MegaFlashROM SCC+ SD

Currently there is only one SD interface emulated: the MegaFlashROM SCC+ SD.
All features of this cartridge are emulated in the sense that all software currently
working with it, runs on openMSX too. It is not emulated accurately
enough to rely on it for development.

The SD card slots appear in the openMSX user interface as "Hard Disk A/B" and
hot plugging is not supported. So, it shows up almost identically to the
Sunrise IDE interface.

The difference compared to a real MegaFlashROM SCC+ SD, is that the extension does not
come with anything flashed on the flash ROM by default. There are two ways to
overcome that. The first one is to download the preflashed ROM content (for URL
see below) and install it into your systemroms folder, like any usual system
ROM. This only works if you use the extension for the first time, unless you
manually delete the persistent file for the flash ROM chip (typically in your
openMSX user
directory`/persistent/MegaFlashROM_SCC+_SD/untitled1/megaflashromsccplussd.sram`).
Only if no such file is found, openMSX will load the content of that ROM file
into the flash ROM of the MegaFlashROM SCC+ SD. The second way is manually
flashing things like Nextor, the rescue menu and the ROM disk. This is all
described in the manual (see at the end of this section) of the MegaFlashROM
SCC+ SD, because on a real device you may also need to do this.

Once you achieved this, usage is again identical to using the Sunrise harddisk
interface, so in the console you can use the `hda/hdb` commands and the matching command-line
parameters `-hda` and `-hdb` to control which image will
be used for the first and second SD card.

Currently, by default, the first SD card is 8MB and the 2nd SD card is 100MB in
size. You can change these defaults by editing the extension file in
`share/extensions/MegaFlashROM_SCC+_SD.xml`. For formatting and
managing the SD cards, please refer to its manual and tools on the Flash part
of the MSX Cartridge Shop (http://www.msxcartridgeshop.com/). It also provides the ROM file with the initial content of
the flash ROM as it is shipped on real MegaFlashROM SCC+ SD cartridges.

To get files on the SD cards, you can use `diskmanipulator` with the
`-nextor` option to partition and to import files, similar to what
is explained above in the Sunrise IDE section.

### 5.5 Running Laserdisc software

In order to run Laserdisc software, you need to have this optional feature
compiled into your openMSX binary. Laserdisc is only supported by the Pioneer
PX-7 or the Pioneer PX-V60 machines, which have special hardware to control the
laserdisc player.

The Laserdisc image can be selected under Main
menu bar â†’ Media â†’ LaserDisc Player or in the `console`, type `laserdiscplayer insert <file>.ogv`

to insert a Laserdisc (image) into the Laserdisc player.
By default, the Laserdisc will be loaded automatically. If the
`autorunlaserdisc`
setting is off, then you will have to take a few steps yourself.

After booting the MSX, choose option 1 when asked if you want to run P-BASIC
(Palcom-BASIC). In MSX-BASIC, type:

`call ld`

to load and run the Laserdisc program.

The program is encoded on the right audio channel, which will not be audible.
With `set fullspeedwhenloading on`,
openMSX runs at maximum speed whenever the Laserdisc is seeking or loading a
program.

## Manual do Usuario - 6. Input Devices

### 6.1 Keyboard

## 6.1.1 MSX Key Mapping

The special MSX keys are mapped as follows, the first column for PCs (running
Windows, Linux or BSD), the second column for Apple Macintosh computers:

**MSX key | key (PC) | key (Mac)**
- CTRL key -- L-CTRL -- L-CTRL
- dead (accents) key -- R-CTRL -- R-CTRL
- GRAPH key -- L-ALT -- L-ALT
- CODE/KANA key -- R-ALT -- R-ALT
- å–æ¶ˆ ('cancel') key -- L-Windows -- 
- å®Ÿè¡Œ ('execute') key -- R-Windows -- 
- SELECT key -- F7 -- F7
- STOP key -- F8 -- F8
- INS key -- Insert -- Cmd+I

## 6.1.2 ColecoVision Key Mapping

The ColecoVision controllers are mapped as follows:

**direction/key | player 1 | player 2**
- up -- cursor up -- W
- down -- cursor down -- S
- left -- cursor left -- A
- right -- cursor right -- D
- fire left -- space, R-CTRL -- L-CTRL
- fire right -- L-ALT, R-ALT, R-SHIFT -- L-SHIFT
- 1 -- 1, numpad 1 -- R
- 2 -- 2, numpad 2 -- T
- 3 -- 3, numpad 3 -- Y
- 4 -- 4, numpad 4 -- F
- 5 -- 5, numpad 5 -- G
- 6 -- 6, numpad 6 -- H
- 7 -- 7, numpad 7 -- V
- 8 -- 8, numpad 8 -- B
- 9 -- 9, numpad 9 -- N
- 0 -- 0, numpad 0 -- U
- * -- -, numpad *, numpad - -- J
- # -- =, numpad /, numpad + -- M

Host joysticks can also be used for directions and the fire buttons, but the
keys from the telephone-style keypad can only be entered via the host keyboard.

## 6.1.3 Emulator Functions Key Mapping

The mapping of the keys for emulator functions is fully customisable using the
`bind` command in
the `console`. Your customised key
bindings are saved together with the settings. This subsection lists the
default key mapping.

**keys (PC) | keys (Mac) | function**
- Pause -- Cmd+P (Pause) -- Pause emulation
- ALT+F4 -- Cmd+Q (Quit) -- Quit openMSX
- CTRL+Pause (Break) --  -- Quit openMSX (not in Windows)
- PrtScr -- Cmd+D (Dump) -- Save current screen to a file (screen shot)
- PageUp -- PageUp -- Go 1 second back in time, using the `reverse` feature
- PageDown -- PageDown -- Go 1 second forward in time, using the `reverse` feature
- F9 -- Cmd+T (Fastforward) -- Toggle `fastforward` mode (normal vs fastforward speed)
- F10 -- Cmd+L (consoLe) -- Toggle `console` display
- F11 or ALT+Enter -- Cmd+F (Full) -- Toggle full screen mode
- F12 -- Cmd+U (mUte) -- Toggle audio mute
- ALT+F7 -- Cmd+R (Restore) -- Quick `loadstate` (from 'quicksave' slot)
- ALT+F8 -- Cmd+S (Save) -- Quick `savestate` (to 'quicksave' slot)
- CTRL+Win+C -- Cmd+C (Copy) -- Copy screen's text content to clipboard
- CTRL+Win+V -- Cmd+V (paste) -- Type the text from the clipboard into the MSX

Note that Mac users must use `GUI` as a modifier for the Command
(Apple logo) key. On PC's use `GUI` for the Windows key.

Please note that openMSX is currently intended to be mouse controlled.
Some parts of the GUI can also be controlled via keyboard, but this has not
been optimized at all for now. Control via gamepad is currently disabled (this
might change in a future version).

## 6.1.4 Keyboard Layouts

This section is about how host computer keyboard layouts are mapped to
MSX keyboard layouts. This is mostly interesting if those differ
(a lot). For example, you have a US-English keyboard on your PC and you are
emulating a Japanese MSX computer. Or, you have a Japanese Mac and you are
emulating a Spanish MSX computer.

There are features to make this as smooth as possible,
so that you can use your own keyboard for any kind of MSX with as little
surprises as possible. The trick is the new character-based mapping mode, which tries to convert
any character you enter with your host computer's keyboard to an MSX key press.
For this feature, all MSX hardware configuration files now have information
about their keyboard layout. Anyway, this mapping mode is enabled by default,
so you don't have to do anything to make this work!

However, there are always some pesky details. For those details we refer to the
documentation of other keyboard settings, where they are explained in full
detail: mapping mode (as mentioned before), `kbd_numkeypad_always_enabled`
(use numerical keypad even when your MSX doesn't have one), `kbd_code_kana_host_key` (specify
an alternative host key for CODE/KANA) and `kbd_numkeypad_enter_key`
(specifies mapping of the ENTER key of the keypad).

You can find the mapping mode setting in Main menu
bar â†’ Settings â†’ Input â†’ Keyboard mapping mode.

### 6.2 Joystick

If you have a controller or joystick connected to your PC, you can map its
input to one of the emulated MSX joystick (like) devices, internally called `msxjoystick1`,
`msxjoystick2`, `joymega1` and `joymega2`.

See the earlier section about plugging devices on how to connect these devices to your emulated machine.

The mapping of your host devices (host controllers, joysticks or keyboard) to
these 4 emulated MSX joysticks is fully configurable. The easiest way is to use
the GUI menu for that under Main menu bar â†’
Settings â†’ Input â†’ Configure MSX joysticks. You can also do it
in the console with the `msxjoystick<n>_config/joymega<n>_config`
settings.

Most modern joysticks have more buttons than the 2 buttons that are defined by
the MSX standard. Therefore a lot of games use extra keys on the keyboard for
extra functionality. For instance, almost all Konami games use F1 to pause
the game. You can assign this extra functionality to your joystick by using the
`bind` command. As
an example here is how to map button 4 of the first joystick to the F1-key,
button 5 to F2, ...

`bind "joy1 button4 down" "keymatrixdown 6 0x20"`
`bind "joy1 button4 up" "keymatrixup 6 0x20"`
`bind "joy1 button5 down" "keymatrixdown 6 0x40"`
`bind "joy1 button5 up" "keymatrixup 6 0x40"`
`bind "joy1 button6 down" "keymatrixdown 6 0x80"`
`bind "joy1 button6 up" "keymatrixup 6 0x80"`
`bind "joy1 button7 down" "keymatrixdown 7 0x01"`
`bind "joy1 button7 up" "keymatrixup 7 0x01"`
`bind "joy1 button8 down" "keymatrixdown 7 0x02"`
`bind "joy1 button8 up" "keymatrixup 7 0x02"`

For a more detailed explanation of this command see the Console Command Reference. Please note that
unfortunately, such mappings are not configurable via the GUI menu.

### 6.3 Mouse

To connect a mouse, you can also use the Main menu
bar â†’ Connectors menu or the `plug` command: `plug joyporta mouse`
will connect a mouse to joystick port A. If you want the joystick emulation
feature that some mice (like the Philips SBC-3810 and the Sony MOS-1) have,
keep the left mouse key pressed when plugging it in, just as on a real MSX.

If you are using openMSX in windowed mode, it might be tricky to use the mouse.
The setting: `set grabinput on`
makes sure all input goes to openMSX. Your cursor cannot leave the openMSX
window with this setting. Just turn it back to off, if you want to disable this
again. If you only want to escape the window briefly, use this command:
`escape_grab`. It permits you to
leave the window, but the next time you enter it, the cursor is grabbed again.
It might be a good idea to bind this command to a key, using the `bind` command, which is
mentioned above. You can also toggle the setting via Main menu bar â†’ Settings â†’ Input â†’ Grab
input.

### 6.4 Arkanoid Pad

The Arkanoid games by Taito both have support for a special Arkanoid game pad,
with a classical rotary knob to control the position of the bat. This device
is emulated as well and can be controlled by the mouse. Plug it via the GUI
Main menu bar â†’ Connector menu or in
the console with `plug joyporta arkanoidpad
`.

### 6.5 Trackball

Some MSX trackballs like the HAL CAT and the Sony HB-G7B seem to have identical hardware
and are also emulated by openMSX, again using the mouse to control it. In MSX
software, the trackball is mostly supported in port B only. Using the console
you can use therefore `plug joyportb trackball`.

Quite some HAL programs have support for it, e.g. Hole in One, Eddy II, Music
Studio G7, Space Trouble and Super Billiards. The test program provided in the
Sony HB-G7B service manual also works fine, of course.

### 6.6 Touchpad

Some MSX touch pads like the Philips NMS 1150 Graphic Tablet are also emulated
by openMSX, again using the mouse to control it (where mouse button 1
corresponds to touch or no touch and mouse button 2 to the button on the pen of
the touch pad). Also the touch pad is mostly supported in port B only, so the
console command is `plug joyportb touchpad`

This device is mostly supported by the Philips drawing programs Designer,
Designer Plus and Video Graphics (all in port B) and by Pioneer MSX Video Art
(port A).

Note that the whole openMSX window will function as the surface of the touch
pad. This may not align with the actual pixels of the screen in that window,
see the `touchpad_transform_matrix`
setting for how to adjust this.

### 6.7 Magic Key

Sony made a small dongle for game testers to cheat within the games. The games
that have support for it will check if the UP and DOWN keys are pressed. The
magic key is supported by these games in port B only (console: `plug joyportb
magic-key`.

Known games that can use this Magic Key are:

**Family Boxing (Sony):** Press the Graph key on the title screen to enter the secret menu
**Jansei (Sony):** You can set the characteristics of the enemy by moving the cursor to
"Actual Battle" on the menu screen and pressing ESC and SELECT.
**Gall Force - Defense of Chaos (Sony):** A new menu item will appear on the home screen

### 6.8 Ninja Tap

The Ninja Tap (å¿è€…ã‚¿ãƒƒãƒ—) is an adapter designed by Knight's chamber and
sold in Japan by PCCM. This adapter allows you to use up to 4 joysticks per port.
Plug it via the GUI or with the console using `plug joyporta ninjatap`.

### 6.9 Tetris II Special Edition dongle

Tetris 2 Special Edition from R.A.M., an Italian MSX group, needs the dongle in
port B too start the game. So, on the console use `plug joyportb tetris2-protection
`

### 6.10 MSX Paddle

The MSX paddle controller is a quite simple device, but there are not so many
commercial implementations for MSX. The Yamaha MMP-01 is a music pad that is
known to use this protocol to transmit its coordinates. Plug it in the console
as follows: `plug
joyporta paddle`.

### 6.11 Circuit Designer dongle

Circuit Designer dongle from The Falcon, needs the dongle in port B to start
the program, so in the console type: `plug joyportb circuit-designer-rd-dongle
`.

## Manual do Usuario - 7. Video

### 7. Video

openMSX uses the OpenGL graphics library for all post processing (hence
the PP in SDLGL-PP, which is the name of the "renderer", the software component that generates
the graphical part of the emulation, the MSX 'screen'). This includes
scalers and other effects, but also the GUI...
Because of all this, openMSX runs best with a hardware accelerated
OpenGL library. See the Setup Guide for
OpenGL performance tips.
So, again, be aware that openMSX requires both your video
card and video driver to support at least OpenGL 2.0. Sometimes you need to
upgrade your driver to make it work. If your videocard or driver don't support
OpenGL 2.0, openMSX will not start up and report an error.

Most video related settings can be found under the Main menu bar â†’ Settings â†’ Video menu.
The rest of this section describes more details about the settings you can find
there. For instance, for full screen mode, there is a checkbox in that menu,
which maps to the `fullscreen` setting.

### 7.1 Scalers

Most MSX screen modes are only 256Ã—212 pixels big. This is quite small
for today's PC screen resolutions. That's why you have the possibility to
scale up the image. There are currently three possible scaling factors: 2, 3
and 4. If you select 2, all MSX pixels are mapped to a 640Ã—480 pixels PC
window, for 3 to a 960Ã—720 pixel window and for 4 to the obvious
1280Ã—960 window. The setting which determines this is called `scale_factor`. In
general, the higher the factor, the better the output image is.

There are also a number of scaling algorithms (setting `scale_algorithm`) that can be
set. The scaling algorithm determines how exactly the mapping is done between
the MSX input screen and the PC output screen. As we render more pixels than
the normally visible MSX pixels, this allows for extra possibilities in the algorithms, like
deinterlacing and adding scanlines, blur, anti-aliasing (rounding of blocky
patters like stair cases) or even a Trinitron-like TV effect.

openMSX contains the following scaling algorithms:

**simple:** This algorithm simply expands each MSX pixel to a square of
(scale_factor)Ã—(scale_factor) PC pixels.
This is the default scaler and can be tuned to look like most CRT screens.
The image looks blocky, especially diagonal edges, but it does support
scanlines and blur.
**ScaleNx (http://scale2x.sourceforge.net/):** This scaler algorithm smoothes edges by using only original colors, so it will
not give any blur. It is fast and its image is less blocky than that of the
simple scaler. However, all corners are rounded, which does not look good on
all graphics. This scaler has not been properly implemented for scaling factors
of 4.
**hq (http://en.wikipedia.org/wiki/Hqx):** This algorithm does a good job on most graphics; it avoids excessive blurring
and it keeps corners sharp.
On some graphics, it does not identify edges correctly, making those edges
blocky instead of smooth.
Especially with high scaling factors, it can give a very smooth looking image.
**RGBTriplet:** This algorithm only works as intended when a scaling factor of 3 is used. Also,
it only works well for MSX screen modes of 256Ã—212, which includes most
games. The idea of the algorithm is that each input pixel is mapped on a
triplet of pixels which represent the R(ed), G(reen) and B(lue) components of
the input pixel. This arrangement of RGB components is also used in the Aperture Grille (http://en.wikipedia.org/wiki/Aperture_grille) CRT's, also known as Trinitron and the modern TFT screens. You can
control the effect with the `blur` setting. This algorithm also includes
scan lines.
**TV:** This algorithm tries to emulate the fact that on a CRT brighter pixels look
bigger than darker pixels. It has some minor flaws, but is already developed
far enough to make it available for you to try out.

A small (somewhat outdated) demonstration of some of the algorithms can be
found on the openMSX web site (http://openmsx.org/).

### 7.2 Gamma Correction

PC monitors can have different gamma values than MSX monitors.
To compensate for this, openMSX has a gamma correction feature.
It is controlled by the `gamma` setting.
A value of 1.0 disables gamma correction; a lower value makes the image darker;
a higher value makes it brighter.

If you want to know what gamma correction really means, read this page about monitor gamma (http://www.bberger.net/rwb/gamma.html).
The gamma correction value you can set in openMSX should be the gamma of your
PC screen divided by the gamma of the MSX screen.
I measured the gamma of my PC screen (TFT) at 2.0 and the gamma of my MSX
monitor at 2.5. That puts the gamma correction at 2.0 / 2.5 = 0.8.
So if I enter that value, the openMSX image will have comparable brightness to
the MSX image.
However, 0.8 is not the value I'm actually using: I prefer a brighter image
than my MSX monitor, so I chose to use a gamma correction of 1.1.

### 7.3 Special Effects

openMSX contains a couple of special effects settings that can be applied to
the video output:

**`deinterlace`:** Interlacing is a technique to double the vertical resolution by splitting the
image into two frames: the first frame displays the even lines, the second
frame the odd lines.
The after glow on a TV and some processes in the human brain combine both
frames into a single image. However, this process is not perfect and you can
notice flickering, especially on horizontal lines.
The deinterlace feature combines the even and the odd frames into a single
output frame, thus eliminating the flicker.
The `deinterlace` setting controls this
feature:
it can be on (enabled) or off (disabled); it is enabled by default.
**`deflicker`:** This filter detects pixels that alternate each frame between two different
colors and replaces those alternations with the average color. Such
'flickering' pixels can occur in software that rapidly changes between colors
to create the illusion of a wider color palette. It can also occur because of
'sprite flickering'. This setting is disabled by default because there aren't
that many situations where it really improves video quality, but it does have
a performance cost.
**`scanline`:** On TV's and MSX monitors, you can see a small black space in between the
display lines, especially when using NTSC.
The scanlines feature simulates this by drawing some lines a bit darker.
This feature is disabled when a scaling algorithm other than
`simple`, `tv` or `RGBTriplet` is used.
**`blur`:** TV's and MSX monitors are less sharp than PC monitors:
neighbouring pixels tend to blur into each other.
The blur feature simulates this by interpolating neighbouring pixels.
The `blur`
settings control this:
0 means no blur (completely sharp), 50 means some blur (like a monitor),
100 means maximum blur (like a TV).
All other values between 0 and 100 are also possible of course.
This feature is disabled when a scaling algorithm other than
`simple` or `RGBTriplet` is used.
**after glow (`glow`):** The after glow feature blends each frame with the previous one.
This results in moving objects leaving a trail (motion blur).
The `glow` setting
controls the amount of after glow:
0 means no after glow, 100 means maximum after glow.
**`noise`:** This setting controls the amount of pixel noise on the screen.
The `noise`
setting controls the amount:
0 means no noise, 100 means maximum noise. The value is actually the deviation
of the colour of the original pixel and non-integer values are also possible.
**display deformation (`display_deform`):** This feature makes it possible to change the shape of the MSX screen. Here are the possibilities:

`normal`: no deformation (default)
`3d`: emulates a 3D view on an arcade cabinet's screen

### 7.4 Accuracy

An advanced setting (which you can find under Main
menu bar â†’ Settings â†’ Video â†’ Advanced (for debugging)
(the `accuracy` setting) controls how often
the renderer is synchronised with the MSX video processor (VDP).
There are three options:

**screen:** Synchronise once per screen (frame).
Good enough for most MSX1 software, but will break most raster effects.
**line:** Synchronise at the start of a line.
This is good enough for most software.
This setting hides imperfections in raster effects,
which could be considered a useful feature.
**pixel:** Synchronise at the exact pixel where a change occurs.
This is the most realistic setting and therefore set as the default.
To see demos like Unknown Reality (scope part) and Verti correctly,
you should use this setting.
Also, you will see any imperfections in raster effects
just like they occur on a real MSX.

### 7.5 GFX9000/Video 9000

openMSX has GFX9000 emulation. As there isn't that much software for it
available, it is not as complete, functional and optimized as the video
emulation of the classical MSX chips.
Despite of all this, most existing GFX9000 software runs pretty well, so we
found it worth sharing with you anyway.

The real GFX9000 has an external video connector to which you can connect a
second monitor. We never took the trouble to
emulate a second monitor, however, so to see the GFX9000 in action, you need to switch the
videosource setting, which mimics a so-called SCART-switch in the real
world: `set
videosource GFX9000`.
This setting is only available when there are actually multiple video sources
available. In the GUI you can find it under Main menu bar â†’ Settings â†’ Video â†’ Video
source to display.

Alternatively, instead of the GFX9000 extension, you could use the
Video9000 extension (also built in in several Boosted MSX machine
configurations). The Video 9000 hardware has the possibility to superimpose the
GFX9000 video on top of the V99xx video (and this is practically the only
feature of the Video 9000 that is currently implemented). Software that is
Video 9000 aware, will tell the Video 9000 to show the GFX9000 if something
interesting is to be seen on the GFX9000 video output. So, for such software,
you do not have to switch video sources if you simply use the Video9000
video source. When a Video 9000 is present in the currently running MSX
configuration, the Video9000 video source will be selected by default, to make
use of this superimpose feature. For programs not aware of Video 9000, you will
still have to switch video sources manually, just like on a real system.

To get your normal MSX screen back, set the setting back to MSX. If you want to
toggle between them with a hotkey, it might be useful to bind a key for it. E.g.: `bind F6 cycle videosource`.

`cycle` is a Tcl
command that cycles through the options of the setting in the parameter.

### 7.6 Video Recording

The video recorder enables you to record the audio and video rendered by
openMSX to an AVI file. The output video is in 320Ã—240 resolution by
default, at 640Ã—480 when using the `-doublesize` flag and at
960Ã—720 when using the `-triplesize` flag. The video is
compressed with the ZMBV codec, a fast lossless compression algorithm that
works very well on 2D computer generated images. The `FAQ` contains more information about this codec. The
audio is uncompressed.

The recorded AVI file will not suffer from any hiccups, even if the emulation
ran too slow when you recorded it. The current video source (see previous
section) is recorded and the sound is recorded with the current `frequency` setting.
If you change the `frequency` setting during recording,
or, more importantly, if the software changes from PAL (50 Hz) to NTSC (60 Hz)
during recording, the video will get out of sync with the audio. Most of the special effects will not be recorded.

If any stereo sound devices are present or any sound device has an off-center
balance, the recording will be made in stereo, otherwise it will be mono. If
a recording is made in mono and then a stereo sound device is added, you'll
receive a warning that stereo sound has been detected and that the two
channels will be mixed down to mono. You can prevent this from happening by
using the `-stereo` option to force a stereo recording even if
no stereo devices are present at the time you enter the command. You can also
force a mono recording with `-mono` to save space.

In the GUI you can find the video recorder under Main menu bar â†’ Tools â†’ Capture â†’
Audio/Video, which will open a the corresponding window, in which you
can specify all the above mentioned settings.

In the console, you can use the command `record start` to record to a default file
name, or you can use an additional parameter to specify a file. The command
`record stop`
stops recording and `record toggle` toggles it. You can use
the `-audioonly` or `-videoonly` option to record only
sound or video.

If you want to put a recorded video on your web site, it is better to transcode
the audio to MP3 or Vorbis format, as this makes the file a lot smaller.
YouTube supports the ZMBV codec, so if you want to upload your recording you do
not need to transcode the video. If you want to share your video with people
who do not have (or want to install) the ZMBV codec, you should still transcode
it, of course. This can be done with programs such as Virtual Dub (http://www.virtualdub.org/) (Windows) or MPlayer's MEncoder (http://www.mplayerhq.hu/)
(Linux/UNIX). For YouTube you may want to use the command `record_chunks` instead:
it will enable you to chop up your video in several parts and enables
`-doublesize` automatically.

Recording as explained above will happen in real-time. This can be annoying if
you want to make a demonstration video, because you all mistakes will be
recorded as well. To work around this, you can also use the `reverse` feature during
the scene you want to record. After the scene, reverse to the beginning, start
the recording as explained above and let the scene replay relaxedly. You can
even speed it up using the `throttle` setting. This method of recording is
also useful when real-time recording has a big impact on the performance of
openMSX on your hardware. See also the chapter about this feature.

## Manual do Usuario - 8. Audio

### 8.1 Audio Settings

Most audio related settings can be found under the Main menu bar â†’ Settings â†’ Sound menu.

There is a `master_volume` setting, which
controls the overall output volume of openMSX (it applies to all sound
devices). Volume 0 means no sound, volume 100 is maximum.

There is also a `mute` setting, to disable all sound from
openMSX at once. It can be on (muted) or off (sound is audible). By default,
mute is bound to the F12 key.

There are also settings for each emulated sound device. These can be found
under the Main menu bar â†’ Settings â†’
Sound â†’ Show sound chip settings option in the menu.

For each sound device there is a volume setting.
Volume 0 means no sound, volume 100 is maximum. In the console you can do this, for example: `set "MSX Music_volume"
50`.

For each sound device, you can control the distribution of the sound output of
this chip over the left and right channel, with the balance setting. This is
very similar to the balance knob on (older?) hifi equipment.
Example: `set PSG_balance -100`, which sets
the PSG entirely to the left channel. Any sound device can also be individually
(un)muted using the `mute_channels` command.

If you'd like to apply some special effects to the PSG sound, you should take a
look at the `vibrato` and `detune`
(both percent and frequency) settings.

### 8.2 MIDI

Currently, openMSX supports the following MSX MIDI interfaces:

- MSX-MIDI of the MSX turboR GT and the Î¼ãƒ»PACK,
- the MIDI interface of the Philips Music Module (NMS 1205),
- the MIDI interface of the Yamaha SFG-01 and SFG-05 module (also present in the Yamaha CX5M series of machines),
- the FAC MIDI Interface, and
- the JVC (UK) MSX MIDI interface.

To use MIDI, start openMSX with a machine that has a MIDI interface built in,
or add one of the mentioned MIDI interface extensions. Then plug a MIDI out
and/or MIDI in device into that MSX MIDI interface using the GUI
Main menu bar â†’ Connector menu or the
openMSX `console`.

## MIDI Out

You can connect the MIDI out of the MSX to a host MIDI device, such as a
physical MIDI out port, a soft synthesizer or a sequencer program. On Windows,
Linux and macOS, host MIDI devices are made available as pluggables in openMSX.
On macOS, you can opt to instead select `Virtual OUT` to create a
virtual MIDI port for Mac MIDI software to connect to.

For example, use the machine `Panasonic_FS-A1GT` and plug into the
Munt (https://sourceforge.net/projects/munt/) soft
synthesizer (MT-32 emulator) using Main menu bar
â†’ Connectors menu, or with the console command `plug msx-midi-out Munt\
MT-32`.

The exact naming of the host MIDI devices differs per platform. In the console
you can use tab completion to see the options: type `plug
msx-midi-out` and hit TAB twice.

The `midi-out-logger` MIDI device is available on all platforms and
logs MIDI events to a file.

You can specify the file to log to using `set
midi-out-logfilename`.
The log is a raw binary log of the bytes written by the MIDI interface, with no
timing information. Therefore its usefulness is mostly limited to debugging.

On UNIX-like systems, it is possible to log to a MIDI device node, for example
`/dev/midi` and configure the sound system to send those notes to a
soft synthesizer. This is harder to configure than using for example the ALSA
MIDI out device, so it's only recommended when no platform-specific MIDI
devices are available in openMSX. On MSX Resource Center there is a forum thread (http://www.msx.org/forum/semi-msx-talk/emulation/openmsx-timidity) which describes how to connect openMSX to Timidity via
`/dev/midi`.

## MIDI In

Vice versa, the MIDI in port can also receive data from the system by plugging
a device into `msx-midi-in` (for the Panasonic FS-A1GT; use the
appropriate connector name for other devices). Analogous to the above mentioned
outputs you can connect a `midi-in-reader` which reads from a file
or `/dev/midi` on Linux. On Windows and macOS available MIDI devices
show up as separate pluggables. On macOS a `Virtual IN` port is
available as well.

### 8.3 Recording Audio to File

openMSX records the sound at the exact speed at which it should be produced, no
matter the speed at which the emulation was running while recording. Note that
recording sound to the uncompressed WAV format will take a lot of disk space:
at 44.1 kHz it will take about 176 kB per second.

In the GUI you can find the audio recorder under Main menu bar â†’ Tools â†’ Capture â†’
Audio/Video, which will open a the audio/video recording window. Just
select only Audio to log to said WAV file.

The underlying console command to start the recording of sound is `soundlog start`. It
will automatically choose a file name and save it in the `soundlogs`
directory in your personal openMSX folder. You can also add an extra parameter
to specify the filename for the new WAV file. To stop recording, use `soundlog stop`. You
can toggle the recording status using `soundlog toggle`, which is useful if
you `bind` this
command to a hotkey.

There is also an advanced feature for recording audio to file: you can record
individual channels of sound chips to individual files on disk. The sound is in
the native frequency of the sound chip this time, which means that for chips
like PSG or SCC (which run at very high frequencies), the files will be huge.
(You have been warned!) This feature can be controlled in the GUI via Main menu bar â†’ Settings â†’ Sound â†’ Show
sound chip settings and in that window click on the "channels" checkbox,
which opens a window where you can fill in a file name for each channel you
want to record with. Perhaps it is easiest to control from the console with the
`record_channels` command. Note
that in contrast to the `soundlog` command, the output file of
this command ends up in the current directory and not in a special directory.
We hope you can use this command to study the fantastic compositions of MSX
software and make great remakes of them.

## Manual do Usuario - 9. Useful Extras

### 9.1 Saving/Loading the State of the Machine

A feature of emulators which is particularly useful is saving the state of the
emulated machine to a file, in order to load it again later and continue
exactly where you left off when saving. Not only useful for games, but also for
debugging or testing. For openMSX we designed this feature in such a way
that it is trying really hard to be future proof. So, you
don't have to be afraid to upgrade to a new version of openMSX: your save
states will remain usable!

In the GUI's Main menu bar â†’ Save
state menu you find all options to (quick) load and save states and even
more.

The easiest way to use it is by using the keyboard shortcuts for quickly saving
and loading a state, see the shortcut hints in the aforementioned menu and also the key mapping section. These shortcuts basically use the `savestate` and loadstate commands, with the
parameter `quicksave`, i.e. they use a savestate file with the name
'quicksave'. You can also use the commands directly yourself, with the argument
as the name of the slot you save the state to (use TAB or the `list_savestates`
command to see your previously saved states). Without having to browse the file
system of your computer, you can also conveniently delete existing save games
with the `delete_savestate` command.

Note that when saving the state of the machine, a screenshot will also be saved
with it, so that those could be used for save state browsing.

### 9.2 Reverse

Inspired by the meisei MSX emulator, openMSX also has a reverse feature.
This enables you to go back in MSX time, so you can correct mistakes in your
game play or you can watch what you did (and also record a video of it).

You can go back in time a second using the key binding for this: PageUp. Once you
went back, openMSX will replay whatever you did when you were at this time for
the first time, until it got at the point where you went back. From then on,
everything will continue as normal. If you touched any control of your MSX
during replay, you have indicated to take over from the replay. If you do that,
the rest of the replay is erased (openMSX forgets that that future ever
happened). This is the typical way to correct mistakes using this feature.

While replaying, you can also jump forward in time ("Back to the Future") using
PageDown. Also, you can go back a specific amount of seconds or to an absolute
moment in (MSX) time, all using the `reverse` command. (This can also be
useful when you're developing/debugging MSX software.)

If all of this sounds a bit confusing, you can use the reverse bar (by default,
it's placed in the bottom right corner, hover there in the main openMSX window
to make it appear), which will show you a visualisation of all of this on
screen. The bar represents the time while the feature was enabled and shows the
current moment in time (the red indicator). You can click on it to jump back
and forward in time. The vertical lines indicate times when snapshots were
made. The bar will fade out after a while, but hovering your cursor over it
makes it reappear. If you want to get rid of the bar, toggle this setting in
the GUI menu: Main menu bar â†’ Save state
â†’ Reverse/replay settings â†’ Show reverse bar. (This will not
turn off the reverse feature itself.)

If you want to disable the reverse feature, you can use Main menu bar â†’ Save state â†’ Reverse/replay
settings â†’ Enable reverse/replay or the underlying `reverse stop` console command.
And if you don't want it to restart again anymore, uncheck the Main menu bar â†’ Save state â†’ Reverse/replay
settings â†’ Auto enable reverse `setting`.

If you want to save a very compact recording of what you did, or want to have
the possibility to start off in the middle of a recording, you can save your
complete replay to a file with Main menu bar â†’ Save state â†’ Save
replay or the `reverse savereplay` command. They can
also be loaded of course, with Main menu bar â†’ Save state â†’ Load
replay or `reverse loadreplay`.

### 9.3 Game Trainer

openMSX includes a game trainer system. You start with it by using the GUI
menu: Main menu bar â†’ Tools â†’ Trainer Selector This will open a window in which you
must first select the game you want to use a trainer for from the list of
supported games. When a game is selected, you see the list of cheats displayed
for the game, where you can also toggle the different cheats you want to
activate.

As with most openMSX functionality, the trainers can also be used from the `console`, and even there it is very easy to
use. As always, you could type: `help trainer`, for some basic help.

Suppose you want to cheat on Metal Gear. Then it would be useful to type:
`trainer Metal[TAB]`, which will expand to: `trainer Metal\
Gear`. When you then press enter, you see which cheats are available in
the Metal Gear trainer. You can activate them by typing e.g.: `trainer
Metal\ Gear 1 2 3 4`. This will activate (toggle) the first 4 cheats (as
the list will tell you which is printed after the command: the crosses indicate an
active cheat). You can also use the descriptions instead of the numbers:
`trainer Metal\ Gear "enemy 1 gone" "enemy 2 gone"`. Or, if you want
to activate all cheats you can simply type: `trainer Metal\ Gear
all`.

If this sounds a bit difficult for you, just try it out. It's really much
easier when you actually work with it.
As always in the console, using TAB to complete your commands and their options
proves to be very useful!

### 9.4 Debug Device

This chapter describes how an MSX programmer can use the openMSX built-in debug
device. This is an artificial MSX device that is connected to an MSX I/O port.
It can be used to send debug messages to the host operating system.

Note that openMSX also contains built-in debugging functions, which can be
accessed with the `debug` console command. With that debugger
you can read and write all registers and memory of almost all devices that are
supported in openMSX. It also supports break points, watch points and stepping.
See the Main menu
bar â†’ Debugger menu for the most common debugging options.

## 9.4.1 Enabling the Debug Device

To enable the debug device, insert the `debugdevice` extension. To
do this when starting openMSX, simply add `-ext debugdevice` to the
openMSX command line. If openMSX is already running, you can use the
`ext`
console command.

You can use the `Debug Device output` setting to specify the
file name to write the debug output to.

## 9.4.2 Output Ports

Controlling the device is done from within an MSX program. For this purpose, the
output ports 0x2E and 0x2F are used. The first port is the Mode Set Register.
Bytes sent to this port have the following meaning.

**bit(s) | meaning**
- 7 -- unused
- 6 -- line feed mode (0 = line feed at mode change, 1 no line feed)
- 5-4 -- output mode (0 = OFF, 1 = single byte, 2 = multi byte)
- 3-0 -- mode-specific parameters (see below)

When using mode 1, single byte mode, the lower 4 bits each enable a particular
output format:

**bit(s) | meaning**
- 3 -- ASCII mode on/off
- 2 -- decimal mode on/off
- 1 -- binary mode on/off
- 0 -- hexadecimal mode on/off

So, every parameter bit turns an output format on or off and more than one
output format can be specified at the same time.

The parameters for mode 2 (multi byte mode) are as follows:

**bit(s) | meaning**
- 3-2 -- unused
- 1-0 -- mode (0 = hex, 1 = binary, 2 = decimal, 3 = ASCII mode)

## 9.4.3 Single Byte Mode

In mode 1, any write to port 0x2F will result in output. This way, the
programmer can see if a specific address is reached by adding a single
`OUT` to the code. The output depends on the parameters set with the
mode register. Each bit represents a specific format, and by turning the bits
on and off, the programmer can decide which formats should be used.

Here is an example:

LD A,65
OUT ($2f),A

This will give the following output:

41h 01000001b 065 'A' emutime: 36407199578

(when all bits are on, mode register = 0x1F)

or

41h 065 'A' emutime: 36407199578

(when the binary bit is off, mode register = 0x1D)

or

41h emutime: 36407199578

(when only the hexbit is on, mode register = 0x11)

and so on.

The EmuTime part is a special number that keeps track of the openMSX emulation.
The larger this number is, the later the event took place. This is a great way
to get an idea of the timing of things.

If the character to print is a special character, like carriage return,
linefeed, beep or tab, the character between the ' ' will be a dot (.) and the
normal character is 'displayed' at the very end of the line, so it won't mess up
the layout of the whole line.

## 9.4.4 Multi Byte Mode

Unlike mode 1, the data in this mode is always shown in one mode only. It's
either in hex mode, binary mode, decimal mode or ASCII mode, but never a
combination. Also the EmuTime bit is left out.

Here is an example:

LD A,xx
OUT ($2e),A
LD A,$41
OUT ($2f),A
OUT ($2f),A
OUT ($2f),A

If we substitute `$20` for `xx`, we get:

41h 41h 41h

and if we substitute `$22` for `xx`, we get:

065 065 065

The extra zero is added to keep alignment. Finally, if we want ASCII
output, all we need to do is change `xx` for `$23`:

AAA

In this special case, the space in between the data is left out. Any special
character like carriage return, linefeed, beep or tab will be printed as you
would expect.

### 9.5 Programmable Device

This chapter describes briefly the built-in programmable device, a resource that
could prove useful for driver or hardware developers writing and debugging
software on openMSX instead of a real MSX. The programmable device is a virtual
MSX device that can be connected on the fly to a user-defined list of I/O ports.
It can be used to create a two-way communication between the virtual computer
and the host operating system by using the high-level Tcl language that openMSX
provides. It goes without saying that you must know how to use the Tcl language
to use this feature.

Note that this is not intended to be used as a drop-in replacement for
resource-intensive hardware like VDPs. Tcl is overall a very slow language, but
a programmable device opens up possibilities for using openMSX as a development
tool that were not possible before.

Note there's some overlap between this device and the `debug watchpoint add read_io/write_io`
command. Both can be used to make Tcl react to I/O read/write operations. This
device is more suited for completely new functionality. The debug command is
more suited to intercept communication with existing MSX devices.

## 9.5.1 Enabling the Programmable Device

To enable the programmable device, insert the `programmabledevice`
extension. To do this when starting openMSX, simply add
`-ext programmabledevice` to the openMSX command line. If openMSX is
already running, you can use the
`ext` console command.

## 9.5.2 Device Ports and callbacks

Device ports are a list of I/O ports connected between the guest computer and
the Tcl environment. This means that anything a Z80 assembly program sends to
one of these I/O ports using an OUT instruction automatically calls an "output
callback" (a Tcl procedure) to receive the data on the Tcl side. You must
declare your own output callback, otherwise the programmable device will do
nothing when it receives a byte. Your callback must have two parameters: port
and value (2 8-bit values) the return value from this callback is ignored.

Alternatively, anything a Z80 assembly program reads from one of these I/O ports
using an IN instruction automatically calls an "input callback" on the Tcl side.
That callback produces the value that will be received by the Z80. You also must
declare your own input callback, otherwise the programmable device will return
0xFF. An input callback receives a (8-bit) port number as the only parameter,
and it must return an 8-bit value.

The third kind of callback you can create is the "reset callback". This one has
no parameters and the return value is ignored. It can be useful for setting back
an initial state when the MSX reboots.

You can check the 4 settings that Programmable Device uses with the `help` command, but briefly:

``set` {Programmable Device
ports} {6 7}`

tracks I/O ports 6 and 7.

``set` {Programmable Device
reset callback} "my_reset_proc"`

connects the reset event with your previously declared "my_reset_proc" callback.

``set` {Programmable Device
output callback} "my_output_proc"`

connects the "OUT instruction" event with your previously declared
"my_output_proc" callback.

``set` {Programmable Device
input callback} "my_input_proc"`

connects the "IN instruction" event with your previously declared
"my_input_proc" callback.

### 9.6 SDCC Debugger

openMSX includes the SDCC Debugger called sdcdb, a Tcl script that mimics GDB (GNU Debugger) and allows you to inspect programs compiled with the Small Device C Compiler (SDCC) from the console. You just need to compile your SDCC code with the `-debug` flag to create a CDB file with symbols and their respective addresses and then call `sdcdb open <directory>` where the CDB file and source code are. Now you can inspect the program while it executes. For instance, to create a breakpoint at file `main.c`, line 155 from your source code, you can type:

`sdcdb break main.c:155`

A SDCDB breakpoint is a regular breakpoint and it can be listed with the `debug breakpoint list` command. When a breakpoint is triggered, you can inspect the source code around it with command `sdcdb info`. There are two commands that executes code step by step. The first is `sdcdb step`, which executes C code line by line and goes inside function calls. It is equivalent to the `step_in` command from the console. The second is `sdcdb next`, which executes C code line by line but doesn't go inside function calls. It is equivalent to the `step_over` command from the console. The useful `sdcdb laddress <address>` will display source code under the given memory address since sdcdb is aware of the program's source code, like GDB. You can type `help sdcdb` for more details or check out the comments in `sdcdb.tcl` script for more examples.

## Manual do Usuario - 10. Contact Info

### 10. Contact Info

Because openMSX is still in heavy development, feedback and bug reports are very
welcome!

If you encounter problems, you have several options:

1. Go to our IRC channel: #openMSX on libera.chat
and ask your question there. Also reachable via webchat (https://web.libera.chat/#openMSX)! If you don't get a reply
immediately, please stick around for a while, or use one of the other contact
options. The majority of the developers lives in time zone GMT+1. You may get
no response if you contact them in the middle of the night...
2. Post a message on the openMSX forum on MRC (http://www.msx.org/forum/semi-msx-talk/openmsx).
3. Create a new issue in the
openMSX issue tracker (https://github.com/openMSX/openMSX/issues)
on GitHub.
You need a (free) log-in on GitHub to get access.
4. Contact us and other users via one of the mailing lists. If you're a regular
user and want to discuss openMSX and possible problems, join our
`openmsx-user` mailing list.
If you want to address the openMSX developers directly, post a message to the
`openmsx-devel` mailing list.
More info on the
openMSX mailing lists (https://sourceforge.net/p/openmsx/mailman),
including an archive of old messages, can be found at SourceForge.

In any case, try to give as much information as possible when you describe your
bug or request.

## Diskmanipulator - General Syntax

### General Syntax

The general command syntax is always of the form:

`diskmanipulator <command> <disk name>
<command arguments>`

`<command>` specifies the action to be performed. The next section lists the commands available and explains them.

`<disk name>` specifies the disk to operate on. Typical values are: `diska`, `diskb`, `hda` or the special `virtual_drive` device. `disk<x>` and `hd<x>` are the drives available to the running emulated MSX machine. This allows interaction with the currently used disk images.

In case the disk contains a Sunrise IDE, Beer IDE 1.9RC1 or Nextor compatible partition table you can add a partition number (starting at 1) to the disk name to specify on which partition the command will act. For example `hda2` is the second partition on the master IDE disk, `hdb3` is the third partition on the slave IDE disk.

`<command arguments>` depend upon the command involved, see the detailed descriptions of the commands below.

The diskmanipulator and all its commands (including most parameters) can be tab completed in the console.

## Diskmanipulator - Commands

### Commands

These are the commands understood by the diskmanipulator:

### chdir

**syntax:**

`diskmanipulator chdir <disk name> <MSX
directory>`

**explanation:**

This command selects the directory on the MSX disk image
that will be used for the `export` and `import` commands.

Note: The directory structure on the MSX disk image cannot be tab
completed.

### create

**syntax:**

`diskmanipulator create <dskfilename>
<size|option> [<size|option> ...]`

**explanation:**

You can create new disk images using this command.

This new disk will be formatted using an MSX-DOS2 boot sector by default,
an MSX-DOS boot sector if you specify the option `-dos1`,
or a Nextor boot sector if you specify the option `-nextor`.

If a size of 360 kB or 720 kB is given, a normal floppy disk image is
created, single or double sided respectively. Any larger value will result
in a Sunrise IDE hard disk image, or a Nextor one if the `-nextor`
option is specified.

You can specify multiple sizes in which case a Beer IDE 1.9, Sunrise IDE
or Nextor compatible partitioned image will be created, see
`partition` for more
information. Each partition will be formatted as required.

You can specify the disk/partition sizes by using the
following postfixes:

- S or s -> size in sectors
- B or b -> size in bytes
- K or k -> size in kilobytes (default)
- M or m -> size in megabytes

### dir

**syntax:**

`diskmanipulator dir <disk name>`

**explanation:**

This will show the directory content of the current working
directory. The output is formatted similarly to the MSX Disk BASIC 2.x command `files,l`.

### export

**syntax:**

`diskmanipulator export <disk name> <host
directory>`

**explanation:**

This will export the files and subdirectories from the disk
inserted in `<disk name>` to the `<host directory>` on
your host OS. The subdirectory that will be exported from the MSX
disk image is selected by the `chdir` command.

### format

**syntax:**

`diskmanipulator format <disk name> [<size|option>]`

**explanation:**

The currently selected partition from `<disk name>` will
be cleanly formatted with a MSX-DOS2 boot sector, unless the option
`-dos1` is specified. If the `-nextor` option is
specified it will use the Nextor boot sector, and use FAT16 if the size is
larger than 32 MB.
FAT and directory sectors will be correctly initialised.
Any data on the disk image / partition is lost!

### import

**syntax:**

`diskmanipulator import <disk name> <host
directory|host file> ...`

**explanation:**

This will import the single `<host file>` into the disk
inserted in `<disk name>`. In case of a `<host
directory>` it will import the files and subdirectories in
`<host directory>` into the inserted disk. Multiple files and
directories can be specified at the same time. The place were the
files will be added in the MSX directory structure is selected
by the `chdir` command.

If you want to use wildcards when importing files, you will have to use
the Tcl glob (http://www.tcl.tk/man/tcl8.5/TclCmd/glob.htm) command. This command will perform the wildcard
expansion and return a Tcl list. Enclose the `glob` command in
between '[' and ']':

`diskmanipulator import hda1 [glob *.txt] [glob
*.asc]`

This command will copy all files matching `*.txt` and `*.asc` in
the current directory on the host OS to the first partition of
the master IDE drive on the emulated MSX.

The `glob` command can also take extra options. For instance, if
you only want to expand regular files and not the names of
directories you can do this:

`diskmanipulator import hda1 [glob -type f
info*]`

Consult your local Tcl guru or documentation for more info
about the `glob` command and Tcl lists.

### mkdir

**syntax:**

`diskmanipulator mkdir <disk name> <MSX
directory>`

**explanation:**

This command will create the specified directory on the MSX disk image.
All the needed parent directories will be created if they do not
yet exist.

### partition

**syntax:**

`diskmanipulator partition <disk name>
[<size|option> ...]`

**explanation:**

You can (re)partition existing disk images using this command.

As many partitions as specified will be created, using one of the
following partition table formats according to the option given:

- `-dos1`: Standard MBR, Beer IDE 1.9 and Nextor compatible.
Max 4 partitions.
- `-dos2` (default): Sunrise IDE MBR, Sunrise IDE compatible.
Max 31 partitions.
- `-nextor`: Standard MBR / EBR, Nextor compatible.
Max 256 partitions.

After partitioning each partition will also be formatted appropriately,
see format for more details on that.

You can specify the disk/partition sizes by using the following
postfixes:

- S or s -> size in sectors
- B or b -> size in bytes
- K or k -> size in kilobytes (default)
- M or m -> size in megabytes

### savedsk

**syntax:**

`diskmanipulator savedsk <disk name>
<dskfilename>`

**explanation:**

This simply reads all the sectors of the `<disk name>` and
saves them again in the file specified by `<dskfilename>`.
This command is mostly equivalent to copying a disk image file on your host OS, but it has the additional possibilities:

- saving a ramdsk (see `diska ramdsk`) into a real disk image file
- saving your current DirAsDisk image into a real disk image file
- saving your disk image which has undergone IPS patches as a patched disk image
- copying the currently active image file in case your host OS would give sharing violations while the file is being used by openMSX (Windows)
- saving a disk image if you removed the directory entry by accident, but openMSX still has an open file handle for the file (UNIX-like systems)

## Diskmanipulator - Examples

### Examples

In these examples we will run the diskmanipulator while the
emulated MSX is powered off.
It is possible to run these commands while the machine is
turned on of course, but be warned that this might have some
strange, unexpected behaviour depending on the emulated MSX model
and the running software on this MSX.

For instance, the turboR models contain a physical switch
inside their diskdrives to detect disk changes. If no disk change
is detected their internal MSX-DOS2 kernel will cache certain
sectors, so that files imported using the `diskmanipulator import`
command will not show up if you perform a `files` or
`dir`. Even worse, if you would write from the
emulated MSX to the disk you will overwrite the result of the import.
The same would happen if you were running a disk cache
program in your emulated MSX machine.

### creating a new disk with content

Here we create a regular 720 kB (double sided, double density)
disk. Then we place the files and subdirectories from the directory
`/tmp/todisk/` on this new disk:

`set `power` off`
`diskmanipulator `create` /tmp/new-disk.dsk 720`
``virtual_drive` /tmp/new-disk.dsk`
`diskmanipulator `import` virtual_drive /tmp/todisk/`

### creating a new harddisk image with content

Here we create a new HD image with 3 partitions the first
partition is 32 MB, then 16 MB and finally a small
one of 720 kB.
Then we place the files and subdirs of the directory
`/tmp/topart1/` on the first partition and `/tmp/topart3/` on the third partition:

`set `power` off`
``ext` ide`
`diskmanipulator `create` /tmp/new-hd.dsk 32M 16M 720`
``hda` /tmp/new-hd.dsk`
`diskmanipulator `import` hda1 /tmp/topart1`
`diskmanipulator `import` hda3 /tmp/topart3`

### importing data in a new subdirectory

On the diskimage `/tmp/disk.dsk` we will create a new
subdirectory called `newsub` and then we fill this subdirectory with the
`.txt` files from `/home/david/sources`:

`set `power` off`
``diska` /tmp/disk.dsk`
`diskmanipulator `mkdir` diska newsub`
`diskmanipulator `chdir` diska newsub`
`diskmanipulator `import` diska [glob -type f /home/david/sources/*.txt]`

### extracting files from an MSX harddisk image to the host OS

We will extract files from the currently used harddisk image on
partition1 in the MSX subdir `\demos\calculus` to `/tmp/`:

`set `power` off`
``ext` ide`
`diskmanipulator `chdir` hda1 /demos/calculus`
`diskmanipulator `export` hda1 /tmp`

## Controle Externo - Introduction

### Introduction

Despite that openMSX now has an internal GUI that can control most of the
emulator's functionality, it is still possible for debugger GUIs, launcher
GUIs, etc., to be external programs that control openMSX. This document
explains you how you can control openMSX from your own application.

Note: This document was written for developers who are interested in writing their own application that
controls openMSX, rather than normal end-users.

Disclaimer: it is possible that some update events are still missing and it
is also possible that the structure of the replies and commands change. We
will do our best to be backwards compatible, though.

## Controle Externo - Connecting

### Connecting

There are multiple ways to connect to openMSX. The first (and oldest) way
is using a pipe. Non-Windows systems use `stdio`, in Windows you can use a named pipe.
To enable this, start openMSX like this:

`openmsx -control stdio`

or for Windows:

`openmsx -control pipe`

The second method is using a socket. Connecting on non-Windows systems
is done with a UNIX domain socket. openMSX puts the socket in
`/tmp/openmsx-<username>/socket.<pid>`. The
`/tmp/` dir can be overridden by environment variables
`TMPDIR`, `TMP` or `TEMP` (in that order).

On Windows (which does not support UNIX domain sockets), the socket is a
normal TCP socket. The port number is random between 9938 and 9958. This is done
to enforce applications to deal with multiple running openMSX processes. The
port number will be put in the following text file:

`%USERPROFILE%\Documents and Settings\<username>\Local Settings\Temp\openmsx-default\socket.<pid>`

or, when `%USERPROFILE%` does not exist:

`%TMPDIR%\openmsx-default`, or

`%TMP%\openmsx-default`, or

`%TEMP%\openmsx-default`, or as a last resort:

`C:\WINDOWS\TEMP`

After connecting, openMSX expects XML input on the channel and it will
also give you output. This is explained in the next section.

## Controle Externo - Communication

### Communication

After connecting, openMSX expects XML input on the channel (pipe or socket)
and it will also give you output in XML format. The first output it gives is this:

<openmsx-output>

On non-Windows systems you can easily try it out by just starting openMSX
via the `stdio` method, as explained above. You give XML
commands via the keyboard in the terminal and openMSX will print its
responses on the terminal as well.

This first output is the opening tag (`<openmsx-output>`).
All messages that are normally printed on stdout in the
terminal from which you start openMSX are in a `<log>` tag.
The level can be "info" or "warning" and the message is in the text node
itself.

When you want to start communicating back, you always have to start
with the opening tag first:

`<openmsx-control>`

When starting openMSX with the `-control` option, it will not show a
window: it starts with the 'none' renderer. So, a nice example (if you're
still experimenting on the command line) would be to type this:

`<command>set renderer SDL</command>`

With the `<command>` tag you can give any openMSX console
command to openMSX. The commands are documented in the Console Commands Reference.

Every `<command>` will result in a reply from openMSX. In
the above case it will be:

<reply result="ok">SDL</reply>

The order is maintained, i.e. the replies will be in the same order as
the commands you gave to openMSX. In this reply example, you see that
the command succeeded (result=ok) and it also gives you the actual result
text that would be printed on the console. In this case, the value of
the renderer setting. When a command fails, you get something like this:

<command>biep</command>
<reply result="nok">invalid command name "biep"
</reply>

"biep" is not a valid command, and openMSX tells you this via a "nok" reply
with the error message in the text node.

The next important thing is events. When you use this interface to control
openMSX, you want to know when things change. For this, you can enable events
for certain event classes.

An example:

`<command>openmsx_update enable led</command>`

This command will enable updates about LED events. When a LED changes, you'll
get messages such as:

<update type="led" machine="machine1" name="power">on</update>

<update> tags are openMSX's way of telling you that something
changed. In this case, it is a LED update, for the machine with ID
"machine1". The name of the LED is "power" and the value is in the text node:
on.

Here is a list of the currently available event types and when they are sent:

- `hardware` -- hardware changes occurred, like a change of machine
- `led` -- LED status changed
- `media` -- media (disk images, cartridges, etc.) changed
- `plug` -- a pluggable got plugged or unplugged (empty value)
- `setting` -- the value of a setting changed
- `setting-info` -- the properties of a setting changed (e.g. number of options changed)
- `status` -- status changed, currently only pause and debug break status
- `extension` -- extensions changed (add/remove)
- `sounddevice` -- sounddevices changed (add/remove)
- `connector` -- connectors changed (add/remove)

### Update Examples

Someone changed machines from Boosted MSX2 to Toshiba HX-10 at run time:

<update type="hardware" name="machine2">add</update>
<update type="hardware" machine="machine2" name="carta">add</update>
<update type="hardware" machine="machine2" name="cartb">add</update>
<update type="hardware" machine="machine2" name="cassetteplayer">add</update>
<update type="hardware" machine="machine1" name="diskb">remove</update>
<update type="hardware" machine="machine1" name="diska">remove</update>
<update type="hardware" machine="machine1" name="carta">remove</update>
<update type="hardware" machine="machine1" name="cartb">remove</update>
<update type="hardware" machine="machine1" name="cartc">remove</update>
<update type="hardware" machine="machine1" name="cassetteplayer">remove</update>
<update type="hardware" name="machine1">remove</update>
<update type="hardware" name="machine2">select</update>

CAPS LED went to OFF:

<update type="led" machine="machine2" name="caps">off</update>

A tape was inserted in the cassette player:

<update type="media" machine="machine2" name="cassetteplayer">/home/manuel/msx-soft/tapes/Zoids.zip</update>

The cassetteplayer got into play mode:

<update type="status" machine="machine2" name="cassetteplayer">play</update>

Someone plugged in a joystick:

<update type="plug" machine="machine2" name="joyporta">msxjoystick1</update>

And unplugged it again:

<update type="plug" machine="machine2" name="joyporta"></update>

The maxframeskip setting was set to 12:

<update type="setting" name="maxframeskip">12</update>

openMSX got paused:

<update type="status" name="paused">true</update>

openMSX entered a debug break state:

<update type="status" machine="machine1" name="cpu">suspended</update>

openMSX exited the debug break state:

<update type="status" machine="machine1" name="cpu">running</update>

A Philips NMS-1205 Music Module was inserted:

<update type="sounddevice" machine="machine2" name="Philips NMS 1205 Music Module MSX-Audio 8-bit DAC">add</update>
<update type="connector" machine="machine2" name="audiokeyboardport">add</update>
<update type="sounddevice" machine="machine2" name="Philips NMS 1205 Music Module MSX-Audio DAC">add</update>
<update type="sounddevice" machine="machine2" name="Philips NMS 1205 Music Module MSX-Audio">add</update>
<update type="extension" machine="machine2" name="Philips_NMS_1205">add</update>

And with this, you should have all info that you need to make any external
application that can control openMSX.

More real world examples can be found here:

- in the Contrib directory of openMSX (openmsx-control*)
- in the code of (the now deprecated) openMSX Catapult (C++ via pipe)
- in the code of the never released newer openMSX Catapult (Python, still via pipe)
- in the code of the (now deprecated) openMSX GUI Debugger (C++ via socket)

## Referencia de Comandos - Introduction

### Introduction

This manual describes all commands and settings which are available in openMSX. You can use them to control openMSX fully from the Console (a built-in command-line interface, use F10 to call it), via Tcl scripts and via remote connections (explained in Controlling openMSX from External Applications). If you want to unleash the full potential of openMSX or just want a reference of all available possibilities, this manual should serve you well.

## Referencia de Comandos - Commands

### after

Execute a command after a certain event occurs, for example a given amount of time has passed or the emulator has been idle for a given amount of time.
Every postponed command executes just once; if you want a command to run periodically, you have to issue it again every time it runs.
The `after` command returns the id of the postponed command.
It is possible to query a list of
postponed commands and also to cancel postponed commands.

**usage:**

- `after time <seconds> <command>` -- Execute a command after some time. Timescale is in MSX seconds.
- `after realtime <seconds> <command>` -- Execute a command after some time. Timescale is in host seconds.
- `after idle <seconds> <command>` -- Execute a command after being idle for some time
- `after frame <command>` -- Execute a command when a video frame is finished
(VDP scanning reaches vsync)
- `after break <command>` -- Execute a command after a breakpoint is reached
- `after boot <command>` -- Execute a command after a (re)boot
- `after machine_switch <command>` -- Execute a command after switch to new a machine
- `after quit <command>` -- Execute a command after receiving a quit event, while openMSX shuts down.
- `after <input-event> <command>` -- Execute a command after the given input event occurs. The events are e.g. mouse, joystick, focus and resize events, the same ones as for the `bind` command.
- `after info` -- List all postponed commands
- `after cancel <id>` -- Cancel the postponed command with given id

**examples:**

`after time 2.6 "set renderer SDLGL-PP"`
`after idle 100 exit`
`after info`
`after cancel after#2`
`after "mouse button1 down" foo`

### bind / unbind / bind_default / unbind_default / activate_input_layer / deactivate_input_layer

Associate events (such as key presses) with commands. Whenever the
specified event occurs (e.g. you press the specified key), the corresponding
command will be executed. Any Tcl command or combination of commands
separated with `;` (normal Tcl syntax) can be used. To customise your
bindings you should use the (un)bind commands. A script that wants to provide
a default binding for its functionality needs to use `bind_default`,
this allows users with different preferences to overrule the default
bindings. Using the `-repeat` option makes sure that if the event is
repeated (e.g. keyboard events when keeping a key pressed), the command is
repeated as well.

Tcl scripts that need a whole set of bindings and only conditionally
activate those bindings can use the 'input layer' system. It's possible to
associate a binding with a specific layer and later specific layer(s) can be
activated or deactivated. Such a layer can also be activated in a blocking
mode. Blocking mode means that even if the layer didn't have a binding for a
certain event, that event is still not passed to the emulated MSX. This can
be useful to implement certain OSD widgets (like a virtual OSD keyboard).

Events can be:

- `<key>[,release]` -- Short for `keyb <key>[,release]`
- `keyb <key>[,release]` -- <key> is pressed [or released]
- `mouse button<n> <up/down>` -- Mouse button <n> went up or down
- `mouse motion <x> <y>` -- Mouse motion of <x> and <y>
- `joy<n> button<m> <up/down>` -- Button <m> of joystick <n> went up/down
- `joy<n> axis<m> <value>` -- Axis <m> of joystick <n> got value <value>
- `focus <boolean>` -- The openMSX window got (1) or lost (0) focus
- `OSDcontrol <button> PRESS|RELEASE` -- The virtual OSDcontrol <button> got pressed or released.

**usage:**

- `bind` -- Show all bindings
- `bind -layer <layername>` -- Show all in a specific layer
- `bind <event> [-layer <layername>]` -- Show binding for the given event, optionally you can specify a layer
- `bind <event> [-layer <layername>] [-repeat] <command>` -- Make a new binding. Optionally make this binding in a specific layer.
Also optionally it's possible to retrigger this binding periodically
(e.g. when a key is kept pressed).
- `bind -layers` -- Show the names of all layers that currently have bindings
- `unbind [-layer <layername>] <event>` -- Undo binding for this event (optionally in a specific layer).
- `unbind -layer <layername>` -- Undo all bindings in the specified layer
- `activate_input_layer` -- Show a list of the currently active layers.
- `activate_input_layer [-blocking] <layername>` -- Activate the specified input layer, optionally this layer can be
activate in blocking mode.
- `deactivate_input_layer <layername>` -- Deactivate the specified input layer.

**examples:**

`bind PAGEUP "set speed 100"`
`bind PAGEDOWN "set speed 50"`
Only run in fastforward-mode while F9 is pressed (like BrMSX):
`unbind F9`
`bind F9 "set fastforward on"`
`bind F9,release "set fastforward off"`
Pause when window loses focus (like fMSX):
`bind "focus 0" "set pause on"`
`bind "focus 1" "set pause off"`
Middle-click to toggle input grabbing:
`bind "mouse button2 down" "toggle grabinput"`
Map button 8 of joystick 1 to F2-key:
`bind "joy1 button8 down" "keymatrixdown 6 0x40"`
`bind "joy1 button8 up" "keymatrixup 6 0x40"`
Use PageUp/Down to increase/decrease emulation speed.
`bind PAGEUP -repeat "incr speed 1"`
`bind PAGEDOWN -repeat "incr speed -1"`
Use Joystick hat left/right to increase/decrease volume.
`bind "joy1 hat0 left" -repeat "incr speed -5"`
`bind "joy1 hat0 right" -repeat "incr speed 5"`
Toggle fullscreen with ALT and ENTER.
`bind ALT+RETURN "toggle fullscreen"`
React to joystick or cursor up movement in a Tcl script:
`bind_default "OSDcontrol UP PRESS" -repeat {osd_menu::menu_action UP }`
React to joystick button 1 or spacebar press in a Tcl script:
`bind_default "OSDcontrol A PRESS" -repeat {osd_menu::menu_action A }`

### cart / cart<x>

Insert a ROM cartridge in a running MSX. The `cart` command inserts the cartridge in the first available slot. The `carta`, `cartb` etc. commands insert it in the specified slot. The cartridges can be removed again with the `eject` subcommand.

ROM cartridges are a special class of extensions. For extensions that are not ROM cartridges, see the commands `ext`, `list_extensions` and `remove_extension`.

**usage:**

- `cart KMARE.ROM` -- Insert ROM cartridge in first free slot
- `cart insert KMARE.ROM` -- Insert ROM cartridge in first free slot
- `carta USAS.ROM -ips USAS.IPS` -- Insert ROM cartridge in slot A, with IPS patch applied to the ROM contents
- `cartb NEMESIS.ROM -romtype Konami` -- Insert ROM cartridge in slot B, and explicitly specify the mapper type (is normally auto detected)
- `carta eject` -- Eject the currently inserted cartridge from slot A

### cassetteplayer

Controls the openMSX cassette player. The various subcommands can be used to insert, remove, create and rewind tape images.

**usage:**

- `cassetteplayer insert <tape image>` -- Insert tape image (WAV, CAS or TSX format) in the cassette player
- `cassetteplayer eject` -- Remove tape from virtual cassette player
- `cassetteplayer rewind` -- Rewind the current tape
- `cassetteplayer motorcontrol on|off` -- Selects whether motor control signal (remote) is obeyed (default: on)
- `cassetteplayer new [<tape image>]` -- Create new tape image and go to record mode
- `cassetteplayer play` -- Go to play mode (when in record mode) and rewind the tape

### cd<x>

Change the CDROM image. The commands `cda`, `cdb` etc. are assigned to all available CDROM drives in the MSX. They will not
correspond to drive names as used in MSX-DOS.

**usage:**

- `cda <iso image>` -- Use ISO image for CDROM drive "cda"
- `cda insert <iso image>` -- Use ISO image for CDROM drive "cda"
- `cda eject` -- Eject CDROM from CDROM drive "cda"
- `cda` -- Show current ISO image for CDROM drive "cda"

### cycle / cycle_back

Iterates through the values of an enumerated setting.

`cycle_back` does the same as `cycle`, but it goes in the opposite direction.

**usage:**

- `cycle <setting>` -- Changes the specified setting to the next value in the cycle
- `cycle_back <setting>` -- Changes the specified setting to the previous value in the cycle

**examples:**

`cycle scale_algorithm`
`cycle videosource`

### debug

This command provides access to the debugger functionality of openMSX. It's meant to be used by an external debugger (see also Controlling openMSX from External Applications). The general format of the debug command is:

`debug <subcommand> [<extra arguments>]`

where 'extra arguments' are specific for each subcommand. Below is a list of the most common subcommands (deprecated commands are not listed):

- `debug list` -- Return a list of all debuggables.

A debuggable is (part of) the state of an MSX device that can be accessed
via these debug commands.

Examples are:

the VDP registers
the currently visible memory for the Z80
the contents of the RAM
- `debug desc <name>` -- Return a description of this debuggable
- `debug size <name>` -- Return the size of this debuggable
- `debug read <name> <addr>` -- Read a byte from a debuggable
- `debug write <name> <addr> <val>` -- Write a byte to a debuggable
- `debug read_block <name> <addr> <size>` -- Read a whole block at once
- `debug write_block <name> <addr> <values>` -- Write a whole block at once
- `debug break` -- Break CPU at current position
- `debug breaked` -- Query CPU break status
- `debug cont` -- Continue execution after break
- `debug step` -- Execute one instruction
- `debug breakpoint <subcommand>` -- Breakpoint related commands. Type `help debug breakpoint` for more details.
- `debug watchpoint <subcommand>` -- Watchpoint related commands. Type `help debug watchpoint` for more details.
- `debug watchexpr <subcommand>` -- Watch expression related commands. Type `help debug watchexpr` for more details.
- `debug condition <subcommand>` -- Condition related commands. Type `help debug condition` for more details.
- `debug probe <subcommand>` -- Probe related commands. Type `help debug probe` for more details.
- `debug disasm [<addr>]` -- Disassemble instructions at PC or given address

This command is much better documented in openMSX itself. Type `help debug` or `help debug <subcommand>` for more detailed help.

Many examples of usage of the debug command can be found in the scripts that come with openMSX (in the `share/scripts` directory). We also list a few here.

**examples:**

break (only!) after 0 is written to 0x8000):

`debug watchpoint create write_mem 0x8000 {[debug read "memory" 0x8000] ==
0x00}`
break on address 0xF37D, but only when Z80 register C has the value 0x2F:

`debug breakpoint create 0xF37D {[reg C] == 0x2F}`
break when CPU reads from any addresses between 0xFBE5 and 0xFBEF:

`debug watchpoint create read_mem {0xFBE5 0xFBEF}`
break after a write was done to I/O port 0x99, but only when Z80 register A has a value of 0x81:

`debug watchpoint create write_io 0x99 {[reg A] == 0x81}`
break as soon as there is a pending Z80 IRQ (even when in DI mode):

`debug probe set_bp z80.pendingIRQ`
break when register HL has the value 1234:

`debug condition create {[reg hl] == 1234}`

Note: Some of the commands are pretty low level. In the share/scripts directory you'll find some Tcl scripts that
offer convenience wrappers around these commands. For example: `showmem`, `disasm`, `cpuregs`, `save_debuggable`, etc.

### disk<x> / virtual_drive

Insert a disk image in a drive. Optionally apply an IPS patch to the disk image.
The commands `diska`, `diskb` etc. are
assigned to all available "physical" disk drives in the MSX. They might not correspond to drive names as used in
MSX-DOS.

In addition to the physical `disk<x>` drives, there is the `virtual_drive`. This fake drive does not correspond to any MSX hardware. It can be used as a source or target for `diskmanipulator` operations just like physical drives.

**usage:**

- `diska <disk image>` -- Insert disk image in drive "diska"
- `diskb insert <disk image>` -- Insert disk image in drive "diskb"
- `diska <disk image> <ips>` -- Insert disk image and apply IPS patch
- `diska eject` -- Remove disk from drive "diska"
- `diska ramdsk` -- Insert scratch disk in drive "diska"

### diskmanipulator

A collection of commands to manipulate (the files on) a disk image.

It can be used in so many different ways, that we wrote a separate manual for it: Using Diskmanipulator.

### escape_grab

Only has effect in windowed mode and when the `grabinput` setting is active. Temporarily release the input grab.
After the openMSX window has lost and regained the focus, the grab is again effective.

**usage:**

- `escape_grab` -- Temporarily release the input grab

### exit

Terminate the openMSX application. Optionally you can pass an exit-code.

**usage:**

- `exit [exit-code]` -- Exits the emulator

### ext / ext<x>

Insert an MSX extension in a running MSX machine. The `ext` command inserts the extension in the first available slot. The `exta`, `extb` etc. commands insert it in the specified slot. The extension can be removed again with the `remove_extension`
command. See also the commands `cart`, `list_extensions` and `remove_extension`.

To get a list of possible extensions it's convenient to use the tab-completion feature, i.e. type '`ext<space><tab>`'. Alternatively the command '`openmsx_info extensions`' gives you the same information (and is easier to use in a scripting context).

Note that some extensions (i.e. those without any memory) will not physically occupy any slot when inserted, even when they were inserted in a specific slot.

**usage:**

- `ext fmpac` -- Insert an FMPAC in a running MSX machine in the first free slot
- `extb scc` -- Insert the empty SCC cart in slot B of the running MSX machine

### filepool

With this command you can manage your file pool settings. File pools are directories on your host system (PC/Mac/Dingoo/etc.). They are used by openMSX to search files in, which are referred to from machine or extension definition files, save states or replays which you are trying to load. First, the file will be searched at the path that was also used when the save state or replay was created. But if it isn't found there (which is usually the case if you load such a state or replay you got from someone else), it will use the file pools to search instead. In other words, if you are trying to load such replays, it's probably a good idea to put the media files referred to (ROMs, disks, tapes) in the (proper) file pool.

File pools have the following properties:

**path:** The path to the directory which is the actual file pool
**position:** There exists a list of file pools, which are searched in order of their position.
**type(s):** A file pool can serve specific types. Currently, the valid types are

`system_rom`
for system ROMs, you are probably using this one already if you installed your system ROMs in the recommended place `share/systemroms`,
`rom`
for other ROM files,
`disk`
for disk images and
`tape`
for cassette/tape images.

Apart from the default system ROM file pool as mentioned above, the other default file pool is `share/software`, which is configured for all other (than type `system_rom`) software files.

**usage:**

- `filepool list` -- Shows the currently defined file pool entries (see below for example output)
- `filepool add -path <path> -types <typelist> [-position <pos>]` -- Add a new entry with the given properties as explained above. For the types, use a format like `"rom tape disk"`. Optionally, you can also specify where in the list of existing file pools the new file pool should be added. By default, this is at the end.
- `filepool remove <position>` -- Remove the file pool at the given position
- `filepool reset` -- Reset the file pool settings to the default values

An example of the default file pools for a Windows 7 system with user Quibus:

1: C:/Users/Quibus/Documents/openMSX/share/systemroms [system_rom]
2: C:/Users/Quibus/Documents/openMSX/share/software [rom disk tape]
3: C:/Program Files/openMSX/share/systemroms [system_rom]
4: C:/Program Files/openMSX/share/software [rom disk tape]

The first one is the system ROMs dir in the user's home directory. The second is the software file pool for other software in the user's home directory. The last two are similar, but then on system level. On a UNIX like system, you get something very similar.

### findcheat

This is a tool to find new cheats, for example for a certain game it can help you find the memory location where the number of remaining lives is stored. These cheats can later be added to the `trainer` command.

It works more or less like this:

1. Initialize the `findcheat` tool, this takes an initial snapshot of the MSX memory.
2. Perform some action in the game that changes the variable that you're interested in. For example if you want to find the memory location where the number of lives is stored, you have to loose (or gain) a life in the game.
3. Now use the `findcheat` tool to compare the current MSX memory state with the previous memory snapshot. `findcheat` offers a lot of possibilities here, for example you can search for memory locations that became bigger or smaller or locations whose value changed or didn't change.
4. `findcheat` will show a list of memory locations that still match the search criteria.
5. If there still are still too many matches, repeat from step 2.

Vampier made a video tutorial on how to use `findcheat`, you can find it here (http://www.youtube.com/watch?v=F11ltfkCtKo).

### hd<x>

Change the hard disk image. The commands `hda`, `hdb` etc. are assigned to all available hard disk drives in the MSX. They will not correspond to drive names as used in MSX-DOS.

**usage:**

- `hda <disk image>` -- Use hard disk image for hard disk "hda"
- `hda insert <disk image>` -- Use hard disk image for hard disk "hda"
- `hda` -- Show current hard disk image for hard disk "hda"

Note: Because of disk caching, changing the hard disk when the MSX is running can lead to corruption of the hard disk contents. Therefore openMSX blocks the `hd<x>` commands unless the MSX is powered off. See `power` setting.

### help

Shows help info for console commands.

**usage:**

- `help` -- Shows a list of all possible commands
- `help <command>` -- Shows help info for a specific command
- `help <command> <subcommand>` -- Some commands have more detailed help on subcommands

### incr

Increment an integer setting.

**usage:**

- `incr <setting>` -- Increment the specified setting by one
- `incr <setting> <num>` -- Increment the specified setting by the given amount (can be negative)

**examples:**

`incr speed`
`incr renshaturbo 10`
`incr scanline -5`

### iomap

Shows what I/O ports are connected to which devices. The related command `slotmap` shows a similar overview, but for memory-mapped devices.

**usage:**

- `iomap` -- Shows the I/O map of the current MSX machine

### keymatrixdown / keymatrixup

Press or release keys in the MSX keyboard matrix. Can be used to make an external program or Tcl script press MSX keys. For some more information about the keymatrix, you could read the article on the MAP (http://map.grauw.nl/articles/keymatrix.php).

**usage:**

- `keymatrixdown <row> <mask>` -- Press the indicated MSX keys
- `keymatrixup <row> <mask>` -- Release the indicated MSX keys

**examples:**

`keymatrixdown 6 0x01`
`keymatrixup 6 0x01`

### laserdiscplayer

Controls the Laserdisc player; a Laserdisc can be inserted or ejected. When a real Laserdisc player is connected to an MSX, no other controls are available either.

Note that this command is only available when the Pioneer PX-7 or Pioneer PX-V60 MSX machine is being emulated

**usage:**

- `laserdiscplayer insert <filename>` -- Inserts the specified file into the virtual laserdisc player.
- `laserdiscplayer eject` -- Ejects the laserdisc from the virtual laserdisc player; this emulates pressing the eject button on a real Laserdisc Player.

### list_extensions

Returns a list of inserted cartridges and extensions. These can be removed with the `remove_extension` command or
additional items can be added with the `cart` and `ext` commands.

**usage:**

- `list_extensions` -- Lists all currently inserted cartridges and extensions

### load_settings

Load settings from a given settings XML file. The settings file does not have to be complete: settings that are not mentioned in the given file are left untouched. See also `save_settings`.

**usage:**

- `load_settings <filename>` -- Load settings from the given file

### machine

Switch to a new MSX machine.

**usage:**

- `machine` -- Returns the handle for the currently active machine
- `machine <machine name>` -- Switch to the specified machine, also returns the handle for that machine

Note: The machine handle is mostly used by external applications controlling openMSX (see also Controlling openMSX from External Applications). For interactive use you can omit the machine handle to have the commands operate on the current machine.

### create_machine / load_machine / activate_machine / list_machines / delete_machine

openMSX has the possibility to have multiple MSX machines concurrently in memory. This is more or less like multiple tabs in a web browser: you only work with one at-a-time, but you can have multiple open at the same time and easily switch between them. These commands are low level commands to manage this.

Some commands are specific per machine, for example if you insert a disk image into the disk drive of the emulated MSX machine and if you have multiple MSX machines, you need to specify in which MSX machine you want to insert the disk. To solve this, we introduced the concept of the 'active' MSX machine (this is also the machine that is visible and audible). All unqualified machine-specific command will act on the active machine. If you want to execute the command in a specific machine, you can qualify the command with a machineID prefix.

- `diska <diskimage>` -- execute the diska command in the active machine
- `<machine-ID>::diska <diskimage>` -- execute the diska command in the specified machine

## create_machine:

This command returns a new machine-id. This machine-id can be used in the following commands. In the web browser analogy this command would open a new empty tab.

## load_machine:

This command loads a machine configuration (= MSX model) into the given machine-ID.
In the web browser analogy, this command would load a page in a previously created empty tab. And unlike a web browser, where you can reload a different page in the same tab, you can only load a machine configuration once in the same machine-ID.

## activate_machine:

This command activates the given machine-ID. At any time there can only be one active machine-ID. This is analogue to switching tabs in a web browser.

## list_machines:

Returns a list of all currently existing machine-IDs.

## delete_machine:

Deletes the given machine-ID. This is analogue to closing a tab in a web browser.

## examples:

- `set oldID [machineID]` -- get the current machineID
- `set newID [create_machine]` -- create a new machineID
- `$newID::load_machine Philips_NMS_8250` -- load an MSX2 configuration in that new machineID
- `activate_machine $newID` -- switch to the new machine
- `activate_machine $oldID` -- switch back to old machine
- `delete_machine $newID` -- delete new machine

**Nota:** If you don't care about multiple active machines, the `machine` command is much more convenient to switch to a different MSX configuration.

### machine_info

Shows information about a certain topic. This command is similar to the `openmsx_info` command. The topics of
`machine_info` are all machine specific, while the topics of `openmsx_info` are generic.

**usage:**

- `machine_info` -- Shows a list of all possible topics
- `machine_info <topic>` -- Shows info on the given topic

### message

Show a message, with optional level (info, warning, error). By default this message will be shown in a coloured box at the top of the screen for a (short) duration and then fade away.

**usage:**

- `message <text> [<level>]`

**examples:**

`message "Hello world!"`
`message "Something bad happened" error`

### monitor_type

Select a monitor color profile.

**usage:**

- `monitor_type` -- Shows the currently selected color profile
- `monitor_type -list` -- Lists all available color profiles
- `monitor_type <profile>` -- Selects a new color profile

Note: This command is a convenience wrapper around the `color_matrix` setting.

### mute_channels / unmute_channels / solo

Mute or unmute specific individual channels of sound devices. The syntax is very similar to the `record_channels` command.

**usage:**

- `mute_channels <device> [<channels>]] [<device> [<channels>]]` -- Mute the specified channels of the specified device(s). If a device is given but no specific channels are specified, all channels of that device are muted. If no arguments are given at all, this command return a list of all currently muted channels.
- `unmute_channels <device> [<channels>]] [<device> [<channels>]]` -- Unmute the specified channels of the specified device(s). If a device is given but no specific channels are specified, all channels of that device are unmuted. If no arguments are given at all, this command unmutes all channels of all devices.
- `solo <device> [<channels>]] [<device> [<channels>]]` -- Mute all channels of all devices except for the specified channels.

**examples:**

`mute_channels`
`mute_channels PSG`
`mute_channels SCC 2,4`
`unmute_channels`
`unmute_channels PSG 1 SCC 1,3-4`
`solo PSG 3`

### nowind<x>

Similar to the `disk<x>`
commands there is a `nowind<x>` command for each nowind
interface. This command is modelled after the 'usbhost' command of the real
nowind interface. Though only a subset of the options is supported. Here's a
short overview of the command-line options:

**long | short | explanation**
- --image -- -i -- specify disk image
- --hdimage -- -m -- specify harddisk image
- --romdisk -- -j -- enable romdisk
- --ctrl -- -c -- no phantom disks
- --no-ctrl -- -C -- enable phantom disks
- --allow -- -a -- allow other diskroms to initialize
- --no-allow -- -A -- don't allow other diskroms to initialize

If you don't pass any arguments to this command, you'll get an overview of
the current nowind status.

This command will create a certain amount of drives on the nowind
interface and (optionally) insert diskimages in those drives. For each of
these drives there will also be a
`nowind<x><1..8>`
command created. Those commands are similar to e.g. the
`diska`
command. They can be used to access the more advanced diskimage insertion
options.

In some cases it is needed to reboot the MSX before the changes take
effect. In those cases you'll get a message that warns about this.

**examples:**

- `nowinda -a image.dsk -j` -- Image.dsk is inserted into drive A: and the romdisk will be drive B:.
Other diskroms will be able to install drives as well. For example when
the MSX has an internal diskdrive, drive C: en D: will be available as
well.
- `nowinda disk1.dsk disk2.dsk` -- The two images will be inserted in A: and B: respectively.
- `nowinda -m hdimage.dsk` -- Inserts a harddisk image. All available partitions will be mounted
as drives.
- `nowinda -m hdimage.dsk:1` -- Inserts the first partition only.
- `nowinda -m hdimage.dsk:2-4` -- Inserts the 2nd, 3th and 4th partition as drive A: B: and C:.

### openmsx_info

Shows information about a certain topic. For machine-specific topics, use the related command `machine_info`.

**usage:**

- `openmsx_info` -- Shows a list of all possible topics
- `openmsx_info <topic>` -- Shows info on the given topic

### openmsx_update

Enable or disable update notifications of a certain type. This command is intended for external programs controlling openMSX. More about this in Controlling openMSX from External Applications.

**usage:**

- `openmsx_update enable <type>` -- enable notifications for this type
- `openmsx_update disable <type>` -- disable notifications for this type

**examples:**

`openmsx_update enable led`
`openmsx_update disable setting`

### osd

openMSX has the possibility to show OSD (on screen display) elements. For example, the game overlays and TAS tools are implemented via OSD elements. This command allows to create new OSD elements, configure existing elements or delete elements.

This command is only useful if you plan to adjust or enhance the openMSX OSD, or create your own OSD widgets.

Execute "`help osd`" to get a detailed description of this command, which we will not repeat here.

### palette

Shows the current VDP palette settings. Related command: `vdpregs`.

**usage:**

- `palette` -- Show the currently active color palette

### plug / unplug

Plugs or unplugs a plug into a connector, for example plug a virtual joystick into a virtual joystick port.

**usage:**

- `plug` -- Shows all currently connected plugs
- `plug <connector>` -- Shows currently connected plug for the specified connector
- `plug <connector> <plug>` -- Plugs the specified plug into the specified connector
- `unplug <connector>` -- Unplugs the plug connected to the specified connector

**examples:**

`plug cassetteport cassetteplayer`
`plug joyporta mouse`
`plug printerport logger`
`unplug joyportb`

### psg_profile

Select a PSG sound profile.

**usage:**

- `psg_profile` -- Shows the currently selected sound profile
- `psg_profile -list` -- Lists all available sound profiles
- `psg_profile <profile>` -- Selects a new sound profile

Note: This command is a convenience wrapper around the `PSG_vibrato_frequency`, `PSG_vibrato_percent`, `PSG_detune_frequency` and `PSG_detune_percent` settings.

### record

Controls video recording: write openMSX audio/video to an AVI file.

**usage:**

- `record start` -- Record to file "openmsxNNNN.avi"
- `record start <filename>` -- Record to indicated file
- `record start -prefix foo` -- Record to file "fooNNNN.avi"
- `record stop` -- Stop recording
- `record toggle` -- Toggle recording

The `start` subcommand also accepts an optional `-audioonly`, `-videoonly`, `-doublesize` and a `-triplesize` flag. Videos are recorded in a 320Ã—240 size by default, at 640Ã—480 when the `-doublesize` flag is used and 960Ã—720 when using the `-triplesize` flag.
If only audio is recorded, the created file will be a WAV file instead of an AVI file.

If any stereo sound devices are present or any sound device has an off-center balance, the recording will be made in stereo, otherwise it will be mono.
If a recording is made in mono and then a stereo sound device is added, you'll receive a warning that stereo sound has been detected and that the two channels will be mixed down to mono.
You can prevent this from happening by using the `-stereo` option to force a stereo recording even if no stereo devices are present at the time you enter the command.
You can also force a mono recording with `-mono` to save space.

The `soundlog` command is a shorthand for `record -audioonly`.

Use `record_chunks` if you want some extra options. You can control the maximum length (in seconds) to record and also set up multiple recordings of a certain length. This is very useful if you want to record for e.g. YouTube. The default length is 14:59 (to make sure YouTube will accept it). Using this command implies `-doublesize`.

Use `record_chunks_on_framerate_changes` if you want to split up the recording in several files, whenever the frame rate of the MSX changes. An AVI file cannot contain video of multiple frame rates, so sound and video will get out of sync if that happens without using this special version of the command. Do not specify the target filename with this variant, or openMSX will record all chunks to the same file.

### record_channels

A high level command to record individual channels of sound chips to separate files. In the following variants of the command you can specify devices and channels. Multiple devices can be specified and multiple channels as well. If you want to specify channels of a device, put them right after the device. You can also specify `all` for the device, which means that all sound devices in the currently running MSX will be recorded. When starting recording, an option `-prefix` can be given to specify a filename prefix.

**usage:**

- `record_channels [start] <device> [<channels>] [<device> [<channels>]] [-prefix <prefix>]` -- Start recording the specified channel(s) of the specified device(s). If no channels are given, all channels of the device are recorded.
- `record_channels stop [<device> [<channels>]] [<device> [<channels>]]` -- Stop recording the specified channel(s) of the specified device(s). If no channels are given, recording for all channels is stopped for the given device(s). If no devices are given, all channel recording is stopped.
- `record_channels all -prefix justtesting` -- Record all channels of all sound devices and create the file names with prefix 'justtesting' (e.g. to quickly delete all these files again).
- `record_channels list` -- Lists which channels of which sound chips are currently being recorded.

**examples:**

`record_channels start PSG`
`record_channels PSG`
`record_channels SCC 1,4-5`
`record_channels SCC PSG 1`
`record_channels "MSX Music" 7-9 SCC 3,5 PSG 2`
`record_channels stop`
`record_channels stop PSG`
`record_channels stop SCC 3,5`
`record_channels list`

### remove_extension

Remove a cartridge or extension from a running MSX machine. See also the commands `cart`, `ext`, `list_extensions`.

**usage:**

- `remove_extension fmpac` -- Removes the FMPAC extension from the running MSX

### reset

Emulates the pressing of the reset button on the MSX. This sends a reset pulse to all devices, but does not erase memory contents.

**usage:**

- `reset` -- Resets the current machine

### reverse

Controls the reverse feature. When this feature is enabled (the default), openMSX will collect data while emulating, which enables you to go back (and forward) in MSX time. In other words: you cannot use the commands to go back and forward in time, if you disable the feature.

**usage:**

- `reverse start` -- Start collecting data (enable the reverse feature).
- `reverse stop` -- Stop collecting data (disable reverse feature) and remove all collected data.
- `reverse status` -- Gives information about the reverse feature and the data it collected. Mostly useful for scripts.
- `reverse goback <n>` -- Go back <n> seconds in time. Of course, you cannot go back to a time before the time the `reverse start` command was given.
- `reverse viewonlymode <on|off>` -- Control the view only mode of the reverse feature. In view only mode, the replay will never get interrupted by any user actions that normally would interrupt the replay. Use this to safely view a replay without accidentally ruining it by touching a key.
- `reverse goto <time>` -- Go to the indicated absolute moment in MSX time (given in seconds). If the time is before the time openMSX started collecting data (with the `reverse start` command) openMSX will jump to the time when collecting started.
- `reverse truncatereplay` -- Stop replaying and wipe all replay data that is in the future (so after **now**). This is useful if you are hindered by the future events somehow, for instance when you are playing a game and jumped too early and therefore reversed. Be careful with this, as there is no way to recover this future. If you are at time 0, it means your whole replay will be gone after executing this command!
- `reverse savereplay [<filename>]` -- Save the collected data (an initial savestate and all collected input events) to a file.
- `reverse loadreplay [-goto <begin|end|savetime|<n>>] [-viewonly] <filename>` -- Load the replay from the given file and start it. It loads the initial snapshot, starts replaying the recorded events, and enables the reverse feature automatically. With the `-goto` option, you can specify where to jump to in the replay after loading (`begin` is default), where `savetime` is the time at which the replay was saved and `n` is an absolute time in seconds in the replay. The `-viewonly` option is a shortcut to put the reverse feature in viewonly mode directly after loading the replay. Without this option, it will always go to normal mode.

There are some extra helper commands to make the feature easier to use.

**usage:**

- `go_back_one_step` / `go_forward_one_step` -- Go back or forward one second (at normal speed) in time (if possible). These are used for the default PageUp and PageDown key bindings.
- `reverse_prev [<min> [<max>]]` -- Go back in time to the previous (internal) snapshot. The further back in the past the less dense the amount of snapshots are. So, executing this command multiple times, will take successively bigger steps in the past. You can optionally specify a minimal and maximal step size. You will at least go back the minimal amount of time (even if there's a snapshot closer to the current time) and at most the maximal amount of time (even if there's no snapshot within the maximum specified time from the current time).
- `reverse_next [<min> [<max>]]` -- As `reverse_prev` but then it goes to the closest snapshot in the future (if possible).

Because the reverse feature is very useful, it is automatically enabled via `auto_enable_reverse` setting.

### save_settings

Write the current openMSX settings to a settings XML file. See also `load_settings`.

If you disabled `save_settings_on_exit`, you can use this command to save your preferences.

**usage:**

- `save_settings` -- Save settings to the default settings file
- `save_settings <filename>` -- Save settings to the given file

### savestate / loadstate / list_savestates / delete_savestate

These commands can be used to manage savestates. These are much easier to use than the lowlevel `store_machine` and `restore_machine` commands.

## savestate [<name>]

This creates a snapshot of the currently emulated MSX machine. Optionally you can specify a name for the savestate, if you omit this name, the default name `quicksave` will be taken.

## loadstate [<name>]

This restores a previously created savestate. Like above you can specify a name which defaults to `quicksave` if omitted.

## list_savestates

This returns the names of all previously created savestates.

## delete_savestate <name>

Delete a previously created savestate.

### screenshot

Take a screenshot of the openMSX screen. By default this takes a screenshot of the 'scaled' MSX screen (see `scale_algorithm` setting) without OSD/GUI elements (e.g. console and icons). If you want to include the GUI and OSD elements pass the `-with-osd` option. If you want a screenshot of the 'unscaled' raw MSX screen, pass the `-raw` option. The screenshots are PNG files and (by default) are saved in the `screenshots` subdirectory of the openMSX data directory in your home directory. There's also an option `-no-sprites` to take a screenshot with sprite rendering disabled.

**usage:**

- `screenshot [-with-osd] [-raw [-size <width>]] [-no-sprites] [-prefix <prefix>] [<filename>]`

**examples:**

- `screenshot` -- Write screenshot to file "openmsxNNNN.png"
- `screenshot <filename>` -- Write screenshot to indicated file
- `screenshot -prefix foo` -- Write screenshot to file "fooNNNN.png"
- `screenshot -raw` -- Create screenshot of the raw MSX screen only (so no icons or console and no scaling)
- `screenshot -raw -size auto` -- Create screenshot of the raw MSX screen only, with resolution dependent on the displayed MSX screen mode
- `screenshot -raw -size 320` -- Create screenshot of the raw MSX screen only, with resolution 320Ã—240
- `screenshot -raw -size 640` -- Create screenshot of the raw MSX screen only, with resolution 640Ã—480
- `screenshot -with-osd` -- Create screenshot of the scaled screen, including OSD elements
- `screenshot -no-sprites` -- Create screenshot with sprite rendering disabled

### set

Change or query the value of various settings. See also: `unset`.

**usage:**

- `set <setting>` -- Query the current value of the specified setting
- `set <setting> <value>` -- Change the specified setting to the given value

The settings that can be adjusted with this command are listed and explained `later` in this document.

**examples:**

`set accuracy pixel`
`set blur 25`
`set scanline 20`
`set deinterlace on`

### setup

Switch to a previously saved setup.

**usage:**

- `setup <setup name>` -- Switch to the specified setup, which you have saved before with the GUI or the `store_setup` command. Also returns the handle of the new machine.

Note: The machine handle is mostly used by external applications controlling openMSX (see also Controlling openMSX from External Applications). For interactive use you can omit the machine handle to have the commands operate on the current machine.

### slotmap

Shows what devices are inserted into which slots. The related command `iomap` shows a similar overview, but for I/O mapped devices.

**usage:**

- `slotmap` -- Shows the slot map of the current MSX machine

### slotselect

Shows the currently selected slots. To see what devices are located in the slots, use the `slotmap` command.

**usage:**

- `slotselect` -- Shows the currently selected slot for each page

### soundlog

Controls sound logging: writing the openMSX sound to a WAV file.

This command is a shorthand for `record -audioonly`.

**usage:**

- `soundlog start` -- Log sound to file "openmsxNNNN.wav"
- `soundlog start <filename>` -- Log sound to indicated file
- `soundlog start -prefix foo` -- Log sound to file "fooNNNN.wav"
- `soundlog stop` -- Stop logging sound
- `soundlog toggle` -- Toggle sound logging state

### store_machine / restore_machine

These are low-level commands, used to implement savestates.

## store_machine:

Saves the state of the specified machine to a file.

- `store_machine <machineID> <filename>` -- Save state of indicated machine to specified file

## restore_machine:

Load a previously saved machine in a new machine-ID, next to the already available machines. See the section on `activate_machine`.

- `restore_machine` -- Load state from last saved state in default directory
- `restore_machine <filename>` -- Load state from indicated file

Note: These commands are pretty low level. The `savestate` and `loadstate` scripts are built on top of this and are much more convenient to use.

### store_setup

Store the current setup in a file.

- `store_setup [depth] <filename>` -- Save the setup with the given depth to specified file

If the filename isn't specified, openMSX creates a unique one for you, based on the name of the machine. The depth argument is mandatory and must be one of the following.

**`machine`:** Save only the machine. This isn't too useful... but you can use it to give your favourite machine your own setup name
**`extensions`:** Save the machine with all plugged in extensions
**`connectors`:** As previous, but also include plugged in equipment in its connectors
**`media`:** As previous, but also include inserted media in its media slots
**`complete_state`:** As previous, but also include the run time state. This is basically identical to a savestate

Storing the current setup can also be done with the GUI via Main menu bar
â†’ Machine â†’ Save setup.

### test_machine / test_all_machines / test_all_extensions

Test whether the given MSX machine configuration works. For example whether you have all required system ROMs for this machine. See also `load_machine`. This is an alternative to using the equivalent option in the GUI Main menu bar
â†’ Machine â†’ Test MSX hardware

**usage:**

- `test_machine <machine-config>` -- Test whether the given machine configuration is OK.

Use the convenience commands `test_all_machines` and `test_all_extensions` to get a full overview on which system ROMs you are still missing.

### toggle

Toggles any boolean (on/off) setting: if it was on, it will be turned off and vice versa.
See also: `cycle`.

**usage:**

- `toggle <setting>` -- Toggles the specified setting

**examples:**

`toggle mute`
`toggle throttle`

### trainer

Control game trainers. You can enable or disable individual cheats of each trainer. Make use of the TAB key to see
what is available. When switching trainers, the currently active trainer will be deactivated.

**usage:**

- `trainer` -- See which trainer is currently active
- `trainer <game>` -- See which cheats are currently active in the trainer
- `trainer <game> all` -- Activate all cheats in the trainer of <game>
- `trainer <game> [<cheat> ..]` -- Toggle cheats of <game> on/off
- `trainer deactivate` -- Deactivate all trainers

**examples:**

`trainer Frogger all`
`trainer "Circus Charlie" 1 2`
`trainer Pippols lives "jump shoes"`

### type / type_via_keyboard

Type a string in the emulated MSX. This command automatically presses and
releases keys in the simulated MSX keyboard matrix. This command is useful
for demoing and for automating tasks in MSX-BASIC.

The command has a `-release` option, with which you can specify
that keys are always released before new ones are pressed. Some game input
routines need this, but it also makes typing twice as slow.

With the `-freq` option, you can tweak how fast typing goes and
how long the keys will be pressed (and released if the `-release`
option is used). Keys will be typed at the given frequency and will remain
pressed/released for 1/freq seconds.

With the `-cancel` option, you can cancel a (long) in progress
type command.

This command should always work, because it is just like as if a user was
actually typing on the MSX keyboard. It is therefore a bit slow, though.
Check out the `type_via_keybuf` command if you're looking for
something faster (but more limited in where it works). With the
`default_type_proc` setting you can even make
`type_via_keybuf` the standard implementation for the
`type` command. Only do this if you really know what you're
doing!

**usage:**

- `type "Hello world!"` -- Yet another manifestation of the most famous program
- `type "PRINT \"Hi!\"\r"` -- Executes this basic command directly

There are also a few scripts extending this command:

- `type_from_file` -- With this command you can automatically type text which is stored in
the given (text) file. Mostly useful if you want to type in some
BASIC program fragment that you found somewhere and pasted in a
text file.
- `type_password_from_file` -- A special version of `type_from_file`, made to type in
passwords of games, which you have stored in a file. The text
file should have a special format: one password per line, lines
starting with # are ignored. After the filename, you can give the
index of the password to type (which is the index of the first
non-comment and non-blank line in the file).

### unset

Undefines a Tcl variable. When used on openMSX settings, they are reverted to their default value. See also: `set`.

**usage:**

- `unset <variable>` -- Undefines the given variable
- `unset <setting>` -- Reverts the given setting to its default value

### user_setting

This command is only meant to be used in Tcl scripts. It allows to create Tcl variables that act very much like built-in openMSX settings. They have a description (can be queried with "`help set <setting-name>`") and their value is stored saved/restored when openMSX is quit/restarted.

Execute "`help user_setting`" to get a detailed description of this command.

### vdpregs

Shows the current register settings of the Video Display Processor (VDP). Related command: `palette`.

**usage:**

- `vdpregs` -- Shows the current VDP control register contents

### other

Most commands described above are generally useful. openMSX also has a bunch of other more specialized commands. Some of these are intended for programmers who code MSX programs using openMSX as a tool. Other of these commands are more like toys or examples that show the openMSX scripting capabilities.

We've only listed a very brief overview of these commands. As always execute "`help <command-name>`" to get a more detailed description of the command.

- `about` -- Search command and setting help-texts for the given keyword
- `cpuregs` -- Gives an overview of the CPU registers
- `data_file` -- Helps locate openMSX data files
- `disasm` -- Print disassembled instructions at the given memory location
- `getcolor` -- Query V99x8 palette settings
- `get_active_cpu` -- Returns the active cpu, z80 or r800
- `get_color_count` -- Gives an overview of the used colors in the current screen
- `get_screen` -- Capture the content of an MSX text screen in a Tcl string
- `get_screen_mode` -- Decodes the current screen mode from the VDP registers and returns it as a Tcl string. `get_screen_mode_number` returns it as a number which would also be used for the basic command `SCREEN`.
- `get_selected_slot` -- Returns the selected slot for the given memory page
- `guess_title` -- Use heuristics to guess the title of the current game (cartridge, disk or tape). For specific media use `guess_cassette_title`, `guess_disk_title` or `guess_rom_title`.
- `listing` -- Reimplementation of the BASIC LIST command in Tcl
- `load_debuggable` -- Write the content of a file to a openMSX debuggable
- `multi_screenshot` -- Take screenshots of multiple successive frames
- `pc_in_slot` -- Check whether CPU is executing from the specified slot (useful as breakpoint condition)
- `peek` -- Read a byte from the given memory location
- `peek16` -- Read a 16 bit word from the given memory location
- `poke` -- Write a byte to the given memory location. Use `dpoke` to only write if the value to be written is different from the current value.
- `poke16` -- Write a 16 bit word to the given memory location
- `psg_log` -- Log or replay PSG register values in binary format
- `ram_watch` -- Add or remove RAM watch addresses to/from the list on the right side of the screen, useful for debugging or tool assisted speedrunning (TAS)
- `reg` -- Read or write CPU registers
- `reg_log` -- Log or replay register values for the specified debuggable in ASCII format
- `rom_info` -- Gives information about the given ROM device, coming from the software database. If no argument is given, the first found (external) ROM device is assumed. This command replaces the info that was previously (before openMSX 0.8.1) automatically printed on stdout.
- `run_to` -- Execute instructions until the PC reaches the specified address
- `save_debuggable` -- Save the (partial) content of a debuggable to a file
- `save_msx_screen` -- Saves the current MSX screen into an MSX compatible binary file (BLOAD format).
- `save_to_file` -- Helper function to save data (e.g. the output of another command) to a file.
- `setcolor` -- Change V99x8 palette settings
- `set_help_text` -- Associate help text with a Tcl proc
- `set_tabcompletion_proc` -- Associate tab completion with a Tcl proc
- `showdebuggable` -- Print the content of a debuggable in a table
- `showmem` -- Print the content of memory in a table
- `show_osd` -- Print an overview of the defined OSD elements
- `shuffler` -- A basic ROM-game shuffler, that switches between a set of ROM programs in a given folder after a certain time is passed.
- `skip_instruction` -- Skip the current CPU instruction
- `stack` -- Print the top of the CPU stack
- `step_in` -- Execute one CPU instruction, go into subroutines
- `step_over` -- Execute one CPU instruction, but don't go into subroutines
- `step_out` -- Step out of the current subroutine
- `step_back` -- Step one instruction back in time
- `text_echo` -- Echo all printed MSX text on stderr
- `toggle_cursors` -- Show (or hide) a widget which shows which keys are pressed
- `toggle_frame_counter` -- Show (or hide) a widget which shows the current frame number since start-up
- `toggle_freq` -- Switch between PAL/NTSC
- `toggle_mog_overlay` -- Enable (or disable) graphical extra information and game hints when playing The Maze of Galious
- `toggle_mog_editor` -- Enable (or disable) wall drawing and Popolon-placement with the mouse when playing The Maze of Galious; needs to have the MoG overlay enabled, see `toggle_mog_overlay`
- `toggle_music_keyboard` -- Enable (or disable) keyboard view of all existing music channels. EXPERIMENTAL! Be careful, it's very slow when many channels are present in the system
- `toggle_nemesis_1_shield` -- Enable (or disable) an OSD drawn shield in Nemesis (Gradius) 1, all enemy objects will repel from it
- `toggle_psg2scc` -- Enable (or disable) playing PSG sound on SCC
- `toggle_scc_editor` -- Show a graphical view of the SCC chip(s) of the system, showing waveforms and volume per channel and also enables you to edit the waveforms per channel
- `toggle_scc_viewer` -- Show a graphical view of the SCC chip(s) of the system, showing
waveforms and volume per channel. In the future, this will be fully
replaced by Main menu bar â†’ Tools
â†’ SCC viewer.
- `toggle_tron` -- Show (or hide) an OSD implementation of the MSX-BASIC TRON command to trace what the current line number of the BASIC interpreter is
- `toggle_vdp_access_test` -- Enable (or disable) reporting in the console when VDP I/O is done which could possibly cause data corruption on the slowest VDP (TMS9xxx), which is not emulated
- `toggle_vdp_busy` -- Enable (or disable) display on the OSD how busy the VDP is
- `type_via_keybuf` -- Alternative to the `type_via_keyboard` (the default `type` command), that uses the keyboard buffer; only works if the running software uses the standard keyboard buffer functions to get keyboard input, but is much faster
- `umrcallback` -- Example proc to use with the umr_callback setting
- `vdpcmdinprogresscallback` -- Example proc to use with the vdpcmdinprogress_callback setting
- `v9990reg` -- Read or write a V9990 register
- `v9990regs` -- Print an overview of all V9990 registers
- `vdpreg` -- Read or write a V99x8 register
- `vdpstatus` -- Shortcut for reading the VDP status registers
- `vdpvramaddress` -- Gives the current VDP VRAM pointer
- `vdrive` -- Easily switch disks in multi-disk games
- `vgm_rec` -- Record the music played by PSG, MSX-MUSIC, MSX-AUDIO, OPL4 and SCC into a VGM file
- `vpeek/vpoke` -- Read/write bytes from/to video RAM

The source code of all these scripts is located in `share/scripts` directory. Feel free to inspect these scripts and modify them to suit your needs.

## Referencia de Comandos - Settings

### Settings

Settings control many aspects of openMSX. Below, the available settings are listed and described. You can change setting values with the `set` command.

### accuracy

Sets the render accuracy. openMSX supports three levels of render accuracy:

**screen accurate::** Changes in VDP state become effective only once per video frame. Works well for most MSX1 software, but will break a lot of MSX2 software (anything that does so-called raster effects).
**line accurate::** Changes in VDP state become effective only once per display line. Works well for almost all software.
**pixel accurate::** Changes in VDP state become effective immediately. In this mode even the 'Unknown Reality scope part' is rendered correctly.

In some cases switching to a lower accuracy level can speed up emulation, but in many cases the speed difference is negligible.

The default is pixel accuracy, since this is the most realistic. If the software you are running shows a jittery screen split and you would prefer a stable screen split, switching to line accuracy can help.

**usage:**

- `set accuracy` -- Shows the current setting
- `set accuracy screen` -- Selects screen accurate rendering
- `set accuracy line` -- Selects line accurate rendering
- `set accuracy pixel` -- Selects pixel accurate rendering

### audio-inputfilename

Sets the audio file from which the wave input is read for the sampler.

By default, it is read from "audio-input.wav" when available.

**usage:**

- `set audio-inputfilename` -- Shows the current setting
- `set audio-inputfilename mysample.wav` -- Read from "mysample.wav"

Note: The file is fully read into memory, so under Linux/UNIX do not attempt to read from a device node such as `/dev/dsp`.

### autoruncassettes

Switches the "auto-run cassettes" feature on or off. When it's enabled, openMSX will try to type the proper loading
instruction when a cassette is inserted.

**usage:**

- `set autoruncassettes` -- Shows the current setting
- `set autoruncassettes on` -- Try to run cassettes automatically
- `set autoruncassettes off` -- Do nothing when cassettes are inserted

Note: Autorun works practically always for cassette images in the CAS and TSX formats. If that fails or for WAV files, openMSX will try to find a hint of the loading instruction (in upper case) in the filename.

### autorunlaserdisc

Switches the "auto-run laserdisc" feature on or off. When it's enabled, openMSX will try to type the proper loading
instruction when a laserdisc is inserted.

**usage:**

- `set autorunlaserdisc` -- Shows the current setting
- `set autorunlaserdisc on` -- Try to load Laserdiscs automatically
- `set autorunlaserdisc off` -- Do nothing when Laserdiscs are inserted

### auto_enable_reverse

Using the `reverse` feature comes at a small memory and performance cost. Therefore it has to be enabled before it can be used. This setting controls whether the reverse feature should automatically be activated when openMSX starts. While with desktop computers this generally won't be a problem, the performance drop might be more noticeable on older/smaller handheld devices.

**usage:**

- `set auto_enable_reverse` -- Shows the current setting
- `set auto_enable_reverse off` -- Don't automatically enable the reverse feature
- `set auto_enable_reverse on` -- Enable the reverse feature when openMSX starts. Default setting for Desktop/PC

### auto_save_replay

Enable this setting to make automatic backups of your current replay. The replay is saved to the filename specified in the `auto_save_replay_filename` setting (default: "auto_save") at an interval as specified by the `auto_save_replay_interval` setting (default: 30 seconds). The interval is in real clock time, not in MSX time.

### blur

Sets the amount of horizontal blur effect. A value of 0 turns off blur, while 100 selects maximum blur.

**usage:**

- `set blur` -- Shows the current setting
- `set blur <value>` -- Change the value

Note: Only some scale algorithms apply horizontal blur; the default algorithm "simple" does.

### bootsector

Sets the boot sector type for DirAsDSK. Default: DOS2. Only relevant on turboR, because it boots differently
depending on the type of boot sector on the disk in drive A.

**usage:**

- `set bootsector` -- Shows the current setting
- `set bootsector DOS1` -- Use a DOS1 boot sector

### brightness

Controls the brightness of the video output. Can be between -100 and 100. Lower values are darker, higher values are brighter. The default is 0, which is neutral. This setting shifts the brightness of all colours, including black and white, while the `gamma` setting changes the relative brightness of colours but does not change black and white.

The section about the `noise` setting describes a typical way of using `brightness`.

**usage:**

- `set brightness` -- Shows the current setting
- `set brightness 5` -- Make the video output a bit brighter than default

### cmdtiming

Controls VDP command execution timing.

This is useful for debugging and for speeding up games where the command engine performance is a bottleneck.

**usage:**

- `set cmdtiming` -- Shows the current setting
- `set cmdtiming broken` -- Make VDP commands finish instantly
- `set cmdtiming real` -- Make VDP commands take a realistic amount of time

Note: When set to `broken` the emulated MSX acts different from a real MSX. This might cause some software to fail.

### color_matrix

This setting represents a 3Ã—3 matrix that is used to transform MSX RGB colours to host RGB colours. This setting can
be used to generate all kind of colour schemes, see `scripts/monitor.tcl` for examples.

To get the following colour transformation:

| a b c | | Rm | | Rh |
| d e f | Ã— | Gm | = | Gh |
| g h i | | Bm | | Bh |

Use this command:

set color_matrix { { a b c } { d e f } { g h i } }

**usage:**

- `set color_matrix` -- Shows the current value
- `set color_matrix { { 1 0 0 } { 0 1 0 } { 0 0 1 } }` -- This is the default (no colour transformation)
- `set color_matrix { { .33 .33 .33 } { .33 .33 .33 } { .33 .33 .33 } }` -- Transform to grey scale

Note: It is often more convenient to use the `monitor_type` command.

### console

Turns the openMSX on-screen console on or off.

**usage:**

- `set console` -- Shows the current setting
- `set console on` -- Turns the console on
- `set console off` -- Turns the console off

### contrast

Controls the contrast of the video output. Can be between -100 and 100. Lower values are less contrast, higher values are more contrast. The default is 0, which is neutral.

The section about the `noise` setting describes a typical way of using `contrast`.

**usage:**

- `set contrast` -- Shows the current setting
- `set contrast -5` -- Reduce the video contrast a bit

### cputrace

Enable/disable CPU instruction tracing. When enabled, the state of the CPU (Z80/R800) is printed on stdout after every instruction. This creates a lot of output and slows down emulation considerably, but it can be very useful for debugging.

**usage:**

- `set cputrace` -- Shows the current setting
- `set cputrace on` -- Enables CPU tracing
- `set cputrace off` -- Disables CPU tracing

### Debug Device output

Selects the file to where the output from the debug device goes.

The User's Manual describes the debug device in more detail.

**usage:**

- `set {Debug Device output}` -- Shows the current output file name
- `set {Debug Device output} stdout` -- Writes debug output to openMSX's standard output stream
- `set {Debug Device output} stderr` -- Writes debug output to openMSX's standard error stream
- `set {Debug Device output} <output file>` -- Writes debug output to the specified file

Note: This setting only exists if the `debugdevice` extension is present in the current MSX machine.

### default_machine

Selects the default MSX model. openMSX uses this machine when it is started without the `-machine` option and without the `-setup` option and the `default_setup` setting is empty or pointing to a non-existing setup. This is a typical setting that should be saved, see also `save_settings`.

In the GUI, under Main menu bar â†’ Machine
â†’ Setup settings you can also configure what openMSX must do at startup, configuring this setting there.

**usage:**

- `set default_machine` -- Shows current setting
- `set default_machine Panasonic_FS-A1GT` -- Use the turboR GT the next time openMSX is started

### default_setup

Selects the default setup. openMSX uses this setup when it is started without the `-setup` or `-machine` option. By default, this setting is empty, because no setups are shipped with openMSX: they have to be created by users, after which this setting can be set to automatically start that setup that got saved earlier. If it is indeed empty or pointing to a non-existing setup, the value for the `default_machine` setting is used to determine what to start.

In the GUI, under Main menu bar â†’ Machine
â†’ Setup settings you can also configure what openMSX must do at startup, configuring this setting there.

**usage:**

- `set default_setup` -- Shows current setting
- `set default_setup mymsx` -- Use the `mymsx` setup the next time openMSX is started without specifying setup or machine

**Nota:** If you set this setting to the same value as the `save_setup_at_exit_name` setting and have the `save_setup_at_exit_depth` setting set to another depth than `none` , openMSX will automatically continue with the last setup when being started up again (and no other machine or setup is specified).

### DirAsDSKmode

Determine the behaviour of the DirAsDSK when inserting a directory to be used as diskimage.

The possible values are `read_only` and `full`. The default mode is `full`.

- `read_only` -- The MSX can not write to the virtual disk.
Changes on the host-OS are still reflected on the virtual disk, however.
- `full` -- All changes are performed both ways, no restrictions apply.

**usage:**

- `set DirAsDSKmode` -- Shows the current setting
- `set DirAsDSKmode read_only` -- Disk image will be read only

Note: this setting is only used when the directory is inserted, it is not possible to change the behaviour of the current virtual disk by altering the setting. The new setting will become effective after the current virtual disk has been ejected.

### deflicker

Turns deflicker on/off. deflicker is a filter which tries to detect pixels
that alternate each frame between two different colour values and replaces
those alternations with the average colour. It gives a very nice result for
software (mostly demos) that use this technique to get the optical illusion
of more colours than are actually supported by the hardware. It also works
well in games with flickering sprites on a static background (like Maze of
Galious). This setting is disabled by default because there aren't that many
situations where the performance cost justifies the improved video quality.

**usage:**

- `set deflicker` -- Shows the current setting
- `set deflicker on` -- Turns deflicker on
- `set deflicker off` -- Turns deflicker off

### deinterlace

Turns deinterlacing on/off. Deinterlace is a filter which combines the even and odd field of interlaced video into a single frame which has double vertical resolution. It results in a sharp and stable image, but can show artifacts on fast animations.

**usage:**

- `set deinterlace` -- Shows the current setting
- `set deinterlace on` -- Turns deinterlacing on
- `set deinterlace off` -- Turns deinterlacing off

### disablesprites

Can be used to disable sprite rendering. Only the rendering itself is
disabled, all other MSX behaviour (like sprite collision detection) stays
the same.

**usage:**

- `set disablesprites` -- Shows the current setting
- `set disablesprites on` -- Disable sprite rendering
- `set disablesprites off` -- Enable sprite rendering (the default)

### display_deform

Select display deformation effect.

**usage:**

- `set display_deform` -- Shows the current setting
- `set display_deform normal` -- Turns off display deform
- `set display_deform 3d` -- Deforms the image in 3D, to look like a CRT (like JEmu2)

Note: In the past there was also a 'horizontal_stretch' mode. This is now replaced by the `horizontal_stretch` setting.

### di_halt_callback

Selects the Tcl procedure to be called when the running MSX software has executed a HALT instruction while the interrupts are disabled (DI).

The default openmsx startup scripts initialize this setting with a proc that prints a warning message.

**usage:**

- `set di_halt_callback` -- Shows the current setting
- `set di_halt_callback my_callback_proc` -- Sets a new callback proc

### enable_session_management

Controls session management. When enabled, openMSX will store the state of all machines when you exit openMSX and restore that state again when starting it up next time. Note that the reverse history is not saved.

Sessions can also be saved manually with the command `save_session`, and explicitly loaded with `load_session`. A list of saved sessions can be retrieved with `list_sessions`.

### fastforward

Chooses between normal speed (off) and fastforward speed (on).

**usage:**

- `set fastforward` -- Shows the current setting
- `set fastforward on` -- Run at fastforward speed: the `fastforwardspeed` setting determines how fast the emulated MSX runs compared to real time
- `set fastforward off` -- Run at normal speed: the `speed` setting determines how fast the emulated MSX runs compared to real time

### fastforwardspeed

Sets the emulation speed relative to the speed of a real MSX when we are running in fastforward mode. Speed 100 means as fast as a real MSX, lower values are slower than real MSX, higher values are faster than real MSX.

**usage:**

- `set fastforwardspeed` -- Shows current fastforward speed
- `set fastforwardspeed <num>` -- Sets new fastforward speed to <num>% of real time

### frequency

Sets the sound mixer frequency. Sound hardware and sound APIs typically support a limited set of frequencies, such as 11025 Hz, 22050 Hz, 44100 Hz and 48000 Hz.

**usage:**

- `set frequency` -- Shows the current setting
- `set frequency 44100` -- Use 44.1 kHz mixing frequency (CD quality)

### firmwareswitch

Some machines (e.g. turboR) have a switch on the front (or on the back) that controls if the machine should boot
'normally' or start the built-in software, also called firmware. This setting controls the position of that
switch.

**usage:**

- `set firmwareswitch` -- Shows the current setting
- `set firmwareswitch on` -- Boot into the internal software
- `set firmwareswitch off` -- Boot into MSX-BASIC or on-disk software

### fullscreen

Switch to/from fullscreen mode.

**usage:**

- `set fullscreen` -- Shows the current setting
- `set fullscreen on` -- Switch to fullscreen mode
- `set fullscreen off` -- Switch to windowed mode

### fullspeedwhenloading

When enabled, openMSX will try to detect when the MSX is loading from diskette, cassette or laserdisc. During loading openMSX will run at full speed (`throttle` off). This can be convenient if you're not interested in the realistic but slow loading times on MSX. Default is off, because it is not how a real MSX behaves.

Unlike the fast loading features in for example fMSX, `fullspeedwhenloading` does not intercept BIOS calls. Instead, it speeds up the emulation of the entire MSX, including all hardware devices.

**usage:**

- `set fullspeedwhenloading` -- Shows the current setting
- `set fullspeedwhenloading on` -- Load as fast as possible
- `set fullspeedwhenloading off` -- Load at the same speed as a real MSX

### full_stretch

Stretches the image to fill the entire screen when in fullscreen mode. This setting is useful when you want to use the full screen real estate, for example when displaying 4:3 content on a 16:9 monitor, or when you prefer to eliminate any black borders around the image.

**usage:**

- `set full_stretch` -- Shows the current setting
- `set full_stretch on` -- Enable full screen stretching
- `set full_stretch off` -- Disable full screen stretching

### gamma

Sets the amount of gamma correction. A value of 1.0 will turn off gamma correction. Lower values will result in a darker image, higher values in a brighter image.

If you want to get a realistic picture, set the openMSX gamma correction to PC gamma / MSX gamma. TVs use a standardised gamma of 2.5, let's take that as the value of MSX gamma. You can measure the gamma of your PC screen with a simple test such as the Gamma Measurement Image in Robert W. Berger's "An Explanation of Monitor Gamma" (https://web.archive.org/web/20150714015749/http://www.bberger.net/rwb/gamma.html). If your PC gamma would be for example 2.0, the most realistic value for gamma correction would be 2.0 / 2.5 = 0.8.

Alternatively, you can just try a few values and see what you like.

**usage:**

- `set gamma` -- Shows the current value
- `set gamma <num>` -- Sets a new gamma correction amount

### glow

Sets the amount of afterglow effect: 0 is off and 100 is a very heavy afterglow.

**usage:**

- `set glow` -- Shows the current setting
- `set glow <value>` -- Change the amount of afterglow

### grabinput

Controls whether openMSX grabs all input events or not. When this setting is turned on, all input events are directly passed to openMSX. The mouse pointer can't leave the openMSX window and the window manager won't be able to react to keyboard shortcuts.

You can turn this setting on when you want to use mouse-controlled MSX software while openMSX is in windowed mode. It is best turned off in all other cases. See also `escape_grab`.

**usage:**

- `set grabinput` -- Shows the current setting
- `set grabinput on` -- Starts grabbing all input events
- `set grabinput off` -- Stops grabbing all input events

### horizontal_stretch

Sets the amount of horizontal stretch, thus also the aspect ratio of the screen. More specifically, a setting of `n` means stretch the centre `n` MSX pixels to the full width of the host output window (at the virtual `scale_factor` 1).

**usage:**

- `set horizontal_stretch` -- Shows the current setting
- `set horizontal_stretch <value>` -- Change the amount of horizontal stretch

**examples of typical useful values:**

`set horizontal_stretch 320` (no horizontal stretch)
`set horizontal_stretch 272` (approach real aspect ratio of MSX screen)
`set horizontal_stretch 280` (default: show all generated border pixels, so that all border demo effects are still visible)
`set horizontal_stretch 256` (borders are not visible at all; doesn't work well in combination with set-adjust)

### inputdelay

Input events for the MSX machine are delayed by this amount. Increase this value when the MSX machine misses keyboard presses when you type very fast. Decrease this value to reduce the latency between pressing a key on the host machine and seeing it being typed in the MSX machine.

**usage:**

- `set inputdelay` -- Shows the current value
- `set inputdelay <time>` -- Sets the input delay to the specified number of seconds

Note: The default value of 0.0 seconds (no extra delay) should almost
always be OK. It only makes sense to increase this setting if you have
a slow host machine and you're typing text very fast and the emulated
MSX machine misses (some of) the keys you typed.

### interleave_black_frame

Insert a black frame in between each normal MSX frame. Useful on (100Hz+)
lightboost enabled monitors to reduce motion blur and double frame
artifacts.

Make sure you configure your monitor to use a refresh rate of 100Hz (for a
PAL MSX machine) or to 120Hz (for a NTSC machine). The brightness will
decrease, so adjust the `gamma`,
`brightness` and
`contrast` settings to compensate.

**usage:**

- `set interleave_black_frame` -- Shows the current value
- `set interleave_black_frame true` -- Enable this feature.

### invalid_ppi_mode_callback

Selects the Tcl procedure to be called when the running MSX software has selected an invalid PPI mode. Or at least a PPI mode that's not yet correctly emulated. Typically on a real machine these modes will hang the MSX.

The default openMSX startup scripts initialize this setting with a proc that prints a warning message just once. Though if you're a developer you may want to change this to always print the warning or automatically break emulation when this happens so you can debug the problem.

**usage:**

- `set invalid_ppi_mode_callback` -- Shows the current setting
- `set invalid_ppi_mode_callback my_callback_proc` -- Sets a new callback proc

### invalid_psg_directions_callback

Selects the Tcl procedure to be called when the running MSX software has selected invalid PSG port directions (port A should always be set as input).

The default openMSX startup scripts initialize this setting with a proc that prints a warning message just once. Though if you're a developer you may want to change this to always print the warning or automatically break emulation when this happens, so you can debug the problem.

**usage:**

- `set invalid_psg_directions_callback` -- Shows the current setting
- `set invalid_psg_directions_callback my_callback_proc` -- Sets a new callback proc

### msxjoystick<n>_config/joymega<n>_config

This setting configures how the buttons/axis/keys of the host are
mapped to the inputs of the emulated MSX joysticks or JoyMega devices. For many
host controllers the initial value of this setting provides an acceptable default
mapping. But depending on your controller type and taste you may want to tweak
it.

The easiest way to tweak it, is by using the GUI menu under Main menu bar â†’ Settings
â†’ Input â†’ Configure MSX joysticks.

The value of this setting is a Tcl dictionary. This means it's a list of
key/value pairs where each even element is a key and each odd element is the
corresponding value. The keys in this dictionary represent the 6 possible MSX
joystick inputs. Possible key values are `LEFT`,
`RIGHT`, `UP`, `DOWN`, `A` and
`B`. For the JoyMega devices, add `C`, `X`,
`Y`, `Z`, `SELECT` and `START`.
The corresponding dictionary-values are lists of boolean host
inputs. Possible elements for these lists regarding host controller input are
`joy<n> button<m>`, `joy<n> +axis<m>`,
`joy<n> -axis<m>` and `joy<n> hat<m>
left/right/down/up`. But also host keyboard input can be configured
with `keyb <KEYNAME>`, where KEYNAME is the name of a
key.

Let's explain this with an example. The following is the default value for
this setting:

`UP {{joy1 -axis1} {joy1 hat0 up}} DOWN {{joy1 +axis1} {joy1 hat0 down}} LEFT {{joy1 -axis0} {joy1 hat0 left}} RIGHT {{joy1 +axis0} {joy1 hat0 right}} A {{joy1 button0} {joy1 button2} {joy1 button4} {joy1 button6} {joy1 button8} {joy1 button10}} B {{joy1 button1} {joy1 button3} {joy1 button5} {joy1 button7} {joy1 button9} {joy1 button11}}`

Axis 0 is usually the primary X-axis of the host controller's analogue stick.
When that axis is moved towards negative values the LEFT input switch on the
emulated joystick is activated. When it is moved towards positive values the
RIGHT MSX input switch is activated. The D-pad of the detected host
controller is also mapped via the `hat0` events.
Similarly host axis1 is mapped to the UP and DOWN MSX inputs. The (default)
configuration for the buttons is slightly more complicated. Here all even
numbered host buttons (0, 2, etc.) will activate MSX button A, and odd host
button numbers will activate MSX button B.

There are no restrictions on the possible mappings. For example it is
allowed to map host axis/buttons to MSX buttons/axis or vice-versa. This
allows to for example map a host joypad (which acts like 4 buttons, instead of hats) to the
MSX directional inputs. (Technically speaking the MSX axis inputs LEFT,
RIGHT, UP and DOWN are just 4 input switches, just like the buttons A and B
are just 2 input switches). It's also allowed to map the same host action to
multiple MSX inputs. This allows to for example make one specific host button
press both MSX buttons simultaneously (e.g. to have a 'crouch button' in
Metal Gear).

It is possible to set this setting directly using the `set`
command, but often using the Tcl `dict` command is more
convenient. See below for some examples.

**usage:**

- `set msxjoystick1_config` -- Shows the current configuration of the first MSX joystick (there are 2 MSX joysticks defined)
- `dict set msxjoystick1_config A {joy1 button5}` -- (Re)map MSX button A to (only) host button 5 of host joystick/controller 1. Leave the mapping of the
other MSX inputs unchanged.
- `dict set msxjoystick1_config A {{joy1 button0} {joy1 button2}}

dict set msxjoystick1_config B {{joy1 button1} {joy1 button2}}` -- Map joystick/controller 1's button 0 to A, 1 to B and 2 to A+B. So pressing host button 2
will press both MSX buttons.
- `dict set msxjoystick1_config LEFT {{joy2 -axis0} {joy2 -axis2} {joy1 button10}}

dict set msxjoystick1_config RIGHT {{joy2 +axis0} {joy2 +axis2} {joy1 button11}}

dict set msxjoystick1_config UP {{joy2 -axis1} {joy2 -axis3} {joy1 button12}}

dict set msxjoystick1_config DOWN {{joy2 +axis1} {joy2 +axis3} {joy1 button13}}` -- Map 2 pairs of axis and 1 keypad (4 buttons) from host controller/joystick 2 to the MSX direction inputs for MSX joystick 1.
- `dict lappend msxjoystick2_config LEFT {joy1 hat0 left}

dict lappend msxjoystick2_config RIGHT {joy1 hat0 right}

dict lappend msxjoystick2_config UP {joy1 hat0 up}

dict lappend msxjoystick2_config DOWN {joy1 hat0 down}` -- Additionally map hat0 of host controller/joystick 1 to the 4 MSX directions of msxjoystick2.
- `dict lappend msxjoystick2_config LEFT {keyb A}

dict lappend msxjoystick2_config RIGHT {keyb D}

dict lappend msxjoystick2_config UP {keyb W}

dict lappend msxjoystick2_config DOWN {keyb S}` -- Additionally map the W, A, S, D keyboard key presses to the 4 MSX directions of msxjoystick2.

### joystick<n>_deadzone

This setting configures how big the dead centre zone of an (analogue)
joystick is. This is expressed as a percentage: 0 means no dead zone, 100
means everything falls inside the dead zone. The setting is only available
when connected host analogue sticks are detected.

**usage:**

- `set joystick1_deadzone` -- Shows the current size of the dead zone of the first joystick
- `set joystick1_deadzone 25` -- Set the size of the dead zone to Â¼ of the total range

### kbd_auto_toggle_code_kana_lock

Switches the "Automatically toggle the CODE/KANA lock" feature on or off. When it's on, openMSX will
automatically toggle the CODE/KANA lock when a user enters a character for which the CODE/KANA lock
state must be changed.

**usage:**

- `set kbd_auto_toggle_code_kana_lock` -- Shows the current setting
- `setÂ kbd_auto_toggle_code_kana_lockÂ on` -- Automatically toggle the CODE/KANA lock when required
- `setÂ kbd_auto_toggle_code_kana_lockÂ off` -- Only toggle CODE/KANA lock status when user presses the CODE/KANA lock key

Note: This only works on MSX models for which the CODE/KANA key locks (e.g. Japanese MSX models and the Philips VG8010). On other models, this setting is ignored.

### kbd_code_kana_host_key

Host key that maps to the MSX CODE/KANA key. By default right-ALT (RALT) key.

It is especially useful for
people with AZERTY host keyboard, on which the RALT key has a special function; on
azerty keyboards it is called the ALT-GR key and not the right-ALT key and it's used to
enter some special characters (some keys are tagged with 3 characters; normal, key+SHIFT, key+ALT-GR).

It is also useful for people with a Japanese (jp106) keyboard; they can map the HENKAN_MODE key (which is similar to the KANA Lock on Japanese MSX models) to the CODE/KANA key.

**usage:**

- `setÂ kbd_code_kana_host_key` -- Shows the current setting
- `setÂ kbd_code_kana_host_keyÂ MENU` -- Binds the MENU key (http://en.wikipedia.org/wiki/Menu_key) on the host keyboard to the MSX CODE/KANA key
- `setÂ kbd_code_kana_host_keyÂ HENKAN_MODE` -- Binds the HENKAN_MODE key on the host keyboard to the MSX CODE/KANA key

### kbd_deadkey1_host_key

Host key that maps to the (1st) dead key. By default right-CTRL (RCTRL) key.

Some MSX models have one dead key that can be used to enter accented characters. For example the MSX
models sold in the Netherlands have a dead key that has following four accents printed on it: ` Â´ ^ Â¨.
On the other hand, the Brazilian Gradiente Expert XP-800 has following four accents on its
dead key: ` Â´ ^ ~.

There are also some MSX models with multiple dead keys like for example the Brazilian Gradiente Expert Plus,
which has two dead keys and the different Sharp Hotbit models that have three dead keys. On such machines,
this setting is for the first dead key which can be used to enter following two accents: Â´ `.

In order to enter an accented character on the MSX, you first have to press and release the dead key, optionally
together with SHIFT, CODE or CODE+SHIFT and then the correct character. The combination with CODE or CODE+SHIFT is
only relevant for the MSX models with a single dead key that can be used to enter four different accents.

Following table shows for example how to
enter respectively Ã¹, Ãº, Ã» or Ã¼ on the MSX models sold in the Netherlands:

**Key presses | Character**
- DEAD_KEY1 followed by u -- Ã¹
- DEAD_KEY1+SHIFT followed by u -- Ãº
- DEAD_KEY1+CODE followed by u -- Ã»
- DEAD_KEY1+SHIFT+CODE followed by u -- Ã¼

In order to use the dead key in openMSX, you must map an appropriate host key to the DEAD_KEY1 of the MSX and
another one to the CODE key of the MSX with respectively this `kbd_deadkey1_host_key` setting and the above
documented `kbd_code_kana_host_key` setting.

Note that especially the last key combination (DEAD_KEY1+SHIFT+CODE) can be impossible to enter on some
host systems; depending on the host operating system, keyboard type and keyboard driver it may be impossible
for the host system to send a combination of three keys at once to an application like openMSX. Unfortunately
openMSX or its developers can't do anything about that.

**usage:**

- `setÂ kbd_deadkey1_host_key` -- Shows the current setting
- `setÂ kbd_deadkey1_host_keyÂ PAGEUP` -- Binds the PAGEUP key on the host keyboard to the 1st dead key

Note that to use for example PAGEUP as 1st dead key you will have to unbind it from the `go_back_one_step`
command in the console; by default openMSX has bound the PAGEUP key to the `go_back_one_step` command and such
a binding takes precedence over keyboard mappings, so if you want to use PAGEUP as the 1st dead key you will have
to enter following additional command in the console: `unbind PAGEUP`.

### kbd_deadkey2_host_key

Host key that maps to the 2nd dead key. By default Page Up (PAGEUP) key.

This is only applicable to MSX models that have at least two dead keys, like the Brazilian Hotbit models
or the Brazilian Gradiente Expert Plus or other Gradiente models with Gradiente basic version 1.1.

On the Hotbit models, the second dead key can be used to enter accent Â¨ while on the Gradiente 1.1
models, the second dead key can be used to enter following accents: ~ ^.

It can be used in the same manner as the first dead key, explained in previous section.

**usage:**

- `setÂ kbd_deadkey2_host_key` -- Shows the current setting
- `setÂ kbd_deadkey2_host_keyÂ PAGEDOWN` -- Binds the PAGEDOWN key on the host keyboard to the 2nd dead key

Note that to use for example PAGEUP or PAGEDOWN as a dead key you will have to unbind them from the
default functions in openMSX using the console; by default openMSX has bound the PAGEUP key to the
`go_back_one_step` command and the PAGEDOWN key to the `go_forward_one_step` command. Such a binding
takes precedence over keyboard mappings, so if you want to use PAGEUP or PAGEDOWN as the second dead key
you will have to enter following additional commands in the console: `unbind PAGEUP` or
`unbind PAGEDOWN`.

### kbd_deadkey3_host_key

Host key that maps to the 3rd dead key. By default Page Down (PAGEDOWN) key.

This is only applicable to MSX models with at least three dead keys, like the Sharp Hotbit models.

On the Hotbit models, the third dead key can be used to enter following two accents: ~ ^.

**usage:**

- `setÂ kbd_deadkey3_host_key` -- Shows the current setting
- `setÂ kbd_deadkey3_host_keyÂ RCTRL` -- Binds the Right CTRL (RCTRL) key on the host keyboard to the 3rd dead key

Note that to use for example PAGEDOWN (default setting!) as the 3rd dead key you will have to unbind
it from the `go_forward_one_step` command in openMSX using the console; by default openMSX has bound
the PAGEUP key to the `go_back_one_step` command. It is a very useful setting for many openMSX users when
playing games but unfortunately it conflicts with the default set-up for the third dead key. Such a command
binding takes precedence over keyboard mappings, so if you want to use PAGEDOWN as the third dead key you
will have to enter following additional command in the console: `unbind PAGEDOWN`.

### kbd_mapping_mode

The keyboard driver can work in several mapping modes: CHARACTER, POSITIONAL or KEY.

**CHARACTER mapping::** A character entered by the user on the host keyboard is mapped to the correct key combination on the MSX keyboard to
enter that same character. For example, when the user enters an '!' character and openMSX is emulating an 'international'
MSX model, the keyboard driver will press SHIFT and '1' on the MSX keyboard. This will be done regardless of the key
or keys that the user pressed on the host keyboard to enter that '!' character.

This is especially useful when the user has an AZERTY host keyboard and is working on a QWERTY style MSX or
when he has a US-QWERTY keyboard and is working on a Japanese MSX.

In other words: in this mode openMSX is aware of both the host and the MSX keyboard layout and tries to remap host key-combinations to the corresponding MSX key-combinations that produce the same character.

Special host keys (like CURSOR keys or CAPSLOCK) are mapped directly to the corresponding MSX keys.

Note that CHARACTER mode isn't perfect (help to improve it is always appreciated). In some cases it may be more convenient or even required to use one of the other mapping modes.
**POSITIONAL mapping::** In this mode both the host and the MSX keyboard layout are ignored. Host keys get mapped to MSX keys that are (approximately) in the same position on both keyboards. (More technically, host 'scan-codes' get mapped to MSX 'keyboard-matrix positions'.)
**KEY mapping::** This mode is deprecated, it's superseded by the previous two modes and may get removed in a future openMSX release.

This mode has rudimentary knowledge about the host keyboard layout, but no knowledge about the MSX keyboard layout. It remaps individual keys, not key combinations. Take for example a French AZERTY host keyboard and an emulated MSX with 'international' keyboard layout. Pressing the 'A' host key correctly maps to the 'A' MSX key. But pressing SHIFT+'3' on the host (which produces '3'), maps to SHIFT+'3' on the MSX keyboard (which produces '#').

**usage:**

- `setÂ kbd_mapping_mode` -- Shows the current mode
- `setÂ kbd_mapping_modeÂ CHARACTER` -- Set the CHARACTER mapping mode
- `setÂ kbd_mapping_modeÂ POSITIONAL` -- Set the POSITIONAL mapping mode

### kbd_numkeypad_always_enabled

Some real MSX computers do not have a numeric keypad. openMSX will ignore
key presses on the host numeric keypad when emulating such an MSX model.
With this parameter, you can indicate that even on such MSX models, presses
on the host numeric keypad must be mapped to the MSX numeric keypad. So, you
can override accurate behaviour with it, which is the reason that by default,
this setting is set to 'off'.

**usage:**

- `set kbd_numkeypad_always_enabled` -- Shows the current setting
- `set kbd_numkeypad_always_enabled on` -- Enables numeric keypad, even if the emulated MSX does not have one

### kbd_numkeypad_enter_key

There is a subtle difference between numeric keypad of MSX computers and
of most host computers; the MSX computers have a '.' and a ',' on the numeric
keypad. On the other hand, the host computers have a '.' and an 'ENTER' key
on the keypad.

In some respect it is logical that the 'ENTER' key on the host numeric
keypad is mapped to the 'normal' MSX 'ENTER' key. On the other hand, that
would make it impossible to enter the ',' on the MSX numeric keypad.
Therefore, the user can choose whether the host numeric keypad ENTER key
should be mapped to the MSX numeric keypad ',' (which is the default) or to
the main 'ENTER' key.

**usage:**

- `setÂ kbd_numkeypad_enter_key` -- Shows the current value
- `setÂ kbd_numkeypad_enter_keyÂ ENTER` -- Maps the keypad enter key to the main 'ENTER' key, instead of the comma key on the MSX keypad

### kbd_trace_key_presses

Log SDL key code, SDL modifiers and Unicode value for each key that gets
pressed on the host keyboard on stderr. Also show Unicode value and
corresponding MSX key-presses for characters that get 'pasted' into the MSX
by the console `type`
command. This setting is especially useful when defining Unicode keymap
files, so that you can find out the Unicode values belonging to certain
keys/characters.

**usage:**

- `set kbd_trace_key_presses` -- Shows the current setting
- `set kbd_trace_key_presses on` -- Turn logging of key presses on

### led_<name>

These are read-only settings. Their value reflects the current status of the corresponding LED on the emulated MSX machine. The currently supported LED names are: `power`, `caps`, `kana`, `pause`, `turbo` and `FDD`.

As for any setting you can use the native `trace` Tcl command to trigger a callback when the value of these settings changes. (In fact this possibility was the main motivation to make these read-only settings instead of topics of the `machine_info` command.)

### limitsprites

Controls whether the VDP has a limit on the number of sprites it can display per line. The default is on, because the real VDP has such a limit. You can turn off the limit to reduce sprite flashing in games such as Aleste. Note that some games (Penguin Adventure, among others) make use of this limitation, so they will display incorrectly if the limit is turned off.

The 5th/9th sprite status flag of the VDP is not influenced by the `limitsprites` setting: the flag always takes the limit into account.

**usage:**

- `set limitsprites` -- Shows the current value
- `set limitsprites on` -- Limits number of sprites per line
- `set limitsprites off` -- Turns off number of sprites per line limit

### master_volume

Controls the overall openMSX volume. The volume of individual sound devices can be controlled with the `<soundchip>_volume` settings.

**usage:**

- `set master_volume` -- Shows current setting
- `set master_volume 50` -- Sets master volume to 50%

### maxframeskip

Sets the maximum amount of frames to skip: show a frame and then skip at most <number> frames. So 0 means show everything (no frame skipping), 1 means show at least every second frame etc.

Frame skipping is done on demand, as a way to keep the flow of time for the emulated MSX in sync with the flow of real time. You can set limits on the amount of frame skipping with the `minframeskip` and `maxframeskip` setting.

In a situation where the number of consecutive frames specified by `maxframeskip` has been skipped, openMSX will display the next frame, even if that means emulation will start lagging behind real time.

**usage:**

- `set maxframeskip` -- Shows the current setting
- `set maxframeskip <number>` -- Sets the maximum number of consecutive frame skips

### midi-in-readfilename

Sets the file from which the MIDI input is read. By default, it is set to `/dev/midi` when available.

**usage:**

- `set midi-in-readfilename` -- Shows the current setting
- `set midi-in-readfilename mymidilog.dat` -- Read MIDI events from "mymidilog.dat"

### midi-out-logfilename

Sets the file to which the MIDI output is logged. By default, it logs to `/dev/midi` when available.

**usage:**

- `set midi-out-logfilename` -- Shows the current setting
- `set midi-out-logfilename mymidilog.dat` -- Log MIDI events to "mymidilog.dat"

### minframeskip

Sets the minimum amount of frames to skip: show a frame and then skip at least <number> frames.
So 0 means no forced frame skipping, 1 means skip at least every second frame etc.

Frame skipping is done on demand, as a way to keep the flow of time for the emulated MSX in sync with the flow of real time. You can set limits on the amount of frame skipping with the `minframeskip` and `maxframeskip` setting.

The `minframeskip` setting can be useful if you want to ease the burden on your PC processor, for example for longer battery life on a laptop. It can also be useful if your PC is consistently too slow to run without frame skipping: in such cases video might be smoother with a low but constant frame rate than with a fluctuating frame rate.

**usage:**

- `set minframeskip` -- Shows the current setting
- `set minframeskip <number>` -- Sets the number of frame skips

### mode

Sets the active mode. A mode is a set of settings (mostly key bindings, but also OSD widgets that are activated) that are most suitable for a certain task. Currently only mode 'normal' and 'tas' exist.

**usage:**

- `set mode` -- Shows the current setting
- `set mode tas` -- Change mode to TAS mode
- `set mode normal` -- Set mode back to normal, which is the default (all purpose) mode

## TAS mode

So far, the only special mode is the TAS mode, which is made for doing Tool Assisted Speedruns, with TAS widgets and easier ways to save replays. It is still experimental, but already very useful for doing a TAS. This mode enables the following widgets:

- frame counter (can also be toggled with `toggle_frame_counter`), which shows the VDP (not V9990) frame number on screen
- cursors (can also be toggled with `toggle_cursors`), shows which keys (important for games) are pressed

The mode configures the following key bindings, overriding any existing key bindings (note: Mac key bindings are not proper yet...):

**keys (PC) | keys (Mac) | function**
- F6 -- (F6) -- Load replay from current slot
- F7 -- (F7) -- Open slot select menu
- F8 -- (F8) -- Save replay to current slot
- End -- (End) -- Advance one frame (`advance_frame`)
- ScrollLock -- (ScrollLock) -- Reverse one frame (`reverse_frame`)

Note that this mode may change in future releases!

### mute

Mute/unmute all sound output.

**usage:**

- `set mute` -- Shows the current setting
- `set mute on` -- Mute sound
- `set mute off` -- Unmute sound

### noise

Controls the amount of Gaussian noise that is added to the video output. A small amount of noise can give a more authentic look to the video output on TFTs. Values can be between 0 and 100, where 0 is no noise and 100 is lots of noise.

This setting is best combined with `brightness` and `contrast`: noise creates small random fluctuations in the brightness of pixels. When noise is applied to pure black, it is not possible to make it any darker, so half of the time the noise is ineffective. The same happens with pure white. By setting the `brightness` slightly above 0 and `contrast` slightly below 0, you will get a better looking noise effect.

**usage:**

- `set noise` -- Shows the current setting
- `set noise 7` -- Add a moderate amount of noise

### pause

Pauses the emulation.

**usage:**

- `set pause` -- Shows the current setting
- `set pause on` -- Pauses emulation
- `set pause off` -- Unpauses emulation

Note: Some video settings cannot be applied to an already rendered frame and will therefore not take effect until openMSX is unpaused.

### pause_on_lost_focus

When this setting is enabled, the emulation will be paused when the
openMSX window loses focus.

**usage:**

- `set pause_on_lost_focus` -- Shows the current setting
- `set pause_on_lost_focus on` -- Emulation will be paused when the openMSX window loses focus
- `set pause_on_lost_focus off` -- Emulation will continue when the openMSX window loses focus (default)

### pointer_hide_delay

The amount of seconds before the mouse pointer will be automatically
hidden after it got shown due to mouse activity. A negative amount means that
it will never be hidden, an amount of 0 means that it will be always hidden.
By default the pointer is hidden 1 second after the last mouse activity.

**usage:**

- `set pointer_hide_delay` -- Shows the current setting
- `set pointer_hide_delay -1` -- Never hide the mouse pointer
- `set pointer_hide_delay 0` -- Always hide the mouse pointer
- `set pointer_hide_delay 3.4` -- Hide the mouse pointer after 3.4 seconds of inactivity

### power

Turn the power of the emulated MSX machine on or off.

**usage:**

- `set power` -- Shows the current setting
- `set power on` -- Turns the MSX machine on (the default)
- `set power off` -- Turns the MSX machine off

### printerlogfilename

Sets the file to which the printer logger writes.

**usage:**

- `set printerlogfilename` -- Shows the current setting
- `set printerlogfilename myprinterlog.txt` -- Log to "myprinterlog.txt"

### print-resolution

Sets the resolution (in dpi) for the emulated dot-matrix printer.

The emulated printer 'prints' pages as PNG files. This settings determines the resolution of those images.

**usage:**

- `set print-resolution` -- Shows the current setting
- `set print-resolution 600` -- Sets resolution to 600 dpi

### PSG_detune_frequency

Sets the frequency of the detune (a random variation in a sound's frequency) effect. It makes a sound fatter and more natural, as if played by a human being.

**usage:**

- `set PSG_detune_frequency` -- Shows the current setting
- `set PSG_detune_frequency <num>` -- Sets new detune frequency in Hz; 1 is minimum, 100 is maximum

**examples:**

`set PSG_detune_frequency`
`set PSG_detune_frequency 5` (default)

Note: It is often more convenient to use the `psg_profile` command.

### psg_detune_percent

Sets the strength of the detune effect. By default it is 0, which means the effect is switched off.

**usage:**

- `set PSG_detune_percent` -- Shows the current setting
- `set PSG_detune_percent <num>` -- Sets new detune strength; 0 is minimum, 10 is maximum

**examples:**

`set PSG_detune_percent`
`set PSG_detune_percent 0` (switched off, default)
`set PSG_detune_percent 0.5` (recommended)

Note: It is often more convenient to use the `psg_profile` command.

### PSG_vibrato_frequency

Sets the frequency of the vibrato (a periodic variation in a sound's frequency) effect.

**usage:**

- `set PSG_vibrato_frequency` -- Shows the current setting
- `set PSG_vibrato_frequency <num>` -- Sets new vibrato frequency in Hz; 1 is minimum, 10 is maximum

**examples:**

`set PSG_vibrato_frequency`
`set PSG_vibrato_frequency 5` (default)

Note: It is often more convenient to use the `psg_profile` command.

### PSG_vibrato_percent

Sets the strength of the vibrato effect. By default it is 0, which means the effect is switched off.

**usage:**

- `set PSG_vibrato_percent` -- Shows the current setting
- `set PSG_vibrato_percent <num>` -- Sets new vibrato strength; 0 is minimum, 10 is maximum

**examples:**

`set PSG_vibrato_percent`
`set PSG_vibrato_percent 0` (switched off, default)
`set PSG_vibrato_percent 1` (recommended)

Note: It is often more convenient to use the `psg_profile` command.

### r800_freq / r800_freq_locked

These two settings control the R800 clock frequency. See `z80_freq / z80_freq_locked` for details.

### renderer

Switch to a different video renderer. However, currently there is only one alternative: `none`, and that is useful only for disabling rendering in scripts completely.

**usage:**

- `set renderer` -- Shows the current setting
- `set renderer none` -- Disable rendering completely

### renshaturbo

Sets the speed of the built-in auto fire on some Japanese MSX models, for example the turboR machines. A value of 0 turns off auto fire, while 100 selects the most rapid auto fire.

**usage:**

- `set renshaturbo` -- Shows the current renshaturbo value
- `set renshaturbo <num>` -- Sets speed to value <num>

Note: This setting is only available if the current MSX machine has hardware Ren-Sha Turbo support.

### resampler

Sets the method to resample the sound of sound chips from their native frequency to the desired output frequency.

**usage:**

- `set resampler` -- Shows the currently active resampler
- `set resampler blip` -- Sets the Blip_Buffer (http://slack.net/~ant/libs/audio.html#Blip_Buffer) based resampler, which has the best quality per CPU usage ratio.
- `set resampler hq` -- Sets the highest quality resampler, but it also takes the most CPU time. It's based on the libsamplerate (http://www.mega-nerd.com/SRC/) algorithm. This is the default value on most platforms, as it gives the best quality.

### rs232-inputfilename

Sets the file from which the RS232-tester reads data. Note that the
`rs232-tester` has to be plugged in the `msx-rs232`
connector for this to become useful. When plugging the tester, this setting
needs to point to a valid file.

**usage:**

- `set rs232-inputfilename` -- Shows the current setting
- `set rs232-inputfilename myrs232input.txt` -- Reads from "myrs232input.txt"

### rs232-outputfilename

Sets the file to which the RS232-tester writes the data. Note that the
`rs232-tester` has to be plugged in the `msx-rs232`
connector for this to become useful. When plugging the tester, this setting
needs to point to a valid file.

**usage:**

- `set rs232-outputfilename` -- Shows the current setting
- `set rs232-outputfilename myrs232output.txt` -- Write to "myrs232output.txt"

### rs232-net-address

Sets the ip address (or hostname) and port for the RS232-Net pluggable. Note that
`rs232-net` has to be plugged in the `msx-rs232`
connector for this to become useful. This setting
needs to point to a valid host at the moment of plugging it.

The address must follow one of the following syntaxes:

- **hostname** e.g.: abc.com
- **hostname:port** e.g.: abc.com:23
- **ipv4** e.g.: 127.0.0.1
- **ipv4:port** e.g.: 127.0.0.1:2323
- **ipv6** e.g.: ::1
- **[ipv6]:port** e.g.: [::1]:8080

**usage:**

- `set rs232-net-address` -- Shows the current setting
- `set rs232-net-address mytelnetbbs.net:23` -- Connects to "mytelnetbbs.net" on port 23

### rs232-net-ip232

Enable the use of the IP232 protocol when used in conjunction with the `TCPSer` software modem. Note that
`rs232-net` has to be plugged in the `msx-rs232`
connector and `rs232-net-address` must point to the ip address and port of a running TCPSer instance.

The IP232 protocol permits the correct emulation of some of the RS-232 port control lines.

This setting must be disabled when using `rs232net` without `TCPSer`.

**usage:**

- `set rs232-net-ip232` -- Shows the current setting
- `set rs232-net-ip232 on` -- Enable the IP232 protocol
- `set rs232-net-ip232 off` -- Disable the IP232 protocol

### rtcmode

Sets the Real Time Clock mode. Can be either `RealTime` or `EmuTime`.

In `RealTime` mode the MSX clock is always synchronized with the host clock, even when for example emulation is paused for a while or when emulation is run at 200% of real speed.

In `EmuTime` mode the time is only synchronized with the host clock when openMSX starts. From then on the clock ticks at the same pace as the emulated machine. So when emulation is paused, the clock is paused as well. If emulation is run at 200% speed, the clock also ticks twice as fast.

In `EmuTime` mode it's not possible for an MSX program to detect whether it's running on a real or on an emulated machine. That's why this is the default mode. On the other hand the `RealTime` mode might be better if for example you care that timestamps of files written by the emulated MSX machine are in sync with the host machine time.

**usage:**

- `set rtcmode` -- Shows the current mode
- `set rtcmode EmuTime` -- Set EmuTime mode (the default)
- `set rtcmode RealTime` -- Set RealTime mode

### samples

Sets the size of the sound mixer buffer. Higher values help against buffer underruns (hickups), but increase the latency of the sound output.

**usage:**

- `set samples` -- Shows the current setting
- `set samples 1024` -- Use a mixing buffer of 1024 samples

### save_settings_on_exit

Automatically save the current settings when openMSX exits: execute a `save_settings` command on exit.

**usage:**

- `set save_settings_on_exit` -- Show current setting
- `set save_settings_on_exit on` -- Enable auto save
- `set save_settings_on_exit off` -- Disable auto save

### save_setup_at_exit_name

Specify the setup name to use when automatically saving the setup when exiting openMSX is active. See also the `save_setup_at_exit_depth` setting.

In the GUI, under Main menu bar â†’ Machine
â†’ Setup settings you can also configure what openMSX must do at startup, configuring this setting there.

**usage:**

- `set save_setup_at_exit_name` -- Show current setting
- `set save_setup_at_exit_name last_used` -- Set the setup name to be used for auto-save at exit to `last_used`

### save_setup_at_exit_depth

Specify the depth to use when automatically saving the setup when exiting openMSX. If the depth is set to `none` (which is the default), the auto-save is not active, but otherwise the setup will be saved under the name specified by the `save_setup_at_exit_name` setting. See also the `store_setup` command to find out about other depths that can be specified.

In the GUI, under Main menu bar â†’ Machine
â†’ Setup settings you can also configure what openMSX must do at startup, configuring this setting there.

**usage:**

- `set save_setup_at_exit_depth` -- Show current setting
- `set save_setup_at_exit_depth extensions` -- When openMSX exits, the current setup is saved including all extensions in the machine.
- `set save_setup_at_exit_depth complete_state` -- When openMSX exits, the complete state is saved into the setup.

**Nota:** If you enable this auto save of the setup and use the same name as for the `default_setup` setting, openMSX will automatically continue with the last setup when being started up again (and no other machine or setup is specified).

### scale_algorithm

Selects the algorithm used to transform MSX pixels to host pixels. The User's Manual contains more information about scalers.

**usage:**

- `set scale_algorithm` -- Shows the current setting
- `set scale_algorithm simple` -- Selects the default scale algorithm
- `set scale_algorithm hq` -- Selects the HQ2x/3x/4x scale algorithm

### scale_factor

Selects the scale factor. Scale factor <n> means the typical MSX pixel (MSX resolution 256Ã—212) is mapped on <n> by <n> host pixels. For the moment the possible values are 2 to 4. In the future we may support a wider range or even non-integer values. The User's Manual contains more information about scalers.

**usage:**

- `set scale_factor` -- Shows the current setting
- `set scale_factor <n>` -- Sets a new scale factor

### scanline

Sets the amount of scanline effect.

**usage:**

- `set scanline` -- Shows the current setting
- `set scanline <value>` -- Changes the value

Note: Some scalers will not render scanlines at all.

### sound_driver

Select the sound output driver.

**usage:**

- `set sound_driver sdl` -- Selects the SDL sound driver
- `set sound_driver null` -- Selects the null sound driver (no sound)

### speed

Sets the emulation speed relative to the speed of a real MSX. Speed 100 means as fast as a real MSX, lower values are slower than real MSX, higher values are faster than real MSX.

**usage:**

- `set speed` -- Shows current emulation speed
- `set speed <num>` -- Sets new emulation speed to <num>% of real time

### <soundchip>_balance

Sets the balance (distribution over the left and right channel) for individual sound chips. It replaces the previously available `<soundchip>_mode` setting. The range is between -100 (totally left) and 100 (totally right).

**usage:**

- `set <soundchip>_balance` -- Shows the current setting
- `set <soundchip>_balance 0` -- Plays the output of this chip on both the left and right channel
- `set <soundchip>_balance -100` -- Plays the output of this chip on only the left channel
- `set <soundchip>_balance 75` -- Plays the output of this chip mostly on the right channel, but also a bit on the left channel

**examples:**

`set PSG_balance`
`set PSG_balance -100`
`set FMPAC_balance 0`

### <soundchip>_ch<channel>_record

Sets the filename to which the sound of an individual channel of
individual sound chips should be recorded. When this setting is not set, no
recording takes place and recording starts as soon as the setting is set.
Normally, you would probably prefer to use the `record_channels` command to set up channel
recording instead of this low level setting.

**usage:**

- `set <soundchip>_ch<channel>_record` -- Shows the current setting
- `set <soundchip>_ch<channel>_record filename` -- Starts recording the sound of the specified chip and channel to the file with name <filename>

**examples:**

`set SCC_ch1_record`
`set PSG_ch3_record /tmp/PSG_ch3.wav`

### <soundchip>_ch<channel>_mute

Use to mute a specific channel of an individual sound chip.
Normally, you would probably prefer to use the `mute_channels` command to set up channel
muting instead of this low level setting.

**usage:**

- `set <soundchip>_ch<channel>_mute` -- Shows the current setting
- `set <soundchip>_ch<channel>_mute on` -- Mutes the sound of the specified channel of the specified chip
- `set <soundchip>_ch<channel>_mute off` -- Unmutes the sound of the specified channel of the specified chip

**examples:**

`set SCC_ch1_mute`
`set PSG_ch3_mute on`
`set SCC_ch5_mute off`

### <soundchip>_volume

Sets the volume for individual sound chips. The overall volume is controlled by the `master_volume` setting.

**usage:**

- `set <soundchip>_volume` -- Shows the current setting
- `set <soundchip>_volume <num>` -- Sets new volume; 0 is off, 100 is maximum

**examples:**

`set PSG_volume`
`set PSG_volume 60`
`set "FMPAC_volume" 50`

### throttle

Sets throttle mode. In throttle mode the emulator tries to run at the specified speed relative to a real MSX (see `speed` command). When throttling is turned off the emulator runs as fast as possible.

**usage:**

- `set throttle` -- Shows the current setting
- `set throttle on` -- Turn throttle mode on (normal operation)
- `set throttle off` -- Turn throttle mode off (fast forward)

### too_fast_vram_access

How should software that accesses the VDP-VRAM too fast be emulated?
Most existing MSX software should not access VRAM too fast, and in that case
this setting has no effect. But you may want to change it when you e.g.
emulate an overclocked Z80 (see `z80_freq`).

**usage:**

- `set too_fast_vram_access` -- Shows the current setting
- `set too_fast_vram_access real` -- Accessing the VRAM too fast results in dropped VRAM accesses, just like on a real machine.
- `set too_fast_vram_access ignore` -- All VRAM accesses are executed, so timing of VRAM access is ignored.

### too_fast_vram_access_callback

Selects the Tcl procedure to be called when a too-fast-VRAM-access (read
or write) has been detected. This is useful for debugging MSX programs that
show certain kinds of VRAM corruption, especially on MSX1.

By default this setting is empty, which means that nothing is done when a
too-fast-VRAM-access is detected. We ship a few example procedures called
`warn_too_fast_vram_access` and
`debug_too_fast_vram_access` which respectively print a warning or
break CPU emulation when this condition occurs. You can find the source code
for these procedures in `scripts/callbackprocs.tcl`. Feel free to
write your own procedure that does exactly what you need.

**usage:**

- `set VDP.too_fast_vram_access_callback` -- Shows the currently installed callback
- `set VDP.too_fast_vram_access_callback warn_too_fast_vram_access` -- Print warning when too fast VRAM access is detected
- `set VDP.too_fast_vram_access_callback debug_too_fast_vram_access` -- Print warning and also break emulation right after the Z80 instruction that triggered this callback
- `set VDP.too_fast_vram_access_callback my_custom_callback_handler` -- Install a custom callback handler
- `set VDP.too_fast_vram_access_callback ""` -- Remove any installed callback handler

### touchpad_transform_matrix

Specify a 2Ã—3 transformation matrix that maps host mouse coordinates
to MSX touchpad coordinates.
To get the following coordinate transformation:

| a b c | | host-X | | touchpad-X |
| d e f | Ã— | host-Y | = | touchpad-Y |
| 1 |

Use this command:

set touchpad_transform_matrix {{a b c} {d e f}}

**usage:**

- `set touchpad_transform_matrix` -- Shows the current value
- `set touchpad_transform_matrix {{256 0 0} {0 256 0}}` -- This is the default, map the full host window to 256Ã—256 touchpad input
- `set touchpad_transform_matrix {{320 0 -64} {0 240 -14}}` -- Attempt to map touch coordinates to corresponding MSX pixel coordinates.

### turborpause

Controls the pause key on an MSX turboR machine.

**usage:**

- `set turborpause` -- Shows the current setting
- `set turborpause on` -- Activate the pause key
- `set turborpause off` -- Deactivate the pause key

Note: If you use this setting often, it may be useful to bind it to a key on your PC keyboard. See the `bind` and `toggle` commands.

### umr_callback

Selects the Tcl procedure to be called when an Uninitialized Memory Read has been detected. This is useful for debugging MSX programs: uninitialized memory is not guaranteed to have any particular value, so reading it is most likely a bug.

By default this setting is empty, which means that nothing is done when an Uninitialized Memory Read is detected. We ship a useful procedure called `umrcallback` which logs all UMRs. You can activate it with `set umr_callback umrcallback`. You can find the source code for this procedure in `scripts/callbackprocs.tcl`.

**usage:**

- `set umr_callback` -- Shows the current UMR callback setting
- `set umr_callback umrcallback` -- Sets callback proc to `umrcallback`

### vdpcmdinprogress_callback

Selects the Tcl procedure to be called when a write to a VDP command engine register is detected while there is still a VDP command in progress. Often this is an indication of a bug in the running MSX program. Note that writes to VDP register R#44 with a command in progress are normal behaviour, so the callback is not triggered for such writes.

By default this setting is empty, which means that nothing is done when a suspicious VDP command engine write is detected. We ship an example proc called `vdpcmdinprogresscallback` which simply logs all occurrences. You can activate it with `set vdpcmdinprogress_callback vdpcmdinprogresscallback`. You can find the source code for this proc in `scripts/callbackprocs.tcl`. Feel free to write your own proc that does exactly what you need. For example it might be a good idea to execute `debug break` in your callback, so that you can easily examine what code triggered this write.

**usage:**

- `set vdpcmdinprogress_callback` -- Shows the current value. Default is "" (meaning no action)
- `set vdpcmdinprogress_callback vdpcmdinprogresscallback` -- Sets callback to `vdpcmdinprogresscallback`

### vdpcmdtrace

Enable/disable VDP command tracing. When enabled, every VDP command is logged on stdout. This is useful when debugging MSX programs that use the VDP command engine.

**usage:**

- `set vdpcmdtrace` -- Shows the current setting
- `set vdpcmdtrace on` -- Enables VDP command tracing
- `set vdpcmdtrace off` -- Disables VDP command tracing

### videosource

Switch between video sources: `MSX` (V99x8, default when no
Video 9000 is available), `GFX9000` (V9990),
`Video9000` (V9990 superimposed on top of V99x8, default if
available) and `Laserdisc` (for Palcom machines). There can be
even more video sources, e.g. offered by cartridges with a built-in VDP such as the Neos MA-20(V).

**usage:**

- `set videosource` -- Shows the current setting
- `set videosource MSX` -- Switch to normal MSX screen
- `set videosource GFX9000` -- Switch to GFX9000 screen

Note: This setting is only available if multiple video sources are present.

### vsync

Enables or disables vsync. This setting determines whether MSX frame rendering should be synchronized to your host monitors frame rate (e.g. 60fps).

The default value is not to synchronize ("`off`"). When enabled, adaptive vsync is attempted if your hardware and driver support it, which means that if a frame is too late, it will be output immediately anyway. If not supported, normal vsync will be used, which may mean a frame is output later, when the sync is missed.

Enable this if your MSX is running at about the same frame rate as your monitor (e.g. 60Hz MSX output on a 60Hz host monitor) and you want to avoid (or reduce) tearing, which can be quite visible in smooth horizontal scrolling demos. Keep in mind throttle mode off works a bit differently if vsync is enabled (see there).

**usage:**

- `set vsync` -- Shows the current setting
- `set vsync off` -- No synchronization to monitor frame rate: draw immediately
- `set vsync on` -- Synchronize to monitor frame rate when possible, otherwise draw immediately. Or, when this is not available on the host hardware/driver, synchronize to monitor frame rate always (default)

### v9990cmdtrace

Enable/disable V9990 command tracing. This is the V9990 equivalent of `vdpcmdtrace`.

**usage:**

- `set v9990cmdtrace` -- Shows the current setting
- `set v9990cmdtrace on` -- Enables V9990 command tracing
- `set v9990cmdtrace off` -- Disables V9990 command tracing

Note: This setting is only available if the `gfx9000` or
`video9000` extension is present.

### z80_freq / z80_freq_locked

These two settings control the Z80 clock frequency. When `z80_freq_locked` is true the emulated Z80 runs at the normal 3.579545 MHz (or possibly 5.369318 MHz on machines that are able to switch the CPU to 'turbo' mode, e.g. the Panasonic MSX2+ models). When `z80_freq_locked` is false the value of `z80_freq` is taken as the Z80 clock frequency. Note: the value of `z80_freq` is by default the MSX Z80 standard of 3579545, so when `z80_freq` is untouched, setting `z80_freq_locked` to false will set the clock frequency of a CPU in 5.37 Mhz turbo mode back to 3.58 Mhz.

WARNING: be careful when changing these settings. When saving the settings in which a different clock is activated, this will be applied for all machines, as these are global settings. Some software (like demos) may stop working properly with a changed CPU clock frequency. Specifically, using a value (just) below the normal value may cause problems loading CAS images, as these are converted to a high baud rate WAV file internally and when the MSX becomes slower it cannot handle that high baud rate.

**examples:**

Overclock Z80 to 14 MHz:
`set z80_freq 14318180`
`set z80_freq_locked false`
F8 switches between 3.5 MHz and 7 MHz:
`set z80_freq 7159090`
`bind F8 "toggle z80_freq_locked"`

### other settings

Like with the commands, there are also some specialized settings, for which we only list a very brief overview. As always execute "`help setting <setting-name>`" to get a more detailed description of the setting.

- `fast_cas_load_hack_enabled` -- Enable a hack that lets you quickly load CAS files, without having openMSX convert them to WAV

The source code of all these scripts is located in `share/scripts` directory. Feel free to inspect these scripts and modify them to suit your needs.

