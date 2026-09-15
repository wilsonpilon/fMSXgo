;
; ------------------------------------------------------------
;  Ajuda -> openMSX...: base de dados dos topicos de ajuda, gerada a partir
;  dos 5 manuais originais do openMSX (docs/openmsx-*.html - Setup Guide,
;  User's Manual, Using Diskmanipulator, Controlling openMSX from External
;  Applications, Console Command Reference), convertidos pra mini-Markdown
;  (script de conversao descartavel, nao versionado - HTML -> "## "/"- "/
;  "**negrito**"/"`codigo`") e agrupados por secao (Grupo = "<manual> -
;  <secao>", mesma ideia de "Parte I"/"Parte II" em MsxBasicManualData.pbi).
;
;  Mesma marcacao/estrutura de todo o resto da Ajuda (ver comentario em
;  NestorBasicHelpData.pbi): "## " (subtitulo), "**negrito**", "`codigo`"
;  inline, "- " (item de lista) - renderizada por NBHelpGui_RenderMarkdown
;  (NestorBasicHelpGui.pbi, XIncluded antes deste arquivo). Navegacao
;  (arvore/busca/historico) em OpenMsxHelpGui.pbi, no mesmo padrao das
;  outras 3 janelas de Ajuda (BasicDignifiedHelpGui.pbi/
;  NestorBasicHelpGui.pbi/MsxBasicHelpGui.pbi) - sem hyperlink clicavel
;  dentro do corpo (a mini-Markdown nao suporta isso), a navegacao entre
;  topicos relacionados e feita pela arvore + busca, como em toda a Ajuda.
;
;  Dividida em varios Build*() (um por manual, dois pro Manual do Usuario e
;  dois pra Referencia de Comandos - Comandos/Configuracoes - por causa do
;  volume) pelo mesmo motivo de NestorBasicHelpData.pbi (BuildDataDisk/
;  BuildDataVram/etc.): manter cada Procedure de tamanho razoavel.
;
;  OMSXHelp_ExportMarkdown() gera docs/reference/openmsx.md a partir desta
;  mesma base de dados (mesma ideia de NBHelp_ExportMarkdown em
;  NestorBasicHelpData.pbi) - editar o conteudo aqui atualiza os dois.
; ------------------------------------------------------------
;

Structure OMSXHelpTopic
  Titulo.s
  Grupo.s
  Corpo.s
EndStructure

Global NewList OMSXHelp_Topics.OMSXHelpTopic()
Global OMSXHelp_DataBuilt.b = #False

Procedure OMSXHelp_Add(Titulo.s, Grupo.s, Corpo.s)
  AddElement(OMSXHelp_Topics())
  OMSXHelp_Topics()\Titulo = Titulo
  OMSXHelp_Topics()\Grupo = Grupo
  OMSXHelp_Topics()\Corpo = Corpo
EndProcedure

Declare OMSXHelp_BuildData()
Declare OMSXHelp_BuildSetup()
Declare OMSXHelp_BuildUserManual1()
Declare OMSXHelp_BuildUserManual2()
Declare OMSXHelp_BuildDiskmanipulator()
Declare OMSXHelp_BuildControl()
Declare OMSXHelp_BuildCommandsCommands()
Declare OMSXHelp_BuildCommandsSettings()

Procedure OMSXHelp_BuildData()
  If OMSXHelp_DataBuilt
    ProcedureReturn
  EndIf
  OMSXHelp_DataBuilt = #True

  OMSXHelp_BuildSetup()
  OMSXHelp_BuildUserManual1()
  OMSXHelp_BuildUserManual2()
  OMSXHelp_BuildDiskmanipulator()
  OMSXHelp_BuildControl()
  OMSXHelp_BuildCommandsCommands()
  OMSXHelp_BuildCommandsSettings()
EndProcedure

; ============================================================
; OMSXHelp_BuildSetup
; ============================================================
Procedure OMSXHelp_BuildSetup()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("1.1 New Versions of this Document",
    "Guia de Configuracao - 1. Introduction",
    "The latest version of the openMSX manual can be found on the openMSX home page:" + #CRLF$ +
    "" + #CRLF$ +
    "http://openmsx.org/manual/ (http://openmsx.org/manual/)" + #CRLF$ +
    "" + #CRLF$ +
    "You can also use this URL to get up-to-date versions of the hyper links" + #CRLF$ +
    "if you printed out this manual.")

  OMSXHelp_Add("1.2 Purpose",
    "Guia de Configuracao - 1. Introduction",
    "This guide is about openMSX, the open source MSX emulator that tries to achieve" + #CRLF$ +
    "near-perfect emulation by using a novel emulation model." + #CRLF$ +
    "You can find more information about openMSX on the" + #CRLF$ +
    "openMSX home page (http://openmsx.org/)." + #CRLF$ +
    "You can also download the emulator itself from there." + #CRLF$ +
    "" + #CRLF$ +
    "This guide describes the setup of openMSX." + #CRLF$ +
    "After installation, openMSX is ready to run using C-BIOS and the default" + #CRLF$ +
    "settings. In this guide you can read how to configure openMSX to emulate actual" + #CRLF$ +
    "MSX machines (such as Panasonic FS-A1GT). It also describes how you can have" + #CRLF$ +
    "openMSX start up with your personal settings, how you can configure openMSX and" + #CRLF$ +
    "your system for optimal performance, and several other configuration related" + #CRLF$ +
    "topics." + #CRLF$ +
    "" + #CRLF$ +
    "Disclaimer:" + #CRLF$ +
    "We do not claim this guide is complete or even correct." + #CRLF$ +
    "What you do with the information in it is entirely at your own risk." + #CRLF$ +
    "We just hope it helps you enjoy openMSX more.")

  OMSXHelp_Add("1.3 Revision History",
    "Guia de Configuracao - 1. Introduction",
    "For the revision history, please refer to the commit log (https://github.com/openMSX/openMSX/commits/master/doc/manual/setup.html).")

  OMSXHelp_Add("2. Machines and Extensions",
    "Guia de Configuracao - 2. Machines and Extensions",
    "We use the word machine to refer to a specific" + #CRLF$ +
    "MSX model. For example, the Sony HB-75P is a machine." + #CRLF$ +
    "openMSX does not have a fixed machine hardcoded into it." + #CRLF$ +
    "Instead, many different MSX machines can be emulated." + #CRLF$ +
    "The details of a machine are described in an XML file." + #CRLF$ +
    "This file describes how much memory a machine has," + #CRLF$ +
    "what video processor it has, in which slots its system ROMs are located," + #CRLF$ +
    "whether the machine has a built-in disk drive etc." + #CRLF$ +
    "openMSX reads the machine description XML and will then emulate exactly" + #CRLF$ +
    "that MSX machine, which can be anything from an MSX1 with 16 kB of RAM" + #CRLF$ +
    "to the Panasonic FS-A1GT MSX turboR." + #CRLF$ +
    "" + #CRLF$ +
    "The openMSX distribution contains XML files describing many existing MSX" + #CRLF$ +
    "models." + #CRLF$ +
    "You can find them in the `share/machines` directory." + #CRLF$ +
    "If you want to run one of those machines," + #CRLF$ +
    "you also need the system ROMs for that machine." + #CRLF$ +
    "See the next chapter for more" + #CRLF$ +
    "information on system ROMs." + #CRLF$ +
    "You can also create your own machine descriptions," + #CRLF$ +
    "to expand existing MSX models or to create your own fantasy MSX. There are" + #CRLF$ +
    "currently some of such fantasy MSX machines, based on real MSX machines," + #CRLF$ +
    "shipped with openMSX. Examples of such machines are " + Chr(34) + "Boosted_MSX2_EN" + Chr(34) + " (a" + #CRLF$ +
    "European MSX2 with loads of hardware built-in) and" + #CRLF$ +
    Chr(34) + "Boosted_MSX2+_JP" + Chr(34) + " (a Japanese MSX2+ with loads of hardware built-in). You can" + #CRLF$ +
    "find some more information about them in their accompanying txt file in" + #CRLF$ +
    "`share/machines/`. More about creating fantasy MSX machines in a" + #CRLF$ +
    "later chapter." + #CRLF$ +
    "" + #CRLF$ +
    "An extension is a piece of MSX hardware that can be" + #CRLF$ +
    "inserted into a cartridge slot to extend the capabilities of an MSX." + #CRLF$ +
    "Examples of extensions are the Panasonic FMPAC, the Sunrise IDE interface" + #CRLF$ +
    "and an external 4MB memory mapper." + #CRLF$ +
    "Extensions, like machines, are described in XML files." + #CRLF$ +
    "You can find a lot of predefined extensions" + #CRLF$ +
    "in the `share/extensions` directory." + #CRLF$ +
    "Some extensions need ROM images in order to run, similar to system ROMs." + #CRLF$ +
    "" + #CRLF$ +
    "In general, the XML files that describe the hardware configuration are called" + #CRLF$ +
    Chr(34) + "hardware configuration XML files" + Chr(34) + "." + #CRLF$ +
    "" + #CRLF$ +
    "If you want to be able to run a combination of a machine and plugged in extensions at a later time, you can store this combination as a setup with the GUI via Main menu bar" + #CRLF$ +
    "→ Machine → Save setup or the `store_setup` command.")

  OMSXHelp_Add("3. System ROMs",
    "Guia de Configuracao - 3. System ROMs",
    "An MSX machine consists of a lot of hardware, but also contains some software." + #CRLF$ +
    "Such software includes the BIOS, MSX-BASIC, software controlling disk drives" + #CRLF$ +
    "and built-in applications (firmware)." + #CRLF$ +
    "openMSX emulates the MSX hardware, but it needs MSX system software to emulate" + #CRLF$ +
    "a full MSX system." + #CRLF$ +
    "Because the internal software is located in ROM chips, it is referred to as" + #CRLF$ +
    "system ROMs." + #CRLF$ +
    "" + #CRLF$ +
    "The software in the system ROMs, like most software, is copyrighted." + #CRLF$ +
    "Depending on your local laws, there are certain things you are allowed to" + #CRLF$ +
    "do with copyrighted software and certain things you are not allowed to do." + #CRLF$ +
    "In this manual, a couple of options are listed for providing system ROMs" + #CRLF$ +
    "to your openMSX installation." + #CRLF$ +
    "It is up to you, the user, to select an option that is legal in your country.")

  OMSXHelp_Add("3.1 C-BIOS",
    "Guia de Configuracao - 3. System ROMs",
    "C-BIOS stands for " + Chr(34) + "Compatible BIOS" + Chr(34) + "." + #CRLF$ +
    "It aims to be compatible with the MSX BIOS found in real MSX machines," + #CRLF$ +
    "but it was written from scratch, so all copyrights belong to its authors." + #CRLF$ +
    "BouKiChi, the original author of C-BIOS, was kind enough to allow" + #CRLF$ +
    "distribution of C-BIOS with openMSX." + #CRLF$ +
    "When Reikan took over maintenance of C-BIOS, the license" + #CRLF$ +
    "was changed to give users and developers even more freedom in using C-BIOS." + #CRLF$ +
    "Later still, C-BIOS was moved to a SourceForge.net project, with several new" + #CRLF$ +
    "maintainers. Every now and then, an updated version of C-BIOS is released." + #CRLF$ +
    "You can wait for it to be included in the next openMSX release," + #CRLF$ +
    "or download it directly from the" + #CRLF$ +
    "C-BIOS web site (http://cbios.sourceforge.net/)." + #CRLF$ +
    "" + #CRLF$ +
    "C-BIOS can be used to run most MSX1, MSX2 and MSX2+ cartridge-based games." + #CRLF$ +
    "It does not include support for MSX-BASIC or disk drives yet," + #CRLF$ +
    "so software that comes on tape, disk or any other media than ROM cartridges" + #CRLF$ +
    "will not run on standard openMSX C-BIOS machines." + #CRLF$ +
    "" + #CRLF$ +
    "openMSX contains several machine configurations using C-BIOS." + #CRLF$ +
    "The machine `C-BIOS_MSX1` is an MSX1 with 64 kB RAM." + #CRLF$ +
    "The machine `C-BIOS_MSX2` is an MSX2 with 512 kB RAM and 128 kB VRAM." + #CRLF$ +
    "The machine `C-BIOS_MSX2+` is an MSX2+ with 512 kB RAM, 128 kB VRAM and MSX-MUSIC." + #CRLF$ +
    "The latter is the default machine for openMSX after" + #CRLF$ +
    "installation, so if you change nothing to the openMSX configuration," + #CRLF$ +
    "then `C-BIOS_MSX2+` is the machine that will be booted. The" + #CRLF$ +
    "mentioned machines have a US English (international) keyboard layout and" + #CRLF$ +
    "character set and run at 60Hz (like NTSC) interrupt frequency. Since C-BIOS" + #CRLF$ +
    "0.25, some localized versions are also available: Japanese, European (like US," + #CRLF$ +
    "but 50Hz), and Brazilian. You can easily recognize them." + #CRLF$ +
    "" + #CRLF$ +
    "It is always legal for you to run the C-BIOS ROMs in openMSX." + #CRLF$ +
    "You are allowed to use C-BIOS and its source code in various other ways" + #CRLF$ +
    "as well, read the C-BIOS license for details." + #CRLF$ +
    "It is located in the file `README.cbios` in the Contrib directory.")

  OMSXHelp_Add("3.2 Dumping ROMs",
    "Guia de Configuracao - 3. System ROMs",
    "If you own a real MSX machine, you can dump the contents of its system ROMs" + #CRLF$ +
    "to create ROM images you can run in openMSX." + #CRLF$ +
    "This way, you can emulate the MSX machines you are familiar with." + #CRLF$ +
    "" + #CRLF$ +
    "## 3.2.1 Tools" + #CRLF$ +
    "" + #CRLF$ +
    "The easiest way to dump system ROMs is to run a special dumping tool on your" + #CRLF$ +
    "real MSX, which copies the contents of the system ROMs to disk." + #CRLF$ +
    "Sean Young has made such tools, you can find the" + #CRLF$ +
    "tools and documentation (http://bifi.msxnet.org/msxnet/utils/saverom.html)" + #CRLF$ +
    "on BiFi's web site." + #CRLF$ +
    "These tools can also be used to dump cartridge ROMs, which may be useful later," + #CRLF$ +
    "if you want to use certain extensions or play games." + #CRLF$ +
    "" + #CRLF$ +
    "## 3.2.2 Legal Issues" + #CRLF$ +
    "" + #CRLF$ +
    "Using ROMs dumped from machines you own is generally speaking not frowned upon in the MSX community." + #CRLF$ +
    "When the MSX machine was bought in a shop years ago, you or the person that" + #CRLF$ +
    "originally bought it paid money for the MSX machine." + #CRLF$ +
    "A small part of that money paid for the software in the system ROMs." + #CRLF$ +
    "However, we are no legal experts, so it is up to you to check whether it" + #CRLF$ +
    "is legal in your country to use dumped ROMs of machines you own.")

  OMSXHelp_Add("3.3 Downloading ROMs",
    "Guia de Configuracao - 3. System ROMs",
    "Some WWW and FTP sites offer MSX system ROMs as a download." + #CRLF$ +
    "Some MSX emulators include system ROMs in their distribution." + #CRLF$ +
    "Downloaded system ROMs can be used in the same way as" + #CRLF$ +
    "system ROMs you dumped yourself, see the previous section." + #CRLF$ +
    "" + #CRLF$ +
    "It may be illegal in your country to download system ROMs." + #CRLF$ +
    "Please inform yourself of the legal aspects before considering this option." + #CRLF$ +
    "Whatever you decide is your own responsibility.")

  CBody = "If you want to emulate real MSX machines next to the default C-BIOS based" + #CRLF$ +
    "machines, you will have to install system ROMs that did not come with openMSX." + #CRLF$ +
    "This section explains how to install these, once you obtained them in one of" + #CRLF$ +
    "the ways that are explained in the previous sections." + #CRLF$ +
    "" + #CRLF$ +
    "## 3.4.1 ROM Locations" + #CRLF$ +
    "" + #CRLF$ +
    "The easiest way is to copy the ROM files in a so-called file pool: a special" + #CRLF$ +
    "directory where openMSX will look for files (system ROMs, other ROMs, disks," + #CRLF$ +
    "tapes, etc.). The default file pool for system ROMs is the" + #CRLF$ +
    "`systemroms` sub directory. The best way is to make a" + #CRLF$ +
    "`systemroms` sub directory in your own user directory, which is" + #CRLF$ +
    "platform dependent:" + #CRLF$ +
    "" + #CRLF$ +
    "**Platform | User directory**" + #CRLF$ +
    "- Windows (e.g. Windows 7) -- `C:\Users\<user name>\Documents\openMSX\share` whereby `<user name>` stands for your Windows login name" + #CRLF$ +
    "- Unix and Linux -- `~/.openMSX/share`" + #CRLF$ +
    "" + #CRLF$ +
    "Please note that the path part which comes before `share` can be" + #CRLF$ +
    "overridden by setting the `OPENMSX_HOME` environment variable, see the chapter about User Preferences." + #CRLF$ +
    "" + #CRLF$ +
    "That way, you do not need special privileges. Furthermore, the (Windows) installer" + #CRLF$ +
    "won't touch them for sure." + #CRLF$ +
    "" + #CRLF$ +
    "A template for the `systemroms` sub directory is present in the" + #CRLF$ +
    "installation directory of openMSX, which is also platform dependent:" + #CRLF$ +
    "" + #CRLF$ +
    "**Platform | Typical openMSX file pool installation directory**" + #CRLF$ +
    "- Windows (any version) -- `C:\Program Files\openMSX\share`" + #CRLF$ +
    "- Unix and Linux -- `/opt/openMSX/share` or `/usr/share/openmsx`" + #CRLF$ +
    "" + #CRLF$ +
    "The quickest way to see where openMSX is searching for system ROMs on your" + #CRLF$ +
    "installation is via the GUI under Main menu bar" + #CRLF$ +
    "→ Machine → Test MSX hardware. At the bottom of this dialog" + #CRLF$ +
    "you can find buttons to quickly open a (native) file browser on the locations" + #CRLF$ +
    "where the ROMs are searched for, both for the user folder and the system wide" + #CRLF$ +
    "folder. The main function of this window is to verify whether your system ROMs" + #CRLF$ +
    "have been installed properly." + #CRLF$ +
    "" + #CRLF$ +
    "In short: you can just copy all your system ROMs to the" + #CRLF$ +
    "`share/systemroms` directory of your user account. The ROM files can" + #CRLF$ +
    "be zipped (or gzipped), but only one file can be in a ZIP file. If multiple ROM" + #CRLF$ +
    "files are in a single ZIP file, openMSX will not find them. The directory" + #CRLF$ +
    "structure below `share/systemroms` is not relevant, openMSX will" + #CRLF$ +
    "search it completely." + #CRLF$ +
    "" + #CRLF$ +
    "More info about file pools is in the documentation of the `filepool` command. If" + #CRLF$ +
    "you can't get this working, please read one of the next sections." + #CRLF$ +
    "" + #CRLF$ +
    "For advanced users, it is also possible to let openMSX load a specific set" + #CRLF$ +
    "of ROM images for a machine, independent of any file pool or the checksums of" + #CRLF$ +
    "the ROM images. For that you copy the ROM file with the name and path as" + #CRLF$ +
    "mentioned in the hardware configuration XML file that describes the machine," + #CRLF$ +
    "relative to the path of that machine description file. For example, if you" + #CRLF$ +
    "dumped the ROMs of a Philips NMS 8250 machine, copy them to" + #CRLF$ +
    "`share/machines`, because in the machine description file (in" + #CRLF$ +
    "`share/machines/Philips_NMS_8250.xml`) the name of the ROMs is like" + #CRLF$ +
    "this: `nms8250_msx2sub.rom`. We recommend to not use this feature," + #CRLF$ +
    "but use the file pools as mentioned above." + #CRLF$ +
    "" + #CRLF$ +
    "## 3.4.2 How openMSX knows which ROM files to use" + #CRLF$ +
    "" + #CRLF$ +
    "All necessary system ROM files used in machines and extensions are" + #CRLF$ +
    "primarily identified with a checksum: a sha1sum. This enables openMSX to find" + #CRLF$ +
    "the right ROM file from one of the file pools of type `system_rom`," + #CRLF$ +
    "regardless of the file name. So the actual content is guaranteed to be" + #CRLF$ +
    "what was intended. If the ROM is explicitly specified in the configuration file" + #CRLF$ +
    "(which is also supported) and the sha1sum doesn't match, a warning will be" + #CRLF$ +
    "printed." + #CRLF$ +
    "" + #CRLF$ +
    "If you are trying to run an MSX machine and get an error like `Fatal" + #CRLF$ +
    "error: Error in " + Chr(34) + "broken" + Chr(34) + " machine: Couldn't find ROM file for " + Chr(34) + "MSX BIOS with" + #CRLF$ +
    "BASIC ROM" + Chr(34) + " (sha1: 12345c041975f31dc2ab1019cfdd4967999de53e).` it means" + #CRLF$ +
    "that the required system ROM for that machine with the given sha1sum cannot be" + #CRLF$ +
    "found in one of the file pools as mentioned above (typically" + #CRLF$ +
    "`share/systemroms`). This is the primary way to know that you are" + #CRLF$ +
    "missing required system ROMs and therefore something went wrong installing them" + #CRLF$ +
    "(typically either not a file with the proper content or you put the file in the" + #CRLF$ +
    "wrong place, or you put it in a large ZIP file with multiple files)." + #CRLF$ +
    "" + #CRLF$ +
    "The quickest way to see which machine and extensions work (i.e.: openMSX" + #CRLF$ +
    "can find the required system ROMs the configuration is referring to) is by" + #CRLF$ +
    "using the GUI under Main menu bar → Machine" + #CRLF$ +
    "→ Test MSX hardware. It will quickly check all machines and" + #CRLF$ +
    "extensions and will show which are working and which are not, and which error" + #CRLF$ +
    "occurred when trying to use it. Besides this, when selecting to run a machine" + #CRLF$ +
    "using the GUI under Main menu bar → Machine" + #CRLF$ +
    "→ Select MSX machine..., you can also see which are working and" + #CRLF$ +
    "which not and why. Likewise for extensions via Main menu bar → Media → Extensions →" + #CRLF$ +
    "Insert for instance." + #CRLF$ +
    "" + #CRLF$ +
    "You can also manually check whether you have the correct ROM images. The" + #CRLF$ +
    "value in the <sha1> tag(s) in the hardware configuration XML files" + #CRLF$ +
    "contain checksums of ROM images that are known to work. You can compare the" + #CRLF$ +
    "checksums of your ROM images to the ones in the hardware configuration XML" + #CRLF$ +
    "files with the `sha1sum` tool. It is installed by default on most" + #CRLF$ +
    "UNIX systems, on Windows you will have to download it separately. If the" + #CRLF$ +
    "checksums match, it is almost certain you have correct system ROMs. If the" + #CRLF$ +
    "checksums do not match, it could mean something went wrong dumping the ROMs, or" + #CRLF$ +
    "it could mean you have a slightly older/newer model which contains different" + #CRLF$ +
    "system ROMs." + #CRLF$ +
    "" + #CRLF$ +
    "A typical case in which you can have problems with checksums (or ROMs not" + #CRLF$ +
    "getting found in a file pool) is disk ROMs. The ROM dump can be correct, and" + #CRLF$ +
    "still have a different checksum. This is because part of the ROM is not" + #CRLF$ +
    "actually ROM, but mapped on the registers of the floppy controller. When you"
  CBody + #CRLF$ + "are sure it is correct, don't put it in a file pool, but put it in the proper" + #CRLF$ +
    "directory, which is explained above. Alternatively, you could add the checksum" + #CRLF$ +
    "in the XML file that describes the machine you made the ROM dump for (multiple" + #CRLF$ +
    "checksums can be present, they will be checked in the same order as they are in" + #CRLF$ +
    "the file)." + #CRLF$ +
    "" + #CRLF$ +
    "## 3.4.3 How to handle split ROMs" + #CRLF$ +
    "" + #CRLF$ +
    "The machine configurations bundled with openMSX often refer to ROM files" + #CRLF$ +
    "that span multiple 16 kB pages. For example, in the NMS 8250 configuration, the" + #CRLF$ +
    "BIOS and MSX-BASIC are expected in a single 32 kB ROM image. If you created two" + #CRLF$ +
    "16 kB images when dumping or got those from downloading, you can concatenate" + #CRLF$ +
    "them using tools included with your OS. In Linux and other Unix(-like) systems" + #CRLF$ +
    "you can do it like this:" + #CRLF$ +
    "" + #CRLF$ +
    "`cat bios.rom basic.rom" + #CRLF$ +
    "> nms8250_basic-bios2.rom`" + #CRLF$ +
    "" + #CRLF$ +
    "In Windows, open a command prompt and" + #CRLF$ +
    "issue this command:" + #CRLF$ +
    "" + #CRLF$ +
    "`copy /b bios.rom + basic.rom" + #CRLF$ +
    "nms8250_basic-bios2.rom`"
  OMSXHelp_Add("3.4 Installing ROMs", "Guia de Configuracao - 3. System ROMs", CBody)

  OMSXHelp_Add("4. Palcom Laserdiscs",
    "Guia de Configuracao - 4. Palcom Laserdiscs",
    "The Pioneer PX-7 and Pioneer PX-V60 are both emulated including an emulated" + #CRLF$ +
    "Laserdisc Player, making it possible to run Palcom Laserdisc software." + #CRLF$ +
    "" + #CRLF$ +
    "The laserdisc must be captured before it can be used with an emulator. The" + #CRLF$ +
    "file must adhere to the following rules:" + #CRLF$ +
    "" + #CRLF$ +
    "- Use the Ogg container format" + #CRLF$ +
    "- Use the Vorbis codec for audio" + #CRLF$ +
    "- Use the Theora codec for video" + #CRLF$ +
    "- Captured at 640×480, YUV420" + #CRLF$ +
    "- A bitrate of at least 200kpbs for audio, otherwise the computer code" + #CRLF$ +
    "encoded on the right audio channel will degrade too much for it to be" + #CRLF$ +
    "readable" + #CRLF$ +
    "- Theora frame numbers must correspond to laserdisc frame numbers" + #CRLF$ +
    "- Some laserdiscs have chapters and/or stop frames. This is encoded in the" + #CRLF$ +
    "VBI signal (http://www.daphne-emu.com/mediawiki/index.php/VBIInfo), and must be converted to plain text. This must be added to the" + #CRLF$ +
    "Theora meta data" + #CRLF$ +
    "" + #CRLF$ +
    "The metadata for chapters and stop frames has the form " + Chr(34) + "chapter:" + #CRLF$ +
    "<chapter-no>,<first-frame>-<last-frame>" + Chr(34) + " and stop frames are" + #CRLF$ +
    Chr(34) + "stop: <frame-no>" + Chr(34) + ". For example:" + #CRLF$ +
    "" + #CRLF$ +
    "chapter: 0,1-360 chapter: 1,361-4500 chapter: 2,4501-9450 chapter:" + #CRLF$ +
    "3,9451-18660 chapter: 4,18661-28950 chapter: 5,28951-38340 chapter:" + #CRLF$ +
    "6,38341-39432 stop: 4796 stop: 9089 stop: 9178 stop: 9751 stop: 14818 stop:" + #CRLF$ +
    "14908 stop: 18270 stop: 18360 stop: 18968 stop: 24815 stop: 24903 stop: 28553" + #CRLF$ +
    "stop: 28641 stop: 29258 stop: 34561 stop: 34649 stop: 38095 stop: 38181 stop:" + #CRLF$ +
    "38341 stop: 39127" + #CRLF$ +
    "" + #CRLF$ +
    "Note that the emulated Pioneer PX-7 and Pioneer PX-V60 are virtually" + #CRLF$ +
    "identical, except that the Pioneer PX-7 has pseudo-stereo for its PSG.")

  OMSXHelp_Add("5. User Preferences",
    "Guia de Configuracao - 5. User Preferences",
    "Almost all user preferences can be set via the GUI menu and the openMSX" + #CRLF$ +
    "console, at openMSX run time. This is more thoroughly explained in the User's Manual." + #CRLF$ +
    "" + #CRLF$ +
    "By using the `bind` command you can create custom key" + #CRLF$ +
    "bindings. These bindings will also be saved as settings in your settings file" + #CRLF$ +
    "if you issue a `save_settings` command." + #CRLF$ +
    "" + #CRLF$ +
    "Many important settings are discussed in the User's Manual and there is an overview in" + #CRLF$ +
    "the Console Command Reference." + #CRLF$ +
    "" + #CRLF$ +
    "If you're a power user and want to specify commands which are executed at" + #CRLF$ +
    "the start of each openMSX start up, put those commands in a text file, one" + #CRLF$ +
    "command per line (i.e. a script) and put it in the `share/scripts`" + #CRLF$ +
    "directory. You can also explicitly specify a Tcl file to be loaded and executed" + #CRLF$ +
    "on the openMSX command line. For this, use the `-script` command line" + #CRLF$ +
    "option, which has the filename of the Tcl script as argument." + #CRLF$ +
    "" + #CRLF$ +
    "If you're a power user and want to tweak where openMSX reads and writes" + #CRLF$ +
    "files from, you can use these hacky environment variables. Hacky, because we" + #CRLF$ +
    "don't really expect anyone to change them, but when the urge is stronger than yourself, do" + #CRLF$ +
    "so at your own risk... Be warned that they may change without notice in a next" + #CRLF$ +
    "release." + #CRLF$ +
    "" + #CRLF$ +
    "**variable | meaning**" + #CRLF$ +
    "- `OPENMSX_HOME` -- The user's home folder, where all" + #CRLF$ +
    "data will get stored that openMSX produces." + #CRLF$ +
    "- `OPENMSX_USER_DATA` -- The user's personal" + #CRLF$ +
    "`share` folder, where amongst others, system ROMs are" + #CRLF$ +
    "searched" + #CRLF$ +
    "- `OPENMSX_SYSTEM_DATA` -- The system" + #CRLF$ +
    "wide `share` folder in the openMSX installation directory" + #CRLF$ +
    "" + #CRLF$ +
    "In the section about ROM locations" + #CRLF$ +
    "you get an idea about the default values of these on different platforms.")

  OMSXHelp_Add("6. Performance Tuning",
    "Guia de Configuracao - 6. Performance Tuning",
    "This chapter contains some tips for tuning the performance of openMSX" + #CRLF$ +
    "on your system.")

  OMSXHelp_Add("6.1 OpenGL",
    "Guia de Configuracao - 6. Performance Tuning",
    "As openMSX is using the SDLGL-PP `renderer`, it needs hardware acceleration to run at a" + #CRLF$ +
    "decent speed, with support for OpenGL 2.0." + #CRLF$ +
    "" + #CRLF$ +
    "Getting OpenGL running hardware accelerated used to be a little cumbersome in some situations." + #CRLF$ +
    "However, nowadays there is a big chance that your system already has hardware" + #CRLF$ +
    "accelerated OpenGL supported in the default installation of your Xorg/Wayland" + #CRLF$ +
    "or Windows environment." + #CRLF$ +
    "" + #CRLF$ +
    "You can verify hardware acceleration on your Linux system by typing" + #CRLF$ +
    "`glxinfo` on the command line. If you have everything working, this" + #CRLF$ +
    "command should output a line like this: `direct rendering: Yes`.")

  OMSXHelp_Add("6.2 Various Tuning Tips",
    "Guia de Configuracao - 6. Performance Tuning",
    "CPU and graphics performance varies a lot, depending on the openMSX" + #CRLF$ +
    "settings and the MSX hardware and software you're emulating." + #CRLF$ +
    "Some things run fine on a 200MHz machine, others are slow on a 2GHz" + #CRLF$ +
    "machine." + #CRLF$ +
    "" + #CRLF$ +
    "If openMSX is running slow, you can try the following measures:" + #CRLF$ +
    "" + #CRLF$ +
    "- Disable the `reverse` feature" + #CRLF$ +
    "(especially if the platform you're running on has a low amount of RAM), which" + #CRLF$ +
    "is enabled by default on most platforms: `set auto_enable_reverse off`" + #CRLF$ +
    "- Make sure there are no CPU or I/O heavy background processes is running." + #CRLF$ +
    "Downloads, P2P software, distributed calculation efforts, search indexers etc. may grab" + #CRLF$ +
    "the CPU from time to time, leaving less time for openMSX to do its job." + #CRLF$ +
    "Even if they only do so only once in a while, it may be enough to cause" + #CRLF$ +
    "emulation to stutter." + #CRLF$ +
    "- Increase the number of frames that may be skipped (`set maxframeskip 10`," + #CRLF$ +
    "for example)." + #CRLF$ +
    "- Use the blip resampler instead of the hq one." + #CRLF$ +
    "- Emulate MSX software that uses fewer sound channels, for example MSX-MUSIC" + #CRLF$ +
    "(maximum 9 channels) instead of MoonSound (maximum 18+24 channels). Or run" + #CRLF$ +
    "simpler software altogether (e.g. MSX1 software instead of turboR software).")

  OMSXHelp_Add("7. Writing Hardware Descriptions",
    "Guia de Configuracao - 7. Writing Hardware Descriptions",
    "There are two ways to use extra devices in your emulated MSX: you can use a" + #CRLF$ +
    "shipped extension (which is similar to inserting a cartridge with the device" + #CRLF$ +
    "into the MSX) or you can modify the hardware configuration file (the same as" + #CRLF$ +
    "opening the MSX and building in the device). As in the real world," + #CRLF$ +
    "extensions are easier to use, but modifying the machine gives you more" + #CRLF$ +
    "possibilities." + #CRLF$ +
    "Normal usage of machines and extensions is covered in the User's Manual; this chapter tells you how you can create" + #CRLF$ +
    "or modify these hardware descriptions, which is a topic for advanced users and" + #CRLF$ +
    "definitely something very few people will (want to) do." + #CRLF$ +
    "By editing the hardware configuration XML files, you can for example increase" + #CRLF$ +
    "the amount of RAM, add built-in MSX-MUSIC, a disk drive, extra" + #CRLF$ +
    "cartridge slots, etc." + #CRLF$ +
    "" + #CRLF$ +
    "You can modify an MSX machine (e.g. to add devices) by editing its hardware" + #CRLF$ +
    "configuration XML file. So, let's make a copy of" + #CRLF$ +
    "`share/machines/Philips_NMS_8250.xml` and put it in" + #CRLF$ +
    "`share/machines/mymsx.xml`." + #CRLF$ +
    "It's the config we are going to play with; our custom MSX." + #CRLF$ +
    "Note: it is convenient to use the user directory (see above)" + #CRLF$ +
    "to store your home-made machines, instead of the openMSX installation directory." + #CRLF$ +
    "" + #CRLF$ +
    "The easiest thing to do is to copy and modify fragments from other existing" + #CRLF$ +
    "configurations that can be found in `share/machines` or" + #CRLF$ +
    "`share/extensions`. For example, to add an FMPAC to the 8250, just" + #CRLF$ +
    "copy it from the `share/extensions/fmpac.xml` to some place in your" + #CRLF$ +
    "`mymsx.xml` file (between the `<devices>` and" + #CRLF$ +
    "`</devices>` tags!):" + #CRLF$ +
    "" + #CRLF$ +
    "<primary slot=" + Chr(34) + "2" + Chr(34) + ">" + #CRLF$ +
    "<secondary slot=" + Chr(34) + "1" + Chr(34) + ">" + #CRLF$ +
    "<FMPAC id=" + Chr(34) + "PanaSoft SW-M004 FMPAC" + Chr(34) + ">" + #CRLF$ +
    "<io base=" + Chr(34) + "0x7C" + Chr(34) + " num=" + Chr(34) + "2" + Chr(34) + " type=" + Chr(34) + "O" + Chr(34) + "/>" + #CRLF$ +
    "<mem base=" + Chr(34) + "0x4000" + Chr(34) + " size=" + Chr(34) + "0x4000" + Chr(34) + "/>" + #CRLF$ +
    "<sound>" + #CRLF$ +
    "<volume>13000</volume>" + #CRLF$ +
    "<balance>-75</balance>" + #CRLF$ +
    "</sound>" + #CRLF$ +
    "<rom>" + #CRLF$ +
    "<sha1>9d789166e3caf28e4742fe933d962e99618c633d</sha1>" + #CRLF$ +
    "<filename>roms/fmpac.rom</filename>" + #CRLF$ +
    "</rom>" + #CRLF$ +
    "<sramname>fmpac.pac</sramname>" + #CRLF$ +
    "</FMPAC>" + #CRLF$ +
    "</secondary>" + #CRLF$ +
    "</primary>" + #CRLF$ +
    "" + #CRLF$ +
    "Don't forget to add the `fmpac.rom` file to one of your `system_rom` file pools." + #CRLF$ +
    "" + #CRLF$ +
    "Because we changed the FMPAC from extension to built-in device, we have to" + #CRLF$ +
    "specify in which slot the FMPAC is residing inside the modified 8250. So, we" + #CRLF$ +
    "should replace the `slot=" + Chr(34) + "any" + Chr(34) + "` stuff, with a specified slot as you" + #CRLF$ +
    "can see in the above fragment." + #CRLF$ +
    "The number in the `slot` attribute of the" + #CRLF$ +
    "`<primary>` tag indicates the" + #CRLF$ +
    "primary slot of the emulated MSX you're editing. In this case the second" + #CRLF$ +
    "cartridge slot of the NMS-8250 is used. `<secondary>` means" + #CRLF$ +
    "sub slot. If we leave it out, the slot is not expanded and the primary slot is" + #CRLF$ +
    "used. If we use it like in the above example, it means that slot 1 (of the" + #CRLF$ +
    "`<primary>` tag) will be an expanded slot. If a" + #CRLF$ +
    "`<primary>` tag has the attribute" + #CRLF$ +
    "`external=" + Chr(34) + "true" + Chr(34) + "`, this means that the slot is visible on the" + #CRLF$ +
    "outside of the machine and can thus be used for external cartridges like" + #CRLF$ +
    "extensions and ROM software. As explained above, the parameter filename can be" + #CRLF$ +
    "adjusted to the name of your (64 kB!) FMPAC ROM file (note: if the file is not" + #CRLF$ +
    "65536 bytes in size, it won't work)." + #CRLF$ +
    Chr(34) + "balance" + Chr(34) + " defines to what channel the FMPAC's sound will be routed by" + #CRLF$ +
    "default: in this case most of the sound goes to the left channel and a little" + #CRLF$ +
    "bit goes to the right channel. " + Chr(34) + "sramname" + Chr(34) + " specifies the file name for file in" + #CRLF$ +
    "which the SRAM contents will be saved to or loaded from. The saved files are" + #CRLF$ +
    "compatible with the files that are saved by the (real) FMPAC commander's save" + #CRLF$ +
    "option." + #CRLF$ +
    "" + #CRLF$ +
    "After saving your config and running openMSX again, you should be able to get" + #CRLF$ +
    "the FMPAC commander with `CALL FMPAC` in the emulated MSX!" + #CRLF$ +
    "" + #CRLF$ +
    "In a similar fashion, you can also add an MSX-Audio device" + #CRLF$ +
    "(`<MSX-AUDIO>`, note that some programs also need the" + #CRLF$ +
    "`MusicModuleMIDI` device to" + #CRLF$ +
    "detect the Music Module, an empty SCC cartridge (`<SCC>`)," + #CRLF$ +
    "etc. Just browse the existing extensions, check the Boosted_MSX2_EN" + #CRLF$ +
    "configuration file and see what you can find." + #CRLF$ +
    "" + #CRLF$ +
    "Devices that contain ROM or RAM will have to be put inside a slot of the MSX," + #CRLF$ +
    "using the `<primary>` and `<secondary>` tags" + #CRLF$ +
    "as demonstrated with the above mentioned FMPAC example. Other devices don't" + #CRLF$ +
    "need this." + #CRLF$ +
    "Remember that you cannot put two devices that have a ROM in the same (sub)slot!" + #CRLF$ +
    "Just use a new free subslot if you need to add such a device and all your" + #CRLF$ +
    "primary slots are full. If a device does not need a slot, like the MSX-Audio" + #CRLF$ +
    "device, you can add as many as you like." + #CRLF$ +
    "" + #CRLF$ +
    "Another thing you may want to change: the amount of RAM of the MSX: change the" + #CRLF$ +
    Chr(34) + "size" + Chr(34) + " parameter in the `<MemoryMapper>` device config." + #CRLF$ +
    "" + #CRLF$ +
    "In principle all of the above mentioned things are also valid for extensions." + #CRLF$ +
    "The main difference is the fact that you should use `" + Chr(34) + "any" + Chr(34) + "` for the" + #CRLF$ +
    "slot specification as was already mentioned above. Just compare the fragment" + #CRLF$ +
    "above with the original FMPAC extension we based it on." + #CRLF$ +
    "" + #CRLF$ +
    "If you understand the basics of XML, you should be able to compose your MSX now!" + #CRLF$ +
    "You can use the ready-made configurations in `share/machines` as" + #CRLF$ +
    "examples.")

  OMSXHelp_Add("8. Contact Info",
    "Guia de Configuracao - 8. Contact Info",
    "Because openMSX is still in heavy development, feedback and bug reports are very" + #CRLF$ +
    "welcome!" + #CRLF$ +
    "" + #CRLF$ +
    "If you encounter problems, you have several options:" + #CRLF$ +
    "" + #CRLF$ +
    "1. Go to our IRC channel: #openMSX on libera.chat and ask your question there. Also reachable via webchat (https://web.libera.chat/#openMSX)! If you" + #CRLF$ +
    "don't get a reply immediately, please stick around for a while, or use one of" + #CRLF$ +
    "the other contact options. The majority of the developers lives in time zone" + #CRLF$ +
    "GMT+1. You may get no response if you contact them in the middle of the" + #CRLF$ +
    "night..." + #CRLF$ +
    "2. Post a message on the openMSX forum on MRC (http://www.msx.org/forum/semi-msx-talk/openmsx)." + #CRLF$ +
    "3. Create a new issue in the" + #CRLF$ +
    "openMSX issue tracker (https://github.com/openMSX/openMSX/issues)" + #CRLF$ +
    "on GitHub." + #CRLF$ +
    "You need a (free) log-in on GitHub to get access." + #CRLF$ +
    "4. Contact us and other users via one of the mailing lists. If you're a regular" + #CRLF$ +
    "user and want to discuss openMSX and possible problems, join our" + #CRLF$ +
    "`openmsx-user` mailing list. If you want to address the openMSX" + #CRLF$ +
    "developers directly," + #CRLF$ +
    "post a message to the `openmsx-devel` mailing list." + #CRLF$ +
    "More info on the openMSX mailing lists (https://sourceforge.net/p/openmsx/mailman)," + #CRLF$ +
    "including an archive of old messages, can be found at SourceForge." + #CRLF$ +
    "" + #CRLF$ +
    "For experienced users: if you get a crash, try to provide a `gdb`" + #CRLF$ +
    "backtrace. This will only work if you did not strip the openMSX binary of its" + #CRLF$ +
    "debug symbols." + #CRLF$ +
    "" + #CRLF$ +
    "In any case, try to give as much information as possible when you describe your" + #CRLF$ +
    "bug or request.")

EndProcedure

; ============================================================
; OMSXHelp_BuildUserManual1
; ============================================================
Procedure OMSXHelp_BuildUserManual1()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("1.1 New Versions of This Document",
    "Manual do Usuario - 1. Introduction",
    "The manual for the latest openMSX release can be found on the openMSX home page:" + #CRLF$ +
    "" + #CRLF$ +
    "http://openmsx.org/manual/ (http://openmsx.org/manual/)")

  OMSXHelp_Add("1.2 Purpose",
    "Manual do Usuario - 1. Introduction",
    "This manual is about openMSX, the open source MSX emulator that tries to achieve" + #CRLF$ +
    "near-perfect emulation by using a novel emulation model." + #CRLF$ +
    "You can find more information about openMSX on the" + #CRLF$ +
    "openMSX home page (http://openmsx.org/)." + #CRLF$ +
    "You can also download the emulator itself from there." + #CRLF$ +
    "" + #CRLF$ +
    "openMSX is not complete yet, which means that most things work but not all" + #CRLF$ +
    "features have been implemented yet." + #CRLF$ +
    "Many emulation features are implemented, but not all of them are represented" + #CRLF$ +
    "yet in the built-in Graphical User Interface. To get the most out of openMSX," + #CRLF$ +
    "we have written this guide." + #CRLF$ +
    "" + #CRLF$ +
    "This manual tells you how you can use openMSX, once it has been installed and" + #CRLF$ +
    "properly set up. You should be able to use most of the features of openMSX if" + #CRLF$ +
    "you have read it." + #CRLF$ +
    "If you are only using the GUI menus of openMSX, you don't have to pay attention" + #CRLF$ +
    "to the exact command and setting names. However it is still useful to read this" + #CRLF$ +
    "document to find out how openMSX works and learn its terminology." + #CRLF$ +
    "" + #CRLF$ +
    "Disclaimer:" + #CRLF$ +
    "We do not claim this guide is complete or even correct." + #CRLF$ +
    "What you do with the information in it is entirely at your own risk." + #CRLF$ +
    "We just hope it helps you enjoy openMSX more.")

  OMSXHelp_Add("1.3 Revision History",
    "Manual do Usuario - 1. Introduction",
    "For the revision history, please refer to the commit log (https://github.com/openMSX/openMSX/commits/master/doc/manual/user.html).")

  OMSXHelp_Add("1.4 Important Terms",
    "Manual do Usuario - 1. Introduction",
    "First some terms. Users of real MSX computers will probably not find it hard to understand these, but we'll explain what we mean with them to make sure the terms used in openMSX are clear for everyone." + #CRLF$ +
    "" + #CRLF$ +
    "**Machine:** With a machine we denote a single instance of a particular MSX computer. The bare computer, with a manufacturer name and a type name, just as they were sold." + #CRLF$ +
    "**Extensions:** All standard MSX computers have cartridge slots in which extension cartridges can be plugged into. They can be anything, like external disk drives, sound cartridges, serial interfaces, video cards, and multi-cartridges like the Carnivore 2 or the MegaFlashROM SCC+ SD." + #CRLF$ +
    "**Connectors:** The bare MSX machine has connectors to which equipment can be plugged of which the plug matches the connector (called " + Chr(34) + "pluggables" + Chr(34) + " here and there)." + #CRLF$ +
    "**Media:** These are containers with software on them. For example: ROM cartridges, floppy disks, and cassette tapes." + #CRLF$ +
    "**Setups:** A setup is the combination of a bare MSX machine, with its plugged-in extensions, plugged-in equipment via the machine's connectors and the media in the available media slots.")

  OMSXHelp_Add("2. Starting the Emulator",
    "Manual do Usuario - 2. Starting the Emulator",
    "In this chapter we will tell you how to select MSX machines and how to use extension cartridges, when starting up openMSX.")

  OMSXHelp_Add("2.1 Machines",
    "Manual do Usuario - 2. Starting the Emulator",
    "If you start openMSX without any command-line parameters, you will get the" + #CRLF$ +
    "default machine, which is stored in the `default_machine` setting. If you did" + #CRLF$ +
    "not change the default machine, the C-BIOS MSX2+ machine will be started." + #CRLF$ +
    "" + #CRLF$ +
    "However, if you created a setup earlier and marked it as the default setup (via the `default_setup` setting), that setup" + #CRLF$ +
    "will be loaded instead. This can be useful to always start up with your favourite" + #CRLF$ +
    "setup." + #CRLF$ +
    "" + #CRLF$ +
    "To select machines from the GUI, click Main menu" + #CRLF$ +
    "bar → Machine → Select MSX machine... This will" + #CRLF$ +
    "give a window in which you can see an overview of all available machines to" + #CRLF$ +
    "select from and hovering on items in the list shows you the most important" + #CRLF$ +
    "properties of these machines. You can also filter on type, region or any part" + #CRLF$ +
    "of the machine names. You can replace the current machine, or run another" + #CRLF$ +
    "machine along the existing running machines. An overview of the running" + #CRLF$ +
    "machines is shown at the top of the machine selection window, where you can" + #CRLF$ +
    "also change the default machine." + #CRLF$ +
    "" + #CRLF$ +
    "To select a different MSX machine from the command line, you can use the" + #CRLF$ +
    "`-machine` argument:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -machine Panasonic_FS-A1GT`" + #CRLF$ +
    "" + #CRLF$ +
    "It is also possible to use the `machine` command to switch at run time" + #CRLF$ +
    "in the `console`, which is explained in" + #CRLF$ +
    "the next chapter." + #CRLF$ +
    "" + #CRLF$ +
    "The C-BIOS machines come with ROMs installed; for other machines you will have" + #CRLF$ +
    "to install system ROMs yourself, see the Setup Guide for details." + #CRLF$ +
    "You can always use Main menu bar → Machine" + #CRLF$ +
    "→ Test MSX hardware to verify which system ROMs have been (correctly)" + #CRLF$ +
    "installed." + #CRLF$ +
    "" + #CRLF$ +
    "If you have saved a setup earlier (using the GUI via Main menu bar" + #CRLF$ +
    "→ Machine → Save setup or the `store_setup` command) you can also use the GUI via Main menu" + #CRLF$ +
    "bar → Machine → Load setup to go from that setup. But also" + #CRLF$ +
    "here you can use the command line (via the `-setup` command line" + #CRLF$ +
    "option) or the console (via the `setup` command).")

  OMSXHelp_Add("2.2 Extensions",
    "Manual do Usuario - 2. Starting the Emulator",
    "Extensions are simply MSX cartridges (extensions to the MSX system) that you" + #CRLF$ +
    "can plug into the emulated MSX. openMSX ships with many predefined" + #CRLF$ +
    "extensions. Note that many of them require firmware ROMs (called system ROMs);" + #CRLF$ +
    "see the Setup Guide for" + #CRLF$ +
    "details." + #CRLF$ +
    "" + #CRLF$ +
    "Using the GUI, use the Main menu bar →" + #CRLF$ +
    "Media menu where you can either first select the MSX cartridge slot to" + #CRLF$ +
    "put the extension into, or directly select the Extensions menu option to insert" + #CRLF$ +
    "an extension in the first free slot or remove extensions from the slot they're" + #CRLF$ +
    "in." + #CRLF$ +
    "" + #CRLF$ +
    "Let's now go into details using the FMPAC as an example. openMSX ships with a" + #CRLF$ +
    "definition (XML file) for the FMPAC extension, but you will have to `add` the" + #CRLF$ +
    "`fmpac.rom` firmware ROM yourself. When you have done so, you can" + #CRLF$ +
    "insert an FMPAC into the emulated MSX machine with the following command line:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -ext fmpac`" + #CRLF$ +
    "" + #CRLF$ +
    "Similar to machines, you can also use the `ext` command in the console to do it at run" + #CRLF$ +
    "time. You can also use something like `-extb` to explicitly specify" + #CRLF$ +
    "cartridge slot B." + #CRLF$ +
    "" + #CRLF$ +
    "If you look in the `share/extensions` directory (or when using the" + #CRLF$ +
    "console, type the TAB key with the `ext` command, see next chapter)," + #CRLF$ +
    "you will see all the extensions known to openMSX. For example `-ext" + #CRLF$ +
    "mbstereo` gives you the MoonBlaster stereo effect: FMPAC on the left" + #CRLF$ +
    "speaker and MSX-AUDIO on the right speaker.")

  OMSXHelp_Add("2.3 Other Command-line Options",
    "Manual do Usuario - 2. Starting the Emulator",
    "Some of the most used command-line options will be discussed later in this manual." + #CRLF$ +
    "For a complete list of them, type the following command:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -h`")

  OMSXHelp_Add("3.1 Console Introduction",
    "Manual do Usuario - 3. The Console and Settings",
    "Most functionality can now be controlled via the built-in GUI, using the" + #CRLF$ +
    "main menu bar as a starting point. This will be sufficient for most users." + #CRLF$ +
    "Originally, this GUI wasn't available and most functionality had to be" + #CRLF$ +
    "controlled differently. This way of control is still available (and will remain" + #CRLF$ +
    "so); this section will tell you more about it. You don't need to care about any" + #CRLF$ +
    "of these commands if the GUI is sufficient for you, but we still recommend having a look at the sections about " + Chr(34) + "Settings" + Chr(34) + #CRLF$ +
    "and " + Chr(34) + "Plugging in devices in connectors" + Chr(34) + "." + #CRLF$ +
    "" + #CRLF$ +
    "openMSX has a built-in command interface called the console," + #CRLF$ +
    "which allows you to control almost all aspects of openMSX while it is running." + #CRLF$ +
    "To access the console, make sure to have the main emulator window selected, and then press F10" + #CRLF$ +
    "(with default key mapping; Cmd+L on" + #CRLF$ +
    "Mac). This will" + #CRLF$ +
    "open a window with a command line inside the main openMSX window." + #CRLF$ +
    "" + #CRLF$ +
    "Typing `help`" + #CRLF$ +
    "gives a list of commands. Using PageUp you can see all of them. If you type" + #CRLF$ +
    "`help [command]` you will get help for the specified command. This" + #CRLF$ +
    "manual describes a few important commands; a full list can be found in the Console Command Reference. The" + #CRLF$ +
    "console can be used to change disk images, plug in `joysticks` or `mice`, change settings at run time and to change key bindings," + #CRLF$ +
    "among others. It actually gives you full control of openMSX: if it can't be" + #CRLF$ +
    "done via the console, it's probably impossible!" + #CRLF$ +
    "" + #CRLF$ +
    "One very practical feature of the console command line is that you can use" + #CRLF$ +
    Chr(34) + "completion" + Chr(34) + " features. Just try typing half a command and then press the TAB" + #CRLF$ +
    "key; openMSX will then try to finish the word you were typing or show the" + #CRLF$ +
    "possibilities in case of ambiguities. You can use it also for file names," + #CRLF$ +
    "connectors, pluggables and settings, and even for machine and extension names." + #CRLF$ +
    "" + #CRLF$ +
    "The console has very common keyboard controls, similar to most text editors." + #CRLF$ +
    "It also supports copy/paste. Some other controls may be less obvious:" + #CRLF$ +
    "" + #CRLF$ +
    "**key(s) | function**" + #CRLF$ +
    "- Up -- show previous command from history (starting with current command line)" + #CRLF$ +
    "- Down -- show next command from history (starting with current command line)" + #CRLF$ +
    "- Tab -- attempt completion of current command" + #CRLF$ +
    "- Enter/Return -- execute command line")

  OMSXHelp_Add("3.2 Some Simple Console Commands",
    "Manual do Usuario - 3. The Console and Settings",
    "You can reset your MSX with the console command `reset` and exit openMSX with the command" + #CRLF$ +
    "`exit`. As" + #CRLF$ +
    "explained in the previous chapter, you can change machines with the `machine` command and" + #CRLF$ +
    "you can insert extensions with the `ext` command (use tab-completion to see the" + #CRLF$ +
    "list of possible extension names). Remove extensions with the `remove_extension` command or" + #CRLF$ +
    "get a list of the currently inserted extensions with the `list_extensions` command. Other" + #CRLF$ +
    "commands will be discussed later on in this manual.")

  OMSXHelp_Add("3.3 Settings",
    "Manual do Usuario - 3. The Console and Settings",
    "There are many settings in openMSX for customization, changing preferences or" + #CRLF$ +
    "enabling extras. The most important ones are in the Main menu bar → Settings menu in the GUI." + #CRLF$ +
    "There is also an Advanced item in that menu that will give a huge window with" + #CRLF$ +
    "all possible settings. Usually, you can revert a setting to its default value" + #CRLF$ +
    "via right click → Restore default in" + #CRLF$ +
    "the context-menu of that setting." + #CRLF$ +
    "" + #CRLF$ +
    "Using the console, you can use the command `set` to change any setting. E.g., you can" + #CRLF$ +
    "use it to set the current `scaler`. Issuing" + #CRLF$ +
    "`set` with only the setting name (like `set scale_algorithm`), queries" + #CRLF$ +
    "the current value of that setting." + #CRLF$ +
    "Settings that have only two possible values can also be toggled with the" + #CRLF$ +
    "`toggle`" + #CRLF$ +
    "command (an example is the default key binding of F11 to `toggle" + #CRLF$ +
    "fullscreen`, see also below). A (hopefully) complete list of settings can" + #CRLF$ +
    "also be found in the Console Command Reference. Note that using the " + Chr(34) + "tab completion" + Chr(34) + " feature can help you a lot" + #CRLF$ +
    "in getting an idea of what settings are possible, as it will only complete" + #CRLF$ +
    "possible options. Just try that." + #CRLF$ +
    "" + #CRLF$ +
    "Let's give a few examples of common settings and how to change them." + #CRLF$ +
    "" + #CRLF$ +
    "If the MSX goes too fast or too slow, adjust the emulation speed with the" + #CRLF$ +
    "`speed` setting," + #CRLF$ +
    "which has the speed percentage as parameter. So, typing `set" + #CRLF$ +
    "speed 120`, will run the emulated MSX at 120% of normal MSX speed." + #CRLF$ +
    "This is useful for debugging purposes (slow down) or when you want to skip" + #CRLF$ +
    "certain parts of a demo for example (speed up). The GUI has this setting under" + #CRLF$ +
    "Main menu bar → Settings → Speed → Emulation." + #CRLF$ +
    "" + #CRLF$ +
    "Some MSX machines like the Panasonic FS-A1GT have built-in software (called" + #CRLF$ +
    "firmware) which can be switched on and off via a switch on the machine itself." + #CRLF$ +
    "In openMSX the internal software is switched off by default, but you can switch" + #CRLF$ +
    "it on with the following setting: `set firmwareswitch on`. If the" + #CRLF$ +
    "currently running machine has a firmware switch, a toggle option will show up in" + #CRLF$ +
    "the Main menu bar → Machine menu to control it." + #CRLF$ +
    "" + #CRLF$ +
    "If you're not really interested in how long a real MSX would take to load" + #CRLF$ +
    "from diskette, cassette or laserdisc, you could enable the full speed when" + #CRLF$ +
    "loading feature: `set fullspeedwhenloading on`," + #CRLF$ +
    "or from the GUI at Main menu bar → Settings" + #CRLF$ +
    "→ Speed → Go full speed when loading. It" + #CRLF$ +
    "runs openMSX at maximum speed whenever it thinks that the MSX is loading. The" + #CRLF$ +
    "drawbacks: it might detect a bit too late that the MSX isn't loading anymore," + #CRLF$ +
    "so sometimes the first notes of music played right after loading might be" + #CRLF$ +
    "fast. Also, when loading openMSX will use all available CPU power to get" + #CRLF$ +
    "maximum speed; the feature has no influence on the state of the MSX, of course." + #CRLF$ +
    "" + #CRLF$ +
    "You can save all your current settings with the `save_settings` command. At start" + #CRLF$ +
    "up, alternative settings files can be loaded by using the `-setting`" + #CRLF$ +
    "command-line option. You can also use the `load_settings` command to load" + #CRLF$ +
    "settings at run time. Settings that are not mentioned in the saved settings" + #CRLF$ +
    "file that you are loading will be untouched. By default, openMSX will" + #CRLF$ +
    "automatically save your settings on exit (whichever way they were changed).")

  OMSXHelp_Add("3.4 Plugging in devices in connectors",
    "Manual do Usuario - 3. The Console and Settings",
    "The Main menu bar → Connectors menu" + #CRLF$ +
    "will show you all connectors of the currently running" + #CRLF$ +
    "machine and which (pluggable) device is currently plugged in. You can easily" + #CRLF$ +
    "plug in other devices there, e.g. a mouse in a joystick port." + #CRLF$ +
    "" + #CRLF$ +
    "Examples of connectors are the joystick ports, the printer port, the MIDI in" + #CRLF$ +
    "and out connector, the cassette port, etc. Examples of pluggables are `joysticks` and `mice`, but also printers and MIDI equipment." + #CRLF$ +
    "" + #CRLF$ +
    "In the console, you can use the command `plug` to do this. The command" + #CRLF$ +
    "`plug`" + #CRLF$ +
    "without any parameters will show a list of connectors and what pluggables are" + #CRLF$ +
    "plugged into them. Using `plug [connector]` will only show what is" + #CRLF$ +
    "plugged into [connector]. It will come as no surprise that the command `plug" + #CRLF$ +
    "[connector] [pluggable]` will plug the [pluggable] into the [connector]." + #CRLF$ +
    "" + #CRLF$ +
    "Note that using the " + Chr(34) + "tab completion" + Chr(34) + " feature can help you a lot in getting an" + #CRLF$ +
    "idea of what plug commands are possible, as it will only complete possible" + #CRLF$ +
    "connectors and their possible pluggables. Just give it a try.")

  OMSXHelp_Add("4.1 Overview",
    "Manual do Usuario - 4. The Graphical User Interface",
    "The Graphical User Interface (GUI) in openMSX has been built with the Dear ImGui library (https://github.com/ocornut/imgui). It allows the developers to relatively easily build and extend the" + #CRLF$ +
    "GUI for all supported platforms. The price we have to pay is that it only works" + #CRLF$ +
    "on systems with 3D hardware acceleration support and that it does not look (a" + #CRLF$ +
    "lot) like the native GUIs of well-known desktop environments like Windows," + #CRLF$ +
    "macOS, GNOME or KDE." + #CRLF$ +
    "" + #CRLF$ +
    "General help on basic usage of the Dear ImGui features can be found in the" + #CRLF$ +
    "Main menu bar → Help → Dear ImGui user" + #CRLF$ +
    "guide menu option." + #CRLF$ +
    "" + #CRLF$ +
    "The current GUI is intended for mouse control. It can (at least" + #CRLF$ +
    "partially) also be controlled with a keyboard, but so far this has not been a major focus of development," + #CRLF$ +
    "so this will definitely not be optimal. Control via a game controller is" + #CRLF$ +
    "currently disabled, but that may change in future versions." + #CRLF$ +
    "" + #CRLF$ +
    "Although the current openMSX release already has a lot of functionality" + #CRLF$ +
    "available via the GUI, it is still incomplete and the user experience could use some love. We appreciate feedback on the GUI a lot and we will try to" + #CRLF$ +
    "improve it in later releases based on your input. Please see section 10. Contact Info for more" + #CRLF$ +
    "information on how to provide feedback." + #CRLF$ +
    "" + #CRLF$ +
    "Almost all commands and settings available in the GUI have an underlying" + #CRLF$ +
    "console command and setting accessible via the console. In several places" + #CRLF$ +
    "these underlying commands are mentioned in this manual. Power users especially" + #CRLF$ +
    "will appreciate all the ways they can manipulate openMSX with external programs, scripts," + #CRLF$ +
    "or other more advanced methods.")

  OMSXHelp_Add("4.2 Main menu bar",
    "Manual do Usuario - 4. The Graphical User Interface",
    "As already mentioned before in this manual, the GUI has a Main menu bar at the" + #CRLF$ +
    "top of the openMSX main window. The menu bar fades out when the MSX screen has" + #CRLF$ +
    "focus. To get it back, move the mouse cursor to the top of the openMSX window." + #CRLF$ +
    "" + #CRLF$ +
    "The Main menu bar contains the following top level menus:" + #CRLF$ +
    "" + #CRLF$ +
    "**Machine:** Selecting the different machines (computer models)" + #CRLF$ +
    "**Media:** Inserting and removing media: ROM or extension cartridges, disks, cassette" + #CRLF$ +
    "tapes, laserdiscs, ..." + #CRLF$ +
    "**Connectors:** Controlling which devices are plugged into which connectors:" + #CRLF$ +
    "printers, joysticks, mice, dongles, MIDI equipment, ..." + #CRLF$ +
    "**Save state:** All save state and replay related functionality, plus some related settings." + #CRLF$ +
    "**Tools:** Several tools that can make your life easier, like virtual keyboard," + #CRLF$ +
    "copying and pasting, audio and video capture, disk manipulation/management," + #CRLF$ +
    "trainers and cheats, audio chip tools and gadgets, etc.." + #CRLF$ +
    "**Settings:** A collection of the most important settings for Video, Sound," + #CRLF$ +
    "Speed, Input, the GUI and Misc settings." + #CRLF$ +
    "**Debugger:** A set of powerful debugging tools for the developer. Practically all" + #CRLF$ +
    "functionality from the old, standalone openMSX debugger has been included." + #CRLF$ +
    "**Help:** Links to get (more) help on using openMSX." + #CRLF$ +
    "" + #CRLF$ +
    "If you like, you can even undock the main menu bar from the main openMSX" + #CRLF$ +
    "window. This is especially useful if you want to stream the openMSX main" + #CRLF$ +
    "window, without showing your interaction with the openMSX menus." + #CRLF$ +
    "Use the triangular icon on the left in the Main menu bar to undock or redock" + #CRLF$ +
    "it.")

  OMSXHelp_Add("4.3 Other default GUI elements",
    "Manual do Usuario - 4. The Graphical User Interface",
    "Besides the Main menu bar, some other main GUI elements you are likely to see." + #CRLF$ +
    "Here is a small overview." + #CRLF$ +
    "" + #CRLF$ +
    "**Reverse bar:** " + #CRLF$ +
    "**OSD icons:** " + #CRLF$ +
    "**Status bar:** ")

  OMSXHelp_Add("4.4 Advanced topics",
    "Manual do Usuario - 4. The Graphical User Interface",
    "The GUI allows you to put any window inside the main openMSX window, or outside" + #CRLF$ +
    "of it. But windows can also be docked together, at the (left/right/top/bottom)" + #CRLF$ +
    "edge of any window except the main window, even in a tab bar." + #CRLF$ +
    "" + #CRLF$ +
    "The GUI also has specific settings, like shortcuts that can be used in the GUI only." + #CRLF$ +
    "" + #CRLF$ +
    "Also, you can save and load layouts of windows that are combined with each" + #CRLF$ +
    "other. This is still a rather rough feature, as it also saves and loads other" + #CRLF$ +
    "data, like the history information from some menus." + #CRLF$ +
    "" + #CRLF$ +
    "As an example of a layout, we created one with a debugger focus. The image below shows:" + #CRLF$ +
    "" + #CRLF$ +
    "- docking with split windows horizontal/vertical, sometimes multiple times" + #CRLF$ +
    "- docking with tab bar (e.g. memory/VRAM/PSG regs)," + #CRLF$ +
    "- hiding the (sub)window title, as it is often quite obvious. For " + Chr(34) + "stack" + Chr(34) + " this wasn't done on purpose, to show the difference.")

  OMSXHelp_Add("4.4.1 Some tips and tricks",
    "Manual do Usuario - 4. The Graphical User Interface",
    "Docking windows can be done in two main ways. Both start by dragging a window" + #CRLF$ +
    "over another one. If you do that a popup will appear with 5 sections (middle," + #CRLF$ +
    "east, west, north, south)." + #CRLF$ +
    "" + #CRLF$ +
    "- If you drop the window in the middle, then you dock both windows into a tab-bar. This is useful if you don't need to see both windows at once (and when both have approx the same size). As an alternative you can also drag two title bars onto each other." + #CRLF$ +
    "- If you drop on one of the 4 directions, the window will split in two (horizontally/vertically) and the two windows are shown next to each other. (The two sections can be resized via dragging the divider line)." + #CRLF$ +
    "" + #CRLF$ +
    "In both cases the windows are now grouped, they will move together and minimize together." + #CRLF$ +
    "" + #CRLF$ +
    "The debugger features can require a lot of screen space. Showing everything at" + #CRLF$ +
    "once won't be possible (unless maybe if you have a 4K monitor). To accomodate" + #CRLF$ +
    "for this, we do try to pay attention to making all openMSX windows compact." + #CRLF$ +
    "" + #CRLF$ +
    "Here are some tips focused on that:" + #CRLF$ +
    "" + #CRLF$ +
    "- Create groups of windows (via docking) that you always use together. Then you can minimize/restore such groups." + #CRLF$ +
    "- You'll soon be familiar with the different debug windows, and then a title like " + Chr(34) + "CPU flags" + Chr(34) + " isn't very useful anymore. You can hide the title via the window menu (the downwards triangle in the top-left corner of a (docked) window). This does save some space." + #CRLF$ +
    "- Use tab-bars for windows that you don't (often) need together. For example (depending on your use case) you may not need the console together with the memory view, then dock these two in a tab-bar instead of next to each other. Similar for the bitmap and tile viewer, you'll not often need these together, Or just close those windows you don't currently/often need." + #CRLF$ +
    "- Some (sub)windows have a configurable layout. E.g. right click in the " + Chr(34) + "CPU flags" + Chr(34) + " window, then in the context window choose between horizontal/vertical layout. Depending on how you arrange your other windows, one of these two layouts may fit better. Or hide the undocumented XY flags, you don't often need these." + #CRLF$ +
    "- In many tables you can hide columns that you don't (currently) need. For example in the " + Chr(34) + "Disassembly" + Chr(34) + " window right-click on the table header, then you can e.g. hide the " + Chr(34) + "opcode" + Chr(34) + " column to save some space. (In most tables you can also drag the columns into a different order). On the other hand, some columns are hidden by default, like the " + Chr(34) + "Action" + Chr(34) + " and " + Chr(34) + "Once" + Chr(34) + " column in the " + Chr(34) + "Breakpoints" + Chr(34) + " window, unhide these if you need them." + #CRLF$ +
    "- Some windows have collapsible sections. For example the " + Chr(34) + "Tile viewer" + Chr(34) + ", once you've chosen the correct settings, you can collapse the " + Chr(34) + "Settings" + Chr(34) + " section to make more room for the " + Chr(34) + "Pattern Table" + Chr(34) + " and " + Chr(34) + "Name Table" + Chr(34) + " sections. And maybe you don't always need to see both these tables? Same for the " + Chr(34) + "Sprite viewer" + Chr(34) + ", " + Chr(34) + "VDP register" + Chr(34) + ", etc." + #CRLF$ +
    "" + #CRLF$ +
    "- You can sometimes more easily navigate between them via CTRL-TAB. This also works for docked windows. And you can also use this to bring window to the front." + #CRLF$ +
    "- If you want to move them around without accidentally docking them, then grab the window on some empty region (rather than the title bar) to move them.")

  OMSXHelp_Add("5. Running MSX Software and Using Media",
    "Manual do Usuario - 5. Running MSX Software and Using Media",
    "With this information, you can run most of the existing MSX software. If you" + #CRLF$ +
    "use the GUI, refer to the Main menu bar →" + #CRLF$ +
    "Media menu." + #CRLF$ +
    "" + #CRLF$ +
    "For all supported media files, there is a list of filename extensions that are" + #CRLF$ +
    "recognized by openMSX. If you run openMSX from the command line, adding a file" + #CRLF$ +
    "name (with path if necessary) as a command-line option, openMSX will insert the" + #CRLF$ +
    "file as the proper type of media. The list of supported extensions for each" + #CRLF$ +
    "media type can be easily retrieved with `-h` option on the command" + #CRLF$ +
    "line. For some media, examples of command-line usage are given below." + #CRLF$ +
    "" + #CRLF$ +
    "If you drag and drop a file with one of these supported extensions" + #CRLF$ +
    "into the main openMSX window, openMSX will try to handle it accordingly.")

  OMSXHelp_Add("5.1 Running ROM software",
    "Manual do Usuario - 5. Running MSX Software and Using Media",
    "In the GUI you can choose which ROM software you want to run by selecting a" + #CRLF$ +
    "Cartridge Slot from the Main menu bar → Media menu. This will open a" + #CRLF$ +
    "window where you can tell openMSX exactly what you want to put in the slot," + #CRLF$ +
    "like a ROM image, which mapper to use if the automatically selected one isn't" + #CRLF$ +
    "correct, and whether the MSX should be reset after inserting." + #CRLF$ +
    "" + #CRLF$ +
    "And finally, you can" + #CRLF$ +
    "also browse for and select (multiple) IPS patches to apply to the selected ROM" + #CRLF$ +
    "image. IPS patches are files that describe a modification of the ROM you are" + #CRLF$ +
    "applying it to, e.g. a translation or a cheat. This way you do not need to" + #CRLF$ +
    "alter the original files." + #CRLF$ +
    "" + #CRLF$ +
    "## Command line and console" + #CRLF$ +
    "" + #CRLF$ +
    "Using the command line, suppose you want to run the ROM file" + #CRLF$ +
    "`galious.rom`. Then you simply type:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx galious.rom`" + #CRLF$ +
    "" + #CRLF$ +
    "and the emulated MSX will run the game. (Of course," + #CRLF$ +
    "in this case, the file `galious.rom` should be in the current directory." + #CRLF$ +
    "You can also explicitly indicate that the thing is a ROM image like this:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -cart galious.gam`" + #CRLF$ +
    "" + #CRLF$ +
    "This lets openMSX know that the file `galious.gam` is a ROM" + #CRLF$ +
    "cartridge and that openMSX should insert it in the first available free" + #CRLF$ +
    "cartridge slot. You can also use `-carta` to explicitly specify" + #CRLF$ +
    "cartridge slot A." + #CRLF$ +
    "" + #CRLF$ +
    "In the event openMSX doesn't have the ROM in the ROM database and fails auto" + #CRLF$ +
    "detection of the mapper type, you can specify the mapper to `Konami`" + #CRLF$ +
    "(for instance) like this:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx galious.rom -romtype Konami`" + #CRLF$ +
    "" + #CRLF$ +
    "Note that in practice you won't need this, because most ROM images are in the" + #CRLF$ +
    "database or auto detected if they are not. The `-romtype` option" + #CRLF$ +
    "should follow the ROM it applies to immediately on the command line." + #CRLF$ +
    "" + #CRLF$ +
    "To apply an IPS patch using the command line, provide the IPS" + #CRLF$ +
    "filename like this:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -cart galious.rom -ips galiouspatch.ips`" + #CRLF$ +
    "" + #CRLF$ +
    "As with the `-romtype` option, the `-ips` option on the" + #CRLF$ +
    "command line must follow the ROM file it applies to directly. You can also use" + #CRLF$ +
    "multiple `-ips` options if you want to apply multiple patches." + #CRLF$ +
    "" + #CRLF$ +
    "If you already have openMSX running and want to insert cartridges at runtime" + #CRLF$ +
    "(maybe even when the MSX is powered on), you can use the `carta` command in the `console` as well, which is just as" + #CRLF$ +
    "powerful.")

  OMSXHelp_Add("5.2 Running Disk Software",
    "Manual do Usuario - 5. Running MSX Software and Using Media",
    "## 5.2.1 Using Disk Images" + #CRLF$ +
    "" + #CRLF$ +
    "Of course, this can only be done if the running machine has one or more disk" + #CRLF$ +
    "drives. From the GUI, simply select the Disk Drive you want to change the disk" + #CRLF$ +
    "image for. This will open a Disk Drive window where you can specify what must" + #CRLF$ +
    "be in the drive: a disk image (select a disk image file, or create a new disk" + #CRLF$ +
    "image), a directory to be used as disk (see next section), a RAM disk" + #CRLF$ +
    "(temporary disk image in RAM), or nothing at all. As with ROM images," + #CRLF$ +
    "IPS patches can be selected to be applied." + #CRLF$ +
    "" + #CRLF$ +
    "Disk images in compressed format ((g)zip, xsa) can be used as regular disk images," + #CRLF$ +
    "but do note that they are read-only." + #CRLF$ +
    "Note that in zipped disk images, the first file that is packed into the zip file" + #CRLF$ +
    "will be used as disk image." + #CRLF$ +
    "" + #CRLF$ +
    "To specify disk images on the command line, you can type:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx relax.dsk`" + #CRLF$ +
    "" + #CRLF$ +
    "for example. Or, if you use a disk image with a filename extension that is" + #CRLF$ +
    "unknown to openMSX:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -diska relax.di`" + #CRLF$ +
    "" + #CRLF$ +
    "You can also change disks at run-time of course. Just type" + #CRLF$ +
    "" + #CRLF$ +
    "``diska` <diskimage>`" + #CRLF$ +
    "" + #CRLF$ +
    "in the `console` to put the specified" + #CRLF$ +
    "disk image in drive A. To eject the disk from drive A, use:" + #CRLF$ +
    "" + #CRLF$ +
    "``diska` eject`" + #CRLF$ +
    "" + #CRLF$ +
    "Note that inserting another disk image automatically ejects the previous one." + #CRLF$ +
    "" + #CRLF$ +
    "To apply an IPS patch, provide the IPS filename like this:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx SDSNAT1C.DSK -ips sdsnat1-eng.ips`" + #CRLF$ +
    "" + #CRLF$ +
    "On the command line, the `-ips` option must immediately follow the disk image" + #CRLF$ +
    "it applies to. You can also use multiple `-ips` options if you" + #CRLF$ +
    "want to apply multiple patches." + #CRLF$ +
    "" + #CRLF$ +
    "You can also apply the patches when changing disks at run-time in the console." + #CRLF$ +
    "Just type something like" + #CRLF$ +
    "" + #CRLF$ +
    "``diska` SDSNAT1C.DSK.gz" + #CRLF$ +
    "sdsnat1-eng.ips sd-cheat.ips`" + #CRLF$ +
    "" + #CRLF$ +
    "in the console to put the specified gzipped disk image SDSNAT1C.DSK.gz in drive" + #CRLF$ +
    "A, with both IPS patches applied." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.2.2 Using Directories as Disks" + #CRLF$ +
    "" + #CRLF$ +
    "The DirAsDsk feature permits you to use a directory on your host computer's" + #CRLF$ +
    "file system as a disk image for your emulated MSX. Note that this has nothing" + #CRLF$ +
    "to do with harddisk emulation. It simply creates a" + #CRLF$ +
    "virtual disk structure in memory from the files that are in the directory" + #CRLF$ +
    "that you specified as if it were a disk image. So, on the command line:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -diska .`" + #CRLF$ +
    "" + #CRLF$ +
    "will try to put all files of the current directory on a disk image in memory and" + #CRLF$ +
    "start openMSX with it. The actual data is still read from/written to the files" + #CRLF$ +
    "in your directory so that if you change the contents of the files, these changes" + #CRLF$ +
    "are immediately visible in the emulated MSX. This way you can for instance" + #CRLF$ +
    "edit source files with your favourite text editor but compile them immediately in" + #CRLF$ +
    "the emulated MSX." + #CRLF$ +
    "" + #CRLF$ +
    "Using the default value of the setting `DirAsDSKmode` (full), all changes to the" + #CRLF$ +
    "directory on the host system and on the MSX system are performed, so" + #CRLF$ +
    "that they are immediately visible to the other side. If this is not the desired" + #CRLF$ +
    "behaviour, please check the documentation of that setting." + #CRLF$ +
    "" + #CRLF$ +
    "Be careful when writing to files from your emulated MSX. In the" + #CRLF$ +
    "default 'full' mode, you can change/overwrite/delete/corrupt files on your host" + #CRLF$ +
    "system, if you made them accessible for the emulated MSX! Still, this is the" + #CRLF$ +
    "behaviour what most people want/expect and it's very useful if you know what" + #CRLF$ +
    "you are doing." + #CRLF$ +
    "" + #CRLF$ +
    "Note that MSX disks only have a limited capacity, typically 720kB. If the" + #CRLF$ +
    "host directory contains more data, then some host files will be ignored and" + #CRLF$ +
    "they will not appear in the virtual disk image." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.2.3 Using Real Disks" + #CRLF$ +
    "" + #CRLF$ +
    "We do not recommend using real disks (e.g. with a USB floppy drive)" + #CRLF$ +
    "with openMSX. There is no specific support for this." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.2.4 Managing Disk Images" + #CRLF$ +
    "" + #CRLF$ +
    "openMSX has a special command to perform file imports and" + #CRLF$ +
    "exports, with support for normal disk images, Sunrise IDE harddisk images with partitions (FAT12" + #CRLF$ +
    "only), and Nextor harddisk images with partitions (FAT12 and FAT16)." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI, you can find this tool under Main menu" + #CRLF$ +
    "bar → Tools → Disk Manipulator. This will open a big window," + #CRLF$ +
    "which has many powerful options. On the left side you select the emulated" + #CRLF$ +
    "machine drive (any existing drive, or the " + Chr(34) + "Virtual drive" + Chr(34) + " which only exists in" + #CRLF$ +
    "memory). On the right side, you see the host directories with their file" + #CRLF$ +
    "content. Use the arrows in the middle to transfer files, the plus button on the" + #CRLF$ +
    "left side to create a new (hard) disk image and the directory button to browse" + #CRLF$ +
    "for a disk image to insert." + #CRLF$ +
    "" + #CRLF$ +
    "For the console commands that are behind this window, please see the separate manual called" + #CRLF$ +
    "Using diskmanipulator.")

  OMSXHelp_Add("5.3 Running Tape Software",
    "Manual do Usuario - 5. Running MSX Software and Using Media",
    "First thing you need to be aware of: this can only be done on machines that" + #CRLF$ +
    "have a cassette port. Most do, but the MSX turboR machines do not, so tape" + #CRLF$ +
    "software cannot be used on these machines." + #CRLF$ +
    "" + #CRLF$ +
    "Cassette/tape image file formats that are supported are WAV files (raw digitized" + #CRLF$ +
    "recordings of real tapes) and CAS/TSX files. Differences are explained below." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI select Main menu bar → Media → Tape" + #CRLF$ +
    "Deck to open the virtual cassette player control window, which allows" + #CRLF$ +
    "you to insert a cassette tape image." + #CRLF$ +
    "" + #CRLF$ +
    "To insert a tape image from the `console`, type:" + #CRLF$ +
    "" + #CRLF$ +
    "``cassetteplayer` insert <file>.wav`" + #CRLF$ +
    "" + #CRLF$ +
    "Once inserted, in MSX Basic, type:" + #CRLF$ +
    "" + #CRLF$ +
    "`run" + Chr(34) + "cas:" + Chr(34) + "`" + #CRLF$ +
    "" + #CRLF$ +
    "(or another command to load the program on 'tape'.)" + #CRLF$ +
    "" + #CRLF$ +
    "The cassetteplayer related commands/settings that are controlled in the tape deck window are:" + #CRLF$ +
    "" + #CRLF$ +
    "- `cassetteplayer rewind`, to rewind the tape" + #CRLF$ +
    "- `cassetteplayer eject`, to eject the tape" + #CRLF$ +
    "- `cassetteplayer new <filename>`, to create a new WAV cassette image to record to; also sets the cassette player in record mode" + #CRLF$ +
    "- `cassetteplayer play`, to set the cassette player in play mode (when you've just recorded to the cassette)" + #CRLF$ +
    "- `cassetteplayer record`, to set the cassette player in record mode, to append to existing cassette images (NOT IMPLEMENTED YET)" + #CRLF$ +
    "- `set cassetteplayer_volume`, to set the volume of the cassette player sound (yeah, the screeching tape sounds!)" + #CRLF$ +
    "" + #CRLF$ +
    "As you can see in this list, appending to existing cassette images (or" + #CRLF$ +
    "(partially) overwriting them) is not supported (yet). If you want to save" + #CRLF$ +
    "again, just insert a blank tape by using the `cassetteplayer new`" + #CRLF$ +
    "command again (or the Record button with the circle icon in the Tape Deck" + #CRLF$ +
    "window)." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.3.1 Using CAS and TSX files" + #CRLF$ +
    "" + #CRLF$ +
    "You can also use the so-called CAS files and also TSX files. Use them exactly as you would use WAV" + #CRLF$ +
    "files, described in the previous section." + #CRLF$ +
    "" + #CRLF$ +
    "We don't support using CAS files by patching a BIOS natively, because it is not" + #CRLF$ +
    "really something we want: we prefer a more authentic emulation without hacks" + #CRLF$ +
    "like this." + #CRLF$ +
    "So, the CAS (and also TSX) files are automatically converted to WAV files, internally. Note" + #CRLF$ +
    "that the loading time is drastically longer this way (but the Main menu bar → Settings → Speed → Go full speed when loading `setting`" + #CRLF$ +
    "will help a lot). On the other hand, you will be able to hear the cassette" + #CRLF$ +
    "sounds also with these file formats... Admit it, using cassettes with an MSX" + #CRLF$ +
    "without those characteristic sounds just wouldn't be the same." + #CRLF$ +
    "" + #CRLF$ +
    "To make it even more comfortable to run software from cassette tapes, check the Main menu bar → Media → Tape Deck → Controls → (try to) Auto Run `setting`, that will attempt to" + #CRLF$ +
    "type the loading instruction for you after the MSX has started up." + #CRLF$ +
    "" + #CRLF$ +
    "Note that saving to existing cassette images is not possible; you can" + #CRLF$ +
    "only save to new cassette images in WAV format.")

  CBody = "The Sunrise IDE interface was the first one to be emulated in openMSX, so by now it's thoroughly supported." + #CRLF$ +
    "Later support for two types of SCSI interfaces was added:" + #CRLF$ +
    "the Gouda/Novaxis SCSI interface and the MEGA-SCSI, followed by support for" + #CRLF$ +
    "the MegaFlashROM SCC+ SD, the Carnivore 2, and the Beer IDE interfaces. Not all harddisk management tools may support these newer mass storage devices." + #CRLF$ +
    "" + #CRLF$ +
    "The extensions that enable this have a built-in mass storage (harddisk, SD card, etc.) configuration, in the" + #CRLF$ +
    "form of a 100MB disk image. This is the default size: if the harddisk" + #CRLF$ +
    "image is not present, a file is created with this size. The image will end up" + #CRLF$ +
    "in your openMSX user" + #CRLF$ +
    "directory`/persistent/NAME/untitled1/IMAGENAME.dsk`, where NAME is" + #CRLF$ +
    "the name of the extension used and IMAGENAME is a name that is configured in" + #CRLF$ +
    "the extension's XML file (e.g. default `hd.dsk` for the Sunrise IDE)." + #CRLF$ +
    "" + #CRLF$ +
    "When using these extensions for the first time, you have to treat them as if" + #CRLF$ +
    "they were real interfaces with a blank harddisk connected. How they should be initialised" + #CRLF$ +
    "depends on the type. We advise you read the manuals, the sections" + #CRLF$ +
    "below give some hints. The `diskmanipulator` may be helpful, as it" + #CRLF$ +
    "supports harddisk images with both Sunrise IDE and Nextor compatible partition" + #CRLF$ +
    "table formats." + #CRLF$ +
    "" + #CRLF$ +
    "For clarity's sake: since the emulation is done on a big disk image, data corruption of your PC's harddisk is impossible. You will need free" + #CRLF$ +
    "disk space for this image, however (default size: 100MB). In other words, you cannot use a normal PC harddisk as an MSX harddisk for these extensions." + #CRLF$ +
    "" + #CRLF$ +
    "The way to use files from your real PC harddisk on an emulated MSX," + #CRLF$ +
    "is by using the DirAsDsk feature. See the DirAsDsk section for more details." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI under Main menu bar → Media" + #CRLF$ +
    "you can find entries like " + Chr(34) + "Hard Disk A" + Chr(34) + " or " + Chr(34) + "CDROM Drive" + #CRLF$ +
    "A" + Chr(34) + " if such devices are connected to the (IDE/SCSI/SD) extension in your" + #CRLF$ +
    "currently active machine. If wanted, you can also change the used image," + #CRLF$ +
    "but note that media like harddisks require the machine" + #CRLF$ +
    "to be powered off first (see the Main menu" + #CRLF$ +
    "bar → Machine menu for the `power`" + #CRLF$ +
    "setting)." + #CRLF$ +
    "" + #CRLF$ +
    "To specify the harddisk image to be used on the command line, use the applicable command-line option, e.g. for Sunrise IDE:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -ext ide -hda symbos.dsk`" + #CRLF$ +
    "" + #CRLF$ +
    "This command gives you the ide extension with symbos.dsk as harddisk" + #CRLF$ +
    "image. You can also change the harddisk image at run time in the `console`, with a command similar to the `diska` command:" + #CRLF$ +
    "" + #CRLF$ +
    "``hda` <diskimage>`" + #CRLF$ +
    "" + #CRLF$ +
    "Please read the following sections for details about the specific extensions." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.4.1 Sunrise IDE" + #CRLF$ +
    "" + #CRLF$ +
    "The extension for this is called 'ide' (shown with the full name Sunrise" + #CRLF$ +
    "ATA-IDE in the extension selector). By default it has a harddisk connected to" + #CRLF$ +
    "the master port and a CD-ROM player connected to the slave port." + #CRLF$ +
    "" + #CRLF$ +
    "The 'ide' extension needs the BIOS that can be flashed into the Sunrise IDE" + #CRLF$ +
    "interface. It can be downloaded from the Sunrise for MSX web site (http://www.msx.ch/sunformsx/download/dl-ide.html)." + #CRLF$ +
    "" + #CRLF$ +
    "The initialisation of a Sunrise IDE harddisk is described in the text files" + #CRLF$ +
    "that come with the FDISK program for IDE, downloadable from the Sunrise for MSX web site (http://www.msx.ch/sunformsx/download/dl-ide.html). There are also some (https://www.msx.org/forum/semi-msx-talk/emulation/how-get-sunrise-ide-working-openmsx)" + #CRLF$ +
    "threads (https://www.msx.org/forum/semi-msx-talk/emulation/openmsx-harddisk-emulation)" + #CRLF$ +
    "on the MSX Resource Center forum that may give you valuable hints." + #CRLF$ +
    "" + #CRLF$ +
    "You can sidestep these procedures by using the `diskmanipulator` to create an initial hd" + #CRLF$ +
    "image complete with any desired files and subdirectories. For" + #CRLF$ +
    "instance to create a harddisk with 3 partitions of 32 megabyte on it, and have" + #CRLF$ +
    "each partition filled with files and subdirectories, proceed as follows:" + #CRLF$ +
    "" + #CRLF$ +
    "Start openMSX with the ide extension, then type in the `console`:" + #CRLF$ +
    "" + #CRLF$ +
    "`set `power` off`" + #CRLF$ +
    "``diskmanipulator` `create` /tmp/new-hd.dsk 32M 32M 32M`" + #CRLF$ +
    "``hda` /tmp/new-hd.dsk`" + #CRLF$ +
    "``diskmanipulator` `import` hda1 /home/david/msxdostools/`" + #CRLF$ +
    "``diskmanipulator` `import` hda2 /home/david/msxdemos/`" + #CRLF$ +
    "``diskmanipulator` `import` hda3 /home/david/msxdrawings/`" + #CRLF$ +
    "`set `power` on`" + #CRLF$ +
    "" + #CRLF$ +
    "As announced above, there is (limited) support for CD-ROM with the 'ide'" + #CRLF$ +
    "extension. You can insert an ISO image in that virtual CD-ROM player with the" + #CRLF$ +
    "`-cda` command-line option and change it at run time with the" + #CRLF$ +
    "`cda` console" + #CRLF$ +
    "command, all similar to the aforementioned `hda` and `diska` commands and options." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.4.2 Beer IDE" + #CRLF$ +
    "" + #CRLF$ +
    "The Beer IDE interface, as brought to us by SOLID, is emulated by openMSX, too." + #CRLF$ +
    "This interface only offers a single device (no master and slave) and can only" + #CRLF$ +
    "handle up to 4 (version 1.9) or 5 (version 1.8) partitions of 32MB. On the" + #CRLF$ +
    "upside, it doesn't need MSX-DOS2, and thus it can run on any MSX (with" + #CRLF$ +
    "64kB RAM to run MSX-DOS). Emulation of this interface should be considered" + #CRLF$ +
    "experimental." + #CRLF$ +
    "" + #CRLF$ +
    "Usage is identical to using the Sunrise harddisk interface: you can use the" + #CRLF$ +
    "GUI, the `hda` command and the" + #CRLF$ +
    "matching command-line parameter `-hda` to control which image will" + #CRLF$ +
    "be used." + #CRLF$ +
    "" + #CRLF$ +
    "By default, the image is 128MB, so that it can fit 4 partitions of 32MB. Firmware" + #CRLF$ +
    "version 1.9RC1 is selected by default, because we could not get the 1.8" + #CRLF$ +
    "firmware to work: the MSXFDISK program didn't create partitions which actually" + #CRLF$ +
    "worked with the 1.8 firmware. If you want to experiment with it, you can change" + #CRLF$ +
    "the firmware to use by editing the extension file in" + #CRLF$ +
    "`share/extensions/Beer_IDE.xml`." + #CRLF$ +
    "" + #CRLF$ +
    "With the 1.9RC1 firmware, you can use `diskmanipulator` to create a harddisk" + #CRLF$ +
    "image and import from and export to them. To get started, partition the default" + #CRLF$ +
    "drive with `diskmanipulator partition hda -dos1 32M 32M 32M 32M`." + #CRLF$ +
    "Then import MSX-DOS system files onto the first partition using" + #CRLF$ +
    "`diskmanipulator import hda1 <host-path>`, and now you should" + #CRLF$ +
    "be able to boot into MSX-DOS." + #CRLF$ +
    ""
  CBody + #CRLF$ + "Unfortunately, the Beer IDE is hardly documented and the software is hard to" + #CRLF$ +
    "find. So, it's for experts only!" + #CRLF$ +
    "" + #CRLF$ +
    "## 5.4.3 SCSI devices" + #CRLF$ +
    "" + #CRLF$ +
    "First of all: the SCSI emulation is experimental! There is a lot bigger chance" + #CRLF$ +
    "that you may lose data on your emulated harddisk images with SCSI than with" + #CRLF$ +
    "Sunrise IDE! When we tried it, everything seemed fine, but you have been warned." + #CRLF$ +
    "" + #CRLF$ +
    "The SCSI extensions (currently Gouda_SCSI, ESE_MEGA-SCSI and ESE_WAVE-SCSI)" + #CRLF$ +
    "have the default 100 MB harddisk image connected on target ID 1 and an (even" + #CRLF$ +
    "more experimental) LS-120 device (basically a harddisk like media that can be" + #CRLF$ +
    "changed/ejected when the power is on) on target ID 2." + #CRLF$ +
    "" + #CRLF$ +
    "Specifying or changing harddisk images works the same as with IDE, see above." + #CRLF$ +
    "" + #CRLF$ +
    "To change the disk image of the LS-120 device, use the `lsa` (LS" + #CRLF$ +
    "drive A) command, exactly the same as the `hda` command. Of course you do not need to have the" + #CRLF$ +
    "power turned off to do this, as this is the whole point of the LS-120 device." + #CRLF$ +
    "You can also just eject it, with the `eject` subcommand. At the time" + #CRLF$ +
    "of writing there seems to be a bug when doing this: the device isn't listed in" + #CRLF$ +
    "the device list if there is no media inserted. It is currently not possible to specify an" + #CRLF$ +
    "LS-120 device on the command line." + #CRLF$ +
    "" + #CRLF$ +
    "Initialisation for the ESE SCSI devices needs tools like `MGINST`," + #CRLF$ +
    "which can be found on Takamichi's web site (http://www.msxnet.org/gtinter/nogame-e.htm)." + #CRLF$ +
    "They include small manuals in English. This manual is not the place to explain" + #CRLF$ +
    "the procedure, but the idea is as follows. First, install the MSX-DOS 2 kernel" + #CRLF$ +
    "in the SRAM of the device, using the `MGINST` program (you might" + #CRLF$ +
    "want to use `KSAVER` first to save the kernel of your DOS 2" + #CRLF$ +
    "cartridge). After this, the MSX will boot from the SRAM disk. Use the" + #CRLF$ +
    "`SFORM-1` (for MSX-DOS) or the `SFORM-2` (for MSX-DOS 2)" + #CRLF$ +
    "to format the drive (use a physical format, for now). Use `ESET` to" + #CRLF$ +
    "assign drive letters to partitions." + #CRLF$ +
    "" + #CRLF$ +
    "For the Gouda (Novaxis) SCSI interface, you need the Novaxis ROM, see also Hans Otten's Page (http://msx.hansotten.com/index.php?page=msxscsi) or The Ultimate MSX FAQ (http://faq.msxnet.org/scsi.html). Those sites" + #CRLF$ +
    "also contain manuals for the Novaxis ROM. Initialisation is done with the" + #CRLF$ +
    "`NFDISK` utility, which can be found on Marcel Delorme's site (https://web.archive.org/web/20200315110709/http://members.chello.nl/m.delorme/) (archived)." + #CRLF$ +
    "" + #CRLF$ +
    "## 5.4.4 MegaFlashROM SCC+ SD" + #CRLF$ +
    "" + #CRLF$ +
    "Currently there is only one SD interface emulated: the MegaFlashROM SCC+ SD." + #CRLF$ +
    "All features of this cartridge are emulated in the sense that all software currently" + #CRLF$ +
    "working with it, runs on openMSX too. It is not emulated accurately" + #CRLF$ +
    "enough to rely on it for development." + #CRLF$ +
    "" + #CRLF$ +
    "The SD card slots appear in the openMSX user interface as " + Chr(34) + "Hard Disk A/B" + Chr(34) + " and" + #CRLF$ +
    "hot plugging is not supported. So, it shows up almost identically to the" + #CRLF$ +
    "Sunrise IDE interface." + #CRLF$ +
    "" + #CRLF$ +
    "The difference compared to a real MegaFlashROM SCC+ SD, is that the extension does not" + #CRLF$ +
    "come with anything flashed on the flash ROM by default. There are two ways to" + #CRLF$ +
    "overcome that. The first one is to download the preflashed ROM content (for URL" + #CRLF$ +
    "see below) and install it into your systemroms folder, like any usual system" + #CRLF$ +
    "ROM. This only works if you use the extension for the first time, unless you" + #CRLF$ +
    "manually delete the persistent file for the flash ROM chip (typically in your" + #CRLF$ +
    "openMSX user" + #CRLF$ +
    "directory`/persistent/MegaFlashROM_SCC+_SD/untitled1/megaflashromsccplussd.sram`)." + #CRLF$ +
    "Only if no such file is found, openMSX will load the content of that ROM file" + #CRLF$ +
    "into the flash ROM of the MegaFlashROM SCC+ SD. The second way is manually" + #CRLF$ +
    "flashing things like Nextor, the rescue menu and the ROM disk. This is all" + #CRLF$ +
    "described in the manual (see at the end of this section) of the MegaFlashROM" + #CRLF$ +
    "SCC+ SD, because on a real device you may also need to do this." + #CRLF$ +
    "" + #CRLF$ +
    "Once you achieved this, usage is again identical to using the Sunrise harddisk" + #CRLF$ +
    "interface, so in the console you can use the `hda/hdb` commands and the matching command-line" + #CRLF$ +
    "parameters `-hda` and `-hdb` to control which image will" + #CRLF$ +
    "be used for the first and second SD card." + #CRLF$ +
    "" + #CRLF$ +
    "Currently, by default, the first SD card is 8MB and the 2nd SD card is 100MB in" + #CRLF$ +
    "size. You can change these defaults by editing the extension file in" + #CRLF$ +
    "`share/extensions/MegaFlashROM_SCC+_SD.xml`. For formatting and" + #CRLF$ +
    "managing the SD cards, please refer to its manual and tools on the Flash part" + #CRLF$ +
    "of the MSX Cartridge Shop (http://www.msxcartridgeshop.com/). It also provides the ROM file with the initial content of" + #CRLF$ +
    "the flash ROM as it is shipped on real MegaFlashROM SCC+ SD cartridges." + #CRLF$ +
    "" + #CRLF$ +
    "To get files on the SD cards, you can use `diskmanipulator` with the" + #CRLF$ +
    "`-nextor` option to partition and to import files, similar to what" + #CRLF$ +
    "is explained above in the Sunrise IDE section."
  OMSXHelp_Add("5.4 Emulating MSX Harddisks and CD-ROM", "Manual do Usuario - 5. Running MSX Software and Using Media", CBody)

  OMSXHelp_Add("5.5 Running Laserdisc software",
    "Manual do Usuario - 5. Running MSX Software and Using Media",
    "In order to run Laserdisc software, you need to have this optional feature" + #CRLF$ +
    "compiled into your openMSX binary. Laserdisc is only supported by the Pioneer" + #CRLF$ +
    "PX-7 or the Pioneer PX-V60 machines, which have special hardware to control the" + #CRLF$ +
    "laserdisc player." + #CRLF$ +
    "" + #CRLF$ +
    "The Laserdisc image can be selected under Main" + #CRLF$ +
    "menu bar → Media → LaserDisc Player or in the `console`, type `laserdiscplayer insert <file>.ogv`" + #CRLF$ +
    "" + #CRLF$ +
    "to insert a Laserdisc (image) into the Laserdisc player." + #CRLF$ +
    "By default, the Laserdisc will be loaded automatically. If the" + #CRLF$ +
    "`autorunlaserdisc`" + #CRLF$ +
    "setting is off, then you will have to take a few steps yourself." + #CRLF$ +
    "" + #CRLF$ +
    "After booting the MSX, choose option 1 when asked if you want to run P-BASIC" + #CRLF$ +
    "(Palcom-BASIC). In MSX-BASIC, type:" + #CRLF$ +
    "" + #CRLF$ +
    "`call ld`" + #CRLF$ +
    "" + #CRLF$ +
    "to load and run the Laserdisc program." + #CRLF$ +
    "" + #CRLF$ +
    "The program is encoded on the right audio channel, which will not be audible." + #CRLF$ +
    "With `set fullspeedwhenloading on`," + #CRLF$ +
    "openMSX runs at maximum speed whenever the Laserdisc is seeking or loading a" + #CRLF$ +
    "program.")

EndProcedure

; ============================================================
; OMSXHelp_BuildUserManual2
; ============================================================
Procedure OMSXHelp_BuildUserManual2()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("6.1 Keyboard",
    "Manual do Usuario - 6. Input Devices",
    "## 6.1.1 MSX Key Mapping" + #CRLF$ +
    "" + #CRLF$ +
    "The special MSX keys are mapped as follows, the first column for PCs (running" + #CRLF$ +
    "Windows, Linux or BSD), the second column for Apple Macintosh computers:" + #CRLF$ +
    "" + #CRLF$ +
    "**MSX key | key (PC) | key (Mac)**" + #CRLF$ +
    "- CTRL key -- L-CTRL -- L-CTRL" + #CRLF$ +
    "- dead (accents) key -- R-CTRL -- R-CTRL" + #CRLF$ +
    "- GRAPH key -- L-ALT -- L-ALT" + #CRLF$ +
    "- CODE/KANA key -- R-ALT -- R-ALT" + #CRLF$ +
    "- 取消 ('cancel') key -- L-Windows -- " + #CRLF$ +
    "- 実行 ('execute') key -- R-Windows -- " + #CRLF$ +
    "- SELECT key -- F7 -- F7" + #CRLF$ +
    "- STOP key -- F8 -- F8" + #CRLF$ +
    "- INS key -- Insert -- Cmd+I" + #CRLF$ +
    "" + #CRLF$ +
    "## 6.1.2 ColecoVision Key Mapping" + #CRLF$ +
    "" + #CRLF$ +
    "The ColecoVision controllers are mapped as follows:" + #CRLF$ +
    "" + #CRLF$ +
    "**direction/key | player 1 | player 2**" + #CRLF$ +
    "- up -- cursor up -- W" + #CRLF$ +
    "- down -- cursor down -- S" + #CRLF$ +
    "- left -- cursor left -- A" + #CRLF$ +
    "- right -- cursor right -- D" + #CRLF$ +
    "- fire left -- space, R-CTRL -- L-CTRL" + #CRLF$ +
    "- fire right -- L-ALT, R-ALT, R-SHIFT -- L-SHIFT" + #CRLF$ +
    "- 1 -- 1, numpad 1 -- R" + #CRLF$ +
    "- 2 -- 2, numpad 2 -- T" + #CRLF$ +
    "- 3 -- 3, numpad 3 -- Y" + #CRLF$ +
    "- 4 -- 4, numpad 4 -- F" + #CRLF$ +
    "- 5 -- 5, numpad 5 -- G" + #CRLF$ +
    "- 6 -- 6, numpad 6 -- H" + #CRLF$ +
    "- 7 -- 7, numpad 7 -- V" + #CRLF$ +
    "- 8 -- 8, numpad 8 -- B" + #CRLF$ +
    "- 9 -- 9, numpad 9 -- N" + #CRLF$ +
    "- 0 -- 0, numpad 0 -- U" + #CRLF$ +
    "- * -- -, numpad *, numpad - -- J" + #CRLF$ +
    "- # -- =, numpad /, numpad + -- M" + #CRLF$ +
    "" + #CRLF$ +
    "Host joysticks can also be used for directions and the fire buttons, but the" + #CRLF$ +
    "keys from the telephone-style keypad can only be entered via the host keyboard." + #CRLF$ +
    "" + #CRLF$ +
    "## 6.1.3 Emulator Functions Key Mapping" + #CRLF$ +
    "" + #CRLF$ +
    "The mapping of the keys for emulator functions is fully customisable using the" + #CRLF$ +
    "`bind` command in" + #CRLF$ +
    "the `console`. Your customised key" + #CRLF$ +
    "bindings are saved together with the settings. This subsection lists the" + #CRLF$ +
    "default key mapping." + #CRLF$ +
    "" + #CRLF$ +
    "**keys (PC) | keys (Mac) | function**" + #CRLF$ +
    "- Pause -- Cmd+P (Pause) -- Pause emulation" + #CRLF$ +
    "- ALT+F4 -- Cmd+Q (Quit) -- Quit openMSX" + #CRLF$ +
    "- CTRL+Pause (Break) --  -- Quit openMSX (not in Windows)" + #CRLF$ +
    "- PrtScr -- Cmd+D (Dump) -- Save current screen to a file (screen shot)" + #CRLF$ +
    "- PageUp -- PageUp -- Go 1 second back in time, using the `reverse` feature" + #CRLF$ +
    "- PageDown -- PageDown -- Go 1 second forward in time, using the `reverse` feature" + #CRLF$ +
    "- F9 -- Cmd+T (Fastforward) -- Toggle `fastforward` mode (normal vs fastforward speed)" + #CRLF$ +
    "- F10 -- Cmd+L (consoLe) -- Toggle `console` display" + #CRLF$ +
    "- F11 or ALT+Enter -- Cmd+F (Full) -- Toggle full screen mode" + #CRLF$ +
    "- F12 -- Cmd+U (mUte) -- Toggle audio mute" + #CRLF$ +
    "- ALT+F7 -- Cmd+R (Restore) -- Quick `loadstate` (from 'quicksave' slot)" + #CRLF$ +
    "- ALT+F8 -- Cmd+S (Save) -- Quick `savestate` (to 'quicksave' slot)" + #CRLF$ +
    "- CTRL+Win+C -- Cmd+C (Copy) -- Copy screen's text content to clipboard" + #CRLF$ +
    "- CTRL+Win+V -- Cmd+V (paste) -- Type the text from the clipboard into the MSX" + #CRLF$ +
    "" + #CRLF$ +
    "Note that Mac users must use `GUI` as a modifier for the Command" + #CRLF$ +
    "(Apple logo) key. On PC's use `GUI` for the Windows key." + #CRLF$ +
    "" + #CRLF$ +
    "Please note that openMSX is currently intended to be mouse controlled." + #CRLF$ +
    "Some parts of the GUI can also be controlled via keyboard, but this has not" + #CRLF$ +
    "been optimized at all for now. Control via gamepad is currently disabled (this" + #CRLF$ +
    "might change in a future version)." + #CRLF$ +
    "" + #CRLF$ +
    "## 6.1.4 Keyboard Layouts" + #CRLF$ +
    "" + #CRLF$ +
    "This section is about how host computer keyboard layouts are mapped to" + #CRLF$ +
    "MSX keyboard layouts. This is mostly interesting if those differ" + #CRLF$ +
    "(a lot). For example, you have a US-English keyboard on your PC and you are" + #CRLF$ +
    "emulating a Japanese MSX computer. Or, you have a Japanese Mac and you are" + #CRLF$ +
    "emulating a Spanish MSX computer." + #CRLF$ +
    "" + #CRLF$ +
    "There are features to make this as smooth as possible," + #CRLF$ +
    "so that you can use your own keyboard for any kind of MSX with as little" + #CRLF$ +
    "surprises as possible. The trick is the new character-based mapping mode, which tries to convert" + #CRLF$ +
    "any character you enter with your host computer's keyboard to an MSX key press." + #CRLF$ +
    "For this feature, all MSX hardware configuration files now have information" + #CRLF$ +
    "about their keyboard layout. Anyway, this mapping mode is enabled by default," + #CRLF$ +
    "so you don't have to do anything to make this work!" + #CRLF$ +
    "" + #CRLF$ +
    "However, there are always some pesky details. For those details we refer to the" + #CRLF$ +
    "documentation of other keyboard settings, where they are explained in full" + #CRLF$ +
    "detail: mapping mode (as mentioned before), `kbd_numkeypad_always_enabled`" + #CRLF$ +
    "(use numerical keypad even when your MSX doesn't have one), `kbd_code_kana_host_key` (specify" + #CRLF$ +
    "an alternative host key for CODE/KANA) and `kbd_numkeypad_enter_key`" + #CRLF$ +
    "(specifies mapping of the ENTER key of the keypad)." + #CRLF$ +
    "" + #CRLF$ +
    "You can find the mapping mode setting in Main menu" + #CRLF$ +
    "bar → Settings → Input → Keyboard mapping mode.")

  OMSXHelp_Add("6.2 Joystick",
    "Manual do Usuario - 6. Input Devices",
    "If you have a controller or joystick connected to your PC, you can map its" + #CRLF$ +
    "input to one of the emulated MSX joystick (like) devices, internally called `msxjoystick1`," + #CRLF$ +
    "`msxjoystick2`, `joymega1` and `joymega2`." + #CRLF$ +
    "" + #CRLF$ +
    "See the earlier section about plugging devices on how to connect these devices to your emulated machine." + #CRLF$ +
    "" + #CRLF$ +
    "The mapping of your host devices (host controllers, joysticks or keyboard) to" + #CRLF$ +
    "these 4 emulated MSX joysticks is fully configurable. The easiest way is to use" + #CRLF$ +
    "the GUI menu for that under Main menu bar →" + #CRLF$ +
    "Settings → Input → Configure MSX joysticks. You can also do it" + #CRLF$ +
    "in the console with the `msxjoystick<n>_config/joymega<n>_config`" + #CRLF$ +
    "settings." + #CRLF$ +
    "" + #CRLF$ +
    "Most modern joysticks have more buttons than the 2 buttons that are defined by" + #CRLF$ +
    "the MSX standard. Therefore a lot of games use extra keys on the keyboard for" + #CRLF$ +
    "extra functionality. For instance, almost all Konami games use F1 to pause" + #CRLF$ +
    "the game. You can assign this extra functionality to your joystick by using the" + #CRLF$ +
    "`bind` command. As" + #CRLF$ +
    "an example here is how to map button 4 of the first joystick to the F1-key," + #CRLF$ +
    "button 5 to F2, ..." + #CRLF$ +
    "" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button4 down" + Chr(34) + " " + Chr(34) + "keymatrixdown 6 0x20" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button4 up" + Chr(34) + " " + Chr(34) + "keymatrixup 6 0x20" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button5 down" + Chr(34) + " " + Chr(34) + "keymatrixdown 6 0x40" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button5 up" + Chr(34) + " " + Chr(34) + "keymatrixup 6 0x40" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button6 down" + Chr(34) + " " + Chr(34) + "keymatrixdown 6 0x80" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button6 up" + Chr(34) + " " + Chr(34) + "keymatrixup 6 0x80" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button7 down" + Chr(34) + " " + Chr(34) + "keymatrixdown 7 0x01" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button7 up" + Chr(34) + " " + Chr(34) + "keymatrixup 7 0x01" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button8 down" + Chr(34) + " " + Chr(34) + "keymatrixdown 7 0x02" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button8 up" + Chr(34) + " " + Chr(34) + "keymatrixup 7 0x02" + Chr(34) + "`" + #CRLF$ +
    "" + #CRLF$ +
    "For a more detailed explanation of this command see the Console Command Reference. Please note that" + #CRLF$ +
    "unfortunately, such mappings are not configurable via the GUI menu.")

  OMSXHelp_Add("6.3 Mouse",
    "Manual do Usuario - 6. Input Devices",
    "To connect a mouse, you can also use the Main menu" + #CRLF$ +
    "bar → Connectors menu or the `plug` command: `plug joyporta mouse`" + #CRLF$ +
    "will connect a mouse to joystick port A. If you want the joystick emulation" + #CRLF$ +
    "feature that some mice (like the Philips SBC-3810 and the Sony MOS-1) have," + #CRLF$ +
    "keep the left mouse key pressed when plugging it in, just as on a real MSX." + #CRLF$ +
    "" + #CRLF$ +
    "If you are using openMSX in windowed mode, it might be tricky to use the mouse." + #CRLF$ +
    "The setting: `set grabinput on`" + #CRLF$ +
    "makes sure all input goes to openMSX. Your cursor cannot leave the openMSX" + #CRLF$ +
    "window with this setting. Just turn it back to off, if you want to disable this" + #CRLF$ +
    "again. If you only want to escape the window briefly, use this command:" + #CRLF$ +
    "`escape_grab`. It permits you to" + #CRLF$ +
    "leave the window, but the next time you enter it, the cursor is grabbed again." + #CRLF$ +
    "It might be a good idea to bind this command to a key, using the `bind` command, which is" + #CRLF$ +
    "mentioned above. You can also toggle the setting via Main menu bar → Settings → Input → Grab" + #CRLF$ +
    "input.")

  OMSXHelp_Add("6.4 Arkanoid Pad",
    "Manual do Usuario - 6. Input Devices",
    "The Arkanoid games by Taito both have support for a special Arkanoid game pad," + #CRLF$ +
    "with a classical rotary knob to control the position of the bat. This device" + #CRLF$ +
    "is emulated as well and can be controlled by the mouse. Plug it via the GUI" + #CRLF$ +
    "Main menu bar → Connector menu or in" + #CRLF$ +
    "the console with `plug joyporta arkanoidpad" + #CRLF$ +
    "`.")

  OMSXHelp_Add("6.5 Trackball",
    "Manual do Usuario - 6. Input Devices",
    "Some MSX trackballs like the HAL CAT and the Sony HB-G7B seem to have identical hardware" + #CRLF$ +
    "and are also emulated by openMSX, again using the mouse to control it. In MSX" + #CRLF$ +
    "software, the trackball is mostly supported in port B only. Using the console" + #CRLF$ +
    "you can use therefore `plug joyportb trackball`." + #CRLF$ +
    "" + #CRLF$ +
    "Quite some HAL programs have support for it, e.g. Hole in One, Eddy II, Music" + #CRLF$ +
    "Studio G7, Space Trouble and Super Billiards. The test program provided in the" + #CRLF$ +
    "Sony HB-G7B service manual also works fine, of course.")

  OMSXHelp_Add("6.6 Touchpad",
    "Manual do Usuario - 6. Input Devices",
    "Some MSX touch pads like the Philips NMS 1150 Graphic Tablet are also emulated" + #CRLF$ +
    "by openMSX, again using the mouse to control it (where mouse button 1" + #CRLF$ +
    "corresponds to touch or no touch and mouse button 2 to the button on the pen of" + #CRLF$ +
    "the touch pad). Also the touch pad is mostly supported in port B only, so the" + #CRLF$ +
    "console command is `plug joyportb touchpad`" + #CRLF$ +
    "" + #CRLF$ +
    "This device is mostly supported by the Philips drawing programs Designer," + #CRLF$ +
    "Designer Plus and Video Graphics (all in port B) and by Pioneer MSX Video Art" + #CRLF$ +
    "(port A)." + #CRLF$ +
    "" + #CRLF$ +
    "Note that the whole openMSX window will function as the surface of the touch" + #CRLF$ +
    "pad. This may not align with the actual pixels of the screen in that window," + #CRLF$ +
    "see the `touchpad_transform_matrix`" + #CRLF$ +
    "setting for how to adjust this.")

  OMSXHelp_Add("6.7 Magic Key",
    "Manual do Usuario - 6. Input Devices",
    "Sony made a small dongle for game testers to cheat within the games. The games" + #CRLF$ +
    "that have support for it will check if the UP and DOWN keys are pressed. The" + #CRLF$ +
    "magic key is supported by these games in port B only (console: `plug joyportb" + #CRLF$ +
    "magic-key`." + #CRLF$ +
    "" + #CRLF$ +
    "Known games that can use this Magic Key are:" + #CRLF$ +
    "" + #CRLF$ +
    "**Family Boxing (Sony):** Press the Graph key on the title screen to enter the secret menu" + #CRLF$ +
    "**Jansei (Sony):** You can set the characteristics of the enemy by moving the cursor to" + #CRLF$ +
    Chr(34) + "Actual Battle" + Chr(34) + " on the menu screen and pressing ESC and SELECT." + #CRLF$ +
    "**Gall Force - Defense of Chaos (Sony):** A new menu item will appear on the home screen")

  OMSXHelp_Add("6.8 Ninja Tap",
    "Manual do Usuario - 6. Input Devices",
    "The Ninja Tap (忍者タップ) is an adapter designed by Knight's chamber and" + #CRLF$ +
    "sold in Japan by PCCM. This adapter allows you to use up to 4 joysticks per port." + #CRLF$ +
    "Plug it via the GUI or with the console using `plug joyporta ninjatap`.")

  OMSXHelp_Add("6.9 Tetris II Special Edition dongle",
    "Manual do Usuario - 6. Input Devices",
    "Tetris 2 Special Edition from R.A.M., an Italian MSX group, needs the dongle in" + #CRLF$ +
    "port B too start the game. So, on the console use `plug joyportb tetris2-protection" + #CRLF$ +
    "`")

  OMSXHelp_Add("6.10 MSX Paddle",
    "Manual do Usuario - 6. Input Devices",
    "The MSX paddle controller is a quite simple device, but there are not so many" + #CRLF$ +
    "commercial implementations for MSX. The Yamaha MMP-01 is a music pad that is" + #CRLF$ +
    "known to use this protocol to transmit its coordinates. Plug it in the console" + #CRLF$ +
    "as follows: `plug" + #CRLF$ +
    "joyporta paddle`.")

  OMSXHelp_Add("6.11 Circuit Designer dongle",
    "Manual do Usuario - 6. Input Devices",
    "Circuit Designer dongle from The Falcon, needs the dongle in port B to start" + #CRLF$ +
    "the program, so in the console type: `plug joyportb circuit-designer-rd-dongle" + #CRLF$ +
    "`.")

  OMSXHelp_Add("7. Video",
    "Manual do Usuario - 7. Video",
    "openMSX uses the OpenGL graphics library for all post processing (hence" + #CRLF$ +
    "the PP in SDLGL-PP, which is the name of the " + Chr(34) + "renderer" + Chr(34) + ", the software component that generates" + #CRLF$ +
    "the graphical part of the emulation, the MSX 'screen'). This includes" + #CRLF$ +
    "scalers and other effects, but also the GUI..." + #CRLF$ +
    "Because of all this, openMSX runs best with a hardware accelerated" + #CRLF$ +
    "OpenGL library. See the Setup Guide for" + #CRLF$ +
    "OpenGL performance tips." + #CRLF$ +
    "So, again, be aware that openMSX requires both your video" + #CRLF$ +
    "card and video driver to support at least OpenGL 2.0. Sometimes you need to" + #CRLF$ +
    "upgrade your driver to make it work. If your videocard or driver don't support" + #CRLF$ +
    "OpenGL 2.0, openMSX will not start up and report an error." + #CRLF$ +
    "" + #CRLF$ +
    "Most video related settings can be found under the Main menu bar → Settings → Video menu." + #CRLF$ +
    "The rest of this section describes more details about the settings you can find" + #CRLF$ +
    "there. For instance, for full screen mode, there is a checkbox in that menu," + #CRLF$ +
    "which maps to the `fullscreen` setting.")

  OMSXHelp_Add("7.1 Scalers",
    "Manual do Usuario - 7. Video",
    "Most MSX screen modes are only 256×212 pixels big. This is quite small" + #CRLF$ +
    "for today's PC screen resolutions. That's why you have the possibility to" + #CRLF$ +
    "scale up the image. There are currently three possible scaling factors: 2, 3" + #CRLF$ +
    "and 4. If you select 2, all MSX pixels are mapped to a 640×480 pixels PC" + #CRLF$ +
    "window, for 3 to a 960×720 pixel window and for 4 to the obvious" + #CRLF$ +
    "1280×960 window. The setting which determines this is called `scale_factor`. In" + #CRLF$ +
    "general, the higher the factor, the better the output image is." + #CRLF$ +
    "" + #CRLF$ +
    "There are also a number of scaling algorithms (setting `scale_algorithm`) that can be" + #CRLF$ +
    "set. The scaling algorithm determines how exactly the mapping is done between" + #CRLF$ +
    "the MSX input screen and the PC output screen. As we render more pixels than" + #CRLF$ +
    "the normally visible MSX pixels, this allows for extra possibilities in the algorithms, like" + #CRLF$ +
    "deinterlacing and adding scanlines, blur, anti-aliasing (rounding of blocky" + #CRLF$ +
    "patters like stair cases) or even a Trinitron-like TV effect." + #CRLF$ +
    "" + #CRLF$ +
    "openMSX contains the following scaling algorithms:" + #CRLF$ +
    "" + #CRLF$ +
    "**simple:** This algorithm simply expands each MSX pixel to a square of" + #CRLF$ +
    "(scale_factor)×(scale_factor) PC pixels." + #CRLF$ +
    "This is the default scaler and can be tuned to look like most CRT screens." + #CRLF$ +
    "The image looks blocky, especially diagonal edges, but it does support" + #CRLF$ +
    "scanlines and blur." + #CRLF$ +
    "**ScaleNx (http://scale2x.sourceforge.net/):** This scaler algorithm smoothes edges by using only original colors, so it will" + #CRLF$ +
    "not give any blur. It is fast and its image is less blocky than that of the" + #CRLF$ +
    "simple scaler. However, all corners are rounded, which does not look good on" + #CRLF$ +
    "all graphics. This scaler has not been properly implemented for scaling factors" + #CRLF$ +
    "of 4." + #CRLF$ +
    "**hq (http://en.wikipedia.org/wiki/Hqx):** This algorithm does a good job on most graphics; it avoids excessive blurring" + #CRLF$ +
    "and it keeps corners sharp." + #CRLF$ +
    "On some graphics, it does not identify edges correctly, making those edges" + #CRLF$ +
    "blocky instead of smooth." + #CRLF$ +
    "Especially with high scaling factors, it can give a very smooth looking image." + #CRLF$ +
    "**RGBTriplet:** This algorithm only works as intended when a scaling factor of 3 is used. Also," + #CRLF$ +
    "it only works well for MSX screen modes of 256×212, which includes most" + #CRLF$ +
    "games. The idea of the algorithm is that each input pixel is mapped on a" + #CRLF$ +
    "triplet of pixels which represent the R(ed), G(reen) and B(lue) components of" + #CRLF$ +
    "the input pixel. This arrangement of RGB components is also used in the Aperture Grille (http://en.wikipedia.org/wiki/Aperture_grille) CRT's, also known as Trinitron and the modern TFT screens. You can" + #CRLF$ +
    "control the effect with the `blur` setting. This algorithm also includes" + #CRLF$ +
    "scan lines." + #CRLF$ +
    "**TV:** This algorithm tries to emulate the fact that on a CRT brighter pixels look" + #CRLF$ +
    "bigger than darker pixels. It has some minor flaws, but is already developed" + #CRLF$ +
    "far enough to make it available for you to try out." + #CRLF$ +
    "" + #CRLF$ +
    "A small (somewhat outdated) demonstration of some of the algorithms can be" + #CRLF$ +
    "found on the openMSX web site (http://openmsx.org/).")

  OMSXHelp_Add("7.2 Gamma Correction",
    "Manual do Usuario - 7. Video",
    "PC monitors can have different gamma values than MSX monitors." + #CRLF$ +
    "To compensate for this, openMSX has a gamma correction feature." + #CRLF$ +
    "It is controlled by the `gamma` setting." + #CRLF$ +
    "A value of 1.0 disables gamma correction; a lower value makes the image darker;" + #CRLF$ +
    "a higher value makes it brighter." + #CRLF$ +
    "" + #CRLF$ +
    "If you want to know what gamma correction really means, read this page about monitor gamma (http://www.bberger.net/rwb/gamma.html)." + #CRLF$ +
    "The gamma correction value you can set in openMSX should be the gamma of your" + #CRLF$ +
    "PC screen divided by the gamma of the MSX screen." + #CRLF$ +
    "I measured the gamma of my PC screen (TFT) at 2.0 and the gamma of my MSX" + #CRLF$ +
    "monitor at 2.5. That puts the gamma correction at 2.0 / 2.5 = 0.8." + #CRLF$ +
    "So if I enter that value, the openMSX image will have comparable brightness to" + #CRLF$ +
    "the MSX image." + #CRLF$ +
    "However, 0.8 is not the value I'm actually using: I prefer a brighter image" + #CRLF$ +
    "than my MSX monitor, so I chose to use a gamma correction of 1.1.")

  OMSXHelp_Add("7.3 Special Effects",
    "Manual do Usuario - 7. Video",
    "openMSX contains a couple of special effects settings that can be applied to" + #CRLF$ +
    "the video output:" + #CRLF$ +
    "" + #CRLF$ +
    "**`deinterlace`:** Interlacing is a technique to double the vertical resolution by splitting the" + #CRLF$ +
    "image into two frames: the first frame displays the even lines, the second" + #CRLF$ +
    "frame the odd lines." + #CRLF$ +
    "The after glow on a TV and some processes in the human brain combine both" + #CRLF$ +
    "frames into a single image. However, this process is not perfect and you can" + #CRLF$ +
    "notice flickering, especially on horizontal lines." + #CRLF$ +
    "The deinterlace feature combines the even and the odd frames into a single" + #CRLF$ +
    "output frame, thus eliminating the flicker." + #CRLF$ +
    "The `deinterlace` setting controls this" + #CRLF$ +
    "feature:" + #CRLF$ +
    "it can be on (enabled) or off (disabled); it is enabled by default." + #CRLF$ +
    "**`deflicker`:** This filter detects pixels that alternate each frame between two different" + #CRLF$ +
    "colors and replaces those alternations with the average color. Such" + #CRLF$ +
    "'flickering' pixels can occur in software that rapidly changes between colors" + #CRLF$ +
    "to create the illusion of a wider color palette. It can also occur because of" + #CRLF$ +
    "'sprite flickering'. This setting is disabled by default because there aren't" + #CRLF$ +
    "that many situations where it really improves video quality, but it does have" + #CRLF$ +
    "a performance cost." + #CRLF$ +
    "**`scanline`:** On TV's and MSX monitors, you can see a small black space in between the" + #CRLF$ +
    "display lines, especially when using NTSC." + #CRLF$ +
    "The scanlines feature simulates this by drawing some lines a bit darker." + #CRLF$ +
    "This feature is disabled when a scaling algorithm other than" + #CRLF$ +
    "`simple`, `tv` or `RGBTriplet` is used." + #CRLF$ +
    "**`blur`:** TV's and MSX monitors are less sharp than PC monitors:" + #CRLF$ +
    "neighbouring pixels tend to blur into each other." + #CRLF$ +
    "The blur feature simulates this by interpolating neighbouring pixels." + #CRLF$ +
    "The `blur`" + #CRLF$ +
    "settings control this:" + #CRLF$ +
    "0 means no blur (completely sharp), 50 means some blur (like a monitor)," + #CRLF$ +
    "100 means maximum blur (like a TV)." + #CRLF$ +
    "All other values between 0 and 100 are also possible of course." + #CRLF$ +
    "This feature is disabled when a scaling algorithm other than" + #CRLF$ +
    "`simple` or `RGBTriplet` is used." + #CRLF$ +
    "**after glow (`glow`):** The after glow feature blends each frame with the previous one." + #CRLF$ +
    "This results in moving objects leaving a trail (motion blur)." + #CRLF$ +
    "The `glow` setting" + #CRLF$ +
    "controls the amount of after glow:" + #CRLF$ +
    "0 means no after glow, 100 means maximum after glow." + #CRLF$ +
    "**`noise`:** This setting controls the amount of pixel noise on the screen." + #CRLF$ +
    "The `noise`" + #CRLF$ +
    "setting controls the amount:" + #CRLF$ +
    "0 means no noise, 100 means maximum noise. The value is actually the deviation" + #CRLF$ +
    "of the colour of the original pixel and non-integer values are also possible." + #CRLF$ +
    "**display deformation (`display_deform`):** This feature makes it possible to change the shape of the MSX screen. Here are the possibilities:" + #CRLF$ +
    "" + #CRLF$ +
    "`normal`: no deformation (default)" + #CRLF$ +
    "`3d`: emulates a 3D view on an arcade cabinet's screen")

  OMSXHelp_Add("7.4 Accuracy",
    "Manual do Usuario - 7. Video",
    "An advanced setting (which you can find under Main" + #CRLF$ +
    "menu bar → Settings → Video → Advanced (for debugging)" + #CRLF$ +
    "(the `accuracy` setting) controls how often" + #CRLF$ +
    "the renderer is synchronised with the MSX video processor (VDP)." + #CRLF$ +
    "There are three options:" + #CRLF$ +
    "" + #CRLF$ +
    "**screen:** Synchronise once per screen (frame)." + #CRLF$ +
    "Good enough for most MSX1 software, but will break most raster effects." + #CRLF$ +
    "**line:** Synchronise at the start of a line." + #CRLF$ +
    "This is good enough for most software." + #CRLF$ +
    "This setting hides imperfections in raster effects," + #CRLF$ +
    "which could be considered a useful feature." + #CRLF$ +
    "**pixel:** Synchronise at the exact pixel where a change occurs." + #CRLF$ +
    "This is the most realistic setting and therefore set as the default." + #CRLF$ +
    "To see demos like Unknown Reality (scope part) and Verti correctly," + #CRLF$ +
    "you should use this setting." + #CRLF$ +
    "Also, you will see any imperfections in raster effects" + #CRLF$ +
    "just like they occur on a real MSX.")

  OMSXHelp_Add("7.5 GFX9000/Video 9000",
    "Manual do Usuario - 7. Video",
    "openMSX has GFX9000 emulation. As there isn't that much software for it" + #CRLF$ +
    "available, it is not as complete, functional and optimized as the video" + #CRLF$ +
    "emulation of the classical MSX chips." + #CRLF$ +
    "Despite of all this, most existing GFX9000 software runs pretty well, so we" + #CRLF$ +
    "found it worth sharing with you anyway." + #CRLF$ +
    "" + #CRLF$ +
    "The real GFX9000 has an external video connector to which you can connect a" + #CRLF$ +
    "second monitor. We never took the trouble to" + #CRLF$ +
    "emulate a second monitor, however, so to see the GFX9000 in action, you need to switch the" + #CRLF$ +
    "videosource setting, which mimics a so-called SCART-switch in the real" + #CRLF$ +
    "world: `set" + #CRLF$ +
    "videosource GFX9000`." + #CRLF$ +
    "This setting is only available when there are actually multiple video sources" + #CRLF$ +
    "available. In the GUI you can find it under Main menu bar → Settings → Video → Video" + #CRLF$ +
    "source to display." + #CRLF$ +
    "" + #CRLF$ +
    "Alternatively, instead of the GFX9000 extension, you could use the" + #CRLF$ +
    "Video9000 extension (also built in in several Boosted MSX machine" + #CRLF$ +
    "configurations). The Video 9000 hardware has the possibility to superimpose the" + #CRLF$ +
    "GFX9000 video on top of the V99xx video (and this is practically the only" + #CRLF$ +
    "feature of the Video 9000 that is currently implemented). Software that is" + #CRLF$ +
    "Video 9000 aware, will tell the Video 9000 to show the GFX9000 if something" + #CRLF$ +
    "interesting is to be seen on the GFX9000 video output. So, for such software," + #CRLF$ +
    "you do not have to switch video sources if you simply use the Video9000" + #CRLF$ +
    "video source. When a Video 9000 is present in the currently running MSX" + #CRLF$ +
    "configuration, the Video9000 video source will be selected by default, to make" + #CRLF$ +
    "use of this superimpose feature. For programs not aware of Video 9000, you will" + #CRLF$ +
    "still have to switch video sources manually, just like on a real system." + #CRLF$ +
    "" + #CRLF$ +
    "To get your normal MSX screen back, set the setting back to MSX. If you want to" + #CRLF$ +
    "toggle between them with a hotkey, it might be useful to bind a key for it. E.g.: `bind F6 cycle videosource`." + #CRLF$ +
    "" + #CRLF$ +
    "`cycle` is a Tcl" + #CRLF$ +
    "command that cycles through the options of the setting in the parameter.")

  OMSXHelp_Add("7.6 Video Recording",
    "Manual do Usuario - 7. Video",
    "The video recorder enables you to record the audio and video rendered by" + #CRLF$ +
    "openMSX to an AVI file. The output video is in 320×240 resolution by" + #CRLF$ +
    "default, at 640×480 when using the `-doublesize` flag and at" + #CRLF$ +
    "960×720 when using the `-triplesize` flag. The video is" + #CRLF$ +
    "compressed with the ZMBV codec, a fast lossless compression algorithm that" + #CRLF$ +
    "works very well on 2D computer generated images. The `FAQ` contains more information about this codec. The" + #CRLF$ +
    "audio is uncompressed." + #CRLF$ +
    "" + #CRLF$ +
    "The recorded AVI file will not suffer from any hiccups, even if the emulation" + #CRLF$ +
    "ran too slow when you recorded it. The current video source (see previous" + #CRLF$ +
    "section) is recorded and the sound is recorded with the current `frequency` setting." + #CRLF$ +
    "If you change the `frequency` setting during recording," + #CRLF$ +
    "or, more importantly, if the software changes from PAL (50 Hz) to NTSC (60 Hz)" + #CRLF$ +
    "during recording, the video will get out of sync with the audio. Most of the special effects will not be recorded." + #CRLF$ +
    "" + #CRLF$ +
    "If any stereo sound devices are present or any sound device has an off-center" + #CRLF$ +
    "balance, the recording will be made in stereo, otherwise it will be mono. If" + #CRLF$ +
    "a recording is made in mono and then a stereo sound device is added, you'll" + #CRLF$ +
    "receive a warning that stereo sound has been detected and that the two" + #CRLF$ +
    "channels will be mixed down to mono. You can prevent this from happening by" + #CRLF$ +
    "using the `-stereo` option to force a stereo recording even if" + #CRLF$ +
    "no stereo devices are present at the time you enter the command. You can also" + #CRLF$ +
    "force a mono recording with `-mono` to save space." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI you can find the video recorder under Main menu bar → Tools → Capture →" + #CRLF$ +
    "Audio/Video, which will open a the corresponding window, in which you" + #CRLF$ +
    "can specify all the above mentioned settings." + #CRLF$ +
    "" + #CRLF$ +
    "In the console, you can use the command `record start` to record to a default file" + #CRLF$ +
    "name, or you can use an additional parameter to specify a file. The command" + #CRLF$ +
    "`record stop`" + #CRLF$ +
    "stops recording and `record toggle` toggles it. You can use" + #CRLF$ +
    "the `-audioonly` or `-videoonly` option to record only" + #CRLF$ +
    "sound or video." + #CRLF$ +
    "" + #CRLF$ +
    "If you want to put a recorded video on your web site, it is better to transcode" + #CRLF$ +
    "the audio to MP3 or Vorbis format, as this makes the file a lot smaller." + #CRLF$ +
    "YouTube supports the ZMBV codec, so if you want to upload your recording you do" + #CRLF$ +
    "not need to transcode the video. If you want to share your video with people" + #CRLF$ +
    "who do not have (or want to install) the ZMBV codec, you should still transcode" + #CRLF$ +
    "it, of course. This can be done with programs such as Virtual Dub (http://www.virtualdub.org/) (Windows) or MPlayer's MEncoder (http://www.mplayerhq.hu/)" + #CRLF$ +
    "(Linux/UNIX). For YouTube you may want to use the command `record_chunks` instead:" + #CRLF$ +
    "it will enable you to chop up your video in several parts and enables" + #CRLF$ +
    "`-doublesize` automatically." + #CRLF$ +
    "" + #CRLF$ +
    "Recording as explained above will happen in real-time. This can be annoying if" + #CRLF$ +
    "you want to make a demonstration video, because you all mistakes will be" + #CRLF$ +
    "recorded as well. To work around this, you can also use the `reverse` feature during" + #CRLF$ +
    "the scene you want to record. After the scene, reverse to the beginning, start" + #CRLF$ +
    "the recording as explained above and let the scene replay relaxedly. You can" + #CRLF$ +
    "even speed it up using the `throttle` setting. This method of recording is" + #CRLF$ +
    "also useful when real-time recording has a big impact on the performance of" + #CRLF$ +
    "openMSX on your hardware. See also the chapter about this feature.")

  OMSXHelp_Add("8.1 Audio Settings",
    "Manual do Usuario - 8. Audio",
    "Most audio related settings can be found under the Main menu bar → Settings → Sound menu." + #CRLF$ +
    "" + #CRLF$ +
    "There is a `master_volume` setting, which" + #CRLF$ +
    "controls the overall output volume of openMSX (it applies to all sound" + #CRLF$ +
    "devices). Volume 0 means no sound, volume 100 is maximum." + #CRLF$ +
    "" + #CRLF$ +
    "There is also a `mute` setting, to disable all sound from" + #CRLF$ +
    "openMSX at once. It can be on (muted) or off (sound is audible). By default," + #CRLF$ +
    "mute is bound to the F12 key." + #CRLF$ +
    "" + #CRLF$ +
    "There are also settings for each emulated sound device. These can be found" + #CRLF$ +
    "under the Main menu bar → Settings →" + #CRLF$ +
    "Sound → Show sound chip settings option in the menu." + #CRLF$ +
    "" + #CRLF$ +
    "For each sound device there is a volume setting." + #CRLF$ +
    "Volume 0 means no sound, volume 100 is maximum. In the console you can do this, for example: `set " + Chr(34) + "MSX Music_volume" + Chr(34) + #CRLF$ +
    "50`." + #CRLF$ +
    "" + #CRLF$ +
    "For each sound device, you can control the distribution of the sound output of" + #CRLF$ +
    "this chip over the left and right channel, with the balance setting. This is" + #CRLF$ +
    "very similar to the balance knob on (older?) hifi equipment." + #CRLF$ +
    "Example: `set PSG_balance -100`, which sets" + #CRLF$ +
    "the PSG entirely to the left channel. Any sound device can also be individually" + #CRLF$ +
    "(un)muted using the `mute_channels` command." + #CRLF$ +
    "" + #CRLF$ +
    "If you'd like to apply some special effects to the PSG sound, you should take a" + #CRLF$ +
    "look at the `vibrato` and `detune`" + #CRLF$ +
    "(both percent and frequency) settings.")

  OMSXHelp_Add("8.2 MIDI",
    "Manual do Usuario - 8. Audio",
    "Currently, openMSX supports the following MSX MIDI interfaces:" + #CRLF$ +
    "" + #CRLF$ +
    "- MSX-MIDI of the MSX turboR GT and the μ・PACK," + #CRLF$ +
    "- the MIDI interface of the Philips Music Module (NMS 1205)," + #CRLF$ +
    "- the MIDI interface of the Yamaha SFG-01 and SFG-05 module (also present in the Yamaha CX5M series of machines)," + #CRLF$ +
    "- the FAC MIDI Interface, and" + #CRLF$ +
    "- the JVC (UK) MSX MIDI interface." + #CRLF$ +
    "" + #CRLF$ +
    "To use MIDI, start openMSX with a machine that has a MIDI interface built in," + #CRLF$ +
    "or add one of the mentioned MIDI interface extensions. Then plug a MIDI out" + #CRLF$ +
    "and/or MIDI in device into that MSX MIDI interface using the GUI" + #CRLF$ +
    "Main menu bar → Connector menu or the" + #CRLF$ +
    "openMSX `console`." + #CRLF$ +
    "" + #CRLF$ +
    "## MIDI Out" + #CRLF$ +
    "" + #CRLF$ +
    "You can connect the MIDI out of the MSX to a host MIDI device, such as a" + #CRLF$ +
    "physical MIDI out port, a soft synthesizer or a sequencer program. On Windows," + #CRLF$ +
    "Linux and macOS, host MIDI devices are made available as pluggables in openMSX." + #CRLF$ +
    "On macOS, you can opt to instead select `Virtual OUT` to create a" + #CRLF$ +
    "virtual MIDI port for Mac MIDI software to connect to." + #CRLF$ +
    "" + #CRLF$ +
    "For example, use the machine `Panasonic_FS-A1GT` and plug into the" + #CRLF$ +
    "Munt (https://sourceforge.net/projects/munt/) soft" + #CRLF$ +
    "synthesizer (MT-32 emulator) using Main menu bar" + #CRLF$ +
    "→ Connectors menu, or with the console command `plug msx-midi-out Munt\" + #CRLF$ +
    "MT-32`." + #CRLF$ +
    "" + #CRLF$ +
    "The exact naming of the host MIDI devices differs per platform. In the console" + #CRLF$ +
    "you can use tab completion to see the options: type `plug" + #CRLF$ +
    "msx-midi-out` and hit TAB twice." + #CRLF$ +
    "" + #CRLF$ +
    "The `midi-out-logger` MIDI device is available on all platforms and" + #CRLF$ +
    "logs MIDI events to a file." + #CRLF$ +
    "" + #CRLF$ +
    "You can specify the file to log to using `set" + #CRLF$ +
    "midi-out-logfilename`." + #CRLF$ +
    "The log is a raw binary log of the bytes written by the MIDI interface, with no" + #CRLF$ +
    "timing information. Therefore its usefulness is mostly limited to debugging." + #CRLF$ +
    "" + #CRLF$ +
    "On UNIX-like systems, it is possible to log to a MIDI device node, for example" + #CRLF$ +
    "`/dev/midi` and configure the sound system to send those notes to a" + #CRLF$ +
    "soft synthesizer. This is harder to configure than using for example the ALSA" + #CRLF$ +
    "MIDI out device, so it's only recommended when no platform-specific MIDI" + #CRLF$ +
    "devices are available in openMSX. On MSX Resource Center there is a forum thread (http://www.msx.org/forum/semi-msx-talk/emulation/openmsx-timidity) which describes how to connect openMSX to Timidity via" + #CRLF$ +
    "`/dev/midi`." + #CRLF$ +
    "" + #CRLF$ +
    "## MIDI In" + #CRLF$ +
    "" + #CRLF$ +
    "Vice versa, the MIDI in port can also receive data from the system by plugging" + #CRLF$ +
    "a device into `msx-midi-in` (for the Panasonic FS-A1GT; use the" + #CRLF$ +
    "appropriate connector name for other devices). Analogous to the above mentioned" + #CRLF$ +
    "outputs you can connect a `midi-in-reader` which reads from a file" + #CRLF$ +
    "or `/dev/midi` on Linux. On Windows and macOS available MIDI devices" + #CRLF$ +
    "show up as separate pluggables. On macOS a `Virtual IN` port is" + #CRLF$ +
    "available as well.")

  OMSXHelp_Add("8.3 Recording Audio to File",
    "Manual do Usuario - 8. Audio",
    "openMSX records the sound at the exact speed at which it should be produced, no" + #CRLF$ +
    "matter the speed at which the emulation was running while recording. Note that" + #CRLF$ +
    "recording sound to the uncompressed WAV format will take a lot of disk space:" + #CRLF$ +
    "at 44.1 kHz it will take about 176 kB per second." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI you can find the audio recorder under Main menu bar → Tools → Capture →" + #CRLF$ +
    "Audio/Video, which will open a the audio/video recording window. Just" + #CRLF$ +
    "select only Audio to log to said WAV file." + #CRLF$ +
    "" + #CRLF$ +
    "The underlying console command to start the recording of sound is `soundlog start`. It" + #CRLF$ +
    "will automatically choose a file name and save it in the `soundlogs`" + #CRLF$ +
    "directory in your personal openMSX folder. You can also add an extra parameter" + #CRLF$ +
    "to specify the filename for the new WAV file. To stop recording, use `soundlog stop`. You" + #CRLF$ +
    "can toggle the recording status using `soundlog toggle`, which is useful if" + #CRLF$ +
    "you `bind` this" + #CRLF$ +
    "command to a hotkey." + #CRLF$ +
    "" + #CRLF$ +
    "There is also an advanced feature for recording audio to file: you can record" + #CRLF$ +
    "individual channels of sound chips to individual files on disk. The sound is in" + #CRLF$ +
    "the native frequency of the sound chip this time, which means that for chips" + #CRLF$ +
    "like PSG or SCC (which run at very high frequencies), the files will be huge." + #CRLF$ +
    "(You have been warned!) This feature can be controlled in the GUI via Main menu bar → Settings → Sound → Show" + #CRLF$ +
    "sound chip settings and in that window click on the " + Chr(34) + "channels" + Chr(34) + " checkbox," + #CRLF$ +
    "which opens a window where you can fill in a file name for each channel you" + #CRLF$ +
    "want to record with. Perhaps it is easiest to control from the console with the" + #CRLF$ +
    "`record_channels` command. Note" + #CRLF$ +
    "that in contrast to the `soundlog` command, the output file of" + #CRLF$ +
    "this command ends up in the current directory and not in a special directory." + #CRLF$ +
    "We hope you can use this command to study the fantastic compositions of MSX" + #CRLF$ +
    "software and make great remakes of them.")

  OMSXHelp_Add("9.1 Saving/Loading the State of the Machine",
    "Manual do Usuario - 9. Useful Extras",
    "A feature of emulators which is particularly useful is saving the state of the" + #CRLF$ +
    "emulated machine to a file, in order to load it again later and continue" + #CRLF$ +
    "exactly where you left off when saving. Not only useful for games, but also for" + #CRLF$ +
    "debugging or testing. For openMSX we designed this feature in such a way" + #CRLF$ +
    "that it is trying really hard to be future proof. So, you" + #CRLF$ +
    "don't have to be afraid to upgrade to a new version of openMSX: your save" + #CRLF$ +
    "states will remain usable!" + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI's Main menu bar → Save" + #CRLF$ +
    "state menu you find all options to (quick) load and save states and even" + #CRLF$ +
    "more." + #CRLF$ +
    "" + #CRLF$ +
    "The easiest way to use it is by using the keyboard shortcuts for quickly saving" + #CRLF$ +
    "and loading a state, see the shortcut hints in the aforementioned menu and also the key mapping section. These shortcuts basically use the `savestate` and loadstate commands, with the" + #CRLF$ +
    "parameter `quicksave`, i.e. they use a savestate file with the name" + #CRLF$ +
    "'quicksave'. You can also use the commands directly yourself, with the argument" + #CRLF$ +
    "as the name of the slot you save the state to (use TAB or the `list_savestates`" + #CRLF$ +
    "command to see your previously saved states). Without having to browse the file" + #CRLF$ +
    "system of your computer, you can also conveniently delete existing save games" + #CRLF$ +
    "with the `delete_savestate` command." + #CRLF$ +
    "" + #CRLF$ +
    "Note that when saving the state of the machine, a screenshot will also be saved" + #CRLF$ +
    "with it, so that those could be used for save state browsing.")

  OMSXHelp_Add("9.2 Reverse",
    "Manual do Usuario - 9. Useful Extras",
    "Inspired by the meisei MSX emulator, openMSX also has a reverse feature." + #CRLF$ +
    "This enables you to go back in MSX time, so you can correct mistakes in your" + #CRLF$ +
    "game play or you can watch what you did (and also record a video of it)." + #CRLF$ +
    "" + #CRLF$ +
    "You can go back in time a second using the key binding for this: PageUp. Once you" + #CRLF$ +
    "went back, openMSX will replay whatever you did when you were at this time for" + #CRLF$ +
    "the first time, until it got at the point where you went back. From then on," + #CRLF$ +
    "everything will continue as normal. If you touched any control of your MSX" + #CRLF$ +
    "during replay, you have indicated to take over from the replay. If you do that," + #CRLF$ +
    "the rest of the replay is erased (openMSX forgets that that future ever" + #CRLF$ +
    "happened). This is the typical way to correct mistakes using this feature." + #CRLF$ +
    "" + #CRLF$ +
    "While replaying, you can also jump forward in time (" + Chr(34) + "Back to the Future" + Chr(34) + ") using" + #CRLF$ +
    "PageDown. Also, you can go back a specific amount of seconds or to an absolute" + #CRLF$ +
    "moment in (MSX) time, all using the `reverse` command. (This can also be" + #CRLF$ +
    "useful when you're developing/debugging MSX software.)" + #CRLF$ +
    "" + #CRLF$ +
    "If all of this sounds a bit confusing, you can use the reverse bar (by default," + #CRLF$ +
    "it's placed in the bottom right corner, hover there in the main openMSX window" + #CRLF$ +
    "to make it appear), which will show you a visualisation of all of this on" + #CRLF$ +
    "screen. The bar represents the time while the feature was enabled and shows the" + #CRLF$ +
    "current moment in time (the red indicator). You can click on it to jump back" + #CRLF$ +
    "and forward in time. The vertical lines indicate times when snapshots were" + #CRLF$ +
    "made. The bar will fade out after a while, but hovering your cursor over it" + #CRLF$ +
    "makes it reappear. If you want to get rid of the bar, toggle this setting in" + #CRLF$ +
    "the GUI menu: Main menu bar → Save state" + #CRLF$ +
    "→ Reverse/replay settings → Show reverse bar. (This will not" + #CRLF$ +
    "turn off the reverse feature itself.)" + #CRLF$ +
    "" + #CRLF$ +
    "If you want to disable the reverse feature, you can use Main menu bar → Save state → Reverse/replay" + #CRLF$ +
    "settings → Enable reverse/replay or the underlying `reverse stop` console command." + #CRLF$ +
    "And if you don't want it to restart again anymore, uncheck the Main menu bar → Save state → Reverse/replay" + #CRLF$ +
    "settings → Auto enable reverse `setting`." + #CRLF$ +
    "" + #CRLF$ +
    "If you want to save a very compact recording of what you did, or want to have" + #CRLF$ +
    "the possibility to start off in the middle of a recording, you can save your" + #CRLF$ +
    "complete replay to a file with Main menu bar → Save state → Save" + #CRLF$ +
    "replay or the `reverse savereplay` command. They can" + #CRLF$ +
    "also be loaded of course, with Main menu bar → Save state → Load" + #CRLF$ +
    "replay or `reverse loadreplay`.")

  OMSXHelp_Add("9.3 Game Trainer",
    "Manual do Usuario - 9. Useful Extras",
    "openMSX includes a game trainer system. You start with it by using the GUI" + #CRLF$ +
    "menu: Main menu bar → Tools → Trainer Selector This will open a window in which you" + #CRLF$ +
    "must first select the game you want to use a trainer for from the list of" + #CRLF$ +
    "supported games. When a game is selected, you see the list of cheats displayed" + #CRLF$ +
    "for the game, where you can also toggle the different cheats you want to" + #CRLF$ +
    "activate." + #CRLF$ +
    "" + #CRLF$ +
    "As with most openMSX functionality, the trainers can also be used from the `console`, and even there it is very easy to" + #CRLF$ +
    "use. As always, you could type: `help trainer`, for some basic help." + #CRLF$ +
    "" + #CRLF$ +
    "Suppose you want to cheat on Metal Gear. Then it would be useful to type:" + #CRLF$ +
    "`trainer Metal[TAB]`, which will expand to: `trainer Metal\" + #CRLF$ +
    "Gear`. When you then press enter, you see which cheats are available in" + #CRLF$ +
    "the Metal Gear trainer. You can activate them by typing e.g.: `trainer" + #CRLF$ +
    "Metal\ Gear 1 2 3 4`. This will activate (toggle) the first 4 cheats (as" + #CRLF$ +
    "the list will tell you which is printed after the command: the crosses indicate an" + #CRLF$ +
    "active cheat). You can also use the descriptions instead of the numbers:" + #CRLF$ +
    "`trainer Metal\ Gear " + Chr(34) + "enemy 1 gone" + Chr(34) + " " + Chr(34) + "enemy 2 gone" + Chr(34) + "`. Or, if you want" + #CRLF$ +
    "to activate all cheats you can simply type: `trainer Metal\ Gear" + #CRLF$ +
    "all`." + #CRLF$ +
    "" + #CRLF$ +
    "If this sounds a bit difficult for you, just try it out. It's really much" + #CRLF$ +
    "easier when you actually work with it." + #CRLF$ +
    "As always in the console, using TAB to complete your commands and their options" + #CRLF$ +
    "proves to be very useful!")

  OMSXHelp_Add("9.4 Debug Device",
    "Manual do Usuario - 9. Useful Extras",
    "This chapter describes how an MSX programmer can use the openMSX built-in debug" + #CRLF$ +
    "device. This is an artificial MSX device that is connected to an MSX I/O port." + #CRLF$ +
    "It can be used to send debug messages to the host operating system." + #CRLF$ +
    "" + #CRLF$ +
    "Note that openMSX also contains built-in debugging functions, which can be" + #CRLF$ +
    "accessed with the `debug` console command. With that debugger" + #CRLF$ +
    "you can read and write all registers and memory of almost all devices that are" + #CRLF$ +
    "supported in openMSX. It also supports break points, watch points and stepping." + #CRLF$ +
    "See the Main menu" + #CRLF$ +
    "bar → Debugger menu for the most common debugging options." + #CRLF$ +
    "" + #CRLF$ +
    "## 9.4.1 Enabling the Debug Device" + #CRLF$ +
    "" + #CRLF$ +
    "To enable the debug device, insert the `debugdevice` extension. To" + #CRLF$ +
    "do this when starting openMSX, simply add `-ext debugdevice` to the" + #CRLF$ +
    "openMSX command line. If openMSX is already running, you can use the" + #CRLF$ +
    "`ext`" + #CRLF$ +
    "console command." + #CRLF$ +
    "" + #CRLF$ +
    "You can use the `Debug Device output` setting to specify the" + #CRLF$ +
    "file name to write the debug output to." + #CRLF$ +
    "" + #CRLF$ +
    "## 9.4.2 Output Ports" + #CRLF$ +
    "" + #CRLF$ +
    "Controlling the device is done from within an MSX program. For this purpose, the" + #CRLF$ +
    "output ports 0x2E and 0x2F are used. The first port is the Mode Set Register." + #CRLF$ +
    "Bytes sent to this port have the following meaning." + #CRLF$ +
    "" + #CRLF$ +
    "**bit(s) | meaning**" + #CRLF$ +
    "- 7 -- unused" + #CRLF$ +
    "- 6 -- line feed mode (0 = line feed at mode change, 1 no line feed)" + #CRLF$ +
    "- 5-4 -- output mode (0 = OFF, 1 = single byte, 2 = multi byte)" + #CRLF$ +
    "- 3-0 -- mode-specific parameters (see below)" + #CRLF$ +
    "" + #CRLF$ +
    "When using mode 1, single byte mode, the lower 4 bits each enable a particular" + #CRLF$ +
    "output format:" + #CRLF$ +
    "" + #CRLF$ +
    "**bit(s) | meaning**" + #CRLF$ +
    "- 3 -- ASCII mode on/off" + #CRLF$ +
    "- 2 -- decimal mode on/off" + #CRLF$ +
    "- 1 -- binary mode on/off" + #CRLF$ +
    "- 0 -- hexadecimal mode on/off" + #CRLF$ +
    "" + #CRLF$ +
    "So, every parameter bit turns an output format on or off and more than one" + #CRLF$ +
    "output format can be specified at the same time." + #CRLF$ +
    "" + #CRLF$ +
    "The parameters for mode 2 (multi byte mode) are as follows:" + #CRLF$ +
    "" + #CRLF$ +
    "**bit(s) | meaning**" + #CRLF$ +
    "- 3-2 -- unused" + #CRLF$ +
    "- 1-0 -- mode (0 = hex, 1 = binary, 2 = decimal, 3 = ASCII mode)" + #CRLF$ +
    "" + #CRLF$ +
    "## 9.4.3 Single Byte Mode" + #CRLF$ +
    "" + #CRLF$ +
    "In mode 1, any write to port 0x2F will result in output. This way, the" + #CRLF$ +
    "programmer can see if a specific address is reached by adding a single" + #CRLF$ +
    "`OUT` to the code. The output depends on the parameters set with the" + #CRLF$ +
    "mode register. Each bit represents a specific format, and by turning the bits" + #CRLF$ +
    "on and off, the programmer can decide which formats should be used." + #CRLF$ +
    "" + #CRLF$ +
    "Here is an example:" + #CRLF$ +
    "" + #CRLF$ +
    "LD A,65" + #CRLF$ +
    "OUT ($2f),A" + #CRLF$ +
    "" + #CRLF$ +
    "This will give the following output:" + #CRLF$ +
    "" + #CRLF$ +
    "41h 01000001b 065 'A' emutime: 36407199578" + #CRLF$ +
    "" + #CRLF$ +
    "(when all bits are on, mode register = 0x1F)" + #CRLF$ +
    "" + #CRLF$ +
    "or" + #CRLF$ +
    "" + #CRLF$ +
    "41h 065 'A' emutime: 36407199578" + #CRLF$ +
    "" + #CRLF$ +
    "(when the binary bit is off, mode register = 0x1D)" + #CRLF$ +
    "" + #CRLF$ +
    "or" + #CRLF$ +
    "" + #CRLF$ +
    "41h emutime: 36407199578" + #CRLF$ +
    "" + #CRLF$ +
    "(when only the hexbit is on, mode register = 0x11)" + #CRLF$ +
    "" + #CRLF$ +
    "and so on." + #CRLF$ +
    "" + #CRLF$ +
    "The EmuTime part is a special number that keeps track of the openMSX emulation." + #CRLF$ +
    "The larger this number is, the later the event took place. This is a great way" + #CRLF$ +
    "to get an idea of the timing of things." + #CRLF$ +
    "" + #CRLF$ +
    "If the character to print is a special character, like carriage return," + #CRLF$ +
    "linefeed, beep or tab, the character between the ' ' will be a dot (.) and the" + #CRLF$ +
    "normal character is 'displayed' at the very end of the line, so it won't mess up" + #CRLF$ +
    "the layout of the whole line." + #CRLF$ +
    "" + #CRLF$ +
    "## 9.4.4 Multi Byte Mode" + #CRLF$ +
    "" + #CRLF$ +
    "Unlike mode 1, the data in this mode is always shown in one mode only. It's" + #CRLF$ +
    "either in hex mode, binary mode, decimal mode or ASCII mode, but never a" + #CRLF$ +
    "combination. Also the EmuTime bit is left out." + #CRLF$ +
    "" + #CRLF$ +
    "Here is an example:" + #CRLF$ +
    "" + #CRLF$ +
    "LD A,xx" + #CRLF$ +
    "OUT ($2e),A" + #CRLF$ +
    "LD A,$41" + #CRLF$ +
    "OUT ($2f),A" + #CRLF$ +
    "OUT ($2f),A" + #CRLF$ +
    "OUT ($2f),A" + #CRLF$ +
    "" + #CRLF$ +
    "If we substitute `$20` for `xx`, we get:" + #CRLF$ +
    "" + #CRLF$ +
    "41h 41h 41h" + #CRLF$ +
    "" + #CRLF$ +
    "and if we substitute `$22` for `xx`, we get:" + #CRLF$ +
    "" + #CRLF$ +
    "065 065 065" + #CRLF$ +
    "" + #CRLF$ +
    "The extra zero is added to keep alignment. Finally, if we want ASCII" + #CRLF$ +
    "output, all we need to do is change `xx` for `$23`:" + #CRLF$ +
    "" + #CRLF$ +
    "AAA" + #CRLF$ +
    "" + #CRLF$ +
    "In this special case, the space in between the data is left out. Any special" + #CRLF$ +
    "character like carriage return, linefeed, beep or tab will be printed as you" + #CRLF$ +
    "would expect.")

  OMSXHelp_Add("9.5 Programmable Device",
    "Manual do Usuario - 9. Useful Extras",
    "This chapter describes briefly the built-in programmable device, a resource that" + #CRLF$ +
    "could prove useful for driver or hardware developers writing and debugging" + #CRLF$ +
    "software on openMSX instead of a real MSX. The programmable device is a virtual" + #CRLF$ +
    "MSX device that can be connected on the fly to a user-defined list of I/O ports." + #CRLF$ +
    "It can be used to create a two-way communication between the virtual computer" + #CRLF$ +
    "and the host operating system by using the high-level Tcl language that openMSX" + #CRLF$ +
    "provides. It goes without saying that you must know how to use the Tcl language" + #CRLF$ +
    "to use this feature." + #CRLF$ +
    "" + #CRLF$ +
    "Note that this is not intended to be used as a drop-in replacement for" + #CRLF$ +
    "resource-intensive hardware like VDPs. Tcl is overall a very slow language, but" + #CRLF$ +
    "a programmable device opens up possibilities for using openMSX as a development" + #CRLF$ +
    "tool that were not possible before." + #CRLF$ +
    "" + #CRLF$ +
    "Note there's some overlap between this device and the `debug watchpoint add read_io/write_io`" + #CRLF$ +
    "command. Both can be used to make Tcl react to I/O read/write operations. This" + #CRLF$ +
    "device is more suited for completely new functionality. The debug command is" + #CRLF$ +
    "more suited to intercept communication with existing MSX devices." + #CRLF$ +
    "" + #CRLF$ +
    "## 9.5.1 Enabling the Programmable Device" + #CRLF$ +
    "" + #CRLF$ +
    "To enable the programmable device, insert the `programmabledevice`" + #CRLF$ +
    "extension. To do this when starting openMSX, simply add" + #CRLF$ +
    "`-ext programmabledevice` to the openMSX command line. If openMSX is" + #CRLF$ +
    "already running, you can use the" + #CRLF$ +
    "`ext` console command." + #CRLF$ +
    "" + #CRLF$ +
    "## 9.5.2 Device Ports and callbacks" + #CRLF$ +
    "" + #CRLF$ +
    "Device ports are a list of I/O ports connected between the guest computer and" + #CRLF$ +
    "the Tcl environment. This means that anything a Z80 assembly program sends to" + #CRLF$ +
    "one of these I/O ports using an OUT instruction automatically calls an " + Chr(34) + "output" + #CRLF$ +
    "callback" + Chr(34) + " (a Tcl procedure) to receive the data on the Tcl side. You must" + #CRLF$ +
    "declare your own output callback, otherwise the programmable device will do" + #CRLF$ +
    "nothing when it receives a byte. Your callback must have two parameters: port" + #CRLF$ +
    "and value (2 8-bit values) the return value from this callback is ignored." + #CRLF$ +
    "" + #CRLF$ +
    "Alternatively, anything a Z80 assembly program reads from one of these I/O ports" + #CRLF$ +
    "using an IN instruction automatically calls an " + Chr(34) + "input callback" + Chr(34) + " on the Tcl side." + #CRLF$ +
    "That callback produces the value that will be received by the Z80. You also must" + #CRLF$ +
    "declare your own input callback, otherwise the programmable device will return" + #CRLF$ +
    "0xFF. An input callback receives a (8-bit) port number as the only parameter," + #CRLF$ +
    "and it must return an 8-bit value." + #CRLF$ +
    "" + #CRLF$ +
    "The third kind of callback you can create is the " + Chr(34) + "reset callback" + Chr(34) + ". This one has" + #CRLF$ +
    "no parameters and the return value is ignored. It can be useful for setting back" + #CRLF$ +
    "an initial state when the MSX reboots." + #CRLF$ +
    "" + #CRLF$ +
    "You can check the 4 settings that Programmable Device uses with the `help` command, but briefly:" + #CRLF$ +
    "" + #CRLF$ +
    "``set` {Programmable Device" + #CRLF$ +
    "ports} {6 7}`" + #CRLF$ +
    "" + #CRLF$ +
    "tracks I/O ports 6 and 7." + #CRLF$ +
    "" + #CRLF$ +
    "``set` {Programmable Device" + #CRLF$ +
    "reset callback} " + Chr(34) + "my_reset_proc" + Chr(34) + "`" + #CRLF$ +
    "" + #CRLF$ +
    "connects the reset event with your previously declared " + Chr(34) + "my_reset_proc" + Chr(34) + " callback." + #CRLF$ +
    "" + #CRLF$ +
    "``set` {Programmable Device" + #CRLF$ +
    "output callback} " + Chr(34) + "my_output_proc" + Chr(34) + "`" + #CRLF$ +
    "" + #CRLF$ +
    "connects the " + Chr(34) + "OUT instruction" + Chr(34) + " event with your previously declared" + #CRLF$ +
    Chr(34) + "my_output_proc" + Chr(34) + " callback." + #CRLF$ +
    "" + #CRLF$ +
    "``set` {Programmable Device" + #CRLF$ +
    "input callback} " + Chr(34) + "my_input_proc" + Chr(34) + "`" + #CRLF$ +
    "" + #CRLF$ +
    "connects the " + Chr(34) + "IN instruction" + Chr(34) + " event with your previously declared" + #CRLF$ +
    Chr(34) + "my_input_proc" + Chr(34) + " callback.")

  OMSXHelp_Add("9.6 SDCC Debugger",
    "Manual do Usuario - 9. Useful Extras",
    "openMSX includes the SDCC Debugger called sdcdb, a Tcl script that mimics GDB (GNU Debugger) and allows you to inspect programs compiled with the Small Device C Compiler (SDCC) from the console. You just need to compile your SDCC code with the `-debug` flag to create a CDB file with symbols and their respective addresses and then call `sdcdb open <directory>` where the CDB file and source code are. Now you can inspect the program while it executes. For instance, to create a breakpoint at file `main.c`, line 155 from your source code, you can type:" + #CRLF$ +
    "" + #CRLF$ +
    "`sdcdb break main.c:155`" + #CRLF$ +
    "" + #CRLF$ +
    "A SDCDB breakpoint is a regular breakpoint and it can be listed with the `debug breakpoint list` command. When a breakpoint is triggered, you can inspect the source code around it with command `sdcdb info`. There are two commands that executes code step by step. The first is `sdcdb step`, which executes C code line by line and goes inside function calls. It is equivalent to the `step_in` command from the console. The second is `sdcdb next`, which executes C code line by line but doesn't go inside function calls. It is equivalent to the `step_over` command from the console. The useful `sdcdb laddress <address>` will display source code under the given memory address since sdcdb is aware of the program's source code, like GDB. You can type `help sdcdb` for more details or check out the comments in `sdcdb.tcl` script for more examples.")

  OMSXHelp_Add("10. Contact Info",
    "Manual do Usuario - 10. Contact Info",
    "Because openMSX is still in heavy development, feedback and bug reports are very" + #CRLF$ +
    "welcome!" + #CRLF$ +
    "" + #CRLF$ +
    "If you encounter problems, you have several options:" + #CRLF$ +
    "" + #CRLF$ +
    "1. Go to our IRC channel: #openMSX on libera.chat" + #CRLF$ +
    "and ask your question there. Also reachable via webchat (https://web.libera.chat/#openMSX)! If you don't get a reply" + #CRLF$ +
    "immediately, please stick around for a while, or use one of the other contact" + #CRLF$ +
    "options. The majority of the developers lives in time zone GMT+1. You may get" + #CRLF$ +
    "no response if you contact them in the middle of the night..." + #CRLF$ +
    "2. Post a message on the openMSX forum on MRC (http://www.msx.org/forum/semi-msx-talk/openmsx)." + #CRLF$ +
    "3. Create a new issue in the" + #CRLF$ +
    "openMSX issue tracker (https://github.com/openMSX/openMSX/issues)" + #CRLF$ +
    "on GitHub." + #CRLF$ +
    "You need a (free) log-in on GitHub to get access." + #CRLF$ +
    "4. Contact us and other users via one of the mailing lists. If you're a regular" + #CRLF$ +
    "user and want to discuss openMSX and possible problems, join our" + #CRLF$ +
    "`openmsx-user` mailing list." + #CRLF$ +
    "If you want to address the openMSX developers directly, post a message to the" + #CRLF$ +
    "`openmsx-devel` mailing list." + #CRLF$ +
    "More info on the" + #CRLF$ +
    "openMSX mailing lists (https://sourceforge.net/p/openmsx/mailman)," + #CRLF$ +
    "including an archive of old messages, can be found at SourceForge." + #CRLF$ +
    "" + #CRLF$ +
    "In any case, try to give as much information as possible when you describe your" + #CRLF$ +
    "bug or request.")

EndProcedure

; ============================================================
; OMSXHelp_BuildDiskmanipulator
; ============================================================
Procedure OMSXHelp_BuildDiskmanipulator()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("General Syntax",
    "Diskmanipulator - General Syntax",
    "The general command syntax is always of the form:" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator <command> <disk name>" + #CRLF$ +
    "<command arguments>`" + #CRLF$ +
    "" + #CRLF$ +
    "`<command>` specifies the action to be performed. The next section lists the commands available and explains them." + #CRLF$ +
    "" + #CRLF$ +
    "`<disk name>` specifies the disk to operate on. Typical values are: `diska`, `diskb`, `hda` or the special `virtual_drive` device. `disk<x>` and `hd<x>` are the drives available to the running emulated MSX machine. This allows interaction with the currently used disk images." + #CRLF$ +
    "" + #CRLF$ +
    "In case the disk contains a Sunrise IDE, Beer IDE 1.9RC1 or Nextor compatible partition table you can add a partition number (starting at 1) to the disk name to specify on which partition the command will act. For example `hda2` is the second partition on the master IDE disk, `hdb3` is the third partition on the slave IDE disk." + #CRLF$ +
    "" + #CRLF$ +
    "`<command arguments>` depend upon the command involved, see the detailed descriptions of the commands below." + #CRLF$ +
    "" + #CRLF$ +
    "The diskmanipulator and all its commands (including most parameters) can be tab completed in the console.")

  OMSXHelp_Add("Commands",
    "Diskmanipulator - Commands",
    "These are the commands understood by the diskmanipulator:")

  OMSXHelp_Add("chdir",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator chdir <disk name> <MSX" + #CRLF$ +
    "directory>`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "This command selects the directory on the MSX disk image" + #CRLF$ +
    "that will be used for the `export` and `import` commands." + #CRLF$ +
    "" + #CRLF$ +
    "Note: The directory structure on the MSX disk image cannot be tab" + #CRLF$ +
    "completed.")

  OMSXHelp_Add("create",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator create <dskfilename>" + #CRLF$ +
    "<size|option> [<size|option> ...]`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "You can create new disk images using this command." + #CRLF$ +
    "" + #CRLF$ +
    "This new disk will be formatted using an MSX-DOS2 boot sector by default," + #CRLF$ +
    "an MSX-DOS boot sector if you specify the option `-dos1`," + #CRLF$ +
    "or a Nextor boot sector if you specify the option `-nextor`." + #CRLF$ +
    "" + #CRLF$ +
    "If a size of 360 kB or 720 kB is given, a normal floppy disk image is" + #CRLF$ +
    "created, single or double sided respectively. Any larger value will result" + #CRLF$ +
    "in a Sunrise IDE hard disk image, or a Nextor one if the `-nextor`" + #CRLF$ +
    "option is specified." + #CRLF$ +
    "" + #CRLF$ +
    "You can specify multiple sizes in which case a Beer IDE 1.9, Sunrise IDE" + #CRLF$ +
    "or Nextor compatible partitioned image will be created, see" + #CRLF$ +
    "`partition` for more" + #CRLF$ +
    "information. Each partition will be formatted as required." + #CRLF$ +
    "" + #CRLF$ +
    "You can specify the disk/partition sizes by using the" + #CRLF$ +
    "following postfixes:" + #CRLF$ +
    "" + #CRLF$ +
    "- S or s -> size in sectors" + #CRLF$ +
    "- B or b -> size in bytes" + #CRLF$ +
    "- K or k -> size in kilobytes (default)" + #CRLF$ +
    "- M or m -> size in megabytes")

  OMSXHelp_Add("dir",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator dir <disk name>`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "This will show the directory content of the current working" + #CRLF$ +
    "directory. The output is formatted similarly to the MSX Disk BASIC 2.x command `files,l`.")

  OMSXHelp_Add("export",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator export <disk name> <host" + #CRLF$ +
    "directory>`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "This will export the files and subdirectories from the disk" + #CRLF$ +
    "inserted in `<disk name>` to the `<host directory>` on" + #CRLF$ +
    "your host OS. The subdirectory that will be exported from the MSX" + #CRLF$ +
    "disk image is selected by the `chdir` command.")

  OMSXHelp_Add("format",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator format <disk name> [<size|option>]`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "The currently selected partition from `<disk name>` will" + #CRLF$ +
    "be cleanly formatted with a MSX-DOS2 boot sector, unless the option" + #CRLF$ +
    "`-dos1` is specified. If the `-nextor` option is" + #CRLF$ +
    "specified it will use the Nextor boot sector, and use FAT16 if the size is" + #CRLF$ +
    "larger than 32 MB." + #CRLF$ +
    "FAT and directory sectors will be correctly initialised." + #CRLF$ +
    "Any data on the disk image / partition is lost!")

  OMSXHelp_Add("import",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator import <disk name> <host" + #CRLF$ +
    "directory|host file> ...`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "This will import the single `<host file>` into the disk" + #CRLF$ +
    "inserted in `<disk name>`. In case of a `<host" + #CRLF$ +
    "directory>` it will import the files and subdirectories in" + #CRLF$ +
    "`<host directory>` into the inserted disk. Multiple files and" + #CRLF$ +
    "directories can be specified at the same time. The place were the" + #CRLF$ +
    "files will be added in the MSX directory structure is selected" + #CRLF$ +
    "by the `chdir` command." + #CRLF$ +
    "" + #CRLF$ +
    "If you want to use wildcards when importing files, you will have to use" + #CRLF$ +
    "the Tcl glob (http://www.tcl.tk/man/tcl8.5/TclCmd/glob.htm) command. This command will perform the wildcard" + #CRLF$ +
    "expansion and return a Tcl list. Enclose the `glob` command in" + #CRLF$ +
    "between '[' and ']':" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator import hda1 [glob *.txt] [glob" + #CRLF$ +
    "*.asc]`" + #CRLF$ +
    "" + #CRLF$ +
    "This command will copy all files matching `*.txt` and `*.asc` in" + #CRLF$ +
    "the current directory on the host OS to the first partition of" + #CRLF$ +
    "the master IDE drive on the emulated MSX." + #CRLF$ +
    "" + #CRLF$ +
    "The `glob` command can also take extra options. For instance, if" + #CRLF$ +
    "you only want to expand regular files and not the names of" + #CRLF$ +
    "directories you can do this:" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator import hda1 [glob -type f" + #CRLF$ +
    "info*]`" + #CRLF$ +
    "" + #CRLF$ +
    "Consult your local Tcl guru or documentation for more info" + #CRLF$ +
    "about the `glob` command and Tcl lists.")

  OMSXHelp_Add("mkdir",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator mkdir <disk name> <MSX" + #CRLF$ +
    "directory>`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "This command will create the specified directory on the MSX disk image." + #CRLF$ +
    "All the needed parent directories will be created if they do not" + #CRLF$ +
    "yet exist.")

  OMSXHelp_Add("partition",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator partition <disk name>" + #CRLF$ +
    "[<size|option> ...]`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "You can (re)partition existing disk images using this command." + #CRLF$ +
    "" + #CRLF$ +
    "As many partitions as specified will be created, using one of the" + #CRLF$ +
    "following partition table formats according to the option given:" + #CRLF$ +
    "" + #CRLF$ +
    "- `-dos1`: Standard MBR, Beer IDE 1.9 and Nextor compatible." + #CRLF$ +
    "Max 4 partitions." + #CRLF$ +
    "- `-dos2` (default): Sunrise IDE MBR, Sunrise IDE compatible." + #CRLF$ +
    "Max 31 partitions." + #CRLF$ +
    "- `-nextor`: Standard MBR / EBR, Nextor compatible." + #CRLF$ +
    "Max 256 partitions." + #CRLF$ +
    "" + #CRLF$ +
    "After partitioning each partition will also be formatted appropriately," + #CRLF$ +
    "see format for more details on that." + #CRLF$ +
    "" + #CRLF$ +
    "You can specify the disk/partition sizes by using the following" + #CRLF$ +
    "postfixes:" + #CRLF$ +
    "" + #CRLF$ +
    "- S or s -> size in sectors" + #CRLF$ +
    "- B or b -> size in bytes" + #CRLF$ +
    "- K or k -> size in kilobytes (default)" + #CRLF$ +
    "- M or m -> size in megabytes")

  OMSXHelp_Add("savedsk",
    "Diskmanipulator - Commands",
    "**syntax:**" + #CRLF$ +
    "" + #CRLF$ +
    "`diskmanipulator savedsk <disk name>" + #CRLF$ +
    "<dskfilename>`" + #CRLF$ +
    "" + #CRLF$ +
    "**explanation:**" + #CRLF$ +
    "" + #CRLF$ +
    "This simply reads all the sectors of the `<disk name>` and" + #CRLF$ +
    "saves them again in the file specified by `<dskfilename>`." + #CRLF$ +
    "This command is mostly equivalent to copying a disk image file on your host OS, but it has the additional possibilities:" + #CRLF$ +
    "" + #CRLF$ +
    "- saving a ramdsk (see `diska ramdsk`) into a real disk image file" + #CRLF$ +
    "- saving your current DirAsDisk image into a real disk image file" + #CRLF$ +
    "- saving your disk image which has undergone IPS patches as a patched disk image" + #CRLF$ +
    "- copying the currently active image file in case your host OS would give sharing violations while the file is being used by openMSX (Windows)" + #CRLF$ +
    "- saving a disk image if you removed the directory entry by accident, but openMSX still has an open file handle for the file (UNIX-like systems)")

  OMSXHelp_Add("Examples",
    "Diskmanipulator - Examples",
    "In these examples we will run the diskmanipulator while the" + #CRLF$ +
    "emulated MSX is powered off." + #CRLF$ +
    "It is possible to run these commands while the machine is" + #CRLF$ +
    "turned on of course, but be warned that this might have some" + #CRLF$ +
    "strange, unexpected behaviour depending on the emulated MSX model" + #CRLF$ +
    "and the running software on this MSX." + #CRLF$ +
    "" + #CRLF$ +
    "For instance, the turboR models contain a physical switch" + #CRLF$ +
    "inside their diskdrives to detect disk changes. If no disk change" + #CRLF$ +
    "is detected their internal MSX-DOS2 kernel will cache certain" + #CRLF$ +
    "sectors, so that files imported using the `diskmanipulator import`" + #CRLF$ +
    "command will not show up if you perform a `files` or" + #CRLF$ +
    "`dir`. Even worse, if you would write from the" + #CRLF$ +
    "emulated MSX to the disk you will overwrite the result of the import." + #CRLF$ +
    "The same would happen if you were running a disk cache" + #CRLF$ +
    "program in your emulated MSX machine.")

  OMSXHelp_Add("creating a new disk with content",
    "Diskmanipulator - Examples",
    "Here we create a regular 720 kB (double sided, double density)" + #CRLF$ +
    "disk. Then we place the files and subdirectories from the directory" + #CRLF$ +
    "`/tmp/todisk/` on this new disk:" + #CRLF$ +
    "" + #CRLF$ +
    "`set `power` off`" + #CRLF$ +
    "`diskmanipulator `create` /tmp/new-disk.dsk 720`" + #CRLF$ +
    "``virtual_drive` /tmp/new-disk.dsk`" + #CRLF$ +
    "`diskmanipulator `import` virtual_drive /tmp/todisk/`")

  OMSXHelp_Add("creating a new harddisk image with content",
    "Diskmanipulator - Examples",
    "Here we create a new HD image with 3 partitions the first" + #CRLF$ +
    "partition is 32 MB, then 16 MB and finally a small" + #CRLF$ +
    "one of 720 kB." + #CRLF$ +
    "Then we place the files and subdirs of the directory" + #CRLF$ +
    "`/tmp/topart1/` on the first partition and `/tmp/topart3/` on the third partition:" + #CRLF$ +
    "" + #CRLF$ +
    "`set `power` off`" + #CRLF$ +
    "``ext` ide`" + #CRLF$ +
    "`diskmanipulator `create` /tmp/new-hd.dsk 32M 16M 720`" + #CRLF$ +
    "``hda` /tmp/new-hd.dsk`" + #CRLF$ +
    "`diskmanipulator `import` hda1 /tmp/topart1`" + #CRLF$ +
    "`diskmanipulator `import` hda3 /tmp/topart3`")

  OMSXHelp_Add("importing data in a new subdirectory",
    "Diskmanipulator - Examples",
    "On the diskimage `/tmp/disk.dsk` we will create a new" + #CRLF$ +
    "subdirectory called `newsub` and then we fill this subdirectory with the" + #CRLF$ +
    "`.txt` files from `/home/david/sources`:" + #CRLF$ +
    "" + #CRLF$ +
    "`set `power` off`" + #CRLF$ +
    "``diska` /tmp/disk.dsk`" + #CRLF$ +
    "`diskmanipulator `mkdir` diska newsub`" + #CRLF$ +
    "`diskmanipulator `chdir` diska newsub`" + #CRLF$ +
    "`diskmanipulator `import` diska [glob -type f /home/david/sources/*.txt]`")

  OMSXHelp_Add("extracting files from an MSX harddisk image to the host OS",
    "Diskmanipulator - Examples",
    "We will extract files from the currently used harddisk image on" + #CRLF$ +
    "partition1 in the MSX subdir `\demos\calculus` to `/tmp/`:" + #CRLF$ +
    "" + #CRLF$ +
    "`set `power` off`" + #CRLF$ +
    "``ext` ide`" + #CRLF$ +
    "`diskmanipulator `chdir` hda1 /demos/calculus`" + #CRLF$ +
    "`diskmanipulator `export` hda1 /tmp`")

EndProcedure

; ============================================================
; OMSXHelp_BuildControl
; ============================================================
Procedure OMSXHelp_BuildControl()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("Introduction",
    "Controle Externo - Introduction",
    "Despite that openMSX now has an internal GUI that can control most of the" + #CRLF$ +
    "emulator's functionality, it is still possible for debugger GUIs, launcher" + #CRLF$ +
    "GUIs, etc., to be external programs that control openMSX. This document" + #CRLF$ +
    "explains you how you can control openMSX from your own application." + #CRLF$ +
    "" + #CRLF$ +
    "Note: This document was written for developers who are interested in writing their own application that" + #CRLF$ +
    "controls openMSX, rather than normal end-users." + #CRLF$ +
    "" + #CRLF$ +
    "Disclaimer: it is possible that some update events are still missing and it" + #CRLF$ +
    "is also possible that the structure of the replies and commands change. We" + #CRLF$ +
    "will do our best to be backwards compatible, though.")

  OMSXHelp_Add("Connecting",
    "Controle Externo - Connecting",
    "There are multiple ways to connect to openMSX. The first (and oldest) way" + #CRLF$ +
    "is using a pipe. Non-Windows systems use `stdio`, in Windows you can use a named pipe." + #CRLF$ +
    "To enable this, start openMSX like this:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -control stdio`" + #CRLF$ +
    "" + #CRLF$ +
    "or for Windows:" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx -control pipe`" + #CRLF$ +
    "" + #CRLF$ +
    "The second method is using a socket. Connecting on non-Windows systems" + #CRLF$ +
    "is done with a UNIX domain socket. openMSX puts the socket in" + #CRLF$ +
    "`/tmp/openmsx-<username>/socket.<pid>`. The" + #CRLF$ +
    "`/tmp/` dir can be overridden by environment variables" + #CRLF$ +
    "`TMPDIR`, `TMP` or `TEMP` (in that order)." + #CRLF$ +
    "" + #CRLF$ +
    "On Windows (which does not support UNIX domain sockets), the socket is a" + #CRLF$ +
    "normal TCP socket. The port number is random between 9938 and 9958. This is done" + #CRLF$ +
    "to enforce applications to deal with multiple running openMSX processes. The" + #CRLF$ +
    "port number will be put in the following text file:" + #CRLF$ +
    "" + #CRLF$ +
    "`%USERPROFILE%\Documents and Settings\<username>\Local Settings\Temp\openmsx-default\socket.<pid>`" + #CRLF$ +
    "" + #CRLF$ +
    "or, when `%USERPROFILE%` does not exist:" + #CRLF$ +
    "" + #CRLF$ +
    "`%TMPDIR%\openmsx-default`, or" + #CRLF$ +
    "" + #CRLF$ +
    "`%TMP%\openmsx-default`, or" + #CRLF$ +
    "" + #CRLF$ +
    "`%TEMP%\openmsx-default`, or as a last resort:" + #CRLF$ +
    "" + #CRLF$ +
    "`C:\WINDOWS\TEMP`" + #CRLF$ +
    "" + #CRLF$ +
    "After connecting, openMSX expects XML input on the channel and it will" + #CRLF$ +
    "also give you output. This is explained in the next section.")

  OMSXHelp_Add("Communication",
    "Controle Externo - Communication",
    "After connecting, openMSX expects XML input on the channel (pipe or socket)" + #CRLF$ +
    "and it will also give you output in XML format. The first output it gives is this:" + #CRLF$ +
    "" + #CRLF$ +
    "<openmsx-output>" + #CRLF$ +
    "" + #CRLF$ +
    "On non-Windows systems you can easily try it out by just starting openMSX" + #CRLF$ +
    "via the `stdio` method, as explained above. You give XML" + #CRLF$ +
    "commands via the keyboard in the terminal and openMSX will print its" + #CRLF$ +
    "responses on the terminal as well." + #CRLF$ +
    "" + #CRLF$ +
    "This first output is the opening tag (`<openmsx-output>`)." + #CRLF$ +
    "All messages that are normally printed on stdout in the" + #CRLF$ +
    "terminal from which you start openMSX are in a `<log>` tag." + #CRLF$ +
    "The level can be " + Chr(34) + "info" + Chr(34) + " or " + Chr(34) + "warning" + Chr(34) + " and the message is in the text node" + #CRLF$ +
    "itself." + #CRLF$ +
    "" + #CRLF$ +
    "When you want to start communicating back, you always have to start" + #CRLF$ +
    "with the opening tag first:" + #CRLF$ +
    "" + #CRLF$ +
    "`<openmsx-control>`" + #CRLF$ +
    "" + #CRLF$ +
    "When starting openMSX with the `-control` option, it will not show a" + #CRLF$ +
    "window: it starts with the 'none' renderer. So, a nice example (if you're" + #CRLF$ +
    "still experimenting on the command line) would be to type this:" + #CRLF$ +
    "" + #CRLF$ +
    "`<command>set renderer SDL</command>`" + #CRLF$ +
    "" + #CRLF$ +
    "With the `<command>` tag you can give any openMSX console" + #CRLF$ +
    "command to openMSX. The commands are documented in the Console Commands Reference." + #CRLF$ +
    "" + #CRLF$ +
    "Every `<command>` will result in a reply from openMSX. In" + #CRLF$ +
    "the above case it will be:" + #CRLF$ +
    "" + #CRLF$ +
    "<reply result=" + Chr(34) + "ok" + Chr(34) + ">SDL</reply>" + #CRLF$ +
    "" + #CRLF$ +
    "The order is maintained, i.e. the replies will be in the same order as" + #CRLF$ +
    "the commands you gave to openMSX. In this reply example, you see that" + #CRLF$ +
    "the command succeeded (result=ok) and it also gives you the actual result" + #CRLF$ +
    "text that would be printed on the console. In this case, the value of" + #CRLF$ +
    "the renderer setting. When a command fails, you get something like this:" + #CRLF$ +
    "" + #CRLF$ +
    "<command>biep</command>" + #CRLF$ +
    "<reply result=" + Chr(34) + "nok" + Chr(34) + ">invalid command name " + Chr(34) + "biep" + Chr(34) + #CRLF$ +
    "</reply>" + #CRLF$ +
    "" + #CRLF$ +
    Chr(34) + "biep" + Chr(34) + " is not a valid command, and openMSX tells you this via a " + Chr(34) + "nok" + Chr(34) + " reply" + #CRLF$ +
    "with the error message in the text node." + #CRLF$ +
    "" + #CRLF$ +
    "The next important thing is events. When you use this interface to control" + #CRLF$ +
    "openMSX, you want to know when things change. For this, you can enable events" + #CRLF$ +
    "for certain event classes." + #CRLF$ +
    "" + #CRLF$ +
    "An example:" + #CRLF$ +
    "" + #CRLF$ +
    "`<command>openmsx_update enable led</command>`" + #CRLF$ +
    "" + #CRLF$ +
    "This command will enable updates about LED events. When a LED changes, you'll" + #CRLF$ +
    "get messages such as:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "led" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "power" + Chr(34) + ">on</update>" + #CRLF$ +
    "" + #CRLF$ +
    "<update> tags are openMSX's way of telling you that something" + #CRLF$ +
    "changed. In this case, it is a LED update, for the machine with ID" + #CRLF$ +
    Chr(34) + "machine1" + Chr(34) + ". The name of the LED is " + Chr(34) + "power" + Chr(34) + " and the value is in the text node:" + #CRLF$ +
    "on." + #CRLF$ +
    "" + #CRLF$ +
    "Here is a list of the currently available event types and when they are sent:" + #CRLF$ +
    "" + #CRLF$ +
    "- `hardware` -- hardware changes occurred, like a change of machine" + #CRLF$ +
    "- `led` -- LED status changed" + #CRLF$ +
    "- `media` -- media (disk images, cartridges, etc.) changed" + #CRLF$ +
    "- `plug` -- a pluggable got plugged or unplugged (empty value)" + #CRLF$ +
    "- `setting` -- the value of a setting changed" + #CRLF$ +
    "- `setting-info` -- the properties of a setting changed (e.g. number of options changed)" + #CRLF$ +
    "- `status` -- status changed, currently only pause and debug break status" + #CRLF$ +
    "- `extension` -- extensions changed (add/remove)" + #CRLF$ +
    "- `sounddevice` -- sounddevices changed (add/remove)" + #CRLF$ +
    "- `connector` -- connectors changed (add/remove)")

  OMSXHelp_Add("Update Examples",
    "Controle Externo - Communication",
    "Someone changed machines from Boosted MSX2 to Toshiba HX-10 at run time:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " name=" + Chr(34) + "machine2" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "carta" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "cartb" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "cassetteplayer" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "diskb" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "diska" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "carta" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "cartb" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "cartc" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "cassetteplayer" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " name=" + Chr(34) + "machine1" + Chr(34) + ">remove</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "hardware" + Chr(34) + " name=" + Chr(34) + "machine2" + Chr(34) + ">select</update>" + #CRLF$ +
    "" + #CRLF$ +
    "CAPS LED went to OFF:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "led" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "caps" + Chr(34) + ">off</update>" + #CRLF$ +
    "" + #CRLF$ +
    "A tape was inserted in the cassette player:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "media" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "cassetteplayer" + Chr(34) + ">/home/manuel/msx-soft/tapes/Zoids.zip</update>" + #CRLF$ +
    "" + #CRLF$ +
    "The cassetteplayer got into play mode:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "status" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "cassetteplayer" + Chr(34) + ">play</update>" + #CRLF$ +
    "" + #CRLF$ +
    "Someone plugged in a joystick:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "plug" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "joyporta" + Chr(34) + ">msxjoystick1</update>" + #CRLF$ +
    "" + #CRLF$ +
    "And unplugged it again:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "plug" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "joyporta" + Chr(34) + "></update>" + #CRLF$ +
    "" + #CRLF$ +
    "The maxframeskip setting was set to 12:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "setting" + Chr(34) + " name=" + Chr(34) + "maxframeskip" + Chr(34) + ">12</update>" + #CRLF$ +
    "" + #CRLF$ +
    "openMSX got paused:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "status" + Chr(34) + " name=" + Chr(34) + "paused" + Chr(34) + ">true</update>" + #CRLF$ +
    "" + #CRLF$ +
    "openMSX entered a debug break state:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "status" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "cpu" + Chr(34) + ">suspended</update>" + #CRLF$ +
    "" + #CRLF$ +
    "openMSX exited the debug break state:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "status" + Chr(34) + " machine=" + Chr(34) + "machine1" + Chr(34) + " name=" + Chr(34) + "cpu" + Chr(34) + ">running</update>" + #CRLF$ +
    "" + #CRLF$ +
    "A Philips NMS-1205 Music Module was inserted:" + #CRLF$ +
    "" + #CRLF$ +
    "<update type=" + Chr(34) + "sounddevice" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "Philips NMS 1205 Music Module MSX-Audio 8-bit DAC" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "connector" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "audiokeyboardport" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "sounddevice" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "Philips NMS 1205 Music Module MSX-Audio DAC" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "sounddevice" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "Philips NMS 1205 Music Module MSX-Audio" + Chr(34) + ">add</update>" + #CRLF$ +
    "<update type=" + Chr(34) + "extension" + Chr(34) + " machine=" + Chr(34) + "machine2" + Chr(34) + " name=" + Chr(34) + "Philips_NMS_1205" + Chr(34) + ">add</update>" + #CRLF$ +
    "" + #CRLF$ +
    "And with this, you should have all info that you need to make any external" + #CRLF$ +
    "application that can control openMSX." + #CRLF$ +
    "" + #CRLF$ +
    "More real world examples can be found here:" + #CRLF$ +
    "" + #CRLF$ +
    "- in the Contrib directory of openMSX (openmsx-control*)" + #CRLF$ +
    "- in the code of (the now deprecated) openMSX Catapult (C++ via pipe)" + #CRLF$ +
    "- in the code of the never released newer openMSX Catapult (Python, still via pipe)" + #CRLF$ +
    "- in the code of the (now deprecated) openMSX GUI Debugger (C++ via socket)")

EndProcedure

; ============================================================
; OMSXHelp_BuildCommandsCommands
; ============================================================
Procedure OMSXHelp_BuildCommandsCommands()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("Introduction",
    "Referencia de Comandos - Introduction",
    "This manual describes all commands and settings which are available in openMSX. You can use them to control openMSX fully from the Console (a built-in command-line interface, use F10 to call it), via Tcl scripts and via remote connections (explained in Controlling openMSX from External Applications). If you want to unleash the full potential of openMSX or just want a reference of all available possibilities, this manual should serve you well.")

  OMSXHelp_Add("after",
    "Referencia de Comandos - Commands",
    "Execute a command after a certain event occurs, for example a given amount of time has passed or the emulator has been idle for a given amount of time." + #CRLF$ +
    "Every postponed command executes just once; if you want a command to run periodically, you have to issue it again every time it runs." + #CRLF$ +
    "The `after` command returns the id of the postponed command." + #CRLF$ +
    "It is possible to query a list of" + #CRLF$ +
    "postponed commands and also to cancel postponed commands." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `after time <seconds> <command>` -- Execute a command after some time. Timescale is in MSX seconds." + #CRLF$ +
    "- `after realtime <seconds> <command>` -- Execute a command after some time. Timescale is in host seconds." + #CRLF$ +
    "- `after idle <seconds> <command>` -- Execute a command after being idle for some time" + #CRLF$ +
    "- `after frame <command>` -- Execute a command when a video frame is finished" + #CRLF$ +
    "(VDP scanning reaches vsync)" + #CRLF$ +
    "- `after break <command>` -- Execute a command after a breakpoint is reached" + #CRLF$ +
    "- `after boot <command>` -- Execute a command after a (re)boot" + #CRLF$ +
    "- `after machine_switch <command>` -- Execute a command after switch to new a machine" + #CRLF$ +
    "- `after quit <command>` -- Execute a command after receiving a quit event, while openMSX shuts down." + #CRLF$ +
    "- `after <input-event> <command>` -- Execute a command after the given input event occurs. The events are e.g. mouse, joystick, focus and resize events, the same ones as for the `bind` command." + #CRLF$ +
    "- `after info` -- List all postponed commands" + #CRLF$ +
    "- `after cancel <id>` -- Cancel the postponed command with given id" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`after time 2.6 " + Chr(34) + "set renderer SDLGL-PP" + Chr(34) + "`" + #CRLF$ +
    "`after idle 100 exit`" + #CRLF$ +
    "`after info`" + #CRLF$ +
    "`after cancel after#2`" + #CRLF$ +
    "`after " + Chr(34) + "mouse button1 down" + Chr(34) + " foo`")

  OMSXHelp_Add("bind / unbind / bind_default / unbind_default / activate_input_layer / deactivate_input_layer",
    "Referencia de Comandos - Commands",
    "Associate events (such as key presses) with commands. Whenever the" + #CRLF$ +
    "specified event occurs (e.g. you press the specified key), the corresponding" + #CRLF$ +
    "command will be executed. Any Tcl command or combination of commands" + #CRLF$ +
    "separated with `;` (normal Tcl syntax) can be used. To customise your" + #CRLF$ +
    "bindings you should use the (un)bind commands. A script that wants to provide" + #CRLF$ +
    "a default binding for its functionality needs to use `bind_default`," + #CRLF$ +
    "this allows users with different preferences to overrule the default" + #CRLF$ +
    "bindings. Using the `-repeat` option makes sure that if the event is" + #CRLF$ +
    "repeated (e.g. keyboard events when keeping a key pressed), the command is" + #CRLF$ +
    "repeated as well." + #CRLF$ +
    "" + #CRLF$ +
    "Tcl scripts that need a whole set of bindings and only conditionally" + #CRLF$ +
    "activate those bindings can use the 'input layer' system. It's possible to" + #CRLF$ +
    "associate a binding with a specific layer and later specific layer(s) can be" + #CRLF$ +
    "activated or deactivated. Such a layer can also be activated in a blocking" + #CRLF$ +
    "mode. Blocking mode means that even if the layer didn't have a binding for a" + #CRLF$ +
    "certain event, that event is still not passed to the emulated MSX. This can" + #CRLF$ +
    "be useful to implement certain OSD widgets (like a virtual OSD keyboard)." + #CRLF$ +
    "" + #CRLF$ +
    "Events can be:" + #CRLF$ +
    "" + #CRLF$ +
    "- `<key>[,release]` -- Short for `keyb <key>[,release]`" + #CRLF$ +
    "- `keyb <key>[,release]` -- <key> is pressed [or released]" + #CRLF$ +
    "- `mouse button<n> <up/down>` -- Mouse button <n> went up or down" + #CRLF$ +
    "- `mouse motion <x> <y>` -- Mouse motion of <x> and <y>" + #CRLF$ +
    "- `joy<n> button<m> <up/down>` -- Button <m> of joystick <n> went up/down" + #CRLF$ +
    "- `joy<n> axis<m> <value>` -- Axis <m> of joystick <n> got value <value>" + #CRLF$ +
    "- `focus <boolean>` -- The openMSX window got (1) or lost (0) focus" + #CRLF$ +
    "- `OSDcontrol <button> PRESS|RELEASE` -- The virtual OSDcontrol <button> got pressed or released." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `bind` -- Show all bindings" + #CRLF$ +
    "- `bind -layer <layername>` -- Show all in a specific layer" + #CRLF$ +
    "- `bind <event> [-layer <layername>]` -- Show binding for the given event, optionally you can specify a layer" + #CRLF$ +
    "- `bind <event> [-layer <layername>] [-repeat] <command>` -- Make a new binding. Optionally make this binding in a specific layer." + #CRLF$ +
    "Also optionally it's possible to retrigger this binding periodically" + #CRLF$ +
    "(e.g. when a key is kept pressed)." + #CRLF$ +
    "- `bind -layers` -- Show the names of all layers that currently have bindings" + #CRLF$ +
    "- `unbind [-layer <layername>] <event>` -- Undo binding for this event (optionally in a specific layer)." + #CRLF$ +
    "- `unbind -layer <layername>` -- Undo all bindings in the specified layer" + #CRLF$ +
    "- `activate_input_layer` -- Show a list of the currently active layers." + #CRLF$ +
    "- `activate_input_layer [-blocking] <layername>` -- Activate the specified input layer, optionally this layer can be" + #CRLF$ +
    "activate in blocking mode." + #CRLF$ +
    "- `deactivate_input_layer <layername>` -- Deactivate the specified input layer." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`bind PAGEUP " + Chr(34) + "set speed 100" + Chr(34) + "`" + #CRLF$ +
    "`bind PAGEDOWN " + Chr(34) + "set speed 50" + Chr(34) + "`" + #CRLF$ +
    "Only run in fastforward-mode while F9 is pressed (like BrMSX):" + #CRLF$ +
    "`unbind F9`" + #CRLF$ +
    "`bind F9 " + Chr(34) + "set fastforward on" + Chr(34) + "`" + #CRLF$ +
    "`bind F9,release " + Chr(34) + "set fastforward off" + Chr(34) + "`" + #CRLF$ +
    "Pause when window loses focus (like fMSX):" + #CRLF$ +
    "`bind " + Chr(34) + "focus 0" + Chr(34) + " " + Chr(34) + "set pause on" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "focus 1" + Chr(34) + " " + Chr(34) + "set pause off" + Chr(34) + "`" + #CRLF$ +
    "Middle-click to toggle input grabbing:" + #CRLF$ +
    "`bind " + Chr(34) + "mouse button2 down" + Chr(34) + " " + Chr(34) + "toggle grabinput" + Chr(34) + "`" + #CRLF$ +
    "Map button 8 of joystick 1 to F2-key:" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button8 down" + Chr(34) + " " + Chr(34) + "keymatrixdown 6 0x40" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 button8 up" + Chr(34) + " " + Chr(34) + "keymatrixup 6 0x40" + Chr(34) + "`" + #CRLF$ +
    "Use PageUp/Down to increase/decrease emulation speed." + #CRLF$ +
    "`bind PAGEUP -repeat " + Chr(34) + "incr speed 1" + Chr(34) + "`" + #CRLF$ +
    "`bind PAGEDOWN -repeat " + Chr(34) + "incr speed -1" + Chr(34) + "`" + #CRLF$ +
    "Use Joystick hat left/right to increase/decrease volume." + #CRLF$ +
    "`bind " + Chr(34) + "joy1 hat0 left" + Chr(34) + " -repeat " + Chr(34) + "incr speed -5" + Chr(34) + "`" + #CRLF$ +
    "`bind " + Chr(34) + "joy1 hat0 right" + Chr(34) + " -repeat " + Chr(34) + "incr speed 5" + Chr(34) + "`" + #CRLF$ +
    "Toggle fullscreen with ALT and ENTER." + #CRLF$ +
    "`bind ALT+RETURN " + Chr(34) + "toggle fullscreen" + Chr(34) + "`" + #CRLF$ +
    "React to joystick or cursor up movement in a Tcl script:" + #CRLF$ +
    "`bind_default " + Chr(34) + "OSDcontrol UP PRESS" + Chr(34) + " -repeat {osd_menu::menu_action UP }`" + #CRLF$ +
    "React to joystick button 1 or spacebar press in a Tcl script:" + #CRLF$ +
    "`bind_default " + Chr(34) + "OSDcontrol A PRESS" + Chr(34) + " -repeat {osd_menu::menu_action A }`")

  OMSXHelp_Add("cart / cart<x>",
    "Referencia de Comandos - Commands",
    "Insert a ROM cartridge in a running MSX. The `cart` command inserts the cartridge in the first available slot. The `carta`, `cartb` etc. commands insert it in the specified slot. The cartridges can be removed again with the `eject` subcommand." + #CRLF$ +
    "" + #CRLF$ +
    "ROM cartridges are a special class of extensions. For extensions that are not ROM cartridges, see the commands `ext`, `list_extensions` and `remove_extension`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `cart KMARE.ROM` -- Insert ROM cartridge in first free slot" + #CRLF$ +
    "- `cart insert KMARE.ROM` -- Insert ROM cartridge in first free slot" + #CRLF$ +
    "- `carta USAS.ROM -ips USAS.IPS` -- Insert ROM cartridge in slot A, with IPS patch applied to the ROM contents" + #CRLF$ +
    "- `cartb NEMESIS.ROM -romtype Konami` -- Insert ROM cartridge in slot B, and explicitly specify the mapper type (is normally auto detected)" + #CRLF$ +
    "- `carta eject` -- Eject the currently inserted cartridge from slot A")

  OMSXHelp_Add("cassetteplayer",
    "Referencia de Comandos - Commands",
    "Controls the openMSX cassette player. The various subcommands can be used to insert, remove, create and rewind tape images." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `cassetteplayer insert <tape image>` -- Insert tape image (WAV, CAS or TSX format) in the cassette player" + #CRLF$ +
    "- `cassetteplayer eject` -- Remove tape from virtual cassette player" + #CRLF$ +
    "- `cassetteplayer rewind` -- Rewind the current tape" + #CRLF$ +
    "- `cassetteplayer motorcontrol on|off` -- Selects whether motor control signal (remote) is obeyed (default: on)" + #CRLF$ +
    "- `cassetteplayer new [<tape image>]` -- Create new tape image and go to record mode" + #CRLF$ +
    "- `cassetteplayer play` -- Go to play mode (when in record mode) and rewind the tape")

  OMSXHelp_Add("cd<x>",
    "Referencia de Comandos - Commands",
    "Change the CDROM image. The commands `cda`, `cdb` etc. are assigned to all available CDROM drives in the MSX. They will not" + #CRLF$ +
    "correspond to drive names as used in MSX-DOS." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `cda <iso image>` -- Use ISO image for CDROM drive " + Chr(34) + "cda" + Chr(34) + #CRLF$ +
    "- `cda insert <iso image>` -- Use ISO image for CDROM drive " + Chr(34) + "cda" + Chr(34) + #CRLF$ +
    "- `cda eject` -- Eject CDROM from CDROM drive " + Chr(34) + "cda" + Chr(34) + #CRLF$ +
    "- `cda` -- Show current ISO image for CDROM drive " + Chr(34) + "cda" + Chr(34))

  OMSXHelp_Add("cycle / cycle_back",
    "Referencia de Comandos - Commands",
    "Iterates through the values of an enumerated setting." + #CRLF$ +
    "" + #CRLF$ +
    "`cycle_back` does the same as `cycle`, but it goes in the opposite direction." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `cycle <setting>` -- Changes the specified setting to the next value in the cycle" + #CRLF$ +
    "- `cycle_back <setting>` -- Changes the specified setting to the previous value in the cycle" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`cycle scale_algorithm`" + #CRLF$ +
    "`cycle videosource`")

  OMSXHelp_Add("debug",
    "Referencia de Comandos - Commands",
    "This command provides access to the debugger functionality of openMSX. It's meant to be used by an external debugger (see also Controlling openMSX from External Applications). The general format of the debug command is:" + #CRLF$ +
    "" + #CRLF$ +
    "`debug <subcommand> [<extra arguments>]`" + #CRLF$ +
    "" + #CRLF$ +
    "where 'extra arguments' are specific for each subcommand. Below is a list of the most common subcommands (deprecated commands are not listed):" + #CRLF$ +
    "" + #CRLF$ +
    "- `debug list` -- Return a list of all debuggables." + #CRLF$ +
    "" + #CRLF$ +
    "A debuggable is (part of) the state of an MSX device that can be accessed" + #CRLF$ +
    "via these debug commands." + #CRLF$ +
    "" + #CRLF$ +
    "Examples are:" + #CRLF$ +
    "" + #CRLF$ +
    "the VDP registers" + #CRLF$ +
    "the currently visible memory for the Z80" + #CRLF$ +
    "the contents of the RAM" + #CRLF$ +
    "- `debug desc <name>` -- Return a description of this debuggable" + #CRLF$ +
    "- `debug size <name>` -- Return the size of this debuggable" + #CRLF$ +
    "- `debug read <name> <addr>` -- Read a byte from a debuggable" + #CRLF$ +
    "- `debug write <name> <addr> <val>` -- Write a byte to a debuggable" + #CRLF$ +
    "- `debug read_block <name> <addr> <size>` -- Read a whole block at once" + #CRLF$ +
    "- `debug write_block <name> <addr> <values>` -- Write a whole block at once" + #CRLF$ +
    "- `debug break` -- Break CPU at current position" + #CRLF$ +
    "- `debug breaked` -- Query CPU break status" + #CRLF$ +
    "- `debug cont` -- Continue execution after break" + #CRLF$ +
    "- `debug step` -- Execute one instruction" + #CRLF$ +
    "- `debug breakpoint <subcommand>` -- Breakpoint related commands. Type `help debug breakpoint` for more details." + #CRLF$ +
    "- `debug watchpoint <subcommand>` -- Watchpoint related commands. Type `help debug watchpoint` for more details." + #CRLF$ +
    "- `debug watchexpr <subcommand>` -- Watch expression related commands. Type `help debug watchexpr` for more details." + #CRLF$ +
    "- `debug condition <subcommand>` -- Condition related commands. Type `help debug condition` for more details." + #CRLF$ +
    "- `debug probe <subcommand>` -- Probe related commands. Type `help debug probe` for more details." + #CRLF$ +
    "- `debug disasm [<addr>]` -- Disassemble instructions at PC or given address" + #CRLF$ +
    "" + #CRLF$ +
    "This command is much better documented in openMSX itself. Type `help debug` or `help debug <subcommand>` for more detailed help." + #CRLF$ +
    "" + #CRLF$ +
    "Many examples of usage of the debug command can be found in the scripts that come with openMSX (in the `share/scripts` directory). We also list a few here." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "break (only!) after 0 is written to 0x8000):" + #CRLF$ +
    "" + #CRLF$ +
    "`debug watchpoint create write_mem 0x8000 {[debug read " + Chr(34) + "memory" + Chr(34) + " 0x8000] ==" + #CRLF$ +
    "0x00}`" + #CRLF$ +
    "break on address 0xF37D, but only when Z80 register C has the value 0x2F:" + #CRLF$ +
    "" + #CRLF$ +
    "`debug breakpoint create 0xF37D {[reg C] == 0x2F}`" + #CRLF$ +
    "break when CPU reads from any addresses between 0xFBE5 and 0xFBEF:" + #CRLF$ +
    "" + #CRLF$ +
    "`debug watchpoint create read_mem {0xFBE5 0xFBEF}`" + #CRLF$ +
    "break after a write was done to I/O port 0x99, but only when Z80 register A has a value of 0x81:" + #CRLF$ +
    "" + #CRLF$ +
    "`debug watchpoint create write_io 0x99 {[reg A] == 0x81}`" + #CRLF$ +
    "break as soon as there is a pending Z80 IRQ (even when in DI mode):" + #CRLF$ +
    "" + #CRLF$ +
    "`debug probe set_bp z80.pendingIRQ`" + #CRLF$ +
    "break when register HL has the value 1234:" + #CRLF$ +
    "" + #CRLF$ +
    "`debug condition create {[reg hl] == 1234}`" + #CRLF$ +
    "" + #CRLF$ +
    "Note: Some of the commands are pretty low level. In the share/scripts directory you'll find some Tcl scripts that" + #CRLF$ +
    "offer convenience wrappers around these commands. For example: `showmem`, `disasm`, `cpuregs`, `save_debuggable`, etc.")

  OMSXHelp_Add("disk<x> / virtual_drive",
    "Referencia de Comandos - Commands",
    "Insert a disk image in a drive. Optionally apply an IPS patch to the disk image." + #CRLF$ +
    "The commands `diska`, `diskb` etc. are" + #CRLF$ +
    "assigned to all available " + Chr(34) + "physical" + Chr(34) + " disk drives in the MSX. They might not correspond to drive names as used in" + #CRLF$ +
    "MSX-DOS." + #CRLF$ +
    "" + #CRLF$ +
    "In addition to the physical `disk<x>` drives, there is the `virtual_drive`. This fake drive does not correspond to any MSX hardware. It can be used as a source or target for `diskmanipulator` operations just like physical drives." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `diska <disk image>` -- Insert disk image in drive " + Chr(34) + "diska" + Chr(34) + #CRLF$ +
    "- `diskb insert <disk image>` -- Insert disk image in drive " + Chr(34) + "diskb" + Chr(34) + #CRLF$ +
    "- `diska <disk image> <ips>` -- Insert disk image and apply IPS patch" + #CRLF$ +
    "- `diska eject` -- Remove disk from drive " + Chr(34) + "diska" + Chr(34) + #CRLF$ +
    "- `diska ramdsk` -- Insert scratch disk in drive " + Chr(34) + "diska" + Chr(34))

  OMSXHelp_Add("diskmanipulator",
    "Referencia de Comandos - Commands",
    "A collection of commands to manipulate (the files on) a disk image." + #CRLF$ +
    "" + #CRLF$ +
    "It can be used in so many different ways, that we wrote a separate manual for it: Using Diskmanipulator.")

  OMSXHelp_Add("escape_grab",
    "Referencia de Comandos - Commands",
    "Only has effect in windowed mode and when the `grabinput` setting is active. Temporarily release the input grab." + #CRLF$ +
    "After the openMSX window has lost and regained the focus, the grab is again effective." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `escape_grab` -- Temporarily release the input grab")

  OMSXHelp_Add("exit",
    "Referencia de Comandos - Commands",
    "Terminate the openMSX application. Optionally you can pass an exit-code." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `exit [exit-code]` -- Exits the emulator")

  OMSXHelp_Add("ext / ext<x>",
    "Referencia de Comandos - Commands",
    "Insert an MSX extension in a running MSX machine. The `ext` command inserts the extension in the first available slot. The `exta`, `extb` etc. commands insert it in the specified slot. The extension can be removed again with the `remove_extension`" + #CRLF$ +
    "command. See also the commands `cart`, `list_extensions` and `remove_extension`." + #CRLF$ +
    "" + #CRLF$ +
    "To get a list of possible extensions it's convenient to use the tab-completion feature, i.e. type '`ext<space><tab>`'. Alternatively the command '`openmsx_info extensions`' gives you the same information (and is easier to use in a scripting context)." + #CRLF$ +
    "" + #CRLF$ +
    "Note that some extensions (i.e. those without any memory) will not physically occupy any slot when inserted, even when they were inserted in a specific slot." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `ext fmpac` -- Insert an FMPAC in a running MSX machine in the first free slot" + #CRLF$ +
    "- `extb scc` -- Insert the empty SCC cart in slot B of the running MSX machine")

  OMSXHelp_Add("filepool",
    "Referencia de Comandos - Commands",
    "With this command you can manage your file pool settings. File pools are directories on your host system (PC/Mac/Dingoo/etc.). They are used by openMSX to search files in, which are referred to from machine or extension definition files, save states or replays which you are trying to load. First, the file will be searched at the path that was also used when the save state or replay was created. But if it isn't found there (which is usually the case if you load such a state or replay you got from someone else), it will use the file pools to search instead. In other words, if you are trying to load such replays, it's probably a good idea to put the media files referred to (ROMs, disks, tapes) in the (proper) file pool." + #CRLF$ +
    "" + #CRLF$ +
    "File pools have the following properties:" + #CRLF$ +
    "" + #CRLF$ +
    "**path:** The path to the directory which is the actual file pool" + #CRLF$ +
    "**position:** There exists a list of file pools, which are searched in order of their position." + #CRLF$ +
    "**type(s):** A file pool can serve specific types. Currently, the valid types are" + #CRLF$ +
    "" + #CRLF$ +
    "`system_rom`" + #CRLF$ +
    "for system ROMs, you are probably using this one already if you installed your system ROMs in the recommended place `share/systemroms`," + #CRLF$ +
    "`rom`" + #CRLF$ +
    "for other ROM files," + #CRLF$ +
    "`disk`" + #CRLF$ +
    "for disk images and" + #CRLF$ +
    "`tape`" + #CRLF$ +
    "for cassette/tape images." + #CRLF$ +
    "" + #CRLF$ +
    "Apart from the default system ROM file pool as mentioned above, the other default file pool is `share/software`, which is configured for all other (than type `system_rom`) software files." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `filepool list` -- Shows the currently defined file pool entries (see below for example output)" + #CRLF$ +
    "- `filepool add -path <path> -types <typelist> [-position <pos>]` -- Add a new entry with the given properties as explained above. For the types, use a format like `" + Chr(34) + "rom tape disk" + Chr(34) + "`. Optionally, you can also specify where in the list of existing file pools the new file pool should be added. By default, this is at the end." + #CRLF$ +
    "- `filepool remove <position>` -- Remove the file pool at the given position" + #CRLF$ +
    "- `filepool reset` -- Reset the file pool settings to the default values" + #CRLF$ +
    "" + #CRLF$ +
    "An example of the default file pools for a Windows 7 system with user Quibus:" + #CRLF$ +
    "" + #CRLF$ +
    "1: C:/Users/Quibus/Documents/openMSX/share/systemroms [system_rom]" + #CRLF$ +
    "2: C:/Users/Quibus/Documents/openMSX/share/software [rom disk tape]" + #CRLF$ +
    "3: C:/Program Files/openMSX/share/systemroms [system_rom]" + #CRLF$ +
    "4: C:/Program Files/openMSX/share/software [rom disk tape]" + #CRLF$ +
    "" + #CRLF$ +
    "The first one is the system ROMs dir in the user's home directory. The second is the software file pool for other software in the user's home directory. The last two are similar, but then on system level. On a UNIX like system, you get something very similar.")

  OMSXHelp_Add("findcheat",
    "Referencia de Comandos - Commands",
    "This is a tool to find new cheats, for example for a certain game it can help you find the memory location where the number of remaining lives is stored. These cheats can later be added to the `trainer` command." + #CRLF$ +
    "" + #CRLF$ +
    "It works more or less like this:" + #CRLF$ +
    "" + #CRLF$ +
    "1. Initialize the `findcheat` tool, this takes an initial snapshot of the MSX memory." + #CRLF$ +
    "2. Perform some action in the game that changes the variable that you're interested in. For example if you want to find the memory location where the number of lives is stored, you have to loose (or gain) a life in the game." + #CRLF$ +
    "3. Now use the `findcheat` tool to compare the current MSX memory state with the previous memory snapshot. `findcheat` offers a lot of possibilities here, for example you can search for memory locations that became bigger or smaller or locations whose value changed or didn't change." + #CRLF$ +
    "4. `findcheat` will show a list of memory locations that still match the search criteria." + #CRLF$ +
    "5. If there still are still too many matches, repeat from step 2." + #CRLF$ +
    "" + #CRLF$ +
    "Vampier made a video tutorial on how to use `findcheat`, you can find it here (http://www.youtube.com/watch?v=F11ltfkCtKo).")

  OMSXHelp_Add("hd<x>",
    "Referencia de Comandos - Commands",
    "Change the hard disk image. The commands `hda`, `hdb` etc. are assigned to all available hard disk drives in the MSX. They will not correspond to drive names as used in MSX-DOS." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `hda <disk image>` -- Use hard disk image for hard disk " + Chr(34) + "hda" + Chr(34) + #CRLF$ +
    "- `hda insert <disk image>` -- Use hard disk image for hard disk " + Chr(34) + "hda" + Chr(34) + #CRLF$ +
    "- `hda` -- Show current hard disk image for hard disk " + Chr(34) + "hda" + Chr(34) + #CRLF$ +
    "" + #CRLF$ +
    "Note: Because of disk caching, changing the hard disk when the MSX is running can lead to corruption of the hard disk contents. Therefore openMSX blocks the `hd<x>` commands unless the MSX is powered off. See `power` setting.")

  OMSXHelp_Add("help",
    "Referencia de Comandos - Commands",
    "Shows help info for console commands." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `help` -- Shows a list of all possible commands" + #CRLF$ +
    "- `help <command>` -- Shows help info for a specific command" + #CRLF$ +
    "- `help <command> <subcommand>` -- Some commands have more detailed help on subcommands")

  OMSXHelp_Add("incr",
    "Referencia de Comandos - Commands",
    "Increment an integer setting." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `incr <setting>` -- Increment the specified setting by one" + #CRLF$ +
    "- `incr <setting> <num>` -- Increment the specified setting by the given amount (can be negative)" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`incr speed`" + #CRLF$ +
    "`incr renshaturbo 10`" + #CRLF$ +
    "`incr scanline -5`")

  OMSXHelp_Add("iomap",
    "Referencia de Comandos - Commands",
    "Shows what I/O ports are connected to which devices. The related command `slotmap` shows a similar overview, but for memory-mapped devices." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `iomap` -- Shows the I/O map of the current MSX machine")

  OMSXHelp_Add("keymatrixdown / keymatrixup",
    "Referencia de Comandos - Commands",
    "Press or release keys in the MSX keyboard matrix. Can be used to make an external program or Tcl script press MSX keys. For some more information about the keymatrix, you could read the article on the MAP (http://map.grauw.nl/articles/keymatrix.php)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `keymatrixdown <row> <mask>` -- Press the indicated MSX keys" + #CRLF$ +
    "- `keymatrixup <row> <mask>` -- Release the indicated MSX keys" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`keymatrixdown 6 0x01`" + #CRLF$ +
    "`keymatrixup 6 0x01`")

  OMSXHelp_Add("laserdiscplayer",
    "Referencia de Comandos - Commands",
    "Controls the Laserdisc player; a Laserdisc can be inserted or ejected. When a real Laserdisc player is connected to an MSX, no other controls are available either." + #CRLF$ +
    "" + #CRLF$ +
    "Note that this command is only available when the Pioneer PX-7 or Pioneer PX-V60 MSX machine is being emulated" + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `laserdiscplayer insert <filename>` -- Inserts the specified file into the virtual laserdisc player." + #CRLF$ +
    "- `laserdiscplayer eject` -- Ejects the laserdisc from the virtual laserdisc player; this emulates pressing the eject button on a real Laserdisc Player.")

  OMSXHelp_Add("list_extensions",
    "Referencia de Comandos - Commands",
    "Returns a list of inserted cartridges and extensions. These can be removed with the `remove_extension` command or" + #CRLF$ +
    "additional items can be added with the `cart` and `ext` commands." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `list_extensions` -- Lists all currently inserted cartridges and extensions")

  OMSXHelp_Add("load_settings",
    "Referencia de Comandos - Commands",
    "Load settings from a given settings XML file. The settings file does not have to be complete: settings that are not mentioned in the given file are left untouched. See also `save_settings`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `load_settings <filename>` -- Load settings from the given file")

  OMSXHelp_Add("machine",
    "Referencia de Comandos - Commands",
    "Switch to a new MSX machine." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `machine` -- Returns the handle for the currently active machine" + #CRLF$ +
    "- `machine <machine name>` -- Switch to the specified machine, also returns the handle for that machine" + #CRLF$ +
    "" + #CRLF$ +
    "Note: The machine handle is mostly used by external applications controlling openMSX (see also Controlling openMSX from External Applications). For interactive use you can omit the machine handle to have the commands operate on the current machine.")

  OMSXHelp_Add("create_machine / load_machine / activate_machine / list_machines / delete_machine",
    "Referencia de Comandos - Commands",
    "openMSX has the possibility to have multiple MSX machines concurrently in memory. This is more or less like multiple tabs in a web browser: you only work with one at-a-time, but you can have multiple open at the same time and easily switch between them. These commands are low level commands to manage this." + #CRLF$ +
    "" + #CRLF$ +
    "Some commands are specific per machine, for example if you insert a disk image into the disk drive of the emulated MSX machine and if you have multiple MSX machines, you need to specify in which MSX machine you want to insert the disk. To solve this, we introduced the concept of the 'active' MSX machine (this is also the machine that is visible and audible). All unqualified machine-specific command will act on the active machine. If you want to execute the command in a specific machine, you can qualify the command with a machineID prefix." + #CRLF$ +
    "" + #CRLF$ +
    "- `diska <diskimage>` -- execute the diska command in the active machine" + #CRLF$ +
    "- `<machine-ID>::diska <diskimage>` -- execute the diska command in the specified machine" + #CRLF$ +
    "" + #CRLF$ +
    "## create_machine:" + #CRLF$ +
    "" + #CRLF$ +
    "This command returns a new machine-id. This machine-id can be used in the following commands. In the web browser analogy this command would open a new empty tab." + #CRLF$ +
    "" + #CRLF$ +
    "## load_machine:" + #CRLF$ +
    "" + #CRLF$ +
    "This command loads a machine configuration (= MSX model) into the given machine-ID." + #CRLF$ +
    "In the web browser analogy, this command would load a page in a previously created empty tab. And unlike a web browser, where you can reload a different page in the same tab, you can only load a machine configuration once in the same machine-ID." + #CRLF$ +
    "" + #CRLF$ +
    "## activate_machine:" + #CRLF$ +
    "" + #CRLF$ +
    "This command activates the given machine-ID. At any time there can only be one active machine-ID. This is analogue to switching tabs in a web browser." + #CRLF$ +
    "" + #CRLF$ +
    "## list_machines:" + #CRLF$ +
    "" + #CRLF$ +
    "Returns a list of all currently existing machine-IDs." + #CRLF$ +
    "" + #CRLF$ +
    "## delete_machine:" + #CRLF$ +
    "" + #CRLF$ +
    "Deletes the given machine-ID. This is analogue to closing a tab in a web browser." + #CRLF$ +
    "" + #CRLF$ +
    "## examples:" + #CRLF$ +
    "" + #CRLF$ +
    "- `set oldID [machineID]` -- get the current machineID" + #CRLF$ +
    "- `set newID [create_machine]` -- create a new machineID" + #CRLF$ +
    "- `$newID::load_machine Philips_NMS_8250` -- load an MSX2 configuration in that new machineID" + #CRLF$ +
    "- `activate_machine $newID` -- switch to the new machine" + #CRLF$ +
    "- `activate_machine $oldID` -- switch back to old machine" + #CRLF$ +
    "- `delete_machine $newID` -- delete new machine" + #CRLF$ +
    "" + #CRLF$ +
    "**Nota:** If you don't care about multiple active machines, the `machine` command is much more convenient to switch to a different MSX configuration.")

  OMSXHelp_Add("machine_info",
    "Referencia de Comandos - Commands",
    "Shows information about a certain topic. This command is similar to the `openmsx_info` command. The topics of" + #CRLF$ +
    "`machine_info` are all machine specific, while the topics of `openmsx_info` are generic." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `machine_info` -- Shows a list of all possible topics" + #CRLF$ +
    "- `machine_info <topic>` -- Shows info on the given topic")

  OMSXHelp_Add("message",
    "Referencia de Comandos - Commands",
    "Show a message, with optional level (info, warning, error). By default this message will be shown in a coloured box at the top of the screen for a (short) duration and then fade away." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `message <text> [<level>]`" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`message " + Chr(34) + "Hello world!" + Chr(34) + "`" + #CRLF$ +
    "`message " + Chr(34) + "Something bad happened" + Chr(34) + " error`")

  OMSXHelp_Add("monitor_type",
    "Referencia de Comandos - Commands",
    "Select a monitor color profile." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `monitor_type` -- Shows the currently selected color profile" + #CRLF$ +
    "- `monitor_type -list` -- Lists all available color profiles" + #CRLF$ +
    "- `monitor_type <profile>` -- Selects a new color profile" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This command is a convenience wrapper around the `color_matrix` setting.")

  OMSXHelp_Add("mute_channels / unmute_channels / solo",
    "Referencia de Comandos - Commands",
    "Mute or unmute specific individual channels of sound devices. The syntax is very similar to the `record_channels` command." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `mute_channels <device> [<channels>]] [<device> [<channels>]]` -- Mute the specified channels of the specified device(s). If a device is given but no specific channels are specified, all channels of that device are muted. If no arguments are given at all, this command return a list of all currently muted channels." + #CRLF$ +
    "- `unmute_channels <device> [<channels>]] [<device> [<channels>]]` -- Unmute the specified channels of the specified device(s). If a device is given but no specific channels are specified, all channels of that device are unmuted. If no arguments are given at all, this command unmutes all channels of all devices." + #CRLF$ +
    "- `solo <device> [<channels>]] [<device> [<channels>]]` -- Mute all channels of all devices except for the specified channels." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`mute_channels`" + #CRLF$ +
    "`mute_channels PSG`" + #CRLF$ +
    "`mute_channels SCC 2,4`" + #CRLF$ +
    "`unmute_channels`" + #CRLF$ +
    "`unmute_channels PSG 1 SCC 1,3-4`" + #CRLF$ +
    "`solo PSG 3`")

  OMSXHelp_Add("nowind<x>",
    "Referencia de Comandos - Commands",
    "Similar to the `disk<x>`" + #CRLF$ +
    "commands there is a `nowind<x>` command for each nowind" + #CRLF$ +
    "interface. This command is modelled after the 'usbhost' command of the real" + #CRLF$ +
    "nowind interface. Though only a subset of the options is supported. Here's a" + #CRLF$ +
    "short overview of the command-line options:" + #CRLF$ +
    "" + #CRLF$ +
    "**long | short | explanation**" + #CRLF$ +
    "- --image -- -i -- specify disk image" + #CRLF$ +
    "- --hdimage -- -m -- specify harddisk image" + #CRLF$ +
    "- --romdisk -- -j -- enable romdisk" + #CRLF$ +
    "- --ctrl -- -c -- no phantom disks" + #CRLF$ +
    "- --no-ctrl -- -C -- enable phantom disks" + #CRLF$ +
    "- --allow -- -a -- allow other diskroms to initialize" + #CRLF$ +
    "- --no-allow -- -A -- don't allow other diskroms to initialize" + #CRLF$ +
    "" + #CRLF$ +
    "If you don't pass any arguments to this command, you'll get an overview of" + #CRLF$ +
    "the current nowind status." + #CRLF$ +
    "" + #CRLF$ +
    "This command will create a certain amount of drives on the nowind" + #CRLF$ +
    "interface and (optionally) insert diskimages in those drives. For each of" + #CRLF$ +
    "these drives there will also be a" + #CRLF$ +
    "`nowind<x><1..8>`" + #CRLF$ +
    "command created. Those commands are similar to e.g. the" + #CRLF$ +
    "`diska`" + #CRLF$ +
    "command. They can be used to access the more advanced diskimage insertion" + #CRLF$ +
    "options." + #CRLF$ +
    "" + #CRLF$ +
    "In some cases it is needed to reboot the MSX before the changes take" + #CRLF$ +
    "effect. In those cases you'll get a message that warns about this." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `nowinda -a image.dsk -j` -- Image.dsk is inserted into drive A: and the romdisk will be drive B:." + #CRLF$ +
    "Other diskroms will be able to install drives as well. For example when" + #CRLF$ +
    "the MSX has an internal diskdrive, drive C: en D: will be available as" + #CRLF$ +
    "well." + #CRLF$ +
    "- `nowinda disk1.dsk disk2.dsk` -- The two images will be inserted in A: and B: respectively." + #CRLF$ +
    "- `nowinda -m hdimage.dsk` -- Inserts a harddisk image. All available partitions will be mounted" + #CRLF$ +
    "as drives." + #CRLF$ +
    "- `nowinda -m hdimage.dsk:1` -- Inserts the first partition only." + #CRLF$ +
    "- `nowinda -m hdimage.dsk:2-4` -- Inserts the 2nd, 3th and 4th partition as drive A: B: and C:.")

  OMSXHelp_Add("openmsx_info",
    "Referencia de Comandos - Commands",
    "Shows information about a certain topic. For machine-specific topics, use the related command `machine_info`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `openmsx_info` -- Shows a list of all possible topics" + #CRLF$ +
    "- `openmsx_info <topic>` -- Shows info on the given topic")

  OMSXHelp_Add("openmsx_update",
    "Referencia de Comandos - Commands",
    "Enable or disable update notifications of a certain type. This command is intended for external programs controlling openMSX. More about this in Controlling openMSX from External Applications." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `openmsx_update enable <type>` -- enable notifications for this type" + #CRLF$ +
    "- `openmsx_update disable <type>` -- disable notifications for this type" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`openmsx_update enable led`" + #CRLF$ +
    "`openmsx_update disable setting`")

  OMSXHelp_Add("osd",
    "Referencia de Comandos - Commands",
    "openMSX has the possibility to show OSD (on screen display) elements. For example, the game overlays and TAS tools are implemented via OSD elements. This command allows to create new OSD elements, configure existing elements or delete elements." + #CRLF$ +
    "" + #CRLF$ +
    "This command is only useful if you plan to adjust or enhance the openMSX OSD, or create your own OSD widgets." + #CRLF$ +
    "" + #CRLF$ +
    "Execute " + Chr(34) + "`help osd`" + Chr(34) + " to get a detailed description of this command, which we will not repeat here.")

  OMSXHelp_Add("palette",
    "Referencia de Comandos - Commands",
    "Shows the current VDP palette settings. Related command: `vdpregs`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `palette` -- Show the currently active color palette")

  OMSXHelp_Add("plug / unplug",
    "Referencia de Comandos - Commands",
    "Plugs or unplugs a plug into a connector, for example plug a virtual joystick into a virtual joystick port." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `plug` -- Shows all currently connected plugs" + #CRLF$ +
    "- `plug <connector>` -- Shows currently connected plug for the specified connector" + #CRLF$ +
    "- `plug <connector> <plug>` -- Plugs the specified plug into the specified connector" + #CRLF$ +
    "- `unplug <connector>` -- Unplugs the plug connected to the specified connector" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`plug cassetteport cassetteplayer`" + #CRLF$ +
    "`plug joyporta mouse`" + #CRLF$ +
    "`plug printerport logger`" + #CRLF$ +
    "`unplug joyportb`")

  OMSXHelp_Add("psg_profile",
    "Referencia de Comandos - Commands",
    "Select a PSG sound profile." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `psg_profile` -- Shows the currently selected sound profile" + #CRLF$ +
    "- `psg_profile -list` -- Lists all available sound profiles" + #CRLF$ +
    "- `psg_profile <profile>` -- Selects a new sound profile" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This command is a convenience wrapper around the `PSG_vibrato_frequency`, `PSG_vibrato_percent`, `PSG_detune_frequency` and `PSG_detune_percent` settings.")

  OMSXHelp_Add("record",
    "Referencia de Comandos - Commands",
    "Controls video recording: write openMSX audio/video to an AVI file." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `record start` -- Record to file " + Chr(34) + "openmsxNNNN.avi" + Chr(34) + #CRLF$ +
    "- `record start <filename>` -- Record to indicated file" + #CRLF$ +
    "- `record start -prefix foo` -- Record to file " + Chr(34) + "fooNNNN.avi" + Chr(34) + #CRLF$ +
    "- `record stop` -- Stop recording" + #CRLF$ +
    "- `record toggle` -- Toggle recording" + #CRLF$ +
    "" + #CRLF$ +
    "The `start` subcommand also accepts an optional `-audioonly`, `-videoonly`, `-doublesize` and a `-triplesize` flag. Videos are recorded in a 320×240 size by default, at 640×480 when the `-doublesize` flag is used and 960×720 when using the `-triplesize` flag." + #CRLF$ +
    "If only audio is recorded, the created file will be a WAV file instead of an AVI file." + #CRLF$ +
    "" + #CRLF$ +
    "If any stereo sound devices are present or any sound device has an off-center balance, the recording will be made in stereo, otherwise it will be mono." + #CRLF$ +
    "If a recording is made in mono and then a stereo sound device is added, you'll receive a warning that stereo sound has been detected and that the two channels will be mixed down to mono." + #CRLF$ +
    "You can prevent this from happening by using the `-stereo` option to force a stereo recording even if no stereo devices are present at the time you enter the command." + #CRLF$ +
    "You can also force a mono recording with `-mono` to save space." + #CRLF$ +
    "" + #CRLF$ +
    "The `soundlog` command is a shorthand for `record -audioonly`." + #CRLF$ +
    "" + #CRLF$ +
    "Use `record_chunks` if you want some extra options. You can control the maximum length (in seconds) to record and also set up multiple recordings of a certain length. This is very useful if you want to record for e.g. YouTube. The default length is 14:59 (to make sure YouTube will accept it). Using this command implies `-doublesize`." + #CRLF$ +
    "" + #CRLF$ +
    "Use `record_chunks_on_framerate_changes` if you want to split up the recording in several files, whenever the frame rate of the MSX changes. An AVI file cannot contain video of multiple frame rates, so sound and video will get out of sync if that happens without using this special version of the command. Do not specify the target filename with this variant, or openMSX will record all chunks to the same file.")

  OMSXHelp_Add("record_channels",
    "Referencia de Comandos - Commands",
    "A high level command to record individual channels of sound chips to separate files. In the following variants of the command you can specify devices and channels. Multiple devices can be specified and multiple channels as well. If you want to specify channels of a device, put them right after the device. You can also specify `all` for the device, which means that all sound devices in the currently running MSX will be recorded. When starting recording, an option `-prefix` can be given to specify a filename prefix." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `record_channels [start] <device> [<channels>] [<device> [<channels>]] [-prefix <prefix>]` -- Start recording the specified channel(s) of the specified device(s). If no channels are given, all channels of the device are recorded." + #CRLF$ +
    "- `record_channels stop [<device> [<channels>]] [<device> [<channels>]]` -- Stop recording the specified channel(s) of the specified device(s). If no channels are given, recording for all channels is stopped for the given device(s). If no devices are given, all channel recording is stopped." + #CRLF$ +
    "- `record_channels all -prefix justtesting` -- Record all channels of all sound devices and create the file names with prefix 'justtesting' (e.g. to quickly delete all these files again)." + #CRLF$ +
    "- `record_channels list` -- Lists which channels of which sound chips are currently being recorded." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`record_channels start PSG`" + #CRLF$ +
    "`record_channels PSG`" + #CRLF$ +
    "`record_channels SCC 1,4-5`" + #CRLF$ +
    "`record_channels SCC PSG 1`" + #CRLF$ +
    "`record_channels " + Chr(34) + "MSX Music" + Chr(34) + " 7-9 SCC 3,5 PSG 2`" + #CRLF$ +
    "`record_channels stop`" + #CRLF$ +
    "`record_channels stop PSG`" + #CRLF$ +
    "`record_channels stop SCC 3,5`" + #CRLF$ +
    "`record_channels list`")

  OMSXHelp_Add("remove_extension",
    "Referencia de Comandos - Commands",
    "Remove a cartridge or extension from a running MSX machine. See also the commands `cart`, `ext`, `list_extensions`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `remove_extension fmpac` -- Removes the FMPAC extension from the running MSX")

  OMSXHelp_Add("reset",
    "Referencia de Comandos - Commands",
    "Emulates the pressing of the reset button on the MSX. This sends a reset pulse to all devices, but does not erase memory contents." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `reset` -- Resets the current machine")

  OMSXHelp_Add("reverse",
    "Referencia de Comandos - Commands",
    "Controls the reverse feature. When this feature is enabled (the default), openMSX will collect data while emulating, which enables you to go back (and forward) in MSX time. In other words: you cannot use the commands to go back and forward in time, if you disable the feature." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `reverse start` -- Start collecting data (enable the reverse feature)." + #CRLF$ +
    "- `reverse stop` -- Stop collecting data (disable reverse feature) and remove all collected data." + #CRLF$ +
    "- `reverse status` -- Gives information about the reverse feature and the data it collected. Mostly useful for scripts." + #CRLF$ +
    "- `reverse goback <n>` -- Go back <n> seconds in time. Of course, you cannot go back to a time before the time the `reverse start` command was given." + #CRLF$ +
    "- `reverse viewonlymode <on|off>` -- Control the view only mode of the reverse feature. In view only mode, the replay will never get interrupted by any user actions that normally would interrupt the replay. Use this to safely view a replay without accidentally ruining it by touching a key." + #CRLF$ +
    "- `reverse goto <time>` -- Go to the indicated absolute moment in MSX time (given in seconds). If the time is before the time openMSX started collecting data (with the `reverse start` command) openMSX will jump to the time when collecting started." + #CRLF$ +
    "- `reverse truncatereplay` -- Stop replaying and wipe all replay data that is in the future (so after **now**). This is useful if you are hindered by the future events somehow, for instance when you are playing a game and jumped too early and therefore reversed. Be careful with this, as there is no way to recover this future. If you are at time 0, it means your whole replay will be gone after executing this command!" + #CRLF$ +
    "- `reverse savereplay [<filename>]` -- Save the collected data (an initial savestate and all collected input events) to a file." + #CRLF$ +
    "- `reverse loadreplay [-goto <begin|end|savetime|<n>>] [-viewonly] <filename>` -- Load the replay from the given file and start it. It loads the initial snapshot, starts replaying the recorded events, and enables the reverse feature automatically. With the `-goto` option, you can specify where to jump to in the replay after loading (`begin` is default), where `savetime` is the time at which the replay was saved and `n` is an absolute time in seconds in the replay. The `-viewonly` option is a shortcut to put the reverse feature in viewonly mode directly after loading the replay. Without this option, it will always go to normal mode." + #CRLF$ +
    "" + #CRLF$ +
    "There are some extra helper commands to make the feature easier to use." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `go_back_one_step` / `go_forward_one_step` -- Go back or forward one second (at normal speed) in time (if possible). These are used for the default PageUp and PageDown key bindings." + #CRLF$ +
    "- `reverse_prev [<min> [<max>]]` -- Go back in time to the previous (internal) snapshot. The further back in the past the less dense the amount of snapshots are. So, executing this command multiple times, will take successively bigger steps in the past. You can optionally specify a minimal and maximal step size. You will at least go back the minimal amount of time (even if there's a snapshot closer to the current time) and at most the maximal amount of time (even if there's no snapshot within the maximum specified time from the current time)." + #CRLF$ +
    "- `reverse_next [<min> [<max>]]` -- As `reverse_prev` but then it goes to the closest snapshot in the future (if possible)." + #CRLF$ +
    "" + #CRLF$ +
    "Because the reverse feature is very useful, it is automatically enabled via `auto_enable_reverse` setting.")

  OMSXHelp_Add("save_settings",
    "Referencia de Comandos - Commands",
    "Write the current openMSX settings to a settings XML file. See also `load_settings`." + #CRLF$ +
    "" + #CRLF$ +
    "If you disabled `save_settings_on_exit`, you can use this command to save your preferences." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `save_settings` -- Save settings to the default settings file" + #CRLF$ +
    "- `save_settings <filename>` -- Save settings to the given file")

  OMSXHelp_Add("savestate / loadstate / list_savestates / delete_savestate",
    "Referencia de Comandos - Commands",
    "These commands can be used to manage savestates. These are much easier to use than the lowlevel `store_machine` and `restore_machine` commands." + #CRLF$ +
    "" + #CRLF$ +
    "## savestate [<name>]" + #CRLF$ +
    "" + #CRLF$ +
    "This creates a snapshot of the currently emulated MSX machine. Optionally you can specify a name for the savestate, if you omit this name, the default name `quicksave` will be taken." + #CRLF$ +
    "" + #CRLF$ +
    "## loadstate [<name>]" + #CRLF$ +
    "" + #CRLF$ +
    "This restores a previously created savestate. Like above you can specify a name which defaults to `quicksave` if omitted." + #CRLF$ +
    "" + #CRLF$ +
    "## list_savestates" + #CRLF$ +
    "" + #CRLF$ +
    "This returns the names of all previously created savestates." + #CRLF$ +
    "" + #CRLF$ +
    "## delete_savestate <name>" + #CRLF$ +
    "" + #CRLF$ +
    "Delete a previously created savestate.")

  OMSXHelp_Add("screenshot",
    "Referencia de Comandos - Commands",
    "Take a screenshot of the openMSX screen. By default this takes a screenshot of the 'scaled' MSX screen (see `scale_algorithm` setting) without OSD/GUI elements (e.g. console and icons). If you want to include the GUI and OSD elements pass the `-with-osd` option. If you want a screenshot of the 'unscaled' raw MSX screen, pass the `-raw` option. The screenshots are PNG files and (by default) are saved in the `screenshots` subdirectory of the openMSX data directory in your home directory. There's also an option `-no-sprites` to take a screenshot with sprite rendering disabled." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `screenshot [-with-osd] [-raw [-size <width>]] [-no-sprites] [-prefix <prefix>] [<filename>]`" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `screenshot` -- Write screenshot to file " + Chr(34) + "openmsxNNNN.png" + Chr(34) + #CRLF$ +
    "- `screenshot <filename>` -- Write screenshot to indicated file" + #CRLF$ +
    "- `screenshot -prefix foo` -- Write screenshot to file " + Chr(34) + "fooNNNN.png" + Chr(34) + #CRLF$ +
    "- `screenshot -raw` -- Create screenshot of the raw MSX screen only (so no icons or console and no scaling)" + #CRLF$ +
    "- `screenshot -raw -size auto` -- Create screenshot of the raw MSX screen only, with resolution dependent on the displayed MSX screen mode" + #CRLF$ +
    "- `screenshot -raw -size 320` -- Create screenshot of the raw MSX screen only, with resolution 320×240" + #CRLF$ +
    "- `screenshot -raw -size 640` -- Create screenshot of the raw MSX screen only, with resolution 640×480" + #CRLF$ +
    "- `screenshot -with-osd` -- Create screenshot of the scaled screen, including OSD elements" + #CRLF$ +
    "- `screenshot -no-sprites` -- Create screenshot with sprite rendering disabled")

  OMSXHelp_Add("set",
    "Referencia de Comandos - Commands",
    "Change or query the value of various settings. See also: `unset`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set <setting>` -- Query the current value of the specified setting" + #CRLF$ +
    "- `set <setting> <value>` -- Change the specified setting to the given value" + #CRLF$ +
    "" + #CRLF$ +
    "The settings that can be adjusted with this command are listed and explained `later` in this document." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set accuracy pixel`" + #CRLF$ +
    "`set blur 25`" + #CRLF$ +
    "`set scanline 20`" + #CRLF$ +
    "`set deinterlace on`")

  OMSXHelp_Add("setup",
    "Referencia de Comandos - Commands",
    "Switch to a previously saved setup." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `setup <setup name>` -- Switch to the specified setup, which you have saved before with the GUI or the `store_setup` command. Also returns the handle of the new machine." + #CRLF$ +
    "" + #CRLF$ +
    "Note: The machine handle is mostly used by external applications controlling openMSX (see also Controlling openMSX from External Applications). For interactive use you can omit the machine handle to have the commands operate on the current machine.")

  OMSXHelp_Add("slotmap",
    "Referencia de Comandos - Commands",
    "Shows what devices are inserted into which slots. The related command `iomap` shows a similar overview, but for I/O mapped devices." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `slotmap` -- Shows the slot map of the current MSX machine")

  OMSXHelp_Add("slotselect",
    "Referencia de Comandos - Commands",
    "Shows the currently selected slots. To see what devices are located in the slots, use the `slotmap` command." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `slotselect` -- Shows the currently selected slot for each page")

  OMSXHelp_Add("soundlog",
    "Referencia de Comandos - Commands",
    "Controls sound logging: writing the openMSX sound to a WAV file." + #CRLF$ +
    "" + #CRLF$ +
    "This command is a shorthand for `record -audioonly`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `soundlog start` -- Log sound to file " + Chr(34) + "openmsxNNNN.wav" + Chr(34) + #CRLF$ +
    "- `soundlog start <filename>` -- Log sound to indicated file" + #CRLF$ +
    "- `soundlog start -prefix foo` -- Log sound to file " + Chr(34) + "fooNNNN.wav" + Chr(34) + #CRLF$ +
    "- `soundlog stop` -- Stop logging sound" + #CRLF$ +
    "- `soundlog toggle` -- Toggle sound logging state")

  OMSXHelp_Add("store_machine / restore_machine",
    "Referencia de Comandos - Commands",
    "These are low-level commands, used to implement savestates." + #CRLF$ +
    "" + #CRLF$ +
    "## store_machine:" + #CRLF$ +
    "" + #CRLF$ +
    "Saves the state of the specified machine to a file." + #CRLF$ +
    "" + #CRLF$ +
    "- `store_machine <machineID> <filename>` -- Save state of indicated machine to specified file" + #CRLF$ +
    "" + #CRLF$ +
    "## restore_machine:" + #CRLF$ +
    "" + #CRLF$ +
    "Load a previously saved machine in a new machine-ID, next to the already available machines. See the section on `activate_machine`." + #CRLF$ +
    "" + #CRLF$ +
    "- `restore_machine` -- Load state from last saved state in default directory" + #CRLF$ +
    "- `restore_machine <filename>` -- Load state from indicated file" + #CRLF$ +
    "" + #CRLF$ +
    "Note: These commands are pretty low level. The `savestate` and `loadstate` scripts are built on top of this and are much more convenient to use.")

  OMSXHelp_Add("store_setup",
    "Referencia de Comandos - Commands",
    "Store the current setup in a file." + #CRLF$ +
    "" + #CRLF$ +
    "- `store_setup [depth] <filename>` -- Save the setup with the given depth to specified file" + #CRLF$ +
    "" + #CRLF$ +
    "If the filename isn't specified, openMSX creates a unique one for you, based on the name of the machine. The depth argument is mandatory and must be one of the following." + #CRLF$ +
    "" + #CRLF$ +
    "**`machine`:** Save only the machine. This isn't too useful... but you can use it to give your favourite machine your own setup name" + #CRLF$ +
    "**`extensions`:** Save the machine with all plugged in extensions" + #CRLF$ +
    "**`connectors`:** As previous, but also include plugged in equipment in its connectors" + #CRLF$ +
    "**`media`:** As previous, but also include inserted media in its media slots" + #CRLF$ +
    "**`complete_state`:** As previous, but also include the run time state. This is basically identical to a savestate" + #CRLF$ +
    "" + #CRLF$ +
    "Storing the current setup can also be done with the GUI via Main menu bar" + #CRLF$ +
    "→ Machine → Save setup.")

  OMSXHelp_Add("test_machine / test_all_machines / test_all_extensions",
    "Referencia de Comandos - Commands",
    "Test whether the given MSX machine configuration works. For example whether you have all required system ROMs for this machine. See also `load_machine`. This is an alternative to using the equivalent option in the GUI Main menu bar" + #CRLF$ +
    "→ Machine → Test MSX hardware" + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `test_machine <machine-config>` -- Test whether the given machine configuration is OK." + #CRLF$ +
    "" + #CRLF$ +
    "Use the convenience commands `test_all_machines` and `test_all_extensions` to get a full overview on which system ROMs you are still missing.")

  OMSXHelp_Add("toggle",
    "Referencia de Comandos - Commands",
    "Toggles any boolean (on/off) setting: if it was on, it will be turned off and vice versa." + #CRLF$ +
    "See also: `cycle`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `toggle <setting>` -- Toggles the specified setting" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`toggle mute`" + #CRLF$ +
    "`toggle throttle`")

  OMSXHelp_Add("trainer",
    "Referencia de Comandos - Commands",
    "Control game trainers. You can enable or disable individual cheats of each trainer. Make use of the TAB key to see" + #CRLF$ +
    "what is available. When switching trainers, the currently active trainer will be deactivated." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `trainer` -- See which trainer is currently active" + #CRLF$ +
    "- `trainer <game>` -- See which cheats are currently active in the trainer" + #CRLF$ +
    "- `trainer <game> all` -- Activate all cheats in the trainer of <game>" + #CRLF$ +
    "- `trainer <game> [<cheat> ..]` -- Toggle cheats of <game> on/off" + #CRLF$ +
    "- `trainer deactivate` -- Deactivate all trainers" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`trainer Frogger all`" + #CRLF$ +
    "`trainer " + Chr(34) + "Circus Charlie" + Chr(34) + " 1 2`" + #CRLF$ +
    "`trainer Pippols lives " + Chr(34) + "jump shoes" + Chr(34) + "`")

  OMSXHelp_Add("type / type_via_keyboard",
    "Referencia de Comandos - Commands",
    "Type a string in the emulated MSX. This command automatically presses and" + #CRLF$ +
    "releases keys in the simulated MSX keyboard matrix. This command is useful" + #CRLF$ +
    "for demoing and for automating tasks in MSX-BASIC." + #CRLF$ +
    "" + #CRLF$ +
    "The command has a `-release` option, with which you can specify" + #CRLF$ +
    "that keys are always released before new ones are pressed. Some game input" + #CRLF$ +
    "routines need this, but it also makes typing twice as slow." + #CRLF$ +
    "" + #CRLF$ +
    "With the `-freq` option, you can tweak how fast typing goes and" + #CRLF$ +
    "how long the keys will be pressed (and released if the `-release`" + #CRLF$ +
    "option is used). Keys will be typed at the given frequency and will remain" + #CRLF$ +
    "pressed/released for 1/freq seconds." + #CRLF$ +
    "" + #CRLF$ +
    "With the `-cancel` option, you can cancel a (long) in progress" + #CRLF$ +
    "type command." + #CRLF$ +
    "" + #CRLF$ +
    "This command should always work, because it is just like as if a user was" + #CRLF$ +
    "actually typing on the MSX keyboard. It is therefore a bit slow, though." + #CRLF$ +
    "Check out the `type_via_keybuf` command if you're looking for" + #CRLF$ +
    "something faster (but more limited in where it works). With the" + #CRLF$ +
    "`default_type_proc` setting you can even make" + #CRLF$ +
    "`type_via_keybuf` the standard implementation for the" + #CRLF$ +
    "`type` command. Only do this if you really know what you're" + #CRLF$ +
    "doing!" + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `type " + Chr(34) + "Hello world!" + Chr(34) + "` -- Yet another manifestation of the most famous program" + #CRLF$ +
    "- `type " + Chr(34) + "PRINT \" + Chr(34) + "Hi!\" + Chr(34) + "\r" + Chr(34) + "` -- Executes this basic command directly" + #CRLF$ +
    "" + #CRLF$ +
    "There are also a few scripts extending this command:" + #CRLF$ +
    "" + #CRLF$ +
    "- `type_from_file` -- With this command you can automatically type text which is stored in" + #CRLF$ +
    "the given (text) file. Mostly useful if you want to type in some" + #CRLF$ +
    "BASIC program fragment that you found somewhere and pasted in a" + #CRLF$ +
    "text file." + #CRLF$ +
    "- `type_password_from_file` -- A special version of `type_from_file`, made to type in" + #CRLF$ +
    "passwords of games, which you have stored in a file. The text" + #CRLF$ +
    "file should have a special format: one password per line, lines" + #CRLF$ +
    "starting with # are ignored. After the filename, you can give the" + #CRLF$ +
    "index of the password to type (which is the index of the first" + #CRLF$ +
    "non-comment and non-blank line in the file).")

  OMSXHelp_Add("unset",
    "Referencia de Comandos - Commands",
    "Undefines a Tcl variable. When used on openMSX settings, they are reverted to their default value. See also: `set`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `unset <variable>` -- Undefines the given variable" + #CRLF$ +
    "- `unset <setting>` -- Reverts the given setting to its default value")

  OMSXHelp_Add("user_setting",
    "Referencia de Comandos - Commands",
    "This command is only meant to be used in Tcl scripts. It allows to create Tcl variables that act very much like built-in openMSX settings. They have a description (can be queried with " + Chr(34) + "`help set <setting-name>`" + Chr(34) + ") and their value is stored saved/restored when openMSX is quit/restarted." + #CRLF$ +
    "" + #CRLF$ +
    "Execute " + Chr(34) + "`help user_setting`" + Chr(34) + " to get a detailed description of this command.")

  OMSXHelp_Add("vdpregs",
    "Referencia de Comandos - Commands",
    "Shows the current register settings of the Video Display Processor (VDP). Related command: `palette`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `vdpregs` -- Shows the current VDP control register contents")

  CBody = "Most commands described above are generally useful. openMSX also has a bunch of other more specialized commands. Some of these are intended for programmers who code MSX programs using openMSX as a tool. Other of these commands are more like toys or examples that show the openMSX scripting capabilities." + #CRLF$ +
    "" + #CRLF$ +
    "We've only listed a very brief overview of these commands. As always execute " + Chr(34) + "`help <command-name>`" + Chr(34) + " to get a more detailed description of the command." + #CRLF$ +
    "" + #CRLF$ +
    "- `about` -- Search command and setting help-texts for the given keyword" + #CRLF$ +
    "- `cpuregs` -- Gives an overview of the CPU registers" + #CRLF$ +
    "- `data_file` -- Helps locate openMSX data files" + #CRLF$ +
    "- `disasm` -- Print disassembled instructions at the given memory location" + #CRLF$ +
    "- `getcolor` -- Query V99x8 palette settings" + #CRLF$ +
    "- `get_active_cpu` -- Returns the active cpu, z80 or r800" + #CRLF$ +
    "- `get_color_count` -- Gives an overview of the used colors in the current screen" + #CRLF$ +
    "- `get_screen` -- Capture the content of an MSX text screen in a Tcl string" + #CRLF$ +
    "- `get_screen_mode` -- Decodes the current screen mode from the VDP registers and returns it as a Tcl string. `get_screen_mode_number` returns it as a number which would also be used for the basic command `SCREEN`." + #CRLF$ +
    "- `get_selected_slot` -- Returns the selected slot for the given memory page" + #CRLF$ +
    "- `guess_title` -- Use heuristics to guess the title of the current game (cartridge, disk or tape). For specific media use `guess_cassette_title`, `guess_disk_title` or `guess_rom_title`." + #CRLF$ +
    "- `listing` -- Reimplementation of the BASIC LIST command in Tcl" + #CRLF$ +
    "- `load_debuggable` -- Write the content of a file to a openMSX debuggable" + #CRLF$ +
    "- `multi_screenshot` -- Take screenshots of multiple successive frames" + #CRLF$ +
    "- `pc_in_slot` -- Check whether CPU is executing from the specified slot (useful as breakpoint condition)" + #CRLF$ +
    "- `peek` -- Read a byte from the given memory location" + #CRLF$ +
    "- `peek16` -- Read a 16 bit word from the given memory location" + #CRLF$ +
    "- `poke` -- Write a byte to the given memory location. Use `dpoke` to only write if the value to be written is different from the current value." + #CRLF$ +
    "- `poke16` -- Write a 16 bit word to the given memory location" + #CRLF$ +
    "- `psg_log` -- Log or replay PSG register values in binary format" + #CRLF$ +
    "- `ram_watch` -- Add or remove RAM watch addresses to/from the list on the right side of the screen, useful for debugging or tool assisted speedrunning (TAS)" + #CRLF$ +
    "- `reg` -- Read or write CPU registers" + #CRLF$ +
    "- `reg_log` -- Log or replay register values for the specified debuggable in ASCII format" + #CRLF$ +
    "- `rom_info` -- Gives information about the given ROM device, coming from the software database. If no argument is given, the first found (external) ROM device is assumed. This command replaces the info that was previously (before openMSX 0.8.1) automatically printed on stdout." + #CRLF$ +
    "- `run_to` -- Execute instructions until the PC reaches the specified address" + #CRLF$ +
    "- `save_debuggable` -- Save the (partial) content of a debuggable to a file" + #CRLF$ +
    "- `save_msx_screen` -- Saves the current MSX screen into an MSX compatible binary file (BLOAD format)." + #CRLF$ +
    "- `save_to_file` -- Helper function to save data (e.g. the output of another command) to a file." + #CRLF$ +
    "- `setcolor` -- Change V99x8 palette settings" + #CRLF$ +
    "- `set_help_text` -- Associate help text with a Tcl proc" + #CRLF$ +
    "- `set_tabcompletion_proc` -- Associate tab completion with a Tcl proc" + #CRLF$ +
    "- `showdebuggable` -- Print the content of a debuggable in a table" + #CRLF$ +
    "- `showmem` -- Print the content of memory in a table" + #CRLF$ +
    "- `show_osd` -- Print an overview of the defined OSD elements" + #CRLF$ +
    "- `shuffler` -- A basic ROM-game shuffler, that switches between a set of ROM programs in a given folder after a certain time is passed." + #CRLF$ +
    "- `skip_instruction` -- Skip the current CPU instruction" + #CRLF$ +
    "- `stack` -- Print the top of the CPU stack" + #CRLF$ +
    "- `step_in` -- Execute one CPU instruction, go into subroutines" + #CRLF$ +
    "- `step_over` -- Execute one CPU instruction, but don't go into subroutines" + #CRLF$ +
    "- `step_out` -- Step out of the current subroutine" + #CRLF$ +
    "- `step_back` -- Step one instruction back in time" + #CRLF$ +
    "- `text_echo` -- Echo all printed MSX text on stderr" + #CRLF$ +
    "- `toggle_cursors` -- Show (or hide) a widget which shows which keys are pressed" + #CRLF$ +
    "- `toggle_frame_counter` -- Show (or hide) a widget which shows the current frame number since start-up" + #CRLF$ +
    "- `toggle_freq` -- Switch between PAL/NTSC" + #CRLF$ +
    "- `toggle_mog_overlay` -- Enable (or disable) graphical extra information and game hints when playing The Maze of Galious" + #CRLF$ +
    "- `toggle_mog_editor` -- Enable (or disable) wall drawing and Popolon-placement with the mouse when playing The Maze of Galious; needs to have the MoG overlay enabled, see `toggle_mog_overlay`" + #CRLF$ +
    "- `toggle_music_keyboard` -- Enable (or disable) keyboard view of all existing music channels. EXPERIMENTAL! Be careful, it's very slow when many channels are present in the system" + #CRLF$ +
    "- `toggle_nemesis_1_shield` -- Enable (or disable) an OSD drawn shield in Nemesis (Gradius) 1, all enemy objects will repel from it" + #CRLF$ +
    "- `toggle_psg2scc` -- Enable (or disable) playing PSG sound on SCC" + #CRLF$ +
    "- `toggle_scc_editor` -- Show a graphical view of the SCC chip(s) of the system, showing waveforms and volume per channel and also enables you to edit the waveforms per channel" + #CRLF$ +
    "- `toggle_scc_viewer` -- Show a graphical view of the SCC chip(s) of the system, showing" + #CRLF$ +
    "waveforms and volume per channel. In the future, this will be fully" + #CRLF$ +
    "replaced by Main menu bar → Tools" + #CRLF$ +
    "→ SCC viewer." + #CRLF$ +
    "- `toggle_tron` -- Show (or hide) an OSD implementation of the MSX-BASIC TRON command to trace what the current line number of the BASIC interpreter is" + #CRLF$ +
    "- `toggle_vdp_access_test` -- Enable (or disable) reporting in the console when VDP I/O is done which could possibly cause data corruption on the slowest VDP (TMS9xxx), which is not emulated" + #CRLF$ +
    "- `toggle_vdp_busy` -- Enable (or disable) display on the OSD how busy the VDP is"
  CBody + #CRLF$ + "- `type_via_keybuf` -- Alternative to the `type_via_keyboard` (the default `type` command), that uses the keyboard buffer; only works if the running software uses the standard keyboard buffer functions to get keyboard input, but is much faster" + #CRLF$ +
    "- `umrcallback` -- Example proc to use with the umr_callback setting" + #CRLF$ +
    "- `vdpcmdinprogresscallback` -- Example proc to use with the vdpcmdinprogress_callback setting" + #CRLF$ +
    "- `v9990reg` -- Read or write a V9990 register" + #CRLF$ +
    "- `v9990regs` -- Print an overview of all V9990 registers" + #CRLF$ +
    "- `vdpreg` -- Read or write a V99x8 register" + #CRLF$ +
    "- `vdpstatus` -- Shortcut for reading the VDP status registers" + #CRLF$ +
    "- `vdpvramaddress` -- Gives the current VDP VRAM pointer" + #CRLF$ +
    "- `vdrive` -- Easily switch disks in multi-disk games" + #CRLF$ +
    "- `vgm_rec` -- Record the music played by PSG, MSX-MUSIC, MSX-AUDIO, OPL4 and SCC into a VGM file" + #CRLF$ +
    "- `vpeek/vpoke` -- Read/write bytes from/to video RAM" + #CRLF$ +
    "" + #CRLF$ +
    "The source code of all these scripts is located in `share/scripts` directory. Feel free to inspect these scripts and modify them to suit your needs."
  OMSXHelp_Add("other", "Referencia de Comandos - Commands", CBody)

EndProcedure

; ============================================================
; OMSXHelp_BuildCommandsSettings
; ============================================================
Procedure OMSXHelp_BuildCommandsSettings()
  ; Usada so pelos topicos grandes (limite de literal-string do PB e 8192
  ; chars por expressao constante) - ver corpo desta procedure.
  Protected CBody.s
  OMSXHelp_Add("Settings",
    "Referencia de Comandos - Settings",
    "Settings control many aspects of openMSX. Below, the available settings are listed and described. You can change setting values with the `set` command.")

  OMSXHelp_Add("accuracy",
    "Referencia de Comandos - Settings",
    "Sets the render accuracy. openMSX supports three levels of render accuracy:" + #CRLF$ +
    "" + #CRLF$ +
    "**screen accurate::** Changes in VDP state become effective only once per video frame. Works well for most MSX1 software, but will break a lot of MSX2 software (anything that does so-called raster effects)." + #CRLF$ +
    "**line accurate::** Changes in VDP state become effective only once per display line. Works well for almost all software." + #CRLF$ +
    "**pixel accurate::** Changes in VDP state become effective immediately. In this mode even the 'Unknown Reality scope part' is rendered correctly." + #CRLF$ +
    "" + #CRLF$ +
    "In some cases switching to a lower accuracy level can speed up emulation, but in many cases the speed difference is negligible." + #CRLF$ +
    "" + #CRLF$ +
    "The default is pixel accuracy, since this is the most realistic. If the software you are running shows a jittery screen split and you would prefer a stable screen split, switching to line accuracy can help." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set accuracy` -- Shows the current setting" + #CRLF$ +
    "- `set accuracy screen` -- Selects screen accurate rendering" + #CRLF$ +
    "- `set accuracy line` -- Selects line accurate rendering" + #CRLF$ +
    "- `set accuracy pixel` -- Selects pixel accurate rendering")

  OMSXHelp_Add("audio-inputfilename",
    "Referencia de Comandos - Settings",
    "Sets the audio file from which the wave input is read for the sampler." + #CRLF$ +
    "" + #CRLF$ +
    "By default, it is read from " + Chr(34) + "audio-input.wav" + Chr(34) + " when available." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set audio-inputfilename` -- Shows the current setting" + #CRLF$ +
    "- `set audio-inputfilename mysample.wav` -- Read from " + Chr(34) + "mysample.wav" + Chr(34) + #CRLF$ +
    "" + #CRLF$ +
    "Note: The file is fully read into memory, so under Linux/UNIX do not attempt to read from a device node such as `/dev/dsp`.")

  OMSXHelp_Add("autoruncassettes",
    "Referencia de Comandos - Settings",
    "Switches the " + Chr(34) + "auto-run cassettes" + Chr(34) + " feature on or off. When it's enabled, openMSX will try to type the proper loading" + #CRLF$ +
    "instruction when a cassette is inserted." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set autoruncassettes` -- Shows the current setting" + #CRLF$ +
    "- `set autoruncassettes on` -- Try to run cassettes automatically" + #CRLF$ +
    "- `set autoruncassettes off` -- Do nothing when cassettes are inserted" + #CRLF$ +
    "" + #CRLF$ +
    "Note: Autorun works practically always for cassette images in the CAS and TSX formats. If that fails or for WAV files, openMSX will try to find a hint of the loading instruction (in upper case) in the filename.")

  OMSXHelp_Add("autorunlaserdisc",
    "Referencia de Comandos - Settings",
    "Switches the " + Chr(34) + "auto-run laserdisc" + Chr(34) + " feature on or off. When it's enabled, openMSX will try to type the proper loading" + #CRLF$ +
    "instruction when a laserdisc is inserted." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set autorunlaserdisc` -- Shows the current setting" + #CRLF$ +
    "- `set autorunlaserdisc on` -- Try to load Laserdiscs automatically" + #CRLF$ +
    "- `set autorunlaserdisc off` -- Do nothing when Laserdiscs are inserted")

  OMSXHelp_Add("auto_enable_reverse",
    "Referencia de Comandos - Settings",
    "Using the `reverse` feature comes at a small memory and performance cost. Therefore it has to be enabled before it can be used. This setting controls whether the reverse feature should automatically be activated when openMSX starts. While with desktop computers this generally won't be a problem, the performance drop might be more noticeable on older/smaller handheld devices." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set auto_enable_reverse` -- Shows the current setting" + #CRLF$ +
    "- `set auto_enable_reverse off` -- Don't automatically enable the reverse feature" + #CRLF$ +
    "- `set auto_enable_reverse on` -- Enable the reverse feature when openMSX starts. Default setting for Desktop/PC")

  OMSXHelp_Add("auto_save_replay",
    "Referencia de Comandos - Settings",
    "Enable this setting to make automatic backups of your current replay. The replay is saved to the filename specified in the `auto_save_replay_filename` setting (default: " + Chr(34) + "auto_save" + Chr(34) + ") at an interval as specified by the `auto_save_replay_interval` setting (default: 30 seconds). The interval is in real clock time, not in MSX time.")

  OMSXHelp_Add("blur",
    "Referencia de Comandos - Settings",
    "Sets the amount of horizontal blur effect. A value of 0 turns off blur, while 100 selects maximum blur." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set blur` -- Shows the current setting" + #CRLF$ +
    "- `set blur <value>` -- Change the value" + #CRLF$ +
    "" + #CRLF$ +
    "Note: Only some scale algorithms apply horizontal blur; the default algorithm " + Chr(34) + "simple" + Chr(34) + " does.")

  OMSXHelp_Add("bootsector",
    "Referencia de Comandos - Settings",
    "Sets the boot sector type for DirAsDSK. Default: DOS2. Only relevant on turboR, because it boots differently" + #CRLF$ +
    "depending on the type of boot sector on the disk in drive A." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set bootsector` -- Shows the current setting" + #CRLF$ +
    "- `set bootsector DOS1` -- Use a DOS1 boot sector")

  OMSXHelp_Add("brightness",
    "Referencia de Comandos - Settings",
    "Controls the brightness of the video output. Can be between -100 and 100. Lower values are darker, higher values are brighter. The default is 0, which is neutral. This setting shifts the brightness of all colours, including black and white, while the `gamma` setting changes the relative brightness of colours but does not change black and white." + #CRLF$ +
    "" + #CRLF$ +
    "The section about the `noise` setting describes a typical way of using `brightness`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set brightness` -- Shows the current setting" + #CRLF$ +
    "- `set brightness 5` -- Make the video output a bit brighter than default")

  OMSXHelp_Add("cmdtiming",
    "Referencia de Comandos - Settings",
    "Controls VDP command execution timing." + #CRLF$ +
    "" + #CRLF$ +
    "This is useful for debugging and for speeding up games where the command engine performance is a bottleneck." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set cmdtiming` -- Shows the current setting" + #CRLF$ +
    "- `set cmdtiming broken` -- Make VDP commands finish instantly" + #CRLF$ +
    "- `set cmdtiming real` -- Make VDP commands take a realistic amount of time" + #CRLF$ +
    "" + #CRLF$ +
    "Note: When set to `broken` the emulated MSX acts different from a real MSX. This might cause some software to fail.")

  OMSXHelp_Add("color_matrix",
    "Referencia de Comandos - Settings",
    "This setting represents a 3×3 matrix that is used to transform MSX RGB colours to host RGB colours. This setting can" + #CRLF$ +
    "be used to generate all kind of colour schemes, see `scripts/monitor.tcl` for examples." + #CRLF$ +
    "" + #CRLF$ +
    "To get the following colour transformation:" + #CRLF$ +
    "" + #CRLF$ +
    "| a b c | | Rm | | Rh |" + #CRLF$ +
    "| d e f | × | Gm | = | Gh |" + #CRLF$ +
    "| g h i | | Bm | | Bh |" + #CRLF$ +
    "" + #CRLF$ +
    "Use this command:" + #CRLF$ +
    "" + #CRLF$ +
    "set color_matrix { { a b c } { d e f } { g h i } }" + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set color_matrix` -- Shows the current value" + #CRLF$ +
    "- `set color_matrix { { 1 0 0 } { 0 1 0 } { 0 0 1 } }` -- This is the default (no colour transformation)" + #CRLF$ +
    "- `set color_matrix { { .33 .33 .33 } { .33 .33 .33 } { .33 .33 .33 } }` -- Transform to grey scale" + #CRLF$ +
    "" + #CRLF$ +
    "Note: It is often more convenient to use the `monitor_type` command.")

  OMSXHelp_Add("console",
    "Referencia de Comandos - Settings",
    "Turns the openMSX on-screen console on or off." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set console` -- Shows the current setting" + #CRLF$ +
    "- `set console on` -- Turns the console on" + #CRLF$ +
    "- `set console off` -- Turns the console off")

  OMSXHelp_Add("contrast",
    "Referencia de Comandos - Settings",
    "Controls the contrast of the video output. Can be between -100 and 100. Lower values are less contrast, higher values are more contrast. The default is 0, which is neutral." + #CRLF$ +
    "" + #CRLF$ +
    "The section about the `noise` setting describes a typical way of using `contrast`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set contrast` -- Shows the current setting" + #CRLF$ +
    "- `set contrast -5` -- Reduce the video contrast a bit")

  OMSXHelp_Add("cputrace",
    "Referencia de Comandos - Settings",
    "Enable/disable CPU instruction tracing. When enabled, the state of the CPU (Z80/R800) is printed on stdout after every instruction. This creates a lot of output and slows down emulation considerably, but it can be very useful for debugging." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set cputrace` -- Shows the current setting" + #CRLF$ +
    "- `set cputrace on` -- Enables CPU tracing" + #CRLF$ +
    "- `set cputrace off` -- Disables CPU tracing")

  OMSXHelp_Add("Debug Device output",
    "Referencia de Comandos - Settings",
    "Selects the file to where the output from the debug device goes." + #CRLF$ +
    "" + #CRLF$ +
    "The User's Manual describes the debug device in more detail." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set {Debug Device output}` -- Shows the current output file name" + #CRLF$ +
    "- `set {Debug Device output} stdout` -- Writes debug output to openMSX's standard output stream" + #CRLF$ +
    "- `set {Debug Device output} stderr` -- Writes debug output to openMSX's standard error stream" + #CRLF$ +
    "- `set {Debug Device output} <output file>` -- Writes debug output to the specified file" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This setting only exists if the `debugdevice` extension is present in the current MSX machine.")

  OMSXHelp_Add("default_machine",
    "Referencia de Comandos - Settings",
    "Selects the default MSX model. openMSX uses this machine when it is started without the `-machine` option and without the `-setup` option and the `default_setup` setting is empty or pointing to a non-existing setup. This is a typical setting that should be saved, see also `save_settings`." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI, under Main menu bar → Machine" + #CRLF$ +
    "→ Setup settings you can also configure what openMSX must do at startup, configuring this setting there." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set default_machine` -- Shows current setting" + #CRLF$ +
    "- `set default_machine Panasonic_FS-A1GT` -- Use the turboR GT the next time openMSX is started")

  OMSXHelp_Add("default_setup",
    "Referencia de Comandos - Settings",
    "Selects the default setup. openMSX uses this setup when it is started without the `-setup` or `-machine` option. By default, this setting is empty, because no setups are shipped with openMSX: they have to be created by users, after which this setting can be set to automatically start that setup that got saved earlier. If it is indeed empty or pointing to a non-existing setup, the value for the `default_machine` setting is used to determine what to start." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI, under Main menu bar → Machine" + #CRLF$ +
    "→ Setup settings you can also configure what openMSX must do at startup, configuring this setting there." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set default_setup` -- Shows current setting" + #CRLF$ +
    "- `set default_setup mymsx` -- Use the `mymsx` setup the next time openMSX is started without specifying setup or machine" + #CRLF$ +
    "" + #CRLF$ +
    "**Nota:** If you set this setting to the same value as the `save_setup_at_exit_name` setting and have the `save_setup_at_exit_depth` setting set to another depth than `none` , openMSX will automatically continue with the last setup when being started up again (and no other machine or setup is specified).")

  OMSXHelp_Add("DirAsDSKmode",
    "Referencia de Comandos - Settings",
    "Determine the behaviour of the DirAsDSK when inserting a directory to be used as diskimage." + #CRLF$ +
    "" + #CRLF$ +
    "The possible values are `read_only` and `full`. The default mode is `full`." + #CRLF$ +
    "" + #CRLF$ +
    "- `read_only` -- The MSX can not write to the virtual disk." + #CRLF$ +
    "Changes on the host-OS are still reflected on the virtual disk, however." + #CRLF$ +
    "- `full` -- All changes are performed both ways, no restrictions apply." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set DirAsDSKmode` -- Shows the current setting" + #CRLF$ +
    "- `set DirAsDSKmode read_only` -- Disk image will be read only" + #CRLF$ +
    "" + #CRLF$ +
    "Note: this setting is only used when the directory is inserted, it is not possible to change the behaviour of the current virtual disk by altering the setting. The new setting will become effective after the current virtual disk has been ejected.")

  OMSXHelp_Add("deflicker",
    "Referencia de Comandos - Settings",
    "Turns deflicker on/off. deflicker is a filter which tries to detect pixels" + #CRLF$ +
    "that alternate each frame between two different colour values and replaces" + #CRLF$ +
    "those alternations with the average colour. It gives a very nice result for" + #CRLF$ +
    "software (mostly demos) that use this technique to get the optical illusion" + #CRLF$ +
    "of more colours than are actually supported by the hardware. It also works" + #CRLF$ +
    "well in games with flickering sprites on a static background (like Maze of" + #CRLF$ +
    "Galious). This setting is disabled by default because there aren't that many" + #CRLF$ +
    "situations where the performance cost justifies the improved video quality." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set deflicker` -- Shows the current setting" + #CRLF$ +
    "- `set deflicker on` -- Turns deflicker on" + #CRLF$ +
    "- `set deflicker off` -- Turns deflicker off")

  OMSXHelp_Add("deinterlace",
    "Referencia de Comandos - Settings",
    "Turns deinterlacing on/off. Deinterlace is a filter which combines the even and odd field of interlaced video into a single frame which has double vertical resolution. It results in a sharp and stable image, but can show artifacts on fast animations." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set deinterlace` -- Shows the current setting" + #CRLF$ +
    "- `set deinterlace on` -- Turns deinterlacing on" + #CRLF$ +
    "- `set deinterlace off` -- Turns deinterlacing off")

  OMSXHelp_Add("disablesprites",
    "Referencia de Comandos - Settings",
    "Can be used to disable sprite rendering. Only the rendering itself is" + #CRLF$ +
    "disabled, all other MSX behaviour (like sprite collision detection) stays" + #CRLF$ +
    "the same." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set disablesprites` -- Shows the current setting" + #CRLF$ +
    "- `set disablesprites on` -- Disable sprite rendering" + #CRLF$ +
    "- `set disablesprites off` -- Enable sprite rendering (the default)")

  OMSXHelp_Add("display_deform",
    "Referencia de Comandos - Settings",
    "Select display deformation effect." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set display_deform` -- Shows the current setting" + #CRLF$ +
    "- `set display_deform normal` -- Turns off display deform" + #CRLF$ +
    "- `set display_deform 3d` -- Deforms the image in 3D, to look like a CRT (like JEmu2)" + #CRLF$ +
    "" + #CRLF$ +
    "Note: In the past there was also a 'horizontal_stretch' mode. This is now replaced by the `horizontal_stretch` setting.")

  OMSXHelp_Add("di_halt_callback",
    "Referencia de Comandos - Settings",
    "Selects the Tcl procedure to be called when the running MSX software has executed a HALT instruction while the interrupts are disabled (DI)." + #CRLF$ +
    "" + #CRLF$ +
    "The default openmsx startup scripts initialize this setting with a proc that prints a warning message." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set di_halt_callback` -- Shows the current setting" + #CRLF$ +
    "- `set di_halt_callback my_callback_proc` -- Sets a new callback proc")

  OMSXHelp_Add("enable_session_management",
    "Referencia de Comandos - Settings",
    "Controls session management. When enabled, openMSX will store the state of all machines when you exit openMSX and restore that state again when starting it up next time. Note that the reverse history is not saved." + #CRLF$ +
    "" + #CRLF$ +
    "Sessions can also be saved manually with the command `save_session`, and explicitly loaded with `load_session`. A list of saved sessions can be retrieved with `list_sessions`.")

  OMSXHelp_Add("fastforward",
    "Referencia de Comandos - Settings",
    "Chooses between normal speed (off) and fastforward speed (on)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set fastforward` -- Shows the current setting" + #CRLF$ +
    "- `set fastforward on` -- Run at fastforward speed: the `fastforwardspeed` setting determines how fast the emulated MSX runs compared to real time" + #CRLF$ +
    "- `set fastforward off` -- Run at normal speed: the `speed` setting determines how fast the emulated MSX runs compared to real time")

  OMSXHelp_Add("fastforwardspeed",
    "Referencia de Comandos - Settings",
    "Sets the emulation speed relative to the speed of a real MSX when we are running in fastforward mode. Speed 100 means as fast as a real MSX, lower values are slower than real MSX, higher values are faster than real MSX." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set fastforwardspeed` -- Shows current fastforward speed" + #CRLF$ +
    "- `set fastforwardspeed <num>` -- Sets new fastforward speed to <num>% of real time")

  OMSXHelp_Add("frequency",
    "Referencia de Comandos - Settings",
    "Sets the sound mixer frequency. Sound hardware and sound APIs typically support a limited set of frequencies, such as 11025 Hz, 22050 Hz, 44100 Hz and 48000 Hz." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set frequency` -- Shows the current setting" + #CRLF$ +
    "- `set frequency 44100` -- Use 44.1 kHz mixing frequency (CD quality)")

  OMSXHelp_Add("firmwareswitch",
    "Referencia de Comandos - Settings",
    "Some machines (e.g. turboR) have a switch on the front (or on the back) that controls if the machine should boot" + #CRLF$ +
    "'normally' or start the built-in software, also called firmware. This setting controls the position of that" + #CRLF$ +
    "switch." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set firmwareswitch` -- Shows the current setting" + #CRLF$ +
    "- `set firmwareswitch on` -- Boot into the internal software" + #CRLF$ +
    "- `set firmwareswitch off` -- Boot into MSX-BASIC or on-disk software")

  OMSXHelp_Add("fullscreen",
    "Referencia de Comandos - Settings",
    "Switch to/from fullscreen mode." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set fullscreen` -- Shows the current setting" + #CRLF$ +
    "- `set fullscreen on` -- Switch to fullscreen mode" + #CRLF$ +
    "- `set fullscreen off` -- Switch to windowed mode")

  OMSXHelp_Add("fullspeedwhenloading",
    "Referencia de Comandos - Settings",
    "When enabled, openMSX will try to detect when the MSX is loading from diskette, cassette or laserdisc. During loading openMSX will run at full speed (`throttle` off). This can be convenient if you're not interested in the realistic but slow loading times on MSX. Default is off, because it is not how a real MSX behaves." + #CRLF$ +
    "" + #CRLF$ +
    "Unlike the fast loading features in for example fMSX, `fullspeedwhenloading` does not intercept BIOS calls. Instead, it speeds up the emulation of the entire MSX, including all hardware devices." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set fullspeedwhenloading` -- Shows the current setting" + #CRLF$ +
    "- `set fullspeedwhenloading on` -- Load as fast as possible" + #CRLF$ +
    "- `set fullspeedwhenloading off` -- Load at the same speed as a real MSX")

  OMSXHelp_Add("full_stretch",
    "Referencia de Comandos - Settings",
    "Stretches the image to fill the entire screen when in fullscreen mode. This setting is useful when you want to use the full screen real estate, for example when displaying 4:3 content on a 16:9 monitor, or when you prefer to eliminate any black borders around the image." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set full_stretch` -- Shows the current setting" + #CRLF$ +
    "- `set full_stretch on` -- Enable full screen stretching" + #CRLF$ +
    "- `set full_stretch off` -- Disable full screen stretching")

  OMSXHelp_Add("gamma",
    "Referencia de Comandos - Settings",
    "Sets the amount of gamma correction. A value of 1.0 will turn off gamma correction. Lower values will result in a darker image, higher values in a brighter image." + #CRLF$ +
    "" + #CRLF$ +
    "If you want to get a realistic picture, set the openMSX gamma correction to PC gamma / MSX gamma. TVs use a standardised gamma of 2.5, let's take that as the value of MSX gamma. You can measure the gamma of your PC screen with a simple test such as the Gamma Measurement Image in Robert W. Berger's " + Chr(34) + "An Explanation of Monitor Gamma" + Chr(34) + " (https://web.archive.org/web/20150714015749/http://www.bberger.net/rwb/gamma.html). If your PC gamma would be for example 2.0, the most realistic value for gamma correction would be 2.0 / 2.5 = 0.8." + #CRLF$ +
    "" + #CRLF$ +
    "Alternatively, you can just try a few values and see what you like." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set gamma` -- Shows the current value" + #CRLF$ +
    "- `set gamma <num>` -- Sets a new gamma correction amount")

  OMSXHelp_Add("glow",
    "Referencia de Comandos - Settings",
    "Sets the amount of afterglow effect: 0 is off and 100 is a very heavy afterglow." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set glow` -- Shows the current setting" + #CRLF$ +
    "- `set glow <value>` -- Change the amount of afterglow")

  OMSXHelp_Add("grabinput",
    "Referencia de Comandos - Settings",
    "Controls whether openMSX grabs all input events or not. When this setting is turned on, all input events are directly passed to openMSX. The mouse pointer can't leave the openMSX window and the window manager won't be able to react to keyboard shortcuts." + #CRLF$ +
    "" + #CRLF$ +
    "You can turn this setting on when you want to use mouse-controlled MSX software while openMSX is in windowed mode. It is best turned off in all other cases. See also `escape_grab`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set grabinput` -- Shows the current setting" + #CRLF$ +
    "- `set grabinput on` -- Starts grabbing all input events" + #CRLF$ +
    "- `set grabinput off` -- Stops grabbing all input events")

  OMSXHelp_Add("horizontal_stretch",
    "Referencia de Comandos - Settings",
    "Sets the amount of horizontal stretch, thus also the aspect ratio of the screen. More specifically, a setting of `n` means stretch the centre `n` MSX pixels to the full width of the host output window (at the virtual `scale_factor` 1)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set horizontal_stretch` -- Shows the current setting" + #CRLF$ +
    "- `set horizontal_stretch <value>` -- Change the amount of horizontal stretch" + #CRLF$ +
    "" + #CRLF$ +
    "**examples of typical useful values:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set horizontal_stretch 320` (no horizontal stretch)" + #CRLF$ +
    "`set horizontal_stretch 272` (approach real aspect ratio of MSX screen)" + #CRLF$ +
    "`set horizontal_stretch 280` (default: show all generated border pixels, so that all border demo effects are still visible)" + #CRLF$ +
    "`set horizontal_stretch 256` (borders are not visible at all; doesn't work well in combination with set-adjust)")

  OMSXHelp_Add("inputdelay",
    "Referencia de Comandos - Settings",
    "Input events for the MSX machine are delayed by this amount. Increase this value when the MSX machine misses keyboard presses when you type very fast. Decrease this value to reduce the latency between pressing a key on the host machine and seeing it being typed in the MSX machine." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set inputdelay` -- Shows the current value" + #CRLF$ +
    "- `set inputdelay <time>` -- Sets the input delay to the specified number of seconds" + #CRLF$ +
    "" + #CRLF$ +
    "Note: The default value of 0.0 seconds (no extra delay) should almost" + #CRLF$ +
    "always be OK. It only makes sense to increase this setting if you have" + #CRLF$ +
    "a slow host machine and you're typing text very fast and the emulated" + #CRLF$ +
    "MSX machine misses (some of) the keys you typed.")

  OMSXHelp_Add("interleave_black_frame",
    "Referencia de Comandos - Settings",
    "Insert a black frame in between each normal MSX frame. Useful on (100Hz+)" + #CRLF$ +
    "lightboost enabled monitors to reduce motion blur and double frame" + #CRLF$ +
    "artifacts." + #CRLF$ +
    "" + #CRLF$ +
    "Make sure you configure your monitor to use a refresh rate of 100Hz (for a" + #CRLF$ +
    "PAL MSX machine) or to 120Hz (for a NTSC machine). The brightness will" + #CRLF$ +
    "decrease, so adjust the `gamma`," + #CRLF$ +
    "`brightness` and" + #CRLF$ +
    "`contrast` settings to compensate." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set interleave_black_frame` -- Shows the current value" + #CRLF$ +
    "- `set interleave_black_frame true` -- Enable this feature.")

  OMSXHelp_Add("invalid_ppi_mode_callback",
    "Referencia de Comandos - Settings",
    "Selects the Tcl procedure to be called when the running MSX software has selected an invalid PPI mode. Or at least a PPI mode that's not yet correctly emulated. Typically on a real machine these modes will hang the MSX." + #CRLF$ +
    "" + #CRLF$ +
    "The default openMSX startup scripts initialize this setting with a proc that prints a warning message just once. Though if you're a developer you may want to change this to always print the warning or automatically break emulation when this happens so you can debug the problem." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set invalid_ppi_mode_callback` -- Shows the current setting" + #CRLF$ +
    "- `set invalid_ppi_mode_callback my_callback_proc` -- Sets a new callback proc")

  OMSXHelp_Add("invalid_psg_directions_callback",
    "Referencia de Comandos - Settings",
    "Selects the Tcl procedure to be called when the running MSX software has selected invalid PSG port directions (port A should always be set as input)." + #CRLF$ +
    "" + #CRLF$ +
    "The default openMSX startup scripts initialize this setting with a proc that prints a warning message just once. Though if you're a developer you may want to change this to always print the warning or automatically break emulation when this happens, so you can debug the problem." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set invalid_psg_directions_callback` -- Shows the current setting" + #CRLF$ +
    "- `set invalid_psg_directions_callback my_callback_proc` -- Sets a new callback proc")

  OMSXHelp_Add("msxjoystick<n>_config/joymega<n>_config",
    "Referencia de Comandos - Settings",
    "This setting configures how the buttons/axis/keys of the host are" + #CRLF$ +
    "mapped to the inputs of the emulated MSX joysticks or JoyMega devices. For many" + #CRLF$ +
    "host controllers the initial value of this setting provides an acceptable default" + #CRLF$ +
    "mapping. But depending on your controller type and taste you may want to tweak" + #CRLF$ +
    "it." + #CRLF$ +
    "" + #CRLF$ +
    "The easiest way to tweak it, is by using the GUI menu under Main menu bar → Settings" + #CRLF$ +
    "→ Input → Configure MSX joysticks." + #CRLF$ +
    "" + #CRLF$ +
    "The value of this setting is a Tcl dictionary. This means it's a list of" + #CRLF$ +
    "key/value pairs where each even element is a key and each odd element is the" + #CRLF$ +
    "corresponding value. The keys in this dictionary represent the 6 possible MSX" + #CRLF$ +
    "joystick inputs. Possible key values are `LEFT`," + #CRLF$ +
    "`RIGHT`, `UP`, `DOWN`, `A` and" + #CRLF$ +
    "`B`. For the JoyMega devices, add `C`, `X`," + #CRLF$ +
    "`Y`, `Z`, `SELECT` and `START`." + #CRLF$ +
    "The corresponding dictionary-values are lists of boolean host" + #CRLF$ +
    "inputs. Possible elements for these lists regarding host controller input are" + #CRLF$ +
    "`joy<n> button<m>`, `joy<n> +axis<m>`," + #CRLF$ +
    "`joy<n> -axis<m>` and `joy<n> hat<m>" + #CRLF$ +
    "left/right/down/up`. But also host keyboard input can be configured" + #CRLF$ +
    "with `keyb <KEYNAME>`, where KEYNAME is the name of a" + #CRLF$ +
    "key." + #CRLF$ +
    "" + #CRLF$ +
    "Let's explain this with an example. The following is the default value for" + #CRLF$ +
    "this setting:" + #CRLF$ +
    "" + #CRLF$ +
    "`UP {{joy1 -axis1} {joy1 hat0 up}} DOWN {{joy1 +axis1} {joy1 hat0 down}} LEFT {{joy1 -axis0} {joy1 hat0 left}} RIGHT {{joy1 +axis0} {joy1 hat0 right}} A {{joy1 button0} {joy1 button2} {joy1 button4} {joy1 button6} {joy1 button8} {joy1 button10}} B {{joy1 button1} {joy1 button3} {joy1 button5} {joy1 button7} {joy1 button9} {joy1 button11}}`" + #CRLF$ +
    "" + #CRLF$ +
    "Axis 0 is usually the primary X-axis of the host controller's analogue stick." + #CRLF$ +
    "When that axis is moved towards negative values the LEFT input switch on the" + #CRLF$ +
    "emulated joystick is activated. When it is moved towards positive values the" + #CRLF$ +
    "RIGHT MSX input switch is activated. The D-pad of the detected host" + #CRLF$ +
    "controller is also mapped via the `hat0` events." + #CRLF$ +
    "Similarly host axis1 is mapped to the UP and DOWN MSX inputs. The (default)" + #CRLF$ +
    "configuration for the buttons is slightly more complicated. Here all even" + #CRLF$ +
    "numbered host buttons (0, 2, etc.) will activate MSX button A, and odd host" + #CRLF$ +
    "button numbers will activate MSX button B." + #CRLF$ +
    "" + #CRLF$ +
    "There are no restrictions on the possible mappings. For example it is" + #CRLF$ +
    "allowed to map host axis/buttons to MSX buttons/axis or vice-versa. This" + #CRLF$ +
    "allows to for example map a host joypad (which acts like 4 buttons, instead of hats) to the" + #CRLF$ +
    "MSX directional inputs. (Technically speaking the MSX axis inputs LEFT," + #CRLF$ +
    "RIGHT, UP and DOWN are just 4 input switches, just like the buttons A and B" + #CRLF$ +
    "are just 2 input switches). It's also allowed to map the same host action to" + #CRLF$ +
    "multiple MSX inputs. This allows to for example make one specific host button" + #CRLF$ +
    "press both MSX buttons simultaneously (e.g. to have a 'crouch button' in" + #CRLF$ +
    "Metal Gear)." + #CRLF$ +
    "" + #CRLF$ +
    "It is possible to set this setting directly using the `set`" + #CRLF$ +
    "command, but often using the Tcl `dict` command is more" + #CRLF$ +
    "convenient. See below for some examples." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set msxjoystick1_config` -- Shows the current configuration of the first MSX joystick (there are 2 MSX joysticks defined)" + #CRLF$ +
    "- `dict set msxjoystick1_config A {joy1 button5}` -- (Re)map MSX button A to (only) host button 5 of host joystick/controller 1. Leave the mapping of the" + #CRLF$ +
    "other MSX inputs unchanged." + #CRLF$ +
    "- `dict set msxjoystick1_config A {{joy1 button0} {joy1 button2}}" + #CRLF$ +
    "" + #CRLF$ +
    "dict set msxjoystick1_config B {{joy1 button1} {joy1 button2}}` -- Map joystick/controller 1's button 0 to A, 1 to B and 2 to A+B. So pressing host button 2" + #CRLF$ +
    "will press both MSX buttons." + #CRLF$ +
    "- `dict set msxjoystick1_config LEFT {{joy2 -axis0} {joy2 -axis2} {joy1 button10}}" + #CRLF$ +
    "" + #CRLF$ +
    "dict set msxjoystick1_config RIGHT {{joy2 +axis0} {joy2 +axis2} {joy1 button11}}" + #CRLF$ +
    "" + #CRLF$ +
    "dict set msxjoystick1_config UP {{joy2 -axis1} {joy2 -axis3} {joy1 button12}}" + #CRLF$ +
    "" + #CRLF$ +
    "dict set msxjoystick1_config DOWN {{joy2 +axis1} {joy2 +axis3} {joy1 button13}}` -- Map 2 pairs of axis and 1 keypad (4 buttons) from host controller/joystick 2 to the MSX direction inputs for MSX joystick 1." + #CRLF$ +
    "- `dict lappend msxjoystick2_config LEFT {joy1 hat0 left}" + #CRLF$ +
    "" + #CRLF$ +
    "dict lappend msxjoystick2_config RIGHT {joy1 hat0 right}" + #CRLF$ +
    "" + #CRLF$ +
    "dict lappend msxjoystick2_config UP {joy1 hat0 up}" + #CRLF$ +
    "" + #CRLF$ +
    "dict lappend msxjoystick2_config DOWN {joy1 hat0 down}` -- Additionally map hat0 of host controller/joystick 1 to the 4 MSX directions of msxjoystick2." + #CRLF$ +
    "- `dict lappend msxjoystick2_config LEFT {keyb A}" + #CRLF$ +
    "" + #CRLF$ +
    "dict lappend msxjoystick2_config RIGHT {keyb D}" + #CRLF$ +
    "" + #CRLF$ +
    "dict lappend msxjoystick2_config UP {keyb W}" + #CRLF$ +
    "" + #CRLF$ +
    "dict lappend msxjoystick2_config DOWN {keyb S}` -- Additionally map the W, A, S, D keyboard key presses to the 4 MSX directions of msxjoystick2.")

  OMSXHelp_Add("joystick<n>_deadzone",
    "Referencia de Comandos - Settings",
    "This setting configures how big the dead centre zone of an (analogue)" + #CRLF$ +
    "joystick is. This is expressed as a percentage: 0 means no dead zone, 100" + #CRLF$ +
    "means everything falls inside the dead zone. The setting is only available" + #CRLF$ +
    "when connected host analogue sticks are detected." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set joystick1_deadzone` -- Shows the current size of the dead zone of the first joystick" + #CRLF$ +
    "- `set joystick1_deadzone 25` -- Set the size of the dead zone to ¼ of the total range")

  OMSXHelp_Add("kbd_auto_toggle_code_kana_lock",
    "Referencia de Comandos - Settings",
    "Switches the " + Chr(34) + "Automatically toggle the CODE/KANA lock" + Chr(34) + " feature on or off. When it's on, openMSX will" + #CRLF$ +
    "automatically toggle the CODE/KANA lock when a user enters a character for which the CODE/KANA lock" + #CRLF$ +
    "state must be changed." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_auto_toggle_code_kana_lock` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_auto_toggle_code_kana_lock on` -- Automatically toggle the CODE/KANA lock when required" + #CRLF$ +
    "- `set kbd_auto_toggle_code_kana_lock off` -- Only toggle CODE/KANA lock status when user presses the CODE/KANA lock key" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This only works on MSX models for which the CODE/KANA key locks (e.g. Japanese MSX models and the Philips VG8010). On other models, this setting is ignored.")

  OMSXHelp_Add("kbd_code_kana_host_key",
    "Referencia de Comandos - Settings",
    "Host key that maps to the MSX CODE/KANA key. By default right-ALT (RALT) key." + #CRLF$ +
    "" + #CRLF$ +
    "It is especially useful for" + #CRLF$ +
    "people with AZERTY host keyboard, on which the RALT key has a special function; on" + #CRLF$ +
    "azerty keyboards it is called the ALT-GR key and not the right-ALT key and it's used to" + #CRLF$ +
    "enter some special characters (some keys are tagged with 3 characters; normal, key+SHIFT, key+ALT-GR)." + #CRLF$ +
    "" + #CRLF$ +
    "It is also useful for people with a Japanese (jp106) keyboard; they can map the HENKAN_MODE key (which is similar to the KANA Lock on Japanese MSX models) to the CODE/KANA key." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_code_kana_host_key` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_code_kana_host_key MENU` -- Binds the MENU key (http://en.wikipedia.org/wiki/Menu_key) on the host keyboard to the MSX CODE/KANA key" + #CRLF$ +
    "- `set kbd_code_kana_host_key HENKAN_MODE` -- Binds the HENKAN_MODE key on the host keyboard to the MSX CODE/KANA key")

  OMSXHelp_Add("kbd_deadkey1_host_key",
    "Referencia de Comandos - Settings",
    "Host key that maps to the (1st) dead key. By default right-CTRL (RCTRL) key." + #CRLF$ +
    "" + #CRLF$ +
    "Some MSX models have one dead key that can be used to enter accented characters. For example the MSX" + #CRLF$ +
    "models sold in the Netherlands have a dead key that has following four accents printed on it: ` ´ ^ ¨." + #CRLF$ +
    "On the other hand, the Brazilian Gradiente Expert XP-800 has following four accents on its" + #CRLF$ +
    "dead key: ` ´ ^ ~." + #CRLF$ +
    "" + #CRLF$ +
    "There are also some MSX models with multiple dead keys like for example the Brazilian Gradiente Expert Plus," + #CRLF$ +
    "which has two dead keys and the different Sharp Hotbit models that have three dead keys. On such machines," + #CRLF$ +
    "this setting is for the first dead key which can be used to enter following two accents: ´ `." + #CRLF$ +
    "" + #CRLF$ +
    "In order to enter an accented character on the MSX, you first have to press and release the dead key, optionally" + #CRLF$ +
    "together with SHIFT, CODE or CODE+SHIFT and then the correct character. The combination with CODE or CODE+SHIFT is" + #CRLF$ +
    "only relevant for the MSX models with a single dead key that can be used to enter four different accents." + #CRLF$ +
    "" + #CRLF$ +
    "Following table shows for example how to" + #CRLF$ +
    "enter respectively ù, ú, û or ü on the MSX models sold in the Netherlands:" + #CRLF$ +
    "" + #CRLF$ +
    "**Key presses | Character**" + #CRLF$ +
    "- DEAD_KEY1 followed by u -- ù" + #CRLF$ +
    "- DEAD_KEY1+SHIFT followed by u -- ú" + #CRLF$ +
    "- DEAD_KEY1+CODE followed by u -- û" + #CRLF$ +
    "- DEAD_KEY1+SHIFT+CODE followed by u -- ü" + #CRLF$ +
    "" + #CRLF$ +
    "In order to use the dead key in openMSX, you must map an appropriate host key to the DEAD_KEY1 of the MSX and" + #CRLF$ +
    "another one to the CODE key of the MSX with respectively this `kbd_deadkey1_host_key` setting and the above" + #CRLF$ +
    "documented `kbd_code_kana_host_key` setting." + #CRLF$ +
    "" + #CRLF$ +
    "Note that especially the last key combination (DEAD_KEY1+SHIFT+CODE) can be impossible to enter on some" + #CRLF$ +
    "host systems; depending on the host operating system, keyboard type and keyboard driver it may be impossible" + #CRLF$ +
    "for the host system to send a combination of three keys at once to an application like openMSX. Unfortunately" + #CRLF$ +
    "openMSX or its developers can't do anything about that." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_deadkey1_host_key` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_deadkey1_host_key PAGEUP` -- Binds the PAGEUP key on the host keyboard to the 1st dead key" + #CRLF$ +
    "" + #CRLF$ +
    "Note that to use for example PAGEUP as 1st dead key you will have to unbind it from the `go_back_one_step`" + #CRLF$ +
    "command in the console; by default openMSX has bound the PAGEUP key to the `go_back_one_step` command and such" + #CRLF$ +
    "a binding takes precedence over keyboard mappings, so if you want to use PAGEUP as the 1st dead key you will have" + #CRLF$ +
    "to enter following additional command in the console: `unbind PAGEUP`.")

  OMSXHelp_Add("kbd_deadkey2_host_key",
    "Referencia de Comandos - Settings",
    "Host key that maps to the 2nd dead key. By default Page Up (PAGEUP) key." + #CRLF$ +
    "" + #CRLF$ +
    "This is only applicable to MSX models that have at least two dead keys, like the Brazilian Hotbit models" + #CRLF$ +
    "or the Brazilian Gradiente Expert Plus or other Gradiente models with Gradiente basic version 1.1." + #CRLF$ +
    "" + #CRLF$ +
    "On the Hotbit models, the second dead key can be used to enter accent ¨ while on the Gradiente 1.1" + #CRLF$ +
    "models, the second dead key can be used to enter following accents: ~ ^." + #CRLF$ +
    "" + #CRLF$ +
    "It can be used in the same manner as the first dead key, explained in previous section." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_deadkey2_host_key` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_deadkey2_host_key PAGEDOWN` -- Binds the PAGEDOWN key on the host keyboard to the 2nd dead key" + #CRLF$ +
    "" + #CRLF$ +
    "Note that to use for example PAGEUP or PAGEDOWN as a dead key you will have to unbind them from the" + #CRLF$ +
    "default functions in openMSX using the console; by default openMSX has bound the PAGEUP key to the" + #CRLF$ +
    "`go_back_one_step` command and the PAGEDOWN key to the `go_forward_one_step` command. Such a binding" + #CRLF$ +
    "takes precedence over keyboard mappings, so if you want to use PAGEUP or PAGEDOWN as the second dead key" + #CRLF$ +
    "you will have to enter following additional commands in the console: `unbind PAGEUP` or" + #CRLF$ +
    "`unbind PAGEDOWN`.")

  OMSXHelp_Add("kbd_deadkey3_host_key",
    "Referencia de Comandos - Settings",
    "Host key that maps to the 3rd dead key. By default Page Down (PAGEDOWN) key." + #CRLF$ +
    "" + #CRLF$ +
    "This is only applicable to MSX models with at least three dead keys, like the Sharp Hotbit models." + #CRLF$ +
    "" + #CRLF$ +
    "On the Hotbit models, the third dead key can be used to enter following two accents: ~ ^." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_deadkey3_host_key` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_deadkey3_host_key RCTRL` -- Binds the Right CTRL (RCTRL) key on the host keyboard to the 3rd dead key" + #CRLF$ +
    "" + #CRLF$ +
    "Note that to use for example PAGEDOWN (default setting!) as the 3rd dead key you will have to unbind" + #CRLF$ +
    "it from the `go_forward_one_step` command in openMSX using the console; by default openMSX has bound" + #CRLF$ +
    "the PAGEUP key to the `go_back_one_step` command. It is a very useful setting for many openMSX users when" + #CRLF$ +
    "playing games but unfortunately it conflicts with the default set-up for the third dead key. Such a command" + #CRLF$ +
    "binding takes precedence over keyboard mappings, so if you want to use PAGEDOWN as the third dead key you" + #CRLF$ +
    "will have to enter following additional command in the console: `unbind PAGEDOWN`.")

  OMSXHelp_Add("kbd_mapping_mode",
    "Referencia de Comandos - Settings",
    "The keyboard driver can work in several mapping modes: CHARACTER, POSITIONAL or KEY." + #CRLF$ +
    "" + #CRLF$ +
    "**CHARACTER mapping::** A character entered by the user on the host keyboard is mapped to the correct key combination on the MSX keyboard to" + #CRLF$ +
    "enter that same character. For example, when the user enters an '!' character and openMSX is emulating an 'international'" + #CRLF$ +
    "MSX model, the keyboard driver will press SHIFT and '1' on the MSX keyboard. This will be done regardless of the key" + #CRLF$ +
    "or keys that the user pressed on the host keyboard to enter that '!' character." + #CRLF$ +
    "" + #CRLF$ +
    "This is especially useful when the user has an AZERTY host keyboard and is working on a QWERTY style MSX or" + #CRLF$ +
    "when he has a US-QWERTY keyboard and is working on a Japanese MSX." + #CRLF$ +
    "" + #CRLF$ +
    "In other words: in this mode openMSX is aware of both the host and the MSX keyboard layout and tries to remap host key-combinations to the corresponding MSX key-combinations that produce the same character." + #CRLF$ +
    "" + #CRLF$ +
    "Special host keys (like CURSOR keys or CAPSLOCK) are mapped directly to the corresponding MSX keys." + #CRLF$ +
    "" + #CRLF$ +
    "Note that CHARACTER mode isn't perfect (help to improve it is always appreciated). In some cases it may be more convenient or even required to use one of the other mapping modes." + #CRLF$ +
    "**POSITIONAL mapping::** In this mode both the host and the MSX keyboard layout are ignored. Host keys get mapped to MSX keys that are (approximately) in the same position on both keyboards. (More technically, host 'scan-codes' get mapped to MSX 'keyboard-matrix positions'.)" + #CRLF$ +
    "**KEY mapping::** This mode is deprecated, it's superseded by the previous two modes and may get removed in a future openMSX release." + #CRLF$ +
    "" + #CRLF$ +
    "This mode has rudimentary knowledge about the host keyboard layout, but no knowledge about the MSX keyboard layout. It remaps individual keys, not key combinations. Take for example a French AZERTY host keyboard and an emulated MSX with 'international' keyboard layout. Pressing the 'A' host key correctly maps to the 'A' MSX key. But pressing SHIFT+'3' on the host (which produces '3'), maps to SHIFT+'3' on the MSX keyboard (which produces '#')." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_mapping_mode` -- Shows the current mode" + #CRLF$ +
    "- `set kbd_mapping_mode CHARACTER` -- Set the CHARACTER mapping mode" + #CRLF$ +
    "- `set kbd_mapping_mode POSITIONAL` -- Set the POSITIONAL mapping mode")

  OMSXHelp_Add("kbd_numkeypad_always_enabled",
    "Referencia de Comandos - Settings",
    "Some real MSX computers do not have a numeric keypad. openMSX will ignore" + #CRLF$ +
    "key presses on the host numeric keypad when emulating such an MSX model." + #CRLF$ +
    "With this parameter, you can indicate that even on such MSX models, presses" + #CRLF$ +
    "on the host numeric keypad must be mapped to the MSX numeric keypad. So, you" + #CRLF$ +
    "can override accurate behaviour with it, which is the reason that by default," + #CRLF$ +
    "this setting is set to 'off'." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_numkeypad_always_enabled` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_numkeypad_always_enabled on` -- Enables numeric keypad, even if the emulated MSX does not have one")

  OMSXHelp_Add("kbd_numkeypad_enter_key",
    "Referencia de Comandos - Settings",
    "There is a subtle difference between numeric keypad of MSX computers and" + #CRLF$ +
    "of most host computers; the MSX computers have a '.' and a ',' on the numeric" + #CRLF$ +
    "keypad. On the other hand, the host computers have a '.' and an 'ENTER' key" + #CRLF$ +
    "on the keypad." + #CRLF$ +
    "" + #CRLF$ +
    "In some respect it is logical that the 'ENTER' key on the host numeric" + #CRLF$ +
    "keypad is mapped to the 'normal' MSX 'ENTER' key. On the other hand, that" + #CRLF$ +
    "would make it impossible to enter the ',' on the MSX numeric keypad." + #CRLF$ +
    "Therefore, the user can choose whether the host numeric keypad ENTER key" + #CRLF$ +
    "should be mapped to the MSX numeric keypad ',' (which is the default) or to" + #CRLF$ +
    "the main 'ENTER' key." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_numkeypad_enter_key` -- Shows the current value" + #CRLF$ +
    "- `set kbd_numkeypad_enter_key ENTER` -- Maps the keypad enter key to the main 'ENTER' key, instead of the comma key on the MSX keypad")

  OMSXHelp_Add("kbd_trace_key_presses",
    "Referencia de Comandos - Settings",
    "Log SDL key code, SDL modifiers and Unicode value for each key that gets" + #CRLF$ +
    "pressed on the host keyboard on stderr. Also show Unicode value and" + #CRLF$ +
    "corresponding MSX key-presses for characters that get 'pasted' into the MSX" + #CRLF$ +
    "by the console `type`" + #CRLF$ +
    "command. This setting is especially useful when defining Unicode keymap" + #CRLF$ +
    "files, so that you can find out the Unicode values belonging to certain" + #CRLF$ +
    "keys/characters." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set kbd_trace_key_presses` -- Shows the current setting" + #CRLF$ +
    "- `set kbd_trace_key_presses on` -- Turn logging of key presses on")

  OMSXHelp_Add("led_<name>",
    "Referencia de Comandos - Settings",
    "These are read-only settings. Their value reflects the current status of the corresponding LED on the emulated MSX machine. The currently supported LED names are: `power`, `caps`, `kana`, `pause`, `turbo` and `FDD`." + #CRLF$ +
    "" + #CRLF$ +
    "As for any setting you can use the native `trace` Tcl command to trigger a callback when the value of these settings changes. (In fact this possibility was the main motivation to make these read-only settings instead of topics of the `machine_info` command.)")

  OMSXHelp_Add("limitsprites",
    "Referencia de Comandos - Settings",
    "Controls whether the VDP has a limit on the number of sprites it can display per line. The default is on, because the real VDP has such a limit. You can turn off the limit to reduce sprite flashing in games such as Aleste. Note that some games (Penguin Adventure, among others) make use of this limitation, so they will display incorrectly if the limit is turned off." + #CRLF$ +
    "" + #CRLF$ +
    "The 5th/9th sprite status flag of the VDP is not influenced by the `limitsprites` setting: the flag always takes the limit into account." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set limitsprites` -- Shows the current value" + #CRLF$ +
    "- `set limitsprites on` -- Limits number of sprites per line" + #CRLF$ +
    "- `set limitsprites off` -- Turns off number of sprites per line limit")

  OMSXHelp_Add("master_volume",
    "Referencia de Comandos - Settings",
    "Controls the overall openMSX volume. The volume of individual sound devices can be controlled with the `<soundchip>_volume` settings." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set master_volume` -- Shows current setting" + #CRLF$ +
    "- `set master_volume 50` -- Sets master volume to 50%")

  OMSXHelp_Add("maxframeskip",
    "Referencia de Comandos - Settings",
    "Sets the maximum amount of frames to skip: show a frame and then skip at most <number> frames. So 0 means show everything (no frame skipping), 1 means show at least every second frame etc." + #CRLF$ +
    "" + #CRLF$ +
    "Frame skipping is done on demand, as a way to keep the flow of time for the emulated MSX in sync with the flow of real time. You can set limits on the amount of frame skipping with the `minframeskip` and `maxframeskip` setting." + #CRLF$ +
    "" + #CRLF$ +
    "In a situation where the number of consecutive frames specified by `maxframeskip` has been skipped, openMSX will display the next frame, even if that means emulation will start lagging behind real time." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set maxframeskip` -- Shows the current setting" + #CRLF$ +
    "- `set maxframeskip <number>` -- Sets the maximum number of consecutive frame skips")

  OMSXHelp_Add("midi-in-readfilename",
    "Referencia de Comandos - Settings",
    "Sets the file from which the MIDI input is read. By default, it is set to `/dev/midi` when available." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set midi-in-readfilename` -- Shows the current setting" + #CRLF$ +
    "- `set midi-in-readfilename mymidilog.dat` -- Read MIDI events from " + Chr(34) + "mymidilog.dat" + Chr(34))

  OMSXHelp_Add("midi-out-logfilename",
    "Referencia de Comandos - Settings",
    "Sets the file to which the MIDI output is logged. By default, it logs to `/dev/midi` when available." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set midi-out-logfilename` -- Shows the current setting" + #CRLF$ +
    "- `set midi-out-logfilename mymidilog.dat` -- Log MIDI events to " + Chr(34) + "mymidilog.dat" + Chr(34))

  OMSXHelp_Add("minframeskip",
    "Referencia de Comandos - Settings",
    "Sets the minimum amount of frames to skip: show a frame and then skip at least <number> frames." + #CRLF$ +
    "So 0 means no forced frame skipping, 1 means skip at least every second frame etc." + #CRLF$ +
    "" + #CRLF$ +
    "Frame skipping is done on demand, as a way to keep the flow of time for the emulated MSX in sync with the flow of real time. You can set limits on the amount of frame skipping with the `minframeskip` and `maxframeskip` setting." + #CRLF$ +
    "" + #CRLF$ +
    "The `minframeskip` setting can be useful if you want to ease the burden on your PC processor, for example for longer battery life on a laptop. It can also be useful if your PC is consistently too slow to run without frame skipping: in such cases video might be smoother with a low but constant frame rate than with a fluctuating frame rate." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set minframeskip` -- Shows the current setting" + #CRLF$ +
    "- `set minframeskip <number>` -- Sets the number of frame skips")

  OMSXHelp_Add("mode",
    "Referencia de Comandos - Settings",
    "Sets the active mode. A mode is a set of settings (mostly key bindings, but also OSD widgets that are activated) that are most suitable for a certain task. Currently only mode 'normal' and 'tas' exist." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set mode` -- Shows the current setting" + #CRLF$ +
    "- `set mode tas` -- Change mode to TAS mode" + #CRLF$ +
    "- `set mode normal` -- Set mode back to normal, which is the default (all purpose) mode" + #CRLF$ +
    "" + #CRLF$ +
    "## TAS mode" + #CRLF$ +
    "" + #CRLF$ +
    "So far, the only special mode is the TAS mode, which is made for doing Tool Assisted Speedruns, with TAS widgets and easier ways to save replays. It is still experimental, but already very useful for doing a TAS. This mode enables the following widgets:" + #CRLF$ +
    "" + #CRLF$ +
    "- frame counter (can also be toggled with `toggle_frame_counter`), which shows the VDP (not V9990) frame number on screen" + #CRLF$ +
    "- cursors (can also be toggled with `toggle_cursors`), shows which keys (important for games) are pressed" + #CRLF$ +
    "" + #CRLF$ +
    "The mode configures the following key bindings, overriding any existing key bindings (note: Mac key bindings are not proper yet...):" + #CRLF$ +
    "" + #CRLF$ +
    "**keys (PC) | keys (Mac) | function**" + #CRLF$ +
    "- F6 -- (F6) -- Load replay from current slot" + #CRLF$ +
    "- F7 -- (F7) -- Open slot select menu" + #CRLF$ +
    "- F8 -- (F8) -- Save replay to current slot" + #CRLF$ +
    "- End -- (End) -- Advance one frame (`advance_frame`)" + #CRLF$ +
    "- ScrollLock -- (ScrollLock) -- Reverse one frame (`reverse_frame`)" + #CRLF$ +
    "" + #CRLF$ +
    "Note that this mode may change in future releases!")

  OMSXHelp_Add("mute",
    "Referencia de Comandos - Settings",
    "Mute/unmute all sound output." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set mute` -- Shows the current setting" + #CRLF$ +
    "- `set mute on` -- Mute sound" + #CRLF$ +
    "- `set mute off` -- Unmute sound")

  OMSXHelp_Add("noise",
    "Referencia de Comandos - Settings",
    "Controls the amount of Gaussian noise that is added to the video output. A small amount of noise can give a more authentic look to the video output on TFTs. Values can be between 0 and 100, where 0 is no noise and 100 is lots of noise." + #CRLF$ +
    "" + #CRLF$ +
    "This setting is best combined with `brightness` and `contrast`: noise creates small random fluctuations in the brightness of pixels. When noise is applied to pure black, it is not possible to make it any darker, so half of the time the noise is ineffective. The same happens with pure white. By setting the `brightness` slightly above 0 and `contrast` slightly below 0, you will get a better looking noise effect." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set noise` -- Shows the current setting" + #CRLF$ +
    "- `set noise 7` -- Add a moderate amount of noise")

  OMSXHelp_Add("pause",
    "Referencia de Comandos - Settings",
    "Pauses the emulation." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set pause` -- Shows the current setting" + #CRLF$ +
    "- `set pause on` -- Pauses emulation" + #CRLF$ +
    "- `set pause off` -- Unpauses emulation" + #CRLF$ +
    "" + #CRLF$ +
    "Note: Some video settings cannot be applied to an already rendered frame and will therefore not take effect until openMSX is unpaused.")

  OMSXHelp_Add("pause_on_lost_focus",
    "Referencia de Comandos - Settings",
    "When this setting is enabled, the emulation will be paused when the" + #CRLF$ +
    "openMSX window loses focus." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set pause_on_lost_focus` -- Shows the current setting" + #CRLF$ +
    "- `set pause_on_lost_focus on` -- Emulation will be paused when the openMSX window loses focus" + #CRLF$ +
    "- `set pause_on_lost_focus off` -- Emulation will continue when the openMSX window loses focus (default)")

  OMSXHelp_Add("pointer_hide_delay",
    "Referencia de Comandos - Settings",
    "The amount of seconds before the mouse pointer will be automatically" + #CRLF$ +
    "hidden after it got shown due to mouse activity. A negative amount means that" + #CRLF$ +
    "it will never be hidden, an amount of 0 means that it will be always hidden." + #CRLF$ +
    "By default the pointer is hidden 1 second after the last mouse activity." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set pointer_hide_delay` -- Shows the current setting" + #CRLF$ +
    "- `set pointer_hide_delay -1` -- Never hide the mouse pointer" + #CRLF$ +
    "- `set pointer_hide_delay 0` -- Always hide the mouse pointer" + #CRLF$ +
    "- `set pointer_hide_delay 3.4` -- Hide the mouse pointer after 3.4 seconds of inactivity")

  OMSXHelp_Add("power",
    "Referencia de Comandos - Settings",
    "Turn the power of the emulated MSX machine on or off." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set power` -- Shows the current setting" + #CRLF$ +
    "- `set power on` -- Turns the MSX machine on (the default)" + #CRLF$ +
    "- `set power off` -- Turns the MSX machine off")

  OMSXHelp_Add("printerlogfilename",
    "Referencia de Comandos - Settings",
    "Sets the file to which the printer logger writes." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set printerlogfilename` -- Shows the current setting" + #CRLF$ +
    "- `set printerlogfilename myprinterlog.txt` -- Log to " + Chr(34) + "myprinterlog.txt" + Chr(34))

  OMSXHelp_Add("print-resolution",
    "Referencia de Comandos - Settings",
    "Sets the resolution (in dpi) for the emulated dot-matrix printer." + #CRLF$ +
    "" + #CRLF$ +
    "The emulated printer 'prints' pages as PNG files. This settings determines the resolution of those images." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set print-resolution` -- Shows the current setting" + #CRLF$ +
    "- `set print-resolution 600` -- Sets resolution to 600 dpi")

  OMSXHelp_Add("PSG_detune_frequency",
    "Referencia de Comandos - Settings",
    "Sets the frequency of the detune (a random variation in a sound's frequency) effect. It makes a sound fatter and more natural, as if played by a human being." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set PSG_detune_frequency` -- Shows the current setting" + #CRLF$ +
    "- `set PSG_detune_frequency <num>` -- Sets new detune frequency in Hz; 1 is minimum, 100 is maximum" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set PSG_detune_frequency`" + #CRLF$ +
    "`set PSG_detune_frequency 5` (default)" + #CRLF$ +
    "" + #CRLF$ +
    "Note: It is often more convenient to use the `psg_profile` command.")

  OMSXHelp_Add("psg_detune_percent",
    "Referencia de Comandos - Settings",
    "Sets the strength of the detune effect. By default it is 0, which means the effect is switched off." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set PSG_detune_percent` -- Shows the current setting" + #CRLF$ +
    "- `set PSG_detune_percent <num>` -- Sets new detune strength; 0 is minimum, 10 is maximum" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set PSG_detune_percent`" + #CRLF$ +
    "`set PSG_detune_percent 0` (switched off, default)" + #CRLF$ +
    "`set PSG_detune_percent 0.5` (recommended)" + #CRLF$ +
    "" + #CRLF$ +
    "Note: It is often more convenient to use the `psg_profile` command.")

  OMSXHelp_Add("PSG_vibrato_frequency",
    "Referencia de Comandos - Settings",
    "Sets the frequency of the vibrato (a periodic variation in a sound's frequency) effect." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set PSG_vibrato_frequency` -- Shows the current setting" + #CRLF$ +
    "- `set PSG_vibrato_frequency <num>` -- Sets new vibrato frequency in Hz; 1 is minimum, 10 is maximum" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set PSG_vibrato_frequency`" + #CRLF$ +
    "`set PSG_vibrato_frequency 5` (default)" + #CRLF$ +
    "" + #CRLF$ +
    "Note: It is often more convenient to use the `psg_profile` command.")

  OMSXHelp_Add("PSG_vibrato_percent",
    "Referencia de Comandos - Settings",
    "Sets the strength of the vibrato effect. By default it is 0, which means the effect is switched off." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set PSG_vibrato_percent` -- Shows the current setting" + #CRLF$ +
    "- `set PSG_vibrato_percent <num>` -- Sets new vibrato strength; 0 is minimum, 10 is maximum" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set PSG_vibrato_percent`" + #CRLF$ +
    "`set PSG_vibrato_percent 0` (switched off, default)" + #CRLF$ +
    "`set PSG_vibrato_percent 1` (recommended)" + #CRLF$ +
    "" + #CRLF$ +
    "Note: It is often more convenient to use the `psg_profile` command.")

  OMSXHelp_Add("r800_freq / r800_freq_locked",
    "Referencia de Comandos - Settings",
    "These two settings control the R800 clock frequency. See `z80_freq / z80_freq_locked` for details.")

  OMSXHelp_Add("renderer",
    "Referencia de Comandos - Settings",
    "Switch to a different video renderer. However, currently there is only one alternative: `none`, and that is useful only for disabling rendering in scripts completely." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set renderer` -- Shows the current setting" + #CRLF$ +
    "- `set renderer none` -- Disable rendering completely")

  OMSXHelp_Add("renshaturbo",
    "Referencia de Comandos - Settings",
    "Sets the speed of the built-in auto fire on some Japanese MSX models, for example the turboR machines. A value of 0 turns off auto fire, while 100 selects the most rapid auto fire." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set renshaturbo` -- Shows the current renshaturbo value" + #CRLF$ +
    "- `set renshaturbo <num>` -- Sets speed to value <num>" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This setting is only available if the current MSX machine has hardware Ren-Sha Turbo support.")

  OMSXHelp_Add("resampler",
    "Referencia de Comandos - Settings",
    "Sets the method to resample the sound of sound chips from their native frequency to the desired output frequency." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set resampler` -- Shows the currently active resampler" + #CRLF$ +
    "- `set resampler blip` -- Sets the Blip_Buffer (http://slack.net/~ant/libs/audio.html#Blip_Buffer) based resampler, which has the best quality per CPU usage ratio." + #CRLF$ +
    "- `set resampler hq` -- Sets the highest quality resampler, but it also takes the most CPU time. It's based on the libsamplerate (http://www.mega-nerd.com/SRC/) algorithm. This is the default value on most platforms, as it gives the best quality.")

  OMSXHelp_Add("rs232-inputfilename",
    "Referencia de Comandos - Settings",
    "Sets the file from which the RS232-tester reads data. Note that the" + #CRLF$ +
    "`rs232-tester` has to be plugged in the `msx-rs232`" + #CRLF$ +
    "connector for this to become useful. When plugging the tester, this setting" + #CRLF$ +
    "needs to point to a valid file." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set rs232-inputfilename` -- Shows the current setting" + #CRLF$ +
    "- `set rs232-inputfilename myrs232input.txt` -- Reads from " + Chr(34) + "myrs232input.txt" + Chr(34))

  OMSXHelp_Add("rs232-outputfilename",
    "Referencia de Comandos - Settings",
    "Sets the file to which the RS232-tester writes the data. Note that the" + #CRLF$ +
    "`rs232-tester` has to be plugged in the `msx-rs232`" + #CRLF$ +
    "connector for this to become useful. When plugging the tester, this setting" + #CRLF$ +
    "needs to point to a valid file." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set rs232-outputfilename` -- Shows the current setting" + #CRLF$ +
    "- `set rs232-outputfilename myrs232output.txt` -- Write to " + Chr(34) + "myrs232output.txt" + Chr(34))

  OMSXHelp_Add("rs232-net-address",
    "Referencia de Comandos - Settings",
    "Sets the ip address (or hostname) and port for the RS232-Net pluggable. Note that" + #CRLF$ +
    "`rs232-net` has to be plugged in the `msx-rs232`" + #CRLF$ +
    "connector for this to become useful. This setting" + #CRLF$ +
    "needs to point to a valid host at the moment of plugging it." + #CRLF$ +
    "" + #CRLF$ +
    "The address must follow one of the following syntaxes:" + #CRLF$ +
    "" + #CRLF$ +
    "- **hostname** e.g.: abc.com" + #CRLF$ +
    "- **hostname:port** e.g.: abc.com:23" + #CRLF$ +
    "- **ipv4** e.g.: 127.0.0.1" + #CRLF$ +
    "- **ipv4:port** e.g.: 127.0.0.1:2323" + #CRLF$ +
    "- **ipv6** e.g.: ::1" + #CRLF$ +
    "- **[ipv6]:port** e.g.: [::1]:8080" + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set rs232-net-address` -- Shows the current setting" + #CRLF$ +
    "- `set rs232-net-address mytelnetbbs.net:23` -- Connects to " + Chr(34) + "mytelnetbbs.net" + Chr(34) + " on port 23")

  OMSXHelp_Add("rs232-net-ip232",
    "Referencia de Comandos - Settings",
    "Enable the use of the IP232 protocol when used in conjunction with the `TCPSer` software modem. Note that" + #CRLF$ +
    "`rs232-net` has to be plugged in the `msx-rs232`" + #CRLF$ +
    "connector and `rs232-net-address` must point to the ip address and port of a running TCPSer instance." + #CRLF$ +
    "" + #CRLF$ +
    "The IP232 protocol permits the correct emulation of some of the RS-232 port control lines." + #CRLF$ +
    "" + #CRLF$ +
    "This setting must be disabled when using `rs232net` without `TCPSer`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set rs232-net-ip232` -- Shows the current setting" + #CRLF$ +
    "- `set rs232-net-ip232 on` -- Enable the IP232 protocol" + #CRLF$ +
    "- `set rs232-net-ip232 off` -- Disable the IP232 protocol")

  OMSXHelp_Add("rtcmode",
    "Referencia de Comandos - Settings",
    "Sets the Real Time Clock mode. Can be either `RealTime` or `EmuTime`." + #CRLF$ +
    "" + #CRLF$ +
    "In `RealTime` mode the MSX clock is always synchronized with the host clock, even when for example emulation is paused for a while or when emulation is run at 200% of real speed." + #CRLF$ +
    "" + #CRLF$ +
    "In `EmuTime` mode the time is only synchronized with the host clock when openMSX starts. From then on the clock ticks at the same pace as the emulated machine. So when emulation is paused, the clock is paused as well. If emulation is run at 200% speed, the clock also ticks twice as fast." + #CRLF$ +
    "" + #CRLF$ +
    "In `EmuTime` mode it's not possible for an MSX program to detect whether it's running on a real or on an emulated machine. That's why this is the default mode. On the other hand the `RealTime` mode might be better if for example you care that timestamps of files written by the emulated MSX machine are in sync with the host machine time." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set rtcmode` -- Shows the current mode" + #CRLF$ +
    "- `set rtcmode EmuTime` -- Set EmuTime mode (the default)" + #CRLF$ +
    "- `set rtcmode RealTime` -- Set RealTime mode")

  OMSXHelp_Add("samples",
    "Referencia de Comandos - Settings",
    "Sets the size of the sound mixer buffer. Higher values help against buffer underruns (hickups), but increase the latency of the sound output." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set samples` -- Shows the current setting" + #CRLF$ +
    "- `set samples 1024` -- Use a mixing buffer of 1024 samples")

  OMSXHelp_Add("save_settings_on_exit",
    "Referencia de Comandos - Settings",
    "Automatically save the current settings when openMSX exits: execute a `save_settings` command on exit." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set save_settings_on_exit` -- Show current setting" + #CRLF$ +
    "- `set save_settings_on_exit on` -- Enable auto save" + #CRLF$ +
    "- `set save_settings_on_exit off` -- Disable auto save")

  OMSXHelp_Add("save_setup_at_exit_name",
    "Referencia de Comandos - Settings",
    "Specify the setup name to use when automatically saving the setup when exiting openMSX is active. See also the `save_setup_at_exit_depth` setting." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI, under Main menu bar → Machine" + #CRLF$ +
    "→ Setup settings you can also configure what openMSX must do at startup, configuring this setting there." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set save_setup_at_exit_name` -- Show current setting" + #CRLF$ +
    "- `set save_setup_at_exit_name last_used` -- Set the setup name to be used for auto-save at exit to `last_used`")

  OMSXHelp_Add("save_setup_at_exit_depth",
    "Referencia de Comandos - Settings",
    "Specify the depth to use when automatically saving the setup when exiting openMSX. If the depth is set to `none` (which is the default), the auto-save is not active, but otherwise the setup will be saved under the name specified by the `save_setup_at_exit_name` setting. See also the `store_setup` command to find out about other depths that can be specified." + #CRLF$ +
    "" + #CRLF$ +
    "In the GUI, under Main menu bar → Machine" + #CRLF$ +
    "→ Setup settings you can also configure what openMSX must do at startup, configuring this setting there." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set save_setup_at_exit_depth` -- Show current setting" + #CRLF$ +
    "- `set save_setup_at_exit_depth extensions` -- When openMSX exits, the current setup is saved including all extensions in the machine." + #CRLF$ +
    "- `set save_setup_at_exit_depth complete_state` -- When openMSX exits, the complete state is saved into the setup." + #CRLF$ +
    "" + #CRLF$ +
    "**Nota:** If you enable this auto save of the setup and use the same name as for the `default_setup` setting, openMSX will automatically continue with the last setup when being started up again (and no other machine or setup is specified).")

  OMSXHelp_Add("scale_algorithm",
    "Referencia de Comandos - Settings",
    "Selects the algorithm used to transform MSX pixels to host pixels. The User's Manual contains more information about scalers." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set scale_algorithm` -- Shows the current setting" + #CRLF$ +
    "- `set scale_algorithm simple` -- Selects the default scale algorithm" + #CRLF$ +
    "- `set scale_algorithm hq` -- Selects the HQ2x/3x/4x scale algorithm")

  OMSXHelp_Add("scale_factor",
    "Referencia de Comandos - Settings",
    "Selects the scale factor. Scale factor <n> means the typical MSX pixel (MSX resolution 256×212) is mapped on <n> by <n> host pixels. For the moment the possible values are 2 to 4. In the future we may support a wider range or even non-integer values. The User's Manual contains more information about scalers." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set scale_factor` -- Shows the current setting" + #CRLF$ +
    "- `set scale_factor <n>` -- Sets a new scale factor")

  OMSXHelp_Add("scanline",
    "Referencia de Comandos - Settings",
    "Sets the amount of scanline effect." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set scanline` -- Shows the current setting" + #CRLF$ +
    "- `set scanline <value>` -- Changes the value" + #CRLF$ +
    "" + #CRLF$ +
    "Note: Some scalers will not render scanlines at all.")

  OMSXHelp_Add("sound_driver",
    "Referencia de Comandos - Settings",
    "Select the sound output driver." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set sound_driver sdl` -- Selects the SDL sound driver" + #CRLF$ +
    "- `set sound_driver null` -- Selects the null sound driver (no sound)")

  OMSXHelp_Add("speed",
    "Referencia de Comandos - Settings",
    "Sets the emulation speed relative to the speed of a real MSX. Speed 100 means as fast as a real MSX, lower values are slower than real MSX, higher values are faster than real MSX." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set speed` -- Shows current emulation speed" + #CRLF$ +
    "- `set speed <num>` -- Sets new emulation speed to <num>% of real time")

  OMSXHelp_Add("<soundchip>_balance",
    "Referencia de Comandos - Settings",
    "Sets the balance (distribution over the left and right channel) for individual sound chips. It replaces the previously available `<soundchip>_mode` setting. The range is between -100 (totally left) and 100 (totally right)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set <soundchip>_balance` -- Shows the current setting" + #CRLF$ +
    "- `set <soundchip>_balance 0` -- Plays the output of this chip on both the left and right channel" + #CRLF$ +
    "- `set <soundchip>_balance -100` -- Plays the output of this chip on only the left channel" + #CRLF$ +
    "- `set <soundchip>_balance 75` -- Plays the output of this chip mostly on the right channel, but also a bit on the left channel" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set PSG_balance`" + #CRLF$ +
    "`set PSG_balance -100`" + #CRLF$ +
    "`set FMPAC_balance 0`")

  OMSXHelp_Add("<soundchip>_ch<channel>_record",
    "Referencia de Comandos - Settings",
    "Sets the filename to which the sound of an individual channel of" + #CRLF$ +
    "individual sound chips should be recorded. When this setting is not set, no" + #CRLF$ +
    "recording takes place and recording starts as soon as the setting is set." + #CRLF$ +
    "Normally, you would probably prefer to use the `record_channels` command to set up channel" + #CRLF$ +
    "recording instead of this low level setting." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set <soundchip>_ch<channel>_record` -- Shows the current setting" + #CRLF$ +
    "- `set <soundchip>_ch<channel>_record filename` -- Starts recording the sound of the specified chip and channel to the file with name <filename>" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set SCC_ch1_record`" + #CRLF$ +
    "`set PSG_ch3_record /tmp/PSG_ch3.wav`")

  OMSXHelp_Add("<soundchip>_ch<channel>_mute",
    "Referencia de Comandos - Settings",
    "Use to mute a specific channel of an individual sound chip." + #CRLF$ +
    "Normally, you would probably prefer to use the `mute_channels` command to set up channel" + #CRLF$ +
    "muting instead of this low level setting." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set <soundchip>_ch<channel>_mute` -- Shows the current setting" + #CRLF$ +
    "- `set <soundchip>_ch<channel>_mute on` -- Mutes the sound of the specified channel of the specified chip" + #CRLF$ +
    "- `set <soundchip>_ch<channel>_mute off` -- Unmutes the sound of the specified channel of the specified chip" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set SCC_ch1_mute`" + #CRLF$ +
    "`set PSG_ch3_mute on`" + #CRLF$ +
    "`set SCC_ch5_mute off`")

  OMSXHelp_Add("<soundchip>_volume",
    "Referencia de Comandos - Settings",
    "Sets the volume for individual sound chips. The overall volume is controlled by the `master_volume` setting." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set <soundchip>_volume` -- Shows the current setting" + #CRLF$ +
    "- `set <soundchip>_volume <num>` -- Sets new volume; 0 is off, 100 is maximum" + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "`set PSG_volume`" + #CRLF$ +
    "`set PSG_volume 60`" + #CRLF$ +
    "`set " + Chr(34) + "FMPAC_volume" + Chr(34) + " 50`")

  OMSXHelp_Add("throttle",
    "Referencia de Comandos - Settings",
    "Sets throttle mode. In throttle mode the emulator tries to run at the specified speed relative to a real MSX (see `speed` command). When throttling is turned off the emulator runs as fast as possible." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set throttle` -- Shows the current setting" + #CRLF$ +
    "- `set throttle on` -- Turn throttle mode on (normal operation)" + #CRLF$ +
    "- `set throttle off` -- Turn throttle mode off (fast forward)")

  OMSXHelp_Add("too_fast_vram_access",
    "Referencia de Comandos - Settings",
    "How should software that accesses the VDP-VRAM too fast be emulated?" + #CRLF$ +
    "Most existing MSX software should not access VRAM too fast, and in that case" + #CRLF$ +
    "this setting has no effect. But you may want to change it when you e.g." + #CRLF$ +
    "emulate an overclocked Z80 (see `z80_freq`)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set too_fast_vram_access` -- Shows the current setting" + #CRLF$ +
    "- `set too_fast_vram_access real` -- Accessing the VRAM too fast results in dropped VRAM accesses, just like on a real machine." + #CRLF$ +
    "- `set too_fast_vram_access ignore` -- All VRAM accesses are executed, so timing of VRAM access is ignored.")

  OMSXHelp_Add("too_fast_vram_access_callback",
    "Referencia de Comandos - Settings",
    "Selects the Tcl procedure to be called when a too-fast-VRAM-access (read" + #CRLF$ +
    "or write) has been detected. This is useful for debugging MSX programs that" + #CRLF$ +
    "show certain kinds of VRAM corruption, especially on MSX1." + #CRLF$ +
    "" + #CRLF$ +
    "By default this setting is empty, which means that nothing is done when a" + #CRLF$ +
    "too-fast-VRAM-access is detected. We ship a few example procedures called" + #CRLF$ +
    "`warn_too_fast_vram_access` and" + #CRLF$ +
    "`debug_too_fast_vram_access` which respectively print a warning or" + #CRLF$ +
    "break CPU emulation when this condition occurs. You can find the source code" + #CRLF$ +
    "for these procedures in `scripts/callbackprocs.tcl`. Feel free to" + #CRLF$ +
    "write your own procedure that does exactly what you need." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set VDP.too_fast_vram_access_callback` -- Shows the currently installed callback" + #CRLF$ +
    "- `set VDP.too_fast_vram_access_callback warn_too_fast_vram_access` -- Print warning when too fast VRAM access is detected" + #CRLF$ +
    "- `set VDP.too_fast_vram_access_callback debug_too_fast_vram_access` -- Print warning and also break emulation right after the Z80 instruction that triggered this callback" + #CRLF$ +
    "- `set VDP.too_fast_vram_access_callback my_custom_callback_handler` -- Install a custom callback handler" + #CRLF$ +
    "- `set VDP.too_fast_vram_access_callback " + Chr(34) + Chr(34) + "` -- Remove any installed callback handler")

  OMSXHelp_Add("touchpad_transform_matrix",
    "Referencia de Comandos - Settings",
    "Specify a 2×3 transformation matrix that maps host mouse coordinates" + #CRLF$ +
    "to MSX touchpad coordinates." + #CRLF$ +
    "To get the following coordinate transformation:" + #CRLF$ +
    "" + #CRLF$ +
    "| a b c | | host-X | | touchpad-X |" + #CRLF$ +
    "| d e f | × | host-Y | = | touchpad-Y |" + #CRLF$ +
    "| 1 |" + #CRLF$ +
    "" + #CRLF$ +
    "Use this command:" + #CRLF$ +
    "" + #CRLF$ +
    "set touchpad_transform_matrix {{a b c} {d e f}}" + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set touchpad_transform_matrix` -- Shows the current value" + #CRLF$ +
    "- `set touchpad_transform_matrix {{256 0 0} {0 256 0}}` -- This is the default, map the full host window to 256×256 touchpad input" + #CRLF$ +
    "- `set touchpad_transform_matrix {{320 0 -64} {0 240 -14}}` -- Attempt to map touch coordinates to corresponding MSX pixel coordinates.")

  OMSXHelp_Add("turborpause",
    "Referencia de Comandos - Settings",
    "Controls the pause key on an MSX turboR machine." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set turborpause` -- Shows the current setting" + #CRLF$ +
    "- `set turborpause on` -- Activate the pause key" + #CRLF$ +
    "- `set turborpause off` -- Deactivate the pause key" + #CRLF$ +
    "" + #CRLF$ +
    "Note: If you use this setting often, it may be useful to bind it to a key on your PC keyboard. See the `bind` and `toggle` commands.")

  OMSXHelp_Add("umr_callback",
    "Referencia de Comandos - Settings",
    "Selects the Tcl procedure to be called when an Uninitialized Memory Read has been detected. This is useful for debugging MSX programs: uninitialized memory is not guaranteed to have any particular value, so reading it is most likely a bug." + #CRLF$ +
    "" + #CRLF$ +
    "By default this setting is empty, which means that nothing is done when an Uninitialized Memory Read is detected. We ship a useful procedure called `umrcallback` which logs all UMRs. You can activate it with `set umr_callback umrcallback`. You can find the source code for this procedure in `scripts/callbackprocs.tcl`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set umr_callback` -- Shows the current UMR callback setting" + #CRLF$ +
    "- `set umr_callback umrcallback` -- Sets callback proc to `umrcallback`")

  OMSXHelp_Add("vdpcmdinprogress_callback",
    "Referencia de Comandos - Settings",
    "Selects the Tcl procedure to be called when a write to a VDP command engine register is detected while there is still a VDP command in progress. Often this is an indication of a bug in the running MSX program. Note that writes to VDP register R#44 with a command in progress are normal behaviour, so the callback is not triggered for such writes." + #CRLF$ +
    "" + #CRLF$ +
    "By default this setting is empty, which means that nothing is done when a suspicious VDP command engine write is detected. We ship an example proc called `vdpcmdinprogresscallback` which simply logs all occurrences. You can activate it with `set vdpcmdinprogress_callback vdpcmdinprogresscallback`. You can find the source code for this proc in `scripts/callbackprocs.tcl`. Feel free to write your own proc that does exactly what you need. For example it might be a good idea to execute `debug break` in your callback, so that you can easily examine what code triggered this write." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set vdpcmdinprogress_callback` -- Shows the current value. Default is " + Chr(34) + Chr(34) + " (meaning no action)" + #CRLF$ +
    "- `set vdpcmdinprogress_callback vdpcmdinprogresscallback` -- Sets callback to `vdpcmdinprogresscallback`")

  OMSXHelp_Add("vdpcmdtrace",
    "Referencia de Comandos - Settings",
    "Enable/disable VDP command tracing. When enabled, every VDP command is logged on stdout. This is useful when debugging MSX programs that use the VDP command engine." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set vdpcmdtrace` -- Shows the current setting" + #CRLF$ +
    "- `set vdpcmdtrace on` -- Enables VDP command tracing" + #CRLF$ +
    "- `set vdpcmdtrace off` -- Disables VDP command tracing")

  OMSXHelp_Add("videosource",
    "Referencia de Comandos - Settings",
    "Switch between video sources: `MSX` (V99x8, default when no" + #CRLF$ +
    "Video 9000 is available), `GFX9000` (V9990)," + #CRLF$ +
    "`Video9000` (V9990 superimposed on top of V99x8, default if" + #CRLF$ +
    "available) and `Laserdisc` (for Palcom machines). There can be" + #CRLF$ +
    "even more video sources, e.g. offered by cartridges with a built-in VDP such as the Neos MA-20(V)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set videosource` -- Shows the current setting" + #CRLF$ +
    "- `set videosource MSX` -- Switch to normal MSX screen" + #CRLF$ +
    "- `set videosource GFX9000` -- Switch to GFX9000 screen" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This setting is only available if multiple video sources are present.")

  OMSXHelp_Add("vsync",
    "Referencia de Comandos - Settings",
    "Enables or disables vsync. This setting determines whether MSX frame rendering should be synchronized to your host monitors frame rate (e.g. 60fps)." + #CRLF$ +
    "" + #CRLF$ +
    "The default value is not to synchronize (" + Chr(34) + "`off`" + Chr(34) + "). When enabled, adaptive vsync is attempted if your hardware and driver support it, which means that if a frame is too late, it will be output immediately anyway. If not supported, normal vsync will be used, which may mean a frame is output later, when the sync is missed." + #CRLF$ +
    "" + #CRLF$ +
    "Enable this if your MSX is running at about the same frame rate as your monitor (e.g. 60Hz MSX output on a 60Hz host monitor) and you want to avoid (or reduce) tearing, which can be quite visible in smooth horizontal scrolling demos. Keep in mind throttle mode off works a bit differently if vsync is enabled (see there)." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set vsync` -- Shows the current setting" + #CRLF$ +
    "- `set vsync off` -- No synchronization to monitor frame rate: draw immediately" + #CRLF$ +
    "- `set vsync on` -- Synchronize to monitor frame rate when possible, otherwise draw immediately. Or, when this is not available on the host hardware/driver, synchronize to monitor frame rate always (default)")

  OMSXHelp_Add("v9990cmdtrace",
    "Referencia de Comandos - Settings",
    "Enable/disable V9990 command tracing. This is the V9990 equivalent of `vdpcmdtrace`." + #CRLF$ +
    "" + #CRLF$ +
    "**usage:**" + #CRLF$ +
    "" + #CRLF$ +
    "- `set v9990cmdtrace` -- Shows the current setting" + #CRLF$ +
    "- `set v9990cmdtrace on` -- Enables V9990 command tracing" + #CRLF$ +
    "- `set v9990cmdtrace off` -- Disables V9990 command tracing" + #CRLF$ +
    "" + #CRLF$ +
    "Note: This setting is only available if the `gfx9000` or" + #CRLF$ +
    "`video9000` extension is present.")

  OMSXHelp_Add("z80_freq / z80_freq_locked",
    "Referencia de Comandos - Settings",
    "These two settings control the Z80 clock frequency. When `z80_freq_locked` is true the emulated Z80 runs at the normal 3.579545 MHz (or possibly 5.369318 MHz on machines that are able to switch the CPU to 'turbo' mode, e.g. the Panasonic MSX2+ models). When `z80_freq_locked` is false the value of `z80_freq` is taken as the Z80 clock frequency. Note: the value of `z80_freq` is by default the MSX Z80 standard of 3579545, so when `z80_freq` is untouched, setting `z80_freq_locked` to false will set the clock frequency of a CPU in 5.37 Mhz turbo mode back to 3.58 Mhz." + #CRLF$ +
    "" + #CRLF$ +
    "WARNING: be careful when changing these settings. When saving the settings in which a different clock is activated, this will be applied for all machines, as these are global settings. Some software (like demos) may stop working properly with a changed CPU clock frequency. Specifically, using a value (just) below the normal value may cause problems loading CAS images, as these are converted to a high baud rate WAV file internally and when the MSX becomes slower it cannot handle that high baud rate." + #CRLF$ +
    "" + #CRLF$ +
    "**examples:**" + #CRLF$ +
    "" + #CRLF$ +
    "Overclock Z80 to 14 MHz:" + #CRLF$ +
    "`set z80_freq 14318180`" + #CRLF$ +
    "`set z80_freq_locked false`" + #CRLF$ +
    "F8 switches between 3.5 MHz and 7 MHz:" + #CRLF$ +
    "`set z80_freq 7159090`" + #CRLF$ +
    "`bind F8 " + Chr(34) + "toggle z80_freq_locked" + Chr(34) + "`")

  OMSXHelp_Add("other settings",
    "Referencia de Comandos - Settings",
    "Like with the commands, there are also some specialized settings, for which we only list a very brief overview. As always execute " + Chr(34) + "`help setting <setting-name>`" + Chr(34) + " to get a more detailed description of the setting." + #CRLF$ +
    "" + #CRLF$ +
    "- `fast_cas_load_hack_enabled` -- Enable a hack that lets you quickly load CAS files, without having openMSX convert them to WAV" + #CRLF$ +
    "" + #CRLF$ +
    "The source code of all these scripts is located in `share/scripts` directory. Feel free to inspect these scripts and modify them to suit your needs.")

EndProcedure


Procedure.s OMSXHelp_FullBody(RefIndex.i)
  If Not SelectElement(OMSXHelp_Topics(), RefIndex)
    ProcedureReturn ""
  EndIf
  ProcedureReturn "## " + OMSXHelp_Topics()\Titulo + #CRLF$ + #CRLF$ +
                  OMSXHelp_Topics()\Grupo + #CRLF$ + #CRLF$ +
                  OMSXHelp_Topics()\Corpo
EndProcedure

; Mesmo algoritmo de NBHelp_Slug (NestorBasicHelpData.pbi): minusculo,
; espaco vira hifen, so sobra a-z/0-9/hifen - usado pelos anchors do indice
; em OMSXHelp_ExportMarkdown().
Procedure.s OMSXHelp_Slug(Text.s)
  Protected Raw.s = ReplaceString(LCase(Text), " ", "-")
  Protected Clean.s = "", i, Ch.s
  For i = 1 To Len(Raw)
    Ch = Mid(Raw, i, 1)
    If (Ch >= "a" And Ch <= "z") Or (Ch >= "0" And Ch <= "9") Or Ch = "-"
      Clean + Ch
    EndIf
  Next
  ProcedureReturn Clean
EndProcedure

; Exporta todos os topicos como um unico Markdown de verdade
; (docs/reference/openmsx.md) - mesma fonte de dados da janela de ajuda
; (OMSXHelp_Topics()), mesma ideia de NBHelp_ExportMarkdown().
Procedure.b OMSXHelp_ExportMarkdown(Path.s)
  OMSXHelp_BuildData()

  Protected Text.s = "# openMSX - Referencia (Ajuda -> openMSX...)" + #CRLF$ + #CRLF$
  Text + "Gerado a partir dos 5 manuais originais do openMSX (docs/openmsx-*.html - Setup Guide, " +
         "User's Manual, Using Diskmanipulator, Controlling openMSX from External Applications, " +
         "Console Command Reference) e da mesma base de dados usada pela janela Ajuda -> openMSX... " +
         "do editor." + #CRLF$ + #CRLF$

  Text + "## Indice" + #CRLF$ + #CRLF$
  Protected LastGrupo.s = Chr(1)
  ForEach OMSXHelp_Topics()
    If OMSXHelp_Topics()\Grupo <> LastGrupo
      LastGrupo = OMSXHelp_Topics()\Grupo
      Text + "- [" + LastGrupo + "](#" + OMSXHelp_Slug(LastGrupo) + ")" + #CRLF$
    EndIf
  Next
  Text + #CRLF$

  LastGrupo = Chr(1)
  ForEach OMSXHelp_Topics()
    If OMSXHelp_Topics()\Grupo <> LastGrupo
      LastGrupo = OMSXHelp_Topics()\Grupo
      Text + "## " + LastGrupo + #CRLF$ + #CRLF$
    EndIf
    If OMSXHelp_Topics()\Titulo <> LastGrupo
      Text + "### " + OMSXHelp_Topics()\Titulo + #CRLF$ + #CRLF$
    EndIf
    Text + OMSXHelp_Topics()\Corpo + #CRLF$ + #CRLF$
  Next

  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  WriteString(FileNum, Text, #PB_UTF8)
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure
