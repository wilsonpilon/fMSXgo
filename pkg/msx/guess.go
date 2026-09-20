package msx

import (
	"crypto/sha1"
	"fmt"
	"path/filepath"
	"strings"
)

// knownHashes maps SHA1 hashes of known MSX cartridge dumps to their mapper type
var knownHashes = map[string]int{
	// Cross Blaim
	"bb902e82a2bdda61101a9b3646462adecdd18c8d": MapperCrossBlaim,
	"88b1633210d9a7c65b502815b9ae97d24d0e9ce1": MapperCrossBlaim,

	// R-Type
	"77caeccd08eb558b727350fdd278ab0d7315e968": MapperRType,
	"37bd4680a36c3a1a078e2bc47b631d858d9296b8": MapperRType,
	"9b6cb224f2a7a4af69221f1280d3344a5c88450e": MapperRType,
	"9c886fff02779267041efe45dadefc5fd7f4b9a2": MapperRType,
	"0b379610cb7085005a56b24a0890b79dd5a7e817": MapperRType,
	"1af18369c1237f96b8a54c515f5c204b37f54749": MapperRType,
	"96c84bfc2756313a6a2e1d09319f4aa85e815127": MapperRType,
	"5efae0c1493eae286ad306071e20eb8a4e4869f4": MapperRType,

	// Harry Fox Yuki no Maou Hen
	"3626b5dd3188ec2a16e102d05c79f8f242fbd892": MapperHarryFox,
	"5c2ebab5ae4ae97bb73f5689eaba3c2e5f866e78": MapperHarryFox,

	// Harry Fox MSX Special (ASCII16 with 2KB SRAM)
	"a3de07612da7986387a4f5c41bbbc7e3b244e077": MapperASCII16SRAM,

	// Hydlide 2 - Shine of Darkness (ASCII16 with 2KB SRAM)
	"da4b44c734029f60388b7cea4ab97c3d5c6a09e9": MapperASCII16SRAM,
	"a3537934a4d9dfbf27aca5aaf42e0f18e4975366": MapperASCII16SRAM,
	"b18d36cc60d0e3b325138bb98472b685cca89f90": MapperASCII16SRAM,
	"0fe07b5f62e179a1294253a505a296ffefca8c95": MapperASCII16SRAM,
	"1eae08241c0681d6b6d87c68ebdaaff1baa40069": MapperASCII16SRAM,

	// Super Pierrot
	"0d2f86dbb70f4b4a4e4dc1bc95df232f48856037": MapperSuperPierrot,
	"feaa75bbe0b9906c981ad6b9aba3823856033477": MapperSuperPierrot,
	"8c4d65ec7e255df5d520abee4b024a4d861d92bb": MapperSuperPierrot,
}

// MapperName returns a human-friendly string for the mapper type
func MapperName(mapperType int) string {
	switch mapperType {
	case MapperGeneric8K:
		return "Generic 8K"
	case MapperGeneric16K:
		return "Generic 16K/32K"
	case MapperKonami5:
		return "Konami with SCC (Konami 5)"
	case MapperKonami4:
		return "Konami without SCC (Konami 4)"
	case MapperASCII8K:
		return "ASCII 8K"
	case MapperASCII16K:
		return "ASCII 16K"
	case MapperCrossBlaim:
		return "Cross Blaim"
	case MapperRType:
		return "R-Type (384KB)"
	case MapperHarryFox:
		return "Harry Fox"
	case MapperSuperPierrot:
		return "Super Pierrot (ASCII16nf)"
	case MapperASCII16SRAM:
		return "ASCII 16K with SRAM"
	default:
		return fmt.Sprintf("Mapper %d", mapperType)
	}
}

// GuessMapper automatically detects the mapper type for a given ROM file.
// It checks SHA1 hash, filename signatures, ROM size, and opcode heuristic write patterns.
func GuessMapper(data []byte, filename string) (int, string) {
	if len(data) == 0 {
		return MapperGeneric16K, MapperName(MapperGeneric16K)
	}

	// 1. Check SHA1 against known dumps database
	hash := fmt.Sprintf("%x", sha1.Sum(data))
	if mapper, found := knownHashes[hash]; found {
		return mapper, MapperName(mapper)
	}

	// 2. Check filename keywords
	lowerName := strings.ToLower(filepath.Base(filename))
	if strings.Contains(lowerName, "cross blaim") || strings.Contains(lowerName, "crossblaim") {
		return MapperCrossBlaim, MapperName(MapperCrossBlaim)
	}
	if strings.Contains(lowerName, "r-type") || strings.Contains(lowerName, "rtype") {
		return MapperRType, MapperName(MapperRType)
	}
	if strings.Contains(lowerName, "hydlide 2") || strings.Contains(lowerName, "hydlide ii") || strings.Contains(lowerName, "hydlide2") {
		return MapperASCII16SRAM, MapperName(MapperASCII16SRAM)
	}
	if strings.Contains(lowerName, "harry fox") || strings.Contains(lowerName, "harryfox") {
		if strings.Contains(lowerName, "special") {
			return MapperASCII16SRAM, MapperName(MapperASCII16SRAM)
		}
		return MapperHarryFox, MapperName(MapperHarryFox)
	}
	if strings.Contains(lowerName, "super pierrot") || strings.Contains(lowerName, "superpierrot") {
		return MapperSuperPierrot, MapperName(MapperSuperPierrot)
	}

	// 3. Size heuristics
	size := len(data)
	if size <= 32*1024 {
		return MapperGeneric16K, MapperName(MapperGeneric16K)
	}
	if size == 64*1024 && (data[0] != 'A' || data[1] != 'B') {
		// 64KB ROM without standard cartridge AB header
		return MapperGeneric16K, MapperName(MapperGeneric16K)
	}

	// 4. Opcode analysis heuristic (fMSX / openMSX)
	// Scan for 32h xx yy (LD (yyxxh), A)
	var k5Count, k4Count, a8Count, a16Count int
	for i := 0; i < len(data)-2; i++ {
		if data[i] == 0x32 {
			addr := uint16(data[i+1]) | (uint16(data[i+2]) << 8)
			switch addr {
			case 0x5000, 0x9000, 0xB000:
				k5Count++
			case 0x4000, 0x8000, 0xA000:
				k4Count++
			case 0x6800, 0x7800:
				a8Count++
			case 0x6000:
				k4Count++
				a8Count++
				a16Count++
			case 0x7000:
				k5Count++
				a8Count++
				a16Count++
			case 0x77FF:
				a16Count++
			}
		}
	}

	if a8Count > 0 {
		a8Count-- // bias adjustment matching openMSX/fMSX
	}

	bestType := MapperKonami4
	bestCount := k4Count

	if k5Count > bestCount {
		bestType = MapperKonami5
		bestCount = k5Count
	}
	if a8Count > bestCount {
		bestType = MapperASCII8K
		bestCount = a8Count
	}
	if a16Count > bestCount {
		bestType = MapperASCII16K
	}

	return bestType, MapperName(bestType)
}
