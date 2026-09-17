package i18n

import (
	"testing"
)

func TestTranslations(t *testing.T) {
	langs := []string{"en", "pt", "es", "nl", "fr"}

	for _, lang := range langs {
		if !SetLanguage(lang) {
			t.Fatalf("Failed to set language %s", lang)
		}
		if GetLanguage() != lang {
			t.Fatalf("Expected language %s, got %s", lang, GetLanguage())
		}

		// Test key translations
		keys := []string{"menu_file", "menu_exit", "menu_setup", "menu_language", "menu_help", "menu_about", "btn_ok"}
		for _, k := range keys {
			trans := T(k)
			if trans == "" || trans == k {
				t.Fatalf("Missing translation for key %s in language %s", k, lang)
			}
		}
	}

	// Test fallback to English for unknown key
	SetLanguage("en")
	if T("unknown_test_key") != "unknown_test_key" {
		t.Fatalf("Expected unknown key to return itself")
	}
}
