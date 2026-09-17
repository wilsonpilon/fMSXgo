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
	{Code: "ja", Name: "Japanese", NativeName: "Nihongo (Japanese)"},
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
		"menu_reset":         "Reset Machine",
		"menu_exit":          "Exit",
		"menu_setup":         "Setup",
		"menu_language":      "Language",
		"menu_help":          "Help",
		"menu_about":         "About fMSXgo",

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
		"cli_quit_desc":      "Exit fMSXgo",
		"cli_lang_desc":      "View or set UI language (en, pt, es, nl, fr, ja)",
		"cli_regs_desc":      "View all registers, flags, and instruction at PC",
		"cli_setreg_desc":    "Set register value (e.g. 'r a 0xFF', 'r pc 0xC000')",
		"cli_dump_desc":      "Hexdump and ASCII memory display",
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
	},
	"pt": {
		// Menus
		"menu_file":          "Arquivo",
		"menu_reset":         "Reiniciar Máquina",
		"menu_exit":          "Sair",
		"menu_setup":         "Configuração",
		"menu_language":      "Idioma",
		"menu_help":          "Ajuda",
		"menu_about":         "Sobre o fMSXgo",

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
		"cli_quit_desc":      "Encerra o fMSXgo",
		"cli_lang_desc":      "Ver ou alterar idioma (en, pt, es, nl, fr, ja)",
		"cli_regs_desc":      "Exibe registradores, flags e instrução no PC",
		"cli_setreg_desc":    "Altera valor de registrador (ex: 'r a 0xFF', 'r pc 0xC000')",
		"cli_dump_desc":      "Exibe hexdump e ASCII da memória",
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
	},
	"es": {
		// Menus
		"menu_file":          "Archivo",
		"menu_reset":         "Reiniciar Máquina",
		"menu_exit":          "Salir",
		"menu_setup":         "Configuración",
		"menu_language":      "Idioma",
		"menu_help":          "Ayuda",
		"menu_about":         "Acerca de fMSXgo",

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
		"cli_quit_desc":      "Cierra fMSXgo",
		"cli_lang_desc":      "Ver o cambiar idioma (en, pt, es, nl, fr, ja)",
		"cli_regs_desc":      "Ver registros, banderas e instrucción en PC",
		"cli_setreg_desc":    "Modificar valor de registro (ej: 'r a 0xFF', 'r pc 0xC000')",
		"cli_dump_desc":      "Muestra volcado hexadecimal y ASCII",
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
	},
	"nl": {
		// Menus (Dutch - deeply tied to MSX history!)
		"menu_file":          "Bestand",
		"menu_reset":         "Herstart Machine",
		"menu_exit":          "Afsluiten",
		"menu_setup":         "Instellingen",
		"menu_language":      "Taal",
		"menu_help":          "Help",
		"menu_about":         "Over fMSXgo",

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
		"cli_quit_desc":      "Sluit fMSXgo af",
		"cli_lang_desc":      "Bekijk of wijzig taal (en, pt, es, nl, fr, ja)",
		"cli_regs_desc":      "Toon registers, vlaggen en instructie bij PC",
		"cli_setreg_desc":    "Stel registerwaarde in (bijv. 'r a 0xFF')",
		"cli_dump_desc":      "Geheugendump in hexadecimaal en ASCII",
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
	},
	"fr": {
		// Menus (French)
		"menu_file":          "Fichier",
		"menu_reset":         "Redémarrer Machine",
		"menu_exit":          "Quitter",
		"menu_setup":         "Configuration",
		"menu_language":      "Langue",
		"menu_help":          "Aide",
		"menu_about":         "À propos de fMSXgo",

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
		"cli_quit_desc":      "Quitte fMSXgo",
		"cli_lang_desc":      "Voir ou changer la langue (en, pt, es, nl, fr, ja)",
		"cli_regs_desc":      "Affiche les registres, drapeaux et instruction au PC",
		"cli_setreg_desc":    "Modifie la valeur d'un registre",
		"cli_dump_desc":      "Vidage hexadécimal et ASCII de la mémoire",
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
	},
	"ja": {
		// Menus (Japanese - Latin-1 compatible display representation for retro feel)
		"menu_file":          "File (Fairu)",
		"menu_reset":         "Reset Machine",
		"menu_exit":          "Exit (Shuuryou)",
		"menu_setup":         "Setup (Settei)",
		"menu_language":      "Language (Gengo)",
		"menu_help":          "Help (Tasukeru)",
		"menu_about":         "About (fMSXgo ni tsuite)",

		// About Dialog
		"about_title":        "ABOUT fMSXgo (Nihongo)",
		"about_app":          "fMSXgo - MSX Emulator & Dev Workstation",
		"about_version":      "Version",
		"about_core":         "Original Core: (C) Marat Fayzullin (fMSX)",
		"about_port":         "Go Port & Tools: (C) Wilson Pilon",
		"about_license":      "Strictly Non-Commercial Use Only",
		"btn_ok":             "  [ OK ]  ",

		// Screen Labels
		"lbl_title":          "=== fMSXgo - MSX Emulator & Kaihatsu Station ===",
		"lbl_model":          "Hardware Model :",
		"lbl_video":          "Video Standard :",
		"lbl_ram":            "Main RAM       :",
		"lbl_vram":           "VRAM           :",
		"lbl_cpu_state":      "--- Z80 CPU Joutai ---",
		"lbl_tips":           "Hinto (Tips):",
		"lbl_tip_exit":       " - 'File -> Exit' matawa [ESC] de shuuryou.",
		"lbl_tip_about":      " - 'Help -> About' de kurejitto to raisensu.",
		"lbl_tip_cli":        " - '--no-window' de CLI monitor wo kidou.",
		"lbl_tip_lang":       " - 'Setup -> Language' de gengo henkou.",

		// CLI
		"cli_welcome":        "fMSXgo - MSX Emulator & Kaihatsu Konsoru",
		"cli_help_hint":      "'HELP' de komando ichiran, 'a' de assembura, 't' de suteppu.",
		"cli_main_ctrls":     "Omo na Sousa (Main Controls):",
		"cli_help_desc":      "Komando ichiran to tasuke wo hyouji",
		"cli_quit_desc":      "fMSXgo wo shuuryou suru",
		"cli_lang_desc":      "Gengo no kakunin to henkou (en, pt, es, nl, fr, ja)",
		"cli_regs_desc":      "Rejisuta, furagu, PC meirei wo hyouji",
		"cli_setreg_desc":    "Rejisuta no chi wo henkou (rei: 'r a 0xFF')",
		"cli_dump_desc":      "Memori no 16-shinsuu to ASCII dasteppu",
		"cli_enter_desc":     "Memori ni baite wo chokusetsu kaki komi",
		"cli_dasm_desc":      "Gyaku-assemburu meirei",
		"cli_asm_desc":       "Mini-assembura moudo",
		"cli_step_desc":      "Suteppu jikkou (step-in)",
		"cli_next_desc":      "Suteppu oobaa (CALL/RST/DJNZ)",
		"cli_run_desc":       "Bureekupointo made jikkou",
		"cli_bp_desc":        "Bureekupointo no kanri",
		"cli_slots_desc":     "Surotto no wariate wo kenshou",
		"cli_mapper_desc":    "RAM mappaa no wariate wo kenshou",
		"cli_in_desc":        "I/O pooto kara baite wo yomi komi",
		"cli_out_desc":       "I/O pooto ni baite wo kaki komi",
		"cli_info_desc":      "Mashin no kousei wo hyouji",
		"cli_reset_desc":     "CPU to MSX haadowea wo risetto",
		"cli_cls_desc":       "Gamen wo kurea",
		"cli_lang_changed":   "Gengo ga henkou saremashita:",
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
