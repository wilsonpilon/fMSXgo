package storage

import (
	"crypto/sha1"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

// ROMInfo contains metadata about a ROM stored in the database.
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

// StoreROM saves a ROM image into the database.
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
	query := `SELECT 1 FROM roms WHERE name = ? LIMIT 1`
	err := db.conn.QueryRow(query, name).Scan(&exists)
	return err == nil
}

// ListROMs returns metadata for all ROMs stored in the database.
func (db *DB) ListROMs() ([]ROMInfo, error) {
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

// SeedFromROMDir populates the database with ROMs found in the given directory.
func (db *DB) SeedFromROMDir(dir string) (int, error) {
	type romMeta struct {
		name    string
		romType string
		model   string
	}

	targets := []romMeta{
		{"MSX.ROM", "machine_bios", "MSX1"},
		{"MSX2.ROM", "machine_bios", "MSX2"},
		{"MSX2EXT.ROM", "sub_bios", "MSX2"},
		{"MSX2P.ROM", "machine_bios", "MSX2+"},
		{"MSX2PEXT.ROM", "sub_bios", "MSX2+"},
		{"DISK.ROM", "disk_bios", "ALL"},
		{"FMPAC.ROM", "extension", "ALL"},
		{"PAINTER.ROM", "cartridge", "ALL"},
	}

	imported := 0
	for _, t := range targets {
		candidate := filepath.Join(dir, t.name)
		data, err := os.ReadFile(candidate)
		if err == nil {
			if err := db.StoreROM(t.name, t.romType, t.model, data); err == nil {
				imported++
			}
		}
	}
	return imported, nil
}
