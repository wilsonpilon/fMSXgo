package storage

import (
	"crypto/sha1"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	_ "modernc.org/sqlite"
)

// ROMCatalogItem represents a registered ROM in the database catalog with full metadata.
type ROMCatalogItem struct {
	ID           int64  `json:"id"`
	Name         string `json:"name"`          // Unique filename / identifier, e.g. "MSX2.ROM"
	Title        string `json:"title"`         // Friendly display name, e.g. "MSX 2 Main BIOS & BASIC"
	Category     string `json:"category"`      // "bios", "basic", "disk", "subrom", "hardware", "cartridge"
	MachineModel string `json:"machine_model"` // "MSX1", "MSX2", "MSX2+", "ALL"
	Size         int    `json:"size"`
	SHA1         string `json:"sha1"`
	Description  string `json:"description"`
	IsDefault    bool   `json:"is_default"`    // True if active default for this slot/model
	IsVerified   bool   `json:"is_verified"`   // True if official fMSX / guaranteed execution
	CreatedAt    string `json:"created_at"`
}

// ROMInfo contains legacy metadata about a ROM stored in the database.
type ROMInfo struct {
	ID           int
	Name         string
	ROMType      string // machine_bios, sub_bios, disk_bios, cartridge
	MachineModel string // MSX1, MSX2, MSX2+, ALL
	Size         int
	SHA1         string
}

// DB encapsulates the SQLite connection and persistence operations for fMSXgo.
type DB struct {
	conn *sql.DB
	Path string
}

// Open initializes or opens the SQLite database at the specified file path.
func Open(path string) (*DB, error) {
	if dir := filepath.Dir(path); dir != "" && dir != "." {
		os.MkdirAll(dir, 0755)
	}

	conn, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, fmt.Errorf("failed to open sqlite db at %s: %w", path, err)
	}

	db := &DB{
		conn: conn,
		Path: path,
	}

	if err := db.initSchema(); err != nil {
		conn.Close()
		return nil, err
	}

	return db, nil
}

// Close closes the database connection.
func (db *DB) Close() error {
	if db.conn != nil {
		return db.conn.Close()
	}
	return nil
}

// initSchema creates the database tables if they do not exist.
func (db *DB) initSchema() error {
	schema := `
	CREATE TABLE IF NOT EXISTS rom_catalog (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT UNIQUE NOT NULL,
		title TEXT NOT NULL,
		category TEXT NOT NULL,
		machine_model TEXT NOT NULL,
		size INTEGER NOT NULL,
		sha1 TEXT NOT NULL,
		description TEXT,
		is_default BOOLEAN DEFAULT 0,
		is_verified BOOLEAN DEFAULT 0,
		data BLOB NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS roms (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT UNIQUE NOT NULL,
		rom_type TEXT NOT NULL,
		machine_model TEXT NOT NULL,
		size INTEGER NOT NULL,
		sha1 TEXT,
		data BLOB NOT NULL
	);

	CREATE TABLE IF NOT EXISTS config (
		key TEXT PRIMARY KEY,
		value TEXT NOT NULL
	);

	CREATE TABLE IF NOT EXISTS manuals (
		topic TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		content TEXT NOT NULL
	);

	CREATE TABLE IF NOT EXISTS machine_profiles (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		model INTEGER NOT NULL,
		video INTEGER NOT NULL,
		ram_pages INTEGER NOT NULL,
		vram_pages INTEGER NOT NULL,
		main_rom TEXT,
		sub_rom TEXT,
		disk_rom TEXT
	);
	`
	_, err := db.conn.Exec(schema)
	return err
}

// ---------------------------------------------------------------------
// ROM Catalog CRUD Operations
// ---------------------------------------------------------------------

// StoreCatalogROM saves or updates a ROM in the catalog with full metadata.
func (db *DB) StoreCatalogROM(item ROMCatalogItem, data []byte) error {
	if strings.TrimSpace(item.Name) == "" {
		return fmt.Errorf("ROM name cannot be empty")
	}
	if strings.TrimSpace(item.Title) == "" {
		item.Title = item.Name
	}
	if strings.TrimSpace(item.Category) == "" {
		item.Category = "bios"
	}
	if strings.TrimSpace(item.MachineModel) == "" {
		item.MachineModel = "ALL"
	}
	h := sha1.Sum(data)
	item.SHA1 = fmt.Sprintf("%x", h)
	item.Size = len(data)

	// If marked as default, clear any other default in the same category & machine model
	if item.IsDefault {
		_ = db.clearDefault(item.Category, item.MachineModel)
	}

	query := `
	INSERT INTO rom_catalog (name, title, category, machine_model, size, sha1, description, is_default, is_verified, data)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	ON CONFLICT(name) DO UPDATE SET
		title = excluded.title,
		category = excluded.category,
		machine_model = excluded.machine_model,
		size = excluded.size,
		sha1 = excluded.sha1,
		description = excluded.description,
		is_default = excluded.is_default,
		is_verified = excluded.is_verified,
		data = excluded.data;
	`
	_, err := db.conn.Exec(query,
		item.Name, item.Title, item.Category, item.MachineModel,
		item.Size, item.SHA1, item.Description, item.IsDefault, item.IsVerified, data,
	)
	return err
}

// GetCatalogItem retrieves a ROM's catalog metadata by its unique name.
func (db *DB) GetCatalogItem(name string) (*ROMCatalogItem, error) {
	query := `SELECT id, name, title, category, machine_model, size, sha1, description, is_default, is_verified, created_at FROM rom_catalog WHERE name = ?`
	var item ROMCatalogItem
	var desc sql.NullString
	var createdAt sql.NullString
	err := db.conn.QueryRow(query, name).Scan(
		&item.ID, &item.Name, &item.Title, &item.Category, &item.MachineModel,
		&item.Size, &item.SHA1, &desc, &item.IsDefault, &item.IsVerified, &createdAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("ROM %q not found in catalog", name)
	}
	if err != nil {
		return nil, err
	}
	item.Description = desc.String
	item.CreatedAt = createdAt.String
	return &item, nil
}

// GetCatalogData retrieves the raw binary data (BLOB) for a catalog ROM.
func (db *DB) GetCatalogData(name string) ([]byte, error) {
	var data []byte
	query := `SELECT data FROM rom_catalog WHERE name = ?`
	err := db.conn.QueryRow(query, name).Scan(&data)
	if err == nil && len(data) > 0 {
		return data, nil
	}
	// Fallback to legacy roms table
	return db.GetROM(name)
}

// ListCatalog returns all ROMs matching optional category and model filters.
func (db *DB) ListCatalog(categoryFilter, modelFilter string) ([]ROMCatalogItem, error) {
	query := `SELECT id, name, title, category, machine_model, size, sha1, description, is_default, is_verified, created_at FROM rom_catalog WHERE 1=1`
	var args []any
	if categoryFilter != "" && strings.ToLower(categoryFilter) != "all" {
		query += " AND LOWER(category) = ?"
		args = append(args, strings.ToLower(categoryFilter))
	}
	if modelFilter != "" && strings.ToUpper(modelFilter) != "ALL" {
		query += " AND (UPPER(machine_model) = ? OR UPPER(machine_model) = 'ALL')"
		args = append(args, strings.ToUpper(modelFilter))
	}
	query += " ORDER BY category ASC, machine_model ASC, name ASC"

	rows, err := db.conn.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []ROMCatalogItem
	for rows.Next() {
		var item ROMCatalogItem
		var desc sql.NullString
		var createdAt sql.NullString
		if err := rows.Scan(
			&item.ID, &item.Name, &item.Title, &item.Category, &item.MachineModel,
			&item.Size, &item.SHA1, &desc, &item.IsDefault, &item.IsVerified, &createdAt,
		); err != nil {
			return nil, err
		}
		item.Description = desc.String
		item.CreatedAt = createdAt.String
		list = append(list, item)
	}
	return list, nil
}

// UpdateCatalogItem updates user-editable metadata fields for an existing ROM.
func (db *DB) UpdateCatalogItem(name, title, description, category, model string) error {
	query := `UPDATE rom_catalog SET title = ?, description = ?, category = ?, machine_model = ? WHERE name = ?`
	res, err := db.conn.Exec(query, title, description, category, model, name)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("ROM %q not found in catalog", name)
	}
	return nil
}

// SetCatalogDefault sets a ROM as active default for its category and machine model.
func (db *DB) SetCatalogDefault(name string) error {
	item, err := db.GetCatalogItem(name)
	if err != nil {
		return err
	}
	_ = db.clearDefault(item.Category, item.MachineModel)

	query := `UPDATE rom_catalog SET is_default = 1 WHERE name = ?`
	_, err = db.conn.Exec(query, name)
	return err
}

func (db *DB) clearDefault(category, model string) error {
	query := `UPDATE rom_catalog SET is_default = 0 WHERE category = ? AND (machine_model = ? OR machine_model = 'ALL')`
	_, err := db.conn.Exec(query, category, model)
	return err
}

// DeleteCatalogROM removes a ROM from the catalog.
// If force is false, it protects verified official default system ROMs from accidental deletion.
func (db *DB) DeleteCatalogROM(name string, force bool) error {
	item, err := db.GetCatalogItem(name)
	if err != nil {
		return err
	}
	if item.IsVerified && item.IsDefault && !force {
		return fmt.Errorf("ROM %q is an official verified default system ROM. Use force=true to delete", name)
	}

	query := `DELETE FROM rom_catalog WHERE name = ?`
	_, err = db.conn.Exec(query, name)
	return err
}

// GetDefaultROM retrieves the active default ROM for a specific category and machine model.
func (db *DB) GetDefaultROM(category, machineModel string) (*ROMCatalogItem, []byte, error) {
	query := `SELECT id, name, title, category, machine_model, size, sha1, description, is_default, is_verified, created_at, data
	          FROM rom_catalog WHERE category = ? AND (machine_model = ? OR machine_model = 'ALL') AND is_default = 1 LIMIT 1`
	var item ROMCatalogItem
	var desc sql.NullString
	var createdAt sql.NullString
	var data []byte
	err := db.conn.QueryRow(query, category, machineModel).Scan(
		&item.ID, &item.Name, &item.Title, &item.Category, &item.MachineModel,
		&item.Size, &item.SHA1, &desc, &item.IsDefault, &item.IsVerified, &createdAt, &data,
	)
	if err != nil {
		return nil, nil, err
	}
	item.Description = desc.String
	item.CreatedAt = createdAt.String
	return &item, data, nil
}

// ---------------------------------------------------------------------
// Legacy Compatibility API & Helpers
// ---------------------------------------------------------------------

// StoreROM saves a ROM image into the database (legacy support).
func (db *DB) StoreROM(name, romType, machineModel string, data []byte) error {
	h := sha1.Sum(data)
	sha1Str := fmt.Sprintf("%x", h)

	query := `
	INSERT INTO roms (name, rom_type, machine_model, size, sha1, data)
	VALUES (?, ?, ?, ?, ?, ?)
	ON CONFLICT(name) DO UPDATE SET
		rom_type = excluded.rom_type,
		machine_model = excluded.machine_model,
		size = excluded.size,
		sha1 = excluded.sha1,
		data = excluded.data;
	`
	_, err := db.conn.Exec(query, name, romType, machineModel, len(data), sha1Str, data)
	return err
}

// GetROM retrieves a ROM's binary data by its name.
func (db *DB) GetROM(name string) ([]byte, error) {
	var data []byte
	// 1. Check rom_catalog first
	queryCat := `SELECT data FROM rom_catalog WHERE name = ?`
	if err := db.conn.QueryRow(queryCat, name).Scan(&data); err == nil && len(data) > 0 {
		return data, nil
	}
	// 2. Check legacy roms table
	query := `SELECT data FROM roms WHERE name = ?`
	err := db.conn.QueryRow(query, name).Scan(&data)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("ROM %q not found in SQLite database", name)
	}
	return data, err
}

// HasROM checks whether a ROM is already registered in the database.
func (db *DB) HasROM(name string) bool {
	var exists int
	queryCat := `SELECT 1 FROM rom_catalog WHERE name = ? LIMIT 1`
	if err := db.conn.QueryRow(queryCat, name).Scan(&exists); err == nil {
		return true
	}
	query := `SELECT 1 FROM roms WHERE name = ? LIMIT 1`
	err := db.conn.QueryRow(query, name).Scan(&exists)
	return err == nil
}

// ListROMs returns metadata for all ROMs stored in the database.
func (db *DB) ListROMs() ([]ROMInfo, error) {
	// Query rom_catalog first
	catItems, err := db.ListCatalog("all", "all")
	if err == nil && len(catItems) > 0 {
		var res []ROMInfo
		for _, c := range catItems {
			res = append(res, ROMInfo{
				ID:           int(c.ID),
				Name:         c.Name,
				ROMType:      c.Category,
				MachineModel: c.MachineModel,
				Size:         c.Size,
				SHA1:         c.SHA1,
			})
		}
		return res, nil
	}

	query := `SELECT id, name, rom_type, machine_model, size, sha1 FROM roms ORDER BY name`
	rows, err := db.conn.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var res []ROMInfo
	for rows.Next() {
		var r ROMInfo
		if err := rows.Scan(&r.ID, &r.Name, &r.ROMType, &r.MachineModel, &r.Size, &r.SHA1); err != nil {
			return nil, err
		}
		res = append(res, r)
	}
	return res, nil
}

// SetConfig sets a key-value configuration pair.
func (db *DB) SetConfig(key, val string) error {
	query := `INSERT INTO config (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value`
	_, err := db.conn.Exec(query, key, val)
	return err
}

// GetConfig gets a configuration value or returns fallback default.
func (db *DB) GetConfig(key, defaultVal string) string {
	var val string
	query := `SELECT value FROM config WHERE key = ?`
	err := db.conn.QueryRow(query, key).Scan(&val)
	if err != nil {
		return defaultVal
	}
	return val
}

// StoreManual saves manual/help topic content.
func (db *DB) StoreManual(topic, title, content string) error {
	query := `INSERT INTO manuals (topic, title, content) VALUES (?, ?, ?) ON CONFLICT(topic) DO UPDATE SET title = excluded.title, content = excluded.content`
	_, err := db.conn.Exec(query, topic, title, content)
	return err
}

// GetManual retrieves a manual topic.
func (db *DB) GetManual(topic string) (title string, content string, err error) {
	query := `SELECT title, content FROM manuals WHERE topic = ?`
	err = db.conn.QueryRow(query, topic).Scan(&title, &content)
	return
}

// SeedFromROMDir populates the catalog with official fMSX standard ROMs found in the given directory.
// All official bundled ROMs are tagged as Default and Guaranteed Execution (is_verified = true).
func (db *DB) SeedFromROMDir(dir string) (int, error) {
	type officialMeta struct {
		name        string
		title       string
		category    string
		model       string
		isDefault   bool
		isVerified  bool
		description string
	}

	officialROMs := []officialMeta{
		{
			name:        "MSX.ROM",
			title:       "MSX 1 Standard BIOS & BASIC",
			category:    "bios",
			model:       "MSX1",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 MSX1 Main BIOS and BASIC interpreter. Guaranteed execution.",
		},
		{
			name:        "MSX2.ROM",
			title:       "MSX 2 Main BIOS & BASIC",
			category:    "bios",
			model:       "MSX2",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 MSX2 Main BIOS and BASIC interpreter. Guaranteed execution.",
		},
		{
			name:        "MSX2EXT.ROM",
			title:       "MSX 2 SubROM / ExtBIOS",
			category:    "subrom",
			model:       "MSX2",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 MSX2 SubROM and extended BIOS routines. Guaranteed execution.",
		},
		{
			name:        "MSX2P.ROM",
			title:       "MSX 2+ Main BIOS & BASIC",
			category:    "bios",
			model:       "MSX2+",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 MSX2+ Main BIOS and BASIC interpreter. Guaranteed execution.",
		},
		{
			name:        "MSX2PEXT.ROM",
			title:       "MSX 2+ SubROM / ExtBIOS",
			category:    "subrom",
			model:       "MSX2+",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 MSX2+ SubROM and extended BIOS routines. Guaranteed execution.",
		},
		{
			name:        "DISK.ROM",
			title:       "Standard MSX-DOS Disk ROM",
			category:    "disk",
			model:       "ALL",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 Floppy Disk Controller & MSX-DOS Disk Interface. Guaranteed execution.",
		},
		{
			name:        "FMPAC.ROM",
			title:       "FM-PAC (MSX-MUSIC / YM2413) Sound Hardware",
			category:    "hardware",
			model:       "ALL",
			isDefault:   true,
			isVerified:  true,
			description: "Official fMSX 6.0 FM-PAC / MSX-MUSIC synthesizer expansion ROM. Guaranteed execution.",
		},
		{
			name:        "KANJI.ROM",
			title:       "Japanese Kanji Font Hardware ROM",
			category:    "hardware",
			model:       "ALL",
			isDefault:   false,
			isVerified:  true,
			description: "Official fMSX 6.0 JIS Level 1 & 2 Kanji Font ROM. Guaranteed execution.",
		},
		{
			name:        "PAINTER.ROM",
			title:       "MSX Painter Graphic Tool Cartridge",
			category:    "cartridge",
			model:       "MSX2",
			isDefault:   false,
			isVerified:  true,
			description: "Bundled MSX2 Painter demonstration application cartridge. Guaranteed execution.",
		},
	}

	imported := 0
	for _, o := range officialROMs {
		candidate := filepath.Join(dir, o.name)
		data, err := os.ReadFile(candidate)
		if err == nil {
			item := ROMCatalogItem{
				Name:         o.name,
				Title:        o.title,
				Category:     o.category,
				MachineModel: o.model,
				IsDefault:    o.isDefault,
				IsVerified:   o.isVerified,
				Description:  o.description,
			}
			if err := db.StoreCatalogROM(item, data); err == nil {
				// Also mirror into legacy roms table for full compatibility
				_ = db.StoreROM(o.name, o.category, o.model, data)
				imported++
			}
		}
	}
	return imported, nil
}
