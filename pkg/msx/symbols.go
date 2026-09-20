package msx

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
)

// SymbolEntry represents a resolved symbol name and its 16-bit address.
type SymbolEntry struct {
	Name string
	Addr uint16
}

// SymbolTable maintains bidirectional mappings between names and 16-bit addresses.
type SymbolTable struct {
	mu          sync.RWMutex
	AddrToNames map[uint16][]string
	NameToAddr  map[string]uint16
}

// NewSymbolTable creates an initialized SymbolTable instance.
func NewSymbolTable() *SymbolTable {
	st := &SymbolTable{
		AddrToNames: make(map[uint16][]string),
		NameToAddr:  make(map[string]uint16),
	}
	st.loadStandardMSXBIOSSymbols()
	return st
}

// loadStandardMSXBIOSSymbols seeds well-known MSX BIOS routines for instant developer clarity.
func (st *SymbolTable) loadStandardMSXBIOSSymbols() {
	standard := map[string]uint16{
		"RDSLT":  0x000C,
		"WRSLT":  0x0014,
		"CALSLT": 0x001C,
		"ENASLT": 0x0024,
		"CALLF":  0x0030,
		"KEYINT": 0x0038,
		"INITIO": 0x003B,
		"INIFNK": 0x003E,
		"DISSCR": 0x0041,
		"ENASCR": 0x0044,
		"WRTVDP": 0x0047,
		"VDPTR":  0x004A,
		"WRTVRM": 0x004D,
		"VPOKE":  0x004D,
		"RDVRM":  0x0050,
		"VPEEK":  0x0050,
		"SETRD":  0x0053,
		"SETWRT": 0x0056,
		"FILVRM": 0x0059,
		"LDIRMV": 0x005C,
		"LDIRVM": 0x005F,
		"CHGMOD": 0x0062,
		"CHGCLR": 0x0065,
		"NMI":    0x0066,
		"CLRSPR": 0x0069,
		"INITXT": 0x006C,
		"INIT32": 0x006F,
		"INIGRP": 0x0072,
		"INIMLT": 0x0075,
		"SETTXT": 0x0078,
		"SETT32": 0x007B,
		"SETGRP": 0x007E,
		"SETMLT": 0x0081,
		"CALPAT": 0x0084,
		"CALATR": 0x0087,
		"GSPSIZ": 0x008A,
		"GRPPRT": 0x008D,
		"GICINI": 0x0090,
		"WRTPSG": 0x0093,
		"RDPSG":  0x0096,
		"STRTMS": 0x0099,
		"CHSNS":  0x009C,
		"CHGET":  0x009F,
		"CHPUT":  0x00A2,
		"LPTOUT": 0x00A5,
		"LPTSTT": 0x00A8,
		"CNVCHR": 0x00AB,
		"PINLIN": 0x00AE,
		"INLIN":  0x00B1,
		"QINLIN": 0x00B4,
		"BREAKX": 0x00B7,
		"BEEP":   0x00C0,
		"CLS":    0x00C3,
		"POSIT":  0x00C6,
		"FNKSB":  0x00C9,
		"ERAFNK": 0x00CC,
		"DSPFNK": 0x00CF,
		"TOTEXT": 0x00D2,
		"GTSTCK": 0x00D5,
		"GTTRIG": 0x00D8,
		"GTPAD":  0x00DB,
		"GTPDL":  0x00DE,
		"TAPION": 0x00E1,
		"TAPIN":  0x00E4,
		"TAPIOF": 0x00E7,
		"TAPOON": 0x00EA,
		"TAPOUT": 0x00ED,
		"TAPOOF": 0x00F0,
		"STMOTR": 0x00F3,
		"LFTQ":   0x00F6,
		"PUTQ":   0x00F9,
		"RIGHTC": 0x00FC,
		"LEFTC":  0x00FF,
		"UPC":    0x0102,
		"TUPC":   0x0105,
		"DOWNC":  0x0108,
		"TDOWNC": 0x010B,
		"SCALXY": 0x010E,
		"MAPXY":  0x0111,
		"FETCHC": 0x0114,
		"STOREC": 0x0117,
		"SETATR": 0x011A,
		"READC":  0x011D,
		"SETC":   0x0120,
		"NSETC":  0x0123,
		"CHGVRM": 0x0126,
		"CHGVR2": 0x0129,
		"NVBINT": 0x012C,
		"NVRINT": 0x012F,
	}
	for name, addr := range standard {
		st.Add(name, addr)
	}
}

// Add associates a symbol name with an address.
func (st *SymbolTable) Add(name string, addr uint16) {
	st.mu.Lock()
	defer st.mu.Unlock()

	upper := strings.ToUpper(strings.TrimSpace(name))
	if upper == "" {
		return
	}

	st.NameToAddr[upper] = addr
	list := st.AddrToNames[addr]
	for _, exist := range list {
		if exist == upper {
			return
		}
	}
	st.AddrToNames[addr] = append(list, upper)
}

// Lookup returns the primary symbol name for an address, if defined.
func (st *SymbolTable) Lookup(addr uint16) (string, bool) {
	st.mu.RLock()
	defer st.mu.RUnlock()

	names, ok := st.AddrToNames[addr]
	if !ok || len(names) == 0 {
		return "", false
	}
	return names[0], true
}

// LookupAll returns all symbol names associated with an address.
func (st *SymbolTable) LookupAll(addr uint16) []string {
	st.mu.RLock()
	defer st.mu.RUnlock()

	names, ok := st.AddrToNames[addr]
	if !ok {
		return nil
	}
	res := make([]string, len(names))
	copy(res, names)
	return res
}

// Find returns the address of a given symbol name.
func (st *SymbolTable) Find(name string) (uint16, bool) {
	st.mu.RLock()
	defer st.mu.RUnlock()

	addr, ok := st.NameToAddr[strings.ToUpper(strings.TrimSpace(name))]
	return addr, ok
}

// FormatAnnotation returns formatted annotation e.g. " <CHPUT>" or "" if not found.
func (st *SymbolTable) FormatAnnotation(addr uint16) string {
	if name, ok := st.Lookup(addr); ok {
		return fmt.Sprintf(" <%s>", name)
	}
	return ""
}

// List returns all symbols matching the optional case-insensitive substring filter.
func (st *SymbolTable) List(filter string) []SymbolEntry {
	st.mu.RLock()
	defer st.mu.RUnlock()

	filter = strings.ToUpper(strings.TrimSpace(filter))
	var entries []SymbolEntry
	for name, addr := range st.NameToAddr {
		if filter == "" || strings.Contains(name, filter) {
			entries = append(entries, SymbolEntry{Name: name, Addr: addr})
		}
	}

	sort.Slice(entries, func(i, j int) bool {
		if entries[i].Addr != entries[j].Addr {
			return entries[i].Addr < entries[j].Addr
		}
		return entries[i].Name < entries[j].Name
	})
	return entries
}

// LoadFile reads symbols from a file in Pasmo, asMSX, Glass, or standard .sym/.map formats.
// Returns count of parsed symbols.
func (st *SymbolTable) LoadFile(path string) (int, error) {
	file, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	count := 0
	for scanner.Scan() {
		line := scanner.Text()
		name, addr, ok := ParseSymbolLine(line)
		if ok {
			st.Add(name, addr)
			count++
		}
	}
	return count, scanner.Err()
}

// ParseSymbolLine parses one line of symbols in various assembler formats.
func ParseSymbolLine(line string) (name string, addr uint16, ok bool) {
	// Strip comments
	if idx := strings.IndexAny(line, ";#"); idx >= 0 {
		line = line[:idx]
	}
	if idx := strings.Index(line, "//"); idx >= 0 {
		line = line[:idx]
	}
	line = strings.TrimSpace(line)
	if line == "" {
		return "", 0, false
	}

	fields := strings.Fields(line)
	if len(fields) < 2 {
		return "", 0, false
	}

	// Format 1: Pasmo / asMSX: "LABEL: EQU 1234h" or "LABEL EQU 1234h" or "LABEL: DEFL 1234h"
	if len(fields) >= 3 {
		upperOp := strings.ToUpper(fields[1])
		if upperOp == "EQU" || upperOp == "DEFL" || upperOp == "=" {
			n := strings.TrimSuffix(fields[0], ":")
			a, err := parseHexOrDec(fields[2])
			if err == nil {
				return n, uint16(a), true
			}
		}
	}

	// Format 2: "LABEL: 1234h" or "LABEL = 1234h"
	if len(fields) == 2 {
		// Try: "1234h LABEL" (standard .map or .sym format)
		if a, err := parseHexOrDec(fields[0]); err == nil {
			return fields[1], uint16(a), true
		}
		// Try: "LABEL 1234h"
		if a, err := parseHexOrDec(fields[1]); err == nil {
			n := strings.TrimSuffix(fields[0], ":")
			return n, uint16(a), true
		}
	}

	return "", 0, false
}

func parseHexOrDec(s string) (uint32, error) {
	s = strings.TrimSpace(s)
	s = strings.TrimPrefix(s, "$")
	s = strings.TrimPrefix(s, "#")
	if strings.HasPrefix(strings.ToLower(s), "0x") {
		val, err := strconv.ParseUint(s[2:], 16, 32)
		return uint32(val), err
	}
	if strings.HasSuffix(strings.ToLower(s), "h") {
		val, err := strconv.ParseUint(s[:len(s)-1], 16, 32)
		return uint32(val), err
	}
	// Try parsing as hex directly first if it has A-F
	for _, ch := range s {
		if (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f') {
			val, err := strconv.ParseUint(s, 16, 32)
			return uint32(val), err
		}
	}
	// Decimal or hex
	val, err := strconv.ParseUint(s, 10, 32)
	if err == nil {
		return uint32(val), nil
	}
	val, err = strconv.ParseUint(s, 16, 32)
	return uint32(val), err
}
