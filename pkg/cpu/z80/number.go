package z80

import (
	"fmt"
	"strconv"
	"strings"
)

// ParseNumber parses numeric literals according to the fMSXgo debugger & assembler standard:
//   - Default is HEXADECIMAL (base 16), even without any prefixes or suffixes.
//   - Explicit base prefixes:
//       'b' / 'B' -> Binary (base 2), e.g. b1010, B11110000, %1010, 0b1010
//       'd' / 'D' -> Decimal (base 10), e.g. d10, D255, #10
//       'h' / 'H' -> Hexadecimal (base 16), e.g. h10, HC000, $C000, 0xC000
//       'o' / 'O' -> Octal (base 8), e.g. o77, O12, 0o77, @77
//   - Explicit base suffixes:
//       'h' / 'H' -> Hexadecimal (e.g. 10h, C000h)
//       'd' / 'D' -> Decimal (e.g. 10d, 255d)
//       'b' / 'B' -> Binary (e.g. 1010b)
//       'o' / 'O' / 'q' / 'Q' -> Octal (e.g. 77o, 77q)
func ParseNumber(s string) (uint64, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("empty number")
	}

	neg := false
	if strings.HasPrefix(s, "-") {
		neg = true
		s = strings.TrimSpace(s[1:])
	} else if strings.HasPrefix(s, "+") {
		s = strings.TrimSpace(s[1:])
	}

	if s == "" {
		return 0, fmt.Errorf("invalid number")
	}

	val, err := parseUnsignedNumber(s)
	if err != nil {
		return 0, err
	}
	if neg {
		return uint64(-int64(val)), nil
	}
	return val, nil
}

func parseUnsignedNumber(s string) (uint64, error) {
	lower := strings.ToLower(s)

	// 1. Classical symbols prefix
	if strings.HasPrefix(s, "$") {
		return strconv.ParseUint(s[1:], 16, 64)
	}
	if strings.HasPrefix(lower, "0x") {
		return strconv.ParseUint(s[2:], 16, 64)
	}
	if strings.HasPrefix(s, "%") {
		return strconv.ParseUint(s[1:], 2, 64)
	}
	if strings.HasPrefix(lower, "0b") {
		return strconv.ParseUint(s[2:], 2, 64)
	}
	if strings.HasPrefix(lower, "0o") {
		return strconv.ParseUint(s[2:], 8, 64)
	}
	if strings.HasPrefix(s, "@") {
		return strconv.ParseUint(s[1:], 8, 64)
	}
	if strings.HasPrefix(s, "#") {
		return strconv.ParseUint(s[1:], 10, 64)
	}

	// 2. Explicit letter prefixes at the beginning: 'b', 'd', 'h', 'o'
	if len(s) > 1 {
		first := lower[0]
		rem := s[1:]

		switch first {
		case 'h':
			if isHexDigits(rem) {
				return strconv.ParseUint(rem, 16, 64)
			}
		case 'o':
			if isOctalDigits(rem) {
				return strconv.ParseUint(rem, 8, 64)
			}
		case 'b':
			// Binary: b/B followed by binary digits
			// Exclude cases like "B000" where multiple leading zeros indicate a 4-hex-digit address
			if !(len(rem) > 1 && strings.HasPrefix(rem, "00")) && isBinaryDigits(rem) {
				return strconv.ParseUint(rem, 2, 64)
			}
		case 'd':
			// Decimal: d/D followed by decimal digits
			// Exclude cases like "D000" where multiple leading zeros indicate a 4-hex-digit address
			if !(len(rem) > 1 && strings.HasPrefix(rem, "00")) && isDecimalDigits(rem) {
				return strconv.ParseUint(rem, 10, 64)
			}
		}
	}

	// 3. Classical suffixes: 'h', 'd', 'b', 'o', 'q'
	if len(s) > 1 {
		last := lower[len(lower)-1]
		body := s[:len(s)-1]
		switch last {
		case 'h':
			if isHexDigits(body) {
				return strconv.ParseUint(body, 16, 64)
			}
		case 'd':
			if isDecimalDigits(body) {
				return strconv.ParseUint(body, 10, 64)
			}
		case 'b':
			if isBinaryDigits(body) {
				return strconv.ParseUint(body, 2, 64)
			}
		case 'o', 'q':
			if isOctalDigits(body) {
				return strconv.ParseUint(body, 8, 64)
			}
		}
	}

	// 4. Default: HEXADECIMAL (base 16)
	return strconv.ParseUint(s, 16, 64)
}

func isBinaryDigits(s string) bool {
	if len(s) == 0 {
		return false
	}
	for _, c := range s {
		if c != '0' && c != '1' {
			return false
		}
	}
	return true
}

func isOctalDigits(s string) bool {
	if len(s) == 0 {
		return false
	}
	for _, c := range s {
		if c < '0' || c > '7' {
			return false
		}
	}
	return true
}

func isDecimalDigits(s string) bool {
	if len(s) == 0 {
		return false
	}
	for _, c := range s {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}

func isHexDigits(s string) bool {
	if len(s) == 0 {
		return false
	}
	for _, c := range s {
		if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
			return false
		}
	}
	return true
}
