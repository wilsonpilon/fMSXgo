package i18n

import (
	"strings"
	"sync"
)

// Language definitions
type LanguageInfo struct {
	Code       string
	Name       string
	NativeName string
}

var SupportedLanguages = []LanguageInfo{
	{Code: "en", Name: "English", NativeName: "English"},
	{Code: "pt", Name: "Portuguese", NativeName: "Português"},
	{Code: "es", Name: "Spanish", NativeName: "Español"},
	{Code: "nl", Name: "Dutch", NativeName: "Nederlands"},
	{Code: "fr", Name: "French", NativeName: "Français"},
}

var (
	currentLang = "en"
	mu          sync.RWMutex
)

// Dictionary of localized strings
var translations = map[string]map[string]string{
	"en": {
		// Menus
		"menu_file":          "File",
		"menu_save_state":    "Save State... (F7)",
		"menu_load_state":    "Load State... (F8)",
		"menu_reset":         "Reset Machine",
		"menu_cli":           "Developer CLI",
		"menu_exit":          "Exit",
		"media_state_file":   "State Snapshot (.sta)",
		"menu_hardware":      "Hardware",
		"menu_setup":         "Setup",
		"menu_config":        "Configuration...",
		"menu_catalog":       "ROMs & HW Catalog...",
		"menu_language":      "Language",
		"menu_help":          "Help",
		"menu_about":         "About fMSXgo",

		// Video Display Menu
		"menu_video":         "Video",
		"video_scale_1":       "Scale 1:1 (256x212)",
		"video_scale_2":       "Scale 2:1 (512x424)",
		"video_scale_3":       "Scale 3:1 (768x636)",
		"video_scale_4":       "Scale 4:1 (1024x848)",
		"video_aspect_11":     "Aspect: 1:1 (Pixel Perfect)",
		"video_aspect_43":     "Aspect: 4:3 (CRT TV Standard)",
		"video_filter_smooth": "Bilinear Filter (Smooth)",

		// Media Management Menu
		"menu_media":         "Media",
		"media_drive_a":      "Floppy Drive A:",
		"media_drive_b":      "Floppy Drive B:",
		"media_cart_1":       "Cartridge Slot 1:",
		"media_cart_2":       "Cartridge Slot 2:",
		"media_tape":         "Cassette Tape:",
		"media_insert_dsk":   "Insert Disk (.dsk)...",
		"media_eject_dsk":    "Eject Disk",
		"media_insert_rom":   "Insert Cartridge (.rom)...",
		"media_eject_rom":    "Eject Cartridge",
		"media_insert_cas":   "Insert Tape (.cas)...",
		"media_eject_cas":    "Eject Tape",
		"media_rewind_cas":   "Rewind Tape to Start",
		"media_empty":        "[Empty]",
		"dlg_picker_title":   "SELECT MEDIA FILE",
		"btn_load":           "  [ Load / Mount ]  ",
		"btn_cancel":         "  [ Cancel ]  ",
		"lbl_parent_dir":     "[..] Up to Parent Directory",

		// Hardware Models
		"lbl_msx1":           "MSX 1 (TMS9918)",
		"lbl_msx2":           "MSX 2 (V9938)",
		"lbl_msx2p":          "MSX 2+ (V9958)",
		"lbl_ntsc":           "NTSC (60Hz)",
		"lbl_pal":            "PAL (50Hz)",
		"cli_model_desc":     "Inspect or switch MSX hardware model (msx1, msx2, msx2+)",
		"cli_model_changed":  "Hardware model changed to",

		// Configuration Dialog
		"dlg_config_title":   "CONFIGURATION & PREFERENCES",
		"cfg_sec_language":   "UI Language:",
		"cfg_sec_theme":      "Color Theme:",
		"cfg_sec_font":       "Typography / Font:",
		"cfg_cat_system":     "System",
		"cfg_cat_dark":       "Dark",
		"cfg_cat_light":      "Light",
		"btn_save_close":     "  [ Save & Close ]  ",

		// About Dialog
		"about_title":        "ABOUT fMSXgo",
		"about_app":          "fMSXgo - MSX Emulator & Dev Workstation",
		"about_version":      "Version",
		"about_core":         "Core Logic: (C) Marat Fayzullin (fMSX)",
		"about_port":         "Go Port & Tools: (C) Wilson Pilon",
		"about_license":      "Strictly Non-Commercial Use Only",
		"btn_ok":             "  [ OK ]  ",

		// Screen Labels
		"lbl_title":          "=== fMSXgo - MSX Emulator & Developer Workstation ===",
		"lbl_model":          "Hardware Model :",
		"lbl_video":          "Video Standard :",
		"lbl_ram":            "Main RAM       :",
		"lbl_vram":           "VRAM           :",
		"lbl_cpu_state":      "--- CPU Z80 Live State ---",
		"lbl_tips":           "Tips:",
		"lbl_tip_exit":       " - Click 'File -> Exit' or press [ESC] to quit.",
		"lbl_tip_about":      " - Click 'Help -> About' for credits & license.",
		"lbl_tip_cli":        " - Start with '--no-window' for interactive CLI monitor.",
		"lbl_tip_lang":       " - Change language in 'Setup -> Language'.",

		// CLI
		"cli_welcome":        "fMSXgo - MSX Emulator & Developer Console",
		"cli_help_hint":      "Type 'HELP' for commands, 'a' for mini-assembler, 't' to step.",
		"cli_main_ctrls":     "Main Controls:",
		"cli_help_desc":      "Display this command summary and help",
		"cli_quit_desc":      "Exit debugger monitor / fMSXgo (MegaAssembler: BA, Super-X: QT)",
		"cli_windows_desc":   "Launch / focus graphical window interface (GUI)",
		"cli_lang_desc":      "View or set UI language (en, pt, es, nl, fr)",
		"cli_regs_desc":      "View all registers, flags, and instruction at PC",
		"cli_setreg_desc":    "Set register value (e.g. 'r a 0xFF', 'r pc 0xC000')",
		"cli_dump_desc":      "Hexdump and ASCII memory display",
		"cli_dm_desc":        "Display & edit 128 bytes with optional displacement (MegaAssembler)",
		"cli_loaddsk_desc":   "Load disk image (.DSK) into memory / Drive A: (opens TUI browser if no file given)",
		"cli_diskcreate_desc": "Create and format a new MSX disk image (.DSK) (opens TUI save picker if no name given)",
		"cli_zap_desc":       "Edit disk sectors in memory (similar to DM, with displacement)",
		"cli_enter_desc":     "Enter raw hex bytes into memory",
		"cli_dasm_desc":      "Disassemble instructions",
		"cli_asm_desc":       "Mini-assembler mode (interactive or single-line)",
		"cli_step_desc":      "Trace / step n instructions",
		"cli_next_desc":      "Step over (CALL/RST/DJNZ)",
		"cli_run_desc":       "Run execution until breakpoint or halt",
		"cli_bp_desc":        "Manage breakpoints (add, del, clear, list)",
		"cli_slots_desc":     "Inspect primary/secondary slot allocations & pages",
		"cli_mapper_desc":    "Inspect RAM mapper state & bank allocations",
		"cli_in_desc":        "Read byte from I/O port",
		"cli_out_desc":       "Write byte to I/O port",
		"cli_info_desc":      "Display machine hardware configuration",
		"cli_reset_desc":     "Reset CPU and MSX hardware",
		"cli_cls_desc":       "Clear console screen",
		"cli_lang_changed":   "Language set to:",
		"cli_theme_desc":     "View or set UI theme (system, github-dark, dracula, etc.)",
		"cli_theme_changed":  "Theme set to:",
		"cli_roms_desc":      "Manage ROMs & hardware catalog in SQLite (list, info, add, default, del, export)",
		"dlg_catalog_title":  "ROMS & HARDWARE CATALOG (SQLite)",
		"cat_official_verified": "Official fMSX Verified (Guaranteed Execution)",
		"cat_sec_actions":    "Click ROM row to set as Default | [DEF] Default | [VER] Guaranteed",
	},
	"pt": {
		// Menus
		"menu_file":          "Arquivo",
		"menu_save_state":    "Salvar Estado... (F7)",
		"menu_load_state":    "Carregar Estado... (F8)",
		"menu_reset":         "Reiniciar Máquina",
		"menu_cli":           "Console CLI",
		"menu_exit":          "Sair",
		"media_state_file":   "Snapshot de Estado (.sta)",
		"menu_hardware":      "Hardware",
		"menu_setup":         "Configuração",
		"menu_config":        "Configurações...",
		"menu_catalog":       "Catálogo de ROMs & HW...",
		"menu_language":      "Idioma",
		"menu_help":          "Ajuda",
		"menu_about":         "Sobre o fMSXgo",

		// Video Display Menu
		"menu_video":         "Vídeo",
		"video_scale_1":       "Escala 1:1 (256x212)",
		"video_scale_2":       "Escala 2:1 (512x424)",
		"video_scale_3":       "Escala 3:1 (768x636)",
		"video_scale_4":       "Escala 4:1 (1024x848)",
		"video_aspect_11":     "Proporção: 1:1 (Pixel Perfeito)",
		"video_aspect_43":     "Proporção: 4:3 (Padrão TV CRT)",
		"video_filter_smooth": "Filtro Bilinear (Suave)",

		// Media Management Menu
		"menu_media":         "Mídia",
		"media_drive_a":      "Drive de Disquete A:",
		"media_drive_b":      "Drive de Disquete B:",
		"media_cart_1":       "Slot de Cartucho 1:",
		"media_cart_2":       "Slot de Cartucho 2:",
		"media_tape":         "Fita Cassete:",
		"media_insert_dsk":   "Inserir Disco (.dsk)...",
		"media_eject_dsk":    "Ejetar Disco",
		"media_insert_rom":   "Inserir Cartucho (.rom)...",
		"media_eject_rom":    "Ejetar Cartucho",
		"media_insert_cas":   "Inserir Fita (.cas)...",
		"media_eject_cas":    "Ejetar Fita",
		"media_rewind_cas":   "Rebobinar Fita ao Início",
		"media_empty":        "[Vazio]",
		"dlg_picker_title":   "SELECIONAR ARQUIVO DE MÍDIA",
		"btn_load":           "  [ Carregar / Montar ]  ",
		"btn_cancel":         "  [ Cancelar ]  ",
		"lbl_parent_dir":     "[..] Subir para Pasta Pai",

		// Hardware Models
		"lbl_msx1":           "MSX 1 (TMS9918)",
		"lbl_msx2":           "MSX 2 (V9938)",
		"lbl_msx2p":          "MSX 2+ (V9958)",
		"lbl_ntsc":           "NTSC (60Hz)",
		"lbl_pal":            "PAL (50Hz)",
		"cli_model_desc":     "Inspecionar ou alternar modelo de MSX (msx1, msx2, msx2+)",
		"cli_model_changed":  "Modelo de hardware alterado para",

		// Configuration Dialog
		"dlg_config_title":   "CONFIGURAÇÕES & PREFERÊNCIAS",
		"cfg_sec_language":   "Idioma da Interface:",
		"cfg_sec_theme":      "Tema de Cores:",
		"cfg_sec_font":       "Tipografia / Fonte:",
		"cfg_cat_system":     "Sistema",
		"cfg_cat_dark":       "Escuro",
		"cfg_cat_light":      "Claro",
		"btn_save_close":     "  [ Salvar & Fechar ]  ",

		// About Dialog
		"about_title":        "SOBRE O fMSXgo",
		"about_app":          "fMSXgo - Emulador MSX & Estação Dev",
		"about_version":      "Versão",
		"about_core":         "Núcleo Original: (C) Marat Fayzullin (fMSX)",
		"about_port":         "Porte em Go & Ferramentas: (C) Wilson Pilon",
		"about_license":      "Uso Estritamente Não-Comercial",
		"btn_ok":             "  [ OK ]  ",

		// Screen Labels
		"lbl_title":          "=== fMSXgo - Emulador MSX & Estação do Desenvolvedor ===",
		"lbl_model":          "Modelo de Hardware:",
		"lbl_video":          "Padrão de Vídeo   :",
		"lbl_ram":            "Memória RAM       :",
		"lbl_vram":           "VRAM              :",
		"lbl_cpu_state":      "--- Estado Z80 em Tempo Real ---",
		"lbl_tips":           "Dicas:",
		"lbl_tip_exit":       " - Clique em 'Arquivo -> Sair' ou [ESC] para encerrar.",
		"lbl_tip_about":      " - Clique em 'Ajuda -> Sobre' para créditos e licença.",
		"lbl_tip_cli":        " - Inicie com '--no-window' para o shell CLI interativo.",
		"lbl_tip_lang":       " - Mude o idioma em 'Configuração -> Idioma'.",

		// CLI
		"cli_welcome":        "fMSXgo - Console de Desenvolvimento & Emulador MSX",
		"cli_help_hint":      "Digite 'HELP' para comandos, 'a' para mini-montador, 't' para step.",
		"cli_main_ctrls":     "Controles Principais:",
		"cli_help_desc":      "Exibe este resumo de comandos e ajuda",
		"cli_quit_desc":      "Encerra o monitor debugger / fMSXgo (MegaAssembler: BA, Super-X: QT)",
		"cli_windows_desc":   "Abre a interface gráfica em janela (GUI)",
		"cli_lang_desc":      "Ver ou alterar idioma (en, pt, es, nl, fr)",
		"cli_regs_desc":      "Exibe registradores, flags e instrução no PC",
		"cli_setreg_desc":    "Altera valor de registrador (ex: 'r a 0xFF', 'r pc 0xC000')",
		"cli_dump_desc":      "Exibe hexdump e ASCII da memória",
		"cli_dm_desc":        "Exibe e edita 128 bytes com deslocamento opcional (MegaAssembler)",
		"cli_loaddsk_desc":   "Carrega imagem de disco (.DSK) na memória / Drive A: (abre navegador TUI se omitido)",
		"cli_diskcreate_desc": "Cria e formata uma nova imagem de disco (.DSK) (abre navegador TUI para escolher local se omitido)",
		"cli_zap_desc":       "Edita setores de disco na memória (similar ao DM, com deslocamento)",
		"cli_enter_desc":     "Grava bytes hexadecimais na memória",
		"cli_dasm_desc":      "Desmonta instruções a partir de um endereço",
		"cli_asm_desc":       "Modo mini-montador (interativo ou linha única)",
		"cli_step_desc":      "Executa passo a passo (step-in) n instruções",
		"cli_next_desc":      "Executa passo sobre (CALL/RST/DJNZ)",
		"cli_run_desc":       "Executa continuamente até breakpoint ou parada",
		"cli_bp_desc":        "Gerencia breakpoints (add, del, clear, list)",
		"cli_slots_desc":     "Inspeciona slots primários, secundários e páginas",
		"cli_mapper_desc":    "Inspeciona registradores do RAM Mapper",
		"cli_in_desc":        "Lê byte de uma porta I/O",
		"cli_out_desc":       "Escreve byte em uma porta I/O",
		"cli_info_desc":      "Exibe configuração da máquina",
		"cli_reset_desc":     "Reinicia a CPU e o hardware MSX",
		"cli_cls_desc":       "Limpa a tela do console",
		"cli_lang_changed":   "Idioma alterado para:",
		"cli_theme_desc":     "Ver ou alterar tema (system, github-dark, dracula, etc.)",
		"cli_theme_changed":  "Tema alterado para:",
		"cli_roms_desc":      "Gerenciar catálogo de ROMs e hardware no SQLite (list, info, add, default, del, export)",
		"dlg_catalog_title":  "CATÁLOGO DE ROMS & HARDWARE (SQLite)",
		"cat_official_verified": "Oficial fMSX Verificado (Garantia de Execução)",
		"cat_sec_actions":    "Clique para definir como Padrão | [DEF] Padrão | [VER] Garantida",
	},
	"es": {
		// Menus
		"menu_file":          "Archivo",
		"menu_save_state":    "Guardar Estado... (F7)",
		"menu_load_state":    "Cargar Estado... (F8)",
		"menu_reset":         "Reiniciar Máquina",
		"menu_cli":           "Consola CLI",
		"menu_exit":          "Salir",
		"media_state_file":   "Instantánea de Estado (.sta)",
		"menu_hardware":      "Hardware",
		"menu_setup":         "Configuración",
		"menu_config":        "Configuración...",
		"menu_catalog":       "Catálogo de ROMs y HW...",
		"menu_language":      "Idioma",
		"menu_help":          "Ayuda",
		"menu_about":         "Acerca de fMSXgo",

		// Video Display Menu
		"menu_video":         "Vídeo",
		"video_scale_1":       "Escala 1:1 (256x212)",
		"video_scale_2":       "Escala 2:1 (512x424)",
		"video_scale_3":       "Escala 3:1 (768x636)",
		"video_scale_4":       "Escala 4:1 (1024x848)",
		"video_aspect_11":     "Aspecto: 1:1 (Píxel Perfecto)",
		"video_aspect_43":     "Aspecto: 4:3 (Estándar TV CRT)",
		"video_filter_smooth": "Filtro Bilineal (Suave)",

		// Media Management Menu
		"menu_media":         "Medios",
		"media_drive_a":      "Disquetera A:",
		"media_drive_b":      "Disquetera B:",
		"media_cart_1":       "Ranura Cartucho 1:",
		"media_cart_2":       "Ranura Cartucho 2:",
		"media_tape":         "Cinta Casete:",
		"media_insert_dsk":   "Insertar Disco (.dsk)...",
		"media_eject_dsk":    "Expulsar Disco",
		"media_insert_rom":   "Insertar Cartucho (.rom)...",
		"media_eject_rom":    "Expulsar Cartucho",
		"media_insert_cas":   "Insertar Casete (.cas)...",
		"media_eject_cas":    "Expulsar Casete",
		"media_rewind_cas":   "Rebobinar Cinta",
		"media_empty":        "[Vacío]",
		"dlg_picker_title":   "SELECCIONAR ARCHIVO DE MEDIO",
		"btn_load":           "  [ Cargar / Montar ]  ",
		"btn_cancel":         "  [ Cancelar ]  ",
		"lbl_parent_dir":     "[..] Subir a Carpeta Superior",

		// Hardware Models
		"lbl_msx1":           "MSX 1 (TMS9918)",
		"lbl_msx2":           "MSX 2 (V9938)",
		"lbl_msx2p":          "MSX 2+ (V9958)",
		"lbl_ntsc":           "NTSC (60Hz)",
		"lbl_pal":            "PAL (50Hz)",
		"cli_model_desc":     "Inspeccionar o cambiar modelo de MSX (msx1, msx2, msx2+)",
		"cli_model_changed":  "Modelo de hardware cambiado a",

		// Configuration Dialog
		"dlg_config_title":   "CONFIGURACIÓN & PREFERENCIAS",
		"cfg_sec_language":   "Idioma de Interfaz:",
		"cfg_sec_theme":      "Tema de Colores:",
		"cfg_sec_font":       "Tipografía / Fuente:",
		"cfg_cat_system":     "Sistema",
		"cfg_cat_dark":       "Oscuro",
		"cfg_cat_light":      "Claro",
		"btn_save_close":     "  [ Guardar & Cerrar ]  ",

		// About Dialog
		"about_title":        "ACERCA DE fMSXgo",
		"about_app":          "fMSXgo - Emulador MSX & Estación Dev",
		"about_version":      "Versión",
		"about_core":         "Núcleo Original: (C) Marat Fayzullin (fMSX)",
		"about_port":         "Port en Go & Herramientas: (C) Wilson Pilon",
		"about_license":      "Uso Estrictamente No Comercial",
		"btn_ok":             "  [ OK ]  ",

		// Screen Labels
		"lbl_title":          "=== fMSXgo - Emulador MSX & Estación de Desarrollo ===",
		"lbl_model":          "Modelo Hardware :",
		"lbl_video":          "Estándar Video  :",
		"lbl_ram":            "Memoria RAM     :",
		"lbl_vram":           "VRAM            :",
		"lbl_cpu_state":      "--- Estado Z80 en Vivo ---",
		"lbl_tips":           "Consejos:",
		"lbl_tip_exit":       " - Clic en 'Archivo -> Salir' o [ESC] para cerrar.",
		"lbl_tip_about":      " - Clic en 'Ayuda -> Acerca de' para créditos y licencia.",
		"lbl_tip_cli":        " - Inicie con '--no-window' para consola CLI interactiva.",
		"lbl_tip_lang":       " - Cambie el idioma en 'Configuración -> Idioma'.",

		// CLI
		"cli_welcome":        "fMSXgo - Consola de Desarrollo & Emulador MSX",
		"cli_help_hint":      "Escriba 'HELP' para comandos, 'a' para mini-ensamblador, 't' para step.",
		"cli_main_ctrls":     "Controles Principales:",
		"cli_help_desc":      "Muestra este resumen de comandos y ayuda",
		"cli_quit_desc":      "Cerrar monitor debugger / fMSXgo (MegaAssembler: BA, Super-X: QT)",
		"cli_windows_desc":   "Abre la ventana gráfica (GUI)",
		"cli_lang_desc":      "Ver o cambiar idioma (en, pt, es, nl, fr)",
		"cli_regs_desc":      "Ver registros, banderas e instrucción en PC",
		"cli_setreg_desc":    "Modificar valor de registro (ej: 'r a 0xFF', 'r pc 0xC000')",
		"cli_dump_desc":      "Muestra volcado hexadecimal y ASCII",
		"cli_dm_desc":        "Muestra y edita 128 bytes con desplazamiento opcional (MegaAssembler)",
		"cli_loaddsk_desc":   "Carga imagen de disco (.DSK) en memoria / Drive A: (abre explorador TUI si se omite)",
		"cli_diskcreate_desc": "Crea y formatea una nueva imagen de disco (.DSK) (abre explorador TUI para elegir ubicación si se omite)",
		"cli_zap_desc":       "Edita sectores de disco en memoria (similar a DM, con desplazamiento)",
		"cli_enter_desc":     "Escribe bytes hexadecimales en memoria",
		"cli_dasm_desc":      "Desensambla instrucciones",
		"cli_asm_desc":       "Modo mini-ensamblador (interactivo o una línea)",
		"cli_step_desc":      "Ejecuta paso a paso n instrucciones",
		"cli_next_desc":      "Paso por encima (CALL/RST/DJNZ)",
		"cli_run_desc":       "Ejecuta hasta breakpoint o parada",
		"cli_bp_desc":        "Administra puntos de interrupción",
		"cli_slots_desc":     "Inspecciona slots primarios y secundarios",
		"cli_mapper_desc":    "Inspecciona registros de RAM Mapper",
		"cli_in_desc":        "Lee byte de un puerto I/O",
		"cli_out_desc":       "Escribe byte en un puerto I/O",
		"cli_info_desc":      "Muestra configuración de la máquina",
		"cli_reset_desc":     "Reinicia CPU y hardware MSX",
		"cli_cls_desc":       "Limpia la pantalla",
		"cli_lang_changed":   "Idioma cambiado a:",
		"cli_theme_desc":     "Ver o cambiar tema (system, github-dark, dracula, etc.)",
		"cli_theme_changed":  "Tema cambiado a:",
		"cli_roms_desc":      "Administrar catálogo de ROMs y hardware en SQLite (list, info, add, default, del, export)",
		"dlg_catalog_title":  "CATÁLOGO DE ROMS Y HARDWARE (SQLite)",
		"cat_official_verified": "Oficial fMSX Verificado (Garantía de Ejecución)",
		"cat_sec_actions":    "Clic para definir como Predeterminado | [DEF] Activo | [VER] Garantizada",
	},
	"nl": {
		// Menus (Dutch - deeply tied to MSX history!)
		"menu_file":          "Bestand",
		"menu_save_state":    "Staat Opslaan... (F7)",
		"menu_load_state":    "Staat Laden... (F8)",
		"menu_reset":         "Herstart Machine",
		"menu_cli":           "CLI Console",
		"menu_exit":          "Afsluiten",
		"media_state_file":   "Staat Snapshot (.sta)",
		"menu_hardware":      "Hardware",
		"menu_setup":         "Instellingen",
		"menu_config":        "Instellingen...",
		"menu_catalog":       "ROMs & Hardware Catalogus...",
		"menu_language":      "Taal",
		"menu_help":          "Help",
		"menu_about":         "Over fMSXgo",

		// Video Display Menu
		"menu_video":         "Video",
		"video_scale_1":       "Schaal 1:1 (256x212)",
		"video_scale_2":       "Schaal 2:1 (512x424)",
		"video_scale_3":       "Schaal 3:1 (768x636)",
		"video_scale_4":       "Schaal 4:1 (1024x848)",
		"video_aspect_11":     "Beeldverhouding: 1:1 (Pixel Perfect)",
		"video_aspect_43":     "Beeldverhouding: 4:3 (CRT TV)",
		"video_filter_smooth": "Bilineair Filter (Vloeiend)",

		// Media Management Menu
		"menu_media":         "Media",
		"media_drive_a":      "Diskettestation A:",
		"media_drive_b":      "Diskettestation B:",
		"media_cart_1":       "Cartridge Sleuf 1:",
		"media_cart_2":       "Cartridge Sleuf 2:",
		"media_tape":         "Cassetteband:",
		"media_insert_dsk":   "Diskette Plaatsen (.dsk)...",
		"media_eject_dsk":    "Diskette Uitwerpen",
		"media_insert_rom":   "Cartridge Plaatsen (.rom)...",
		"media_eject_rom":    "Cartridge Uitwerpen",
		"media_insert_cas":   "Cassetteband Plaatsen (.cas)...",
		"media_eject_cas":    "Cassetteband Uitwerpen",
		"media_rewind_cas":   "Band Terugspoelen",
		"media_empty":        "[Leeg]",
		"dlg_picker_title":   "SELECTEER MEDIABESTAND",
		"btn_load":           "  [ Laden / Koppelen ]  ",
		"btn_cancel":         "  [ Annuleren ]  ",
		"lbl_parent_dir":     "[..] Naar Bovenliggende Map",

		// Hardware Models
		"lbl_msx1":           "MSX 1 (TMS9918)",
		"lbl_msx2":           "MSX 2 (V9938)",
		"lbl_msx2p":          "MSX 2+ (V9958)",
		"lbl_ntsc":           "NTSC (60Hz)",
		"lbl_pal":            "PAL (50Hz)",
		"cli_model_desc":     "MSX hardware model bekijken of wijzigen (msx1, msx2, msx2+)",
		"cli_model_changed":  "Hardware model gewijzigd naar",

		// Configuration Dialog
		"dlg_config_title":   "INSTELLINGEN & VOORKEUREN",
		"cfg_sec_language":   "Interfacetaal:",
		"cfg_sec_theme":      "Kleurthema:",
		"cfg_sec_font":       "Typografie / Lettertype:",
		"cfg_cat_system":     "Systeem",
		"cfg_cat_dark":       "Donker",
		"cfg_cat_light":      "Licht",
		"btn_save_close":     "  [ Opslaan & Sluiten ]  ",

		// About Dialog
		"about_title":        "OVER fMSXgo",
		"about_app":          "fMSXgo - MSX Emulator & Ontwikkelstation",
		"about_version":      "Versie",
		"about_core":         "Originele Core: (C) Marat Fayzullin (fMSX)",
		"about_port":         "Go Port & Gereedschappen: (C) Wilson Pilon",
		"about_license":      "Uitsluitend Niet-Commercieel Gebruik",
		"btn_ok":             "  [ OK ]  ",

		// Screen Labels
		"lbl_title":          "=== fMSXgo - MSX Emulator & Ontwikkelaar Werkstation ===",
		"lbl_model":          "Hardware Model :",
		"lbl_video":          "Videostandaard  :",
		"lbl_ram":            "Hoofdgeheugen   :",
		"lbl_vram":           "VRAM            :",
		"lbl_cpu_state":      "--- Z80 CPU Status ---",
		"lbl_tips":           "Tips:",
		"lbl_tip_exit":       " - Klik op 'Bestand -> Afsluiten' of druk op [ESC].",
		"lbl_tip_about":      " - Klik op 'Help -> Over fMSXgo' voor credits en licentie.",
		"lbl_tip_cli":        " - Start met '--no-window' voor CLI-ontwikkelconsole.",
		"lbl_tip_lang":       " - Wijzig taal in 'Instellingen -> Taal'.",

		// CLI
		"cli_welcome":        "fMSXgo - MSX Emulator & Ontwikkelconsole",
		"cli_help_hint":      "Typ 'HELP' voor opdrachten, 'a' voor assembler, 't' voor stap.",
		"cli_main_ctrls":     "Hoofdbesturing:",
		"cli_help_desc":      "Toont dit overzicht van opdrachten",
		"cli_quit_desc":      "Verlaat debugger monitor / fMSXgo (MegaAssembler: BA, Super-X: QT)",
		"cli_windows_desc":   "Open grafisch venster (GUI)",
		"cli_lang_desc":      "Bekijk of wijzig taal (en, pt, es, nl, fr)",
		"cli_regs_desc":      "Toon registers, vlaggen en instructie bij PC",
		"cli_setreg_desc":    "Stel registerwaarde in (bijv. 'r a 0xFF')",
		"cli_dump_desc":      "Geheugendump in hexadecimaal en ASCII",
		"cli_dm_desc":        "Toon en bewerk 128 bytes met optionele verplaatsing (MegaAssembler)",
		"cli_loaddsk_desc":   "Laad schijfkopie (.DSK) in geheugen / Drive A: (opent TUI-browser als leeg)",
		"cli_diskcreate_desc": "Maak en formatteer een nieuwe MSX-schijfkopie (.DSK) (opent TUI-browser als leeg)",
		"cli_zap_desc":       "Bewerk schijfsectoren in geheugen (zoals DM, met verschuiving)",
		"cli_enter_desc":     "Schrijf hex-bytes rechtstreeks naar het geheugen",
		"cli_dasm_desc":      "Decompileer instructies",
		"cli_asm_desc":       "Mini-assembler modus",
		"cli_step_desc":      "Voer stap voor stap n instructies uit",
		"cli_next_desc":      "Stap over aanroepen (CALL/RST/DJNZ)",
		"cli_run_desc":       "Blijf uitvoeren tot breekpunt",
		"cli_bp_desc":        "Beheer breekpunten",
		"cli_slots_desc":     "Inspecteer primaire en secundaire slots",
		"cli_mapper_desc":    "Inspecteer RAM-mapper toewijzingen",
		"cli_in_desc":        "Lees byte van I/O-poort",
		"cli_out_desc":       "Schrijf byte naar I/O-poort",
		"cli_info_desc":      "Toon machineconfiguratie",
		"cli_reset_desc":     "Herstart CPU en hardware",
		"cli_cls_desc":       "Wis consolevenster",
		"cli_lang_changed":   "Taal gewijzigd in:",
		"cli_theme_desc":     "Bekijk of wijzig thema (system, github-dark, etc.)",
		"cli_theme_changed":  "Thema gewijzigd naar:",
		"cli_roms_desc":      "Beheer ROM- en hardwarecatalogus in SQLite (list, info, add, default, del, export)",
		"dlg_catalog_title":  "ROMS & HARDWARE CATALOGUS (SQLite)",
		"cat_official_verified": "Officieel fMSX Geverifieerd (Gegarandeerde Werking)",
		"cat_sec_actions":    "Klik om als Standaard in te stellen | [DEF] Standaard | [VER] Gegarandeerd",
	},
	"fr": {
		// Menus (French)
		"menu_file":          "Fichier",
		"menu_save_state":    "Sauvegarder l'état... (F7)",
		"menu_load_state":    "Charger l'état... (F8)",
		"menu_reset":         "Redémarrer Machine",
		"menu_cli":           "Console CLI",
		"menu_exit":          "Quitter",
		"media_state_file":   "Instantané d'état (.sta)",
		"menu_hardware":      "Matériel",
		"menu_setup":         "Configuration",
		"menu_config":        "Paramètres...",
		"menu_catalog":       "Catalogue ROMs & Matériel...",
		"menu_language":      "Langue",
		"menu_help":          "Aide",
		"menu_about":         "À propos de fMSXgo",

		// Video Display Menu
		"menu_video":         "Vidéo",
		"video_scale_1":       "Échelle 1:1 (256x212)",
		"video_scale_2":       "Échelle 2:1 (512x424)",
		"video_scale_3":       "Échelle 3:1 (768x636)",
		"video_scale_4":       "Échelle 4:1 (1024x848)",
		"video_aspect_11":     "Format: 1:1 (Pixel Parfait)",
		"video_aspect_43":     "Format: 4:3 (Standard TV CRT)",
		"video_filter_smooth": "Filtre Bilinéaire (Lisse)",

		// Media Management Menu
		"menu_media":         "Média",
		"media_drive_a":      "Lecteur Disquette A:",
		"media_drive_b":      "Lecteur Disquette B:",
		"media_cart_1":       "Port Cartouche 1:",
		"media_cart_2":       "Port Cartouche 2:",
		"media_tape":         "Bande Cassette:",
		"media_insert_dsk":   "Insérer Disquette (.dsk)...",
		"media_eject_dsk":    "Éjecter Disquette",
		"media_insert_rom":   "Insérer Cartouche (.rom)...",
		"media_eject_rom":    "Éjecter Cartouche",
		"media_insert_cas":   "Insérer Cassette (.cas)...",
		"media_eject_cas":    "Éjecter Cassette",
		"media_rewind_cas":   "Rembobiner la Bande",
		"media_empty":        "[Vide]",
		"dlg_picker_title":   "SÉLECTIONNER UN FICHIER",
		"btn_load":           "  [ Charger / Monter ]  ",
		"btn_cancel":         "  [ Annuler ]  ",
		"lbl_parent_dir":     "[..] Dossier Parent",

		// Hardware Models
		"lbl_msx1":           "MSX 1 (TMS9918)",
		"lbl_msx2":           "MSX 2 (V9938)",
		"lbl_msx2p":          "MSX 2+ (V9958)",
		"lbl_ntsc":           "NTSC (60Hz)",
		"lbl_pal":            "PAL (50Hz)",
		"cli_model_desc":     "Inspecter ou changer le modèle matériel MSX (msx1, msx2, msx2+)",
		"cli_model_changed":  "Modèle matériel changé en",

		// Configuration Dialog
		"dlg_config_title":   "CONFIGURATION & PRÉFÉRENCES",
		"cfg_sec_language":   "Langue de l'interface:",
		"cfg_sec_theme":      "Thème de Couleurs:",
		"cfg_sec_font":       "Typographie / Police:",
		"cfg_cat_system":     "Système",
		"cfg_cat_dark":       "Sombre",
		"cfg_cat_light":      "Clair",
		"btn_save_close":     "  [ Enregistrer & Fermer ]  ",

		// About Dialog
		"about_title":        "À PROPOS DE fMSXgo",
		"about_app":          "fMSXgo - Émulateur MSX & Station Dev",
		"about_version":      "Version",
		"about_core":         "Cœur Original: (C) Marat Fayzullin (fMSX)",
		"about_port":         "Portage Go & Outils: (C) Wilson Pilon",
		"about_license":      "Usage Strictement Non Commercial",
		"btn_ok":             "  [ OK ]  ",

		// Screen Labels
		"lbl_title":          "=== fMSXgo - Émulateur MSX & Station de Développement ===",
		"lbl_model":          "Modèle Hardware :",
		"lbl_video":          "Standard Vidéo  :",
		"lbl_ram":            "Mémoire RAM     :",
		"lbl_vram":           "VRAM            :",
		"lbl_cpu_state":      "--- État Z80 en Direct ---",
		"lbl_tips":           "Astuces:",
		"lbl_tip_exit":       " - Cliquez sur 'Fichier -> Quitter' ou [ESC] pour fermer.",
		"lbl_tip_about":      " - Cliquez sur 'Aide -> À propos' pour crédits et licence.",
		"lbl_tip_cli":        " - Lancez avec '--no-window' pour la console CLI interactive.",
		"lbl_tip_lang":       " - Changez la langue dans 'Configuration -> Langue'.",

		// CLI
		"cli_welcome":        "fMSXgo - Console de Développement & Émulateur MSX",
		"cli_help_hint":      "Tapez 'HELP' pour les commandes, 'a' pour assembleur, 't' pour pas.",
		"cli_main_ctrls":     "Contrôles Principaux:",
		"cli_help_desc":      "Affiche ce résumé des commandes et l'aide",
		"cli_quit_desc":      "Quitter le débogueur / fMSXgo (MegaAssembler: BA, Super-X: QT)",
		"cli_windows_desc":   "Ouvrir la fenêtre graphique (GUI)",
		"cli_lang_desc":      "Voir ou changer la langue (en, pt, es, nl, fr)",
		"cli_regs_desc":      "Affiche les registres, drapeaux et instruction au PC",
		"cli_setreg_desc":    "Modifie la valeur d'un registre",
		"cli_dump_desc":      "Vidage hexadécimal et ASCII de la mémoire",
		"cli_dm_desc":        "Affiche et modifie 128 octets avec déplacement optionnel (MegaAssembler)",
		"cli_loaddsk_desc":   "Charge l'image disque (.DSK) en mémoire / Lecteur A: (ouvre le navigateur TUI si omis)",
		"cli_diskcreate_desc": "Crée et formate une nouvelle image disque (.DSK) (ouvre le navigateur TUI pour choisir l'emplacement si omis)",
		"cli_zap_desc":       "Édite les secteurs de disque en mémoire (comme DM, avec décalage)",
		"cli_enter_desc":     "Écrit des octets hexadécimaux en mémoire",
		"cli_dasm_desc":      "Désassemble les instructions",
		"cli_asm_desc":       "Mode mini-assembleur",
		"cli_step_desc":      "Exécute pas à pas n instructions",
		"cli_next_desc":      "Passe par-dessus (CALL/RST/DJNZ)",
		"cli_run_desc":       "Exécute jusqu'au point d'arrêt",
		"cli_bp_desc":        "Gère les points d'arrêt",
		"cli_slots_desc":     "Inspecte les slots primaires et secondaires",
		"cli_mapper_desc":    "Inspecte les allocations de la mémoire mappée",
		"cli_in_desc":        "Lit un octet sur un port I/O",
		"cli_out_desc":       "Écrit un octet sur un port I/O",
		"cli_info_desc":      "Affiche la configuration de la machine",
		"cli_reset_desc":     "Réinitialise la CPU et le matériel",
		"cli_cls_desc":       "Efface la console",
		"cli_lang_changed":   "Langue modifiée en:",
		"cli_theme_desc":     "Voir ou changer le thème (system, github-dark, etc.)",
		"cli_theme_changed":  "Thème modifié en:",
		"cli_roms_desc":      "Gérer le catalogue de ROMs et matériel en SQLite (list, info, add, default, del, export)",
		"dlg_catalog_title":  "CATALOGUE DE ROMS & MATÉRIEL (SQLite)",
		"cat_official_verified": "Officiel fMSX Vérifié (Exécution Garantie)",
		"cat_sec_actions":    "Cliquez pour définir par défaut | [DEF] Défaut | [VER] Garantie",
	},
}

// T translates a key into the currently active language.
func T(key string) string {
	mu.RLock()
	defer mu.RUnlock()

	if dict, ok := translations[currentLang]; ok {
		if val, found := dict[key]; found {
			return val
		}
	}
	// Fallback to English
	if dict, ok := translations["en"]; ok {
		if val, found := dict[key]; found {
			return val
		}
	}
	return key
}

// SetLanguage changes the current language if supported.
func SetLanguage(code string) bool {
	code = strings.ToLower(strings.TrimSpace(code))
	for _, l := range SupportedLanguages {
		if strings.ToLower(l.Code) == code || strings.ToLower(l.Name) == code {
			mu.Lock()
			currentLang = l.Code
			mu.Unlock()
			return true
		}
	}
	return false
}

// GetLanguage returns the current language code.
func GetLanguage() string {
	mu.RLock()
	defer mu.RUnlock()
	return currentLang
}

// GetLanguageName returns the human-readable native name for the current language.
func GetLanguageName() string {
	mu.RLock()
	defer mu.RUnlock()
	for _, l := range SupportedLanguages {
		if l.Code == currentLang {
			return l.NativeName
		}
	}
	return "English"
}
