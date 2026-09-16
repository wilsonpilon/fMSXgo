package z80

import (
	"fmt"
	"strconv"
	"strings"
)

// AssembleLine parses a single Z80 assembly instruction line at the given address (pc)
// and returns the assembled bytes or an error.
func AssembleLine(pc uint16, line string) ([]byte, error) {
	line = strings.TrimSpace(line)
	if line == "" || strings.HasPrefix(line, ";") {
		return nil, nil
	}

	// Strip comments
	if idx := strings.Index(line, ";"); idx != -1 {
		line = strings.TrimSpace(line[:idx])
	}

	// Split mnemonic and operands
	parts := strings.SplitN(line, " ", 2)
	mnemonic := strings.ToUpper(strings.TrimSpace(parts[0]))
	operandsStr := ""
	if len(parts) > 1 {
		operandsStr = strings.TrimSpace(parts[1])
	}

	// Directives: DB, DW
	if mnemonic == "DB" || mnemonic == "DEFB" {
		return parseDB(operandsStr)
	}
	if mnemonic == "DW" || mnemonic == "DEFW" {
		return parseDW(operandsStr)
	}

	operands := splitOperands(operandsStr)

	switch mnemonic {
	case "NOP":
		return []byte{0x00}, nil
	case "HALT":
		return []byte{0x76}, nil
	case "DI":
		return []byte{0xF3}, nil
	case "EI":
		return []byte{0xFB}, nil
	case "EXX":
		return []byte{0xD9}, nil
	case "RLCA":
		return []byte{0x07}, nil
	case "RRCA":
		return []byte{0x0F}, nil
	case "RLA":
		return []byte{0x17}, nil
	case "RRA":
		return []byte{0x1F}, nil
	case "DAA":
		return []byte{0x27}, nil
	case "CPL":
		return []byte{0x2F}, nil
	case "SCF":
		return []byte{0x37}, nil
	case "CCF":
		return []byte{0x3F}, nil
	case "RETI":
		return []byte{0xED, 0x4D}, nil
	case "RETN":
		return []byte{0xED, 0x45}, nil
	case "NEG":
		return []byte{0xED, 0x44}, nil
	case "RRD":
		return []byte{0xED, 0x67}, nil
	case "RLD":
		return []byte{0xED, 0x6F}, nil
	case "LDI":
		return []byte{0xED, 0xA0}, nil
	case "LDIR":
		return []byte{0xED, 0xB0}, nil
	case "LDD":
		return []byte{0xED, 0xA8}, nil
	case "LDDR":
		return []byte{0xED, 0xB8}, nil
	case "CPI":
		return []byte{0xED, 0xA1}, nil
	case "CPIR":
		return []byte{0xED, 0xB1}, nil
	case "CPD":
		return []byte{0xED, 0xA9}, nil
	case "CPDR":
		return []byte{0xED, 0xB9}, nil

	case "EX":
		if len(operands) != 2 {
			return nil, fmt.Errorf("EX expects 2 operands")
		}
		op1, op2 := strings.ToUpper(operands[0]), strings.ToUpper(operands[1])
		if op1 == "AF" && (op2 == "AF'" || op2 == "AF`") {
			return []byte{0x08}, nil
		}
		if (op1 == "DE" && op2 == "HL") || (op1 == "HL" && op2 == "DE") {
			return []byte{0xEB}, nil
		}
		if op1 == "(SP)" && op2 == "HL" {
			return []byte{0xE3}, nil
		}
		if op1 == "(SP)" && op2 == "IX" {
			return []byte{0xDD, 0xE3}, nil
		}
		if op1 == "(SP)" && op2 == "IY" {
			return []byte{0xFD, 0xE3}, nil
		}

	case "RET":
		if len(operands) == 0 {
			return []byte{0xC9}, nil
		}
		cond := strings.ToUpper(operands[0])
		ccMap := map[string]byte{
			"NZ": 0xC0, "Z": 0xC8, "NC": 0xD0, "C": 0xD8,
			"PO": 0xE0, "PE": 0xE8, "P": 0xF0, "M": 0xF8,
		}
		if code, ok := ccMap[cond]; ok {
			return []byte{code}, nil
		}

	case "JP":
		return assembleJP(operands)

	case "JR":
		return assembleJR(pc, operands)

	case "CALL":
		return assembleCALL(operands)

	case "DJNZ":
		if len(operands) != 1 {
			return nil, fmt.Errorf("DJNZ expects 1 operand")
		}
		val, err := parseNumber(operands[0])
		if err != nil {
			return nil, err
		}
		offset := calculateRelativeOffset(pc+2, val)
		return []byte{0x10, uint8(offset)}, nil

	case "RST":
		if len(operands) != 1 {
			return nil, fmt.Errorf("RST expects 1 operand")
		}
		val, err := parseNumber(operands[0])
		if err != nil {
			return nil, err
		}
		switch val {
		case 0x00:
			return []byte{0xC7}, nil
		case 0x08:
			return []byte{0xCF}, nil
		case 0x10:
			return []byte{0xD7}, nil
		case 0x18:
			return []byte{0xDF}, nil
		case 0x20:
			return []byte{0xE7}, nil
		case 0x28:
			return []byte{0xEF}, nil
		case 0x30:
			return []byte{0xF7}, nil
		case 0x38:
			return []byte{0xFF}, nil
		default:
			return nil, fmt.Errorf("invalid RST vector: %02X", val)
		}

	case "INC":
		return assembleIncDec(operands, true)

	case "DEC":
		return assembleIncDec(operands, false)

	case "PUSH":
		if len(operands) != 1 {
			return nil, fmt.Errorf("PUSH expects 1 operand")
		}
		switch strings.ToUpper(operands[0]) {
		case "BC":
			return []byte{0xC5}, nil
		case "DE":
			return []byte{0xD5}, nil
		case "HL":
			return []byte{0xE5}, nil
		case "AF":
			return []byte{0xF5}, nil
		case "IX":
			return []byte{0xDD, 0xE5}, nil
		case "IY":
			return []byte{0xFD, 0xE5}, nil
		}

	case "POP":
		if len(operands) != 1 {
			return nil, fmt.Errorf("POP expects 1 operand")
		}
		switch strings.ToUpper(operands[0]) {
		case "BC":
			return []byte{0xC1}, nil
		case "DE":
			return []byte{0xD1}, nil
		case "HL":
			return []byte{0xE1}, nil
		case "AF":
			return []byte{0xF1}, nil
		case "IX":
			return []byte{0xDD, 0xE1}, nil
		case "IY":
			return []byte{0xFD, 0xE1}, nil
		}

	case "ADD":
		return assembleADD(operands)

	case "ADC":
		return assembleADC(operands)

	case "SUB":
		return assembleALUSingle(operands, 0x90, 0xD6)

	case "SBC":
		return assembleSBC(operands)

	case "AND":
		return assembleALUSingle(operands, 0xA0, 0xE6)

	case "XOR":
		return assembleALUSingle(operands, 0xA8, 0xEE)

	case "OR":
		return assembleALUSingle(operands, 0xB0, 0xF6)

	case "CP":
		return assembleALUSingle(operands, 0xB8, 0xFE)

	case "LD":
		return assembleLD(operands)

	case "IN":
		return assembleIN(operands)

	case "OUT":
		return assembleOUT(operands)

	case "IM":
		if len(operands) != 1 {
			return nil, fmt.Errorf("IM expects 1 operand (0, 1, or 2)")
		}
		switch operands[0] {
		case "0":
			return []byte{0xED, 0x46}, nil
		case "1":
			return []byte{0xED, 0x56}, nil
		case "2":
			return []byte{0xED, 0x5E}, nil
		}

	// Bit / Shift Operations
	case "BIT", "SET", "RES":
		return assembleBit(mnemonic, operands)

	case "RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL":
		return assembleShift(mnemonic, operands)
	}

	return nil, fmt.Errorf("unknown instruction: %s", line)
}

func assembleJP(operands []string) ([]byte, error) {
	if len(operands) == 1 {
		op := strings.ToUpper(operands[0])
		if op == "(HL)" {
			return []byte{0xE9}, nil
		}
		if op == "(IX)" {
			return []byte{0xDD, 0xE9}, nil
		}
		if op == "(IY)" {
			return []byte{0xFD, 0xE9}, nil
		}
		val, err := parseNumber(operands[0])
		if err != nil {
			return nil, err
		}
		return []byte{0xC3, uint8(val), uint8(val >> 8)}, nil
	} else if len(operands) == 2 {
		cond := strings.ToUpper(operands[0])
		val, err := parseNumber(operands[1])
		if err != nil {
			return nil, err
		}
		ccMap := map[string]byte{
			"NZ": 0xC2, "Z": 0xCA, "NC": 0xD2, "C": 0xDA,
			"PO": 0xE2, "PE": 0xEA, "P": 0xF2, "M": 0xFA,
		}
		if code, ok := ccMap[cond]; ok {
			return []byte{code, uint8(val), uint8(val >> 8)}, nil
		}
	}
	return nil, fmt.Errorf("invalid JP syntax")
}

func assembleJR(pc uint16, operands []string) ([]byte, error) {
	if len(operands) == 1 {
		val, err := parseNumber(operands[0])
		if err != nil {
			return nil, err
		}
		offset := calculateRelativeOffset(pc+2, val)
		return []byte{0x18, uint8(offset)}, nil
	} else if len(operands) == 2 {
		cond := strings.ToUpper(operands[0])
		val, err := parseNumber(operands[1])
		if err != nil {
			return nil, err
		}
		offset := calculateRelativeOffset(pc+2, val)
		ccMap := map[string]byte{
			"NZ": 0x20, "Z": 0x28, "NC": 0x30, "C": 0x38,
		}
		if code, ok := ccMap[cond]; ok {
			return []byte{code, uint8(offset)}, nil
		}
	}
	return nil, fmt.Errorf("invalid JR syntax")
}

func assembleCALL(operands []string) ([]byte, error) {
	if len(operands) == 1 {
		val, err := parseNumber(operands[0])
		if err != nil {
			return nil, err
		}
		return []byte{0xCD, uint8(val), uint8(val >> 8)}, nil
	} else if len(operands) == 2 {
		cond := strings.ToUpper(operands[0])
		val, err := parseNumber(operands[1])
		if err != nil {
			return nil, err
		}
		ccMap := map[string]byte{
			"NZ": 0xC4, "Z": 0xCC, "NC": 0xD4, "C": 0xDC,
			"PO": 0xE4, "PE": 0xEC, "P": 0xF4, "M": 0xFC,
		}
		if code, ok := ccMap[cond]; ok {
			return []byte{code, uint8(val), uint8(val >> 8)}, nil
		}
	}
	return nil, fmt.Errorf("invalid CALL syntax")
}

func assembleIncDec(operands []string, isInc bool) ([]byte, error) {
	if len(operands) != 1 {
		return nil, fmt.Errorf("expected 1 operand")
	}
	reg := strings.ToUpper(operands[0])
	r8Map := map[string]byte{
		"B": 0x00, "C": 0x01, "D": 0x02, "E": 0x03, "H": 0x04, "L": 0x05, "(HL)": 0x06, "A": 0x07,
	}
	if idx, ok := r8Map[reg]; ok {
		base := byte(0x04)
		if !isInc {
			base = 0x05
		}
		return []byte{base | (idx << 3)}, nil
	}
	r16Map := map[string]byte{
		"BC": 0x00, "DE": 0x10, "HL": 0x20, "SP": 0x30,
	}
	if offset, ok := r16Map[reg]; ok {
		base := byte(0x03)
		if !isInc {
			base = 0x0B
		}
		return []byte{base | offset}, nil
	}
	if reg == "IX" {
		if isInc {
			return []byte{0xDD, 0x23}, nil
		}
		return []byte{0xDD, 0x2B}, nil
	}
	if reg == "IY" {
		if isInc {
			return []byte{0xFD, 0x23}, nil
		}
		return []byte{0xFD, 0x2B}, nil
	}
	return nil, fmt.Errorf("invalid operand for INC/DEC: %s", reg)
}

func assembleADD(operands []string) ([]byte, error) {
	if len(operands) == 1 {
		return assembleALUSingle(operands, 0x80, 0xC6)
	}
	if len(operands) == 2 {
		dst := strings.ToUpper(operands[0])
		src := strings.ToUpper(operands[1])
		if dst == "A" {
			return assembleALUSingle([]string{src}, 0x80, 0xC6)
		}
		if dst == "HL" {
			r16Map := map[string]byte{"BC": 0x09, "DE": 0x19, "HL": 0x29, "SP": 0x39}
			if code, ok := r16Map[src]; ok {
				return []byte{code}, nil
			}
		}
		if dst == "IX" {
			r16Map := map[string]byte{"BC": 0x09, "DE": 0x19, "IX": 0x29, "SP": 0x39}
			if code, ok := r16Map[src]; ok {
				return []byte{0xDD, code}, nil
			}
		}
		if dst == "IY" {
			r16Map := map[string]byte{"BC": 0x09, "DE": 0x19, "IY": 0x29, "SP": 0x39}
			if code, ok := r16Map[src]; ok {
				return []byte{0xFD, code}, nil
			}
		}
	}
	return nil, fmt.Errorf("invalid ADD operands")
}

func assembleADC(operands []string) ([]byte, error) {
	if len(operands) == 1 {
		return assembleALUSingle(operands, 0x88, 0xCE)
	}
	if len(operands) == 2 {
		dst := strings.ToUpper(operands[0])
		src := strings.ToUpper(operands[1])
		if dst == "A" {
			return assembleALUSingle([]string{src}, 0x88, 0xCE)
		}
		if dst == "HL" {
			r16Map := map[string]byte{"BC": 0x4A, "DE": 0x5A, "HL": 0x6A, "SP": 0x7A}
			if code, ok := r16Map[src]; ok {
				return []byte{0xED, code}, nil
			}
		}
	}
	return nil, fmt.Errorf("invalid ADC operands")
}

func assembleSBC(operands []string) ([]byte, error) {
	if len(operands) == 1 {
		return assembleALUSingle(operands, 0x98, 0xDE)
	}
	if len(operands) == 2 {
		dst := strings.ToUpper(operands[0])
		src := strings.ToUpper(operands[1])
		if dst == "A" {
			return assembleALUSingle([]string{src}, 0x98, 0xDE)
		}
		if dst == "HL" {
			r16Map := map[string]byte{"BC": 0x42, "DE": 0x52, "HL": 0x62, "SP": 0x72}
			if code, ok := r16Map[src]; ok {
				return []byte{0xED, code}, nil
			}
		}
	}
	return nil, fmt.Errorf("invalid SBC operands")
}

func assembleALUSingle(operands []string, regBase byte, immOpcode byte) ([]byte, error) {
	if len(operands) != 1 {
		return nil, fmt.Errorf("expected 1 operand")
	}
	src := strings.ToUpper(operands[0])
	r8Map := map[string]byte{
		"B": 0, "C": 1, "D": 2, "E": 3, "H": 4, "L": 5, "(HL)": 6, "A": 7,
	}
	if idx, ok := r8Map[src]; ok {
		return []byte{regBase | idx}, nil
	}
	// Immediate
	val, err := parseNumber(src)
	if err == nil {
		return []byte{immOpcode, uint8(val)}, nil
	}
	return nil, fmt.Errorf("invalid operand: %s", src)
}

func assembleLD(operands []string) ([]byte, error) {
	if len(operands) != 2 {
		return nil, fmt.Errorf("LD expects 2 operands")
	}
	dst := strings.ToUpper(operands[0])
	src := strings.ToUpper(operands[1])

	r8Map := map[string]byte{
		"B": 0, "C": 1, "D": 2, "E": 3, "H": 4, "L": 5, "(HL)": 6, "A": 7,
	}
	dstIdx, dstIsR8 := r8Map[dst]
	srcIdx, srcIsR8 := r8Map[src]

	// LD r, r'
	if dstIsR8 && srcIsR8 {
		if dst == "(HL)" && src == "(HL)" {
			return nil, fmt.Errorf("cannot LD (HL), (HL)")
		}
		return []byte{0x40 | (dstIdx << 3) | srcIdx}, nil
	}

	// LD r, n
	if dstIsR8 {
		val, err := parseNumber(src)
		if err == nil {
			return []byte{0x06 | (dstIdx << 3), uint8(val)}, nil
		}
	}

	// LD A, (BC) / (DE)
	if dst == "A" && src == "(BC)" {
		return []byte{0x0A}, nil
	}
	if dst == "A" && src == "(DE)" {
		return []byte{0x1A}, nil
	}
	if dst == "(BC)" && src == "A" {
		return []byte{0x02}, nil
	}
	if dst == "(DE)" && src == "A" {
		return []byte{0x12}, nil
	}

	// LD SP, HL
	if dst == "SP" && src == "HL" {
		return []byte{0xF9}, nil
	}

	// 16-bit register immediate: LD rr, nn
	r16Map := map[string]byte{"BC": 0x01, "DE": 0x11, "HL": 0x21, "SP": 0x31}
	if opcode, ok := r16Map[dst]; ok {
		val, err := parseNumber(src)
		if err == nil {
			return []byte{opcode, uint8(val), uint8(val >> 8)}, nil
		}
	}

	// LD IX/IY, nn
	if dst == "IX" {
		val, err := parseNumber(src)
		if err == nil {
			return []byte{0xDD, 0x21, uint8(val), uint8(val >> 8)}, nil
		}
	}
	if dst == "IY" {
		val, err := parseNumber(src)
		if err == nil {
			return []byte{0xFD, 0x21, uint8(val), uint8(val >> 8)}, nil
		}
	}

	// Direct memory: LD (nn), A / LD A, (nn)
	if strings.HasPrefix(dst, "(") && strings.HasSuffix(dst, ")") && src == "A" {
		val, err := parseNumber(dst[1 : len(dst)-1])
		if err == nil {
			return []byte{0x32, uint8(val), uint8(val >> 8)}, nil
		}
	}
	if dst == "A" && strings.HasPrefix(src, "(") && strings.HasSuffix(src, ")") {
		val, err := parseNumber(src[1 : len(src)-1])
		if err == nil {
			return []byte{0x3A, uint8(val), uint8(val >> 8)}, nil
		}
	}

	// LD (nn), HL / LD HL, (nn)
	if strings.HasPrefix(dst, "(") && strings.HasSuffix(dst, ")") && src == "HL" {
		val, err := parseNumber(dst[1 : len(dst)-1])
		if err == nil {
			return []byte{0x22, uint8(val), uint8(val >> 8)}, nil
		}
	}
	if dst == "HL" && strings.HasPrefix(src, "(") && strings.HasSuffix(src, ")") {
		val, err := parseNumber(src[1 : len(src)-1])
		if err == nil {
			return []byte{0x2A, uint8(val), uint8(val >> 8)}, nil
		}
	}

	return nil, fmt.Errorf("unsupported LD form: %s, %s", dst, src)
}

func assembleIN(operands []string) ([]byte, error) {
	if len(operands) != 2 {
		return nil, fmt.Errorf("IN expects 2 operands")
	}
	dst := strings.ToUpper(operands[0])
	src := strings.ToUpper(operands[1])

	if dst == "A" && strings.HasPrefix(src, "(") && strings.HasSuffix(src, ")") {
		inner := src[1 : len(src)-1]
		if inner == "C" {
			return []byte{0xED, 0x78}, nil
		}
		port, err := parseNumber(inner)
		if err == nil {
			return []byte{0xDB, uint8(port)}, nil
		}
	}
	return nil, fmt.Errorf("invalid IN syntax")
}

func assembleOUT(operands []string) ([]byte, error) {
	if len(operands) != 2 {
		return nil, fmt.Errorf("OUT expects 2 operands")
	}
	dst := strings.ToUpper(operands[0])
	src := strings.ToUpper(operands[1])

	if strings.HasPrefix(dst, "(") && strings.HasSuffix(dst, ")") && src == "A" {
		inner := dst[1 : len(dst)-1]
		if inner == "C" {
			return []byte{0xED, 0x79}, nil
		}
		port, err := parseNumber(inner)
		if err == nil {
			return []byte{0xD3, uint8(port)}, nil
		}
	}
	return nil, fmt.Errorf("invalid OUT syntax")
}

func assembleBit(mnemonic string, operands []string) ([]byte, error) {
	if len(operands) != 2 {
		return nil, fmt.Errorf("%s expects 2 operands", mnemonic)
	}
	bit, err := parseNumber(operands[0])
	if err != nil || bit > 7 {
		return nil, fmt.Errorf("invalid bit number: %s", operands[0])
	}
	r8Map := map[string]byte{"B": 0, "C": 1, "D": 2, "E": 3, "H": 4, "L": 5, "(HL)": 6, "A": 7}
	regIdx, ok := r8Map[strings.ToUpper(operands[1])]
	if !ok {
		return nil, fmt.Errorf("invalid register for %s: %s", mnemonic, operands[1])
	}
	var base byte
	switch mnemonic {
	case "BIT":
		base = 0x40
	case "RES":
		base = 0x80
	case "SET":
		base = 0xC0
	}
	return []byte{0xCB, base | (byte(bit) << 3) | regIdx}, nil
}

func assembleShift(mnemonic string, operands []string) ([]byte, error) {
	if len(operands) != 1 {
		return nil, fmt.Errorf("%s expects 1 operand", mnemonic)
	}
	r8Map := map[string]byte{"B": 0, "C": 1, "D": 2, "E": 3, "H": 4, "L": 5, "(HL)": 6, "A": 7}
	regIdx, ok := r8Map[strings.ToUpper(operands[0])]
	if !ok {
		return nil, fmt.Errorf("invalid register for %s: %s", mnemonic, operands[0])
	}
	shiftMap := map[string]byte{
		"RLC": 0x00, "RRC": 0x08, "RL": 0x10, "RR": 0x18,
		"SLA": 0x20, "SRA": 0x28, "SLL": 0x30, "SRL": 0x38,
	}
	return []byte{0xCB, shiftMap[mnemonic] | regIdx}, nil
}

func parseDB(operandsStr string) ([]byte, error) {
	parts := splitOperands(operandsStr)
	var res []byte
	for _, p := range parts {
		val, err := parseNumber(p)
		if err != nil {
			return nil, err
		}
		res = append(res, uint8(val))
	}
	return res, nil
}

func parseDW(operandsStr string) ([]byte, error) {
	parts := splitOperands(operandsStr)
	var res []byte
	for _, p := range parts {
		val, err := parseNumber(p)
		if err != nil {
			return nil, err
		}
		res = append(res, uint8(val), uint8(val>>8))
	}
	return res, nil
}

func splitOperands(s string) []string {
	var res []string
	for _, part := range strings.Split(s, ",") {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			res = append(res, trimmed)
		}
	}
	return res
}

func parseNumber(s string) (uint32, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("empty number")
	}
	// Binary: %1010 or 0b1010
	if strings.HasPrefix(s, "%") {
		v, err := strconv.ParseUint(s[1:], 2, 32)
		return uint32(v), err
	}
	if strings.HasPrefix(strings.ToLower(s), "0b") {
		v, err := strconv.ParseUint(s[2:], 2, 32)
		return uint32(v), err
	}
	// Hex: $12, 0x12, 12h, 12H
	if strings.HasPrefix(s, "$") {
		v, err := strconv.ParseUint(s[1:], 16, 32)
		return uint32(v), err
	}
	if strings.HasPrefix(strings.ToLower(s), "0x") {
		v, err := strconv.ParseUint(s[2:], 16, 32)
		return uint32(v), err
	}
	if strings.HasSuffix(strings.ToLower(s), "h") {
		v, err := strconv.ParseUint(s[:len(s)-1], 16, 32)
		return uint32(v), err
	}
	// Decimal
	v, err := strconv.ParseUint(s, 10, 32)
	if err == nil {
		return uint32(v), nil
	}
	// If standard decimal failed, try hex as fallback
	vHex, errHex := strconv.ParseUint(s, 16, 32)
	if errHex == nil {
		return uint32(vHex), nil
	}
	return 0, err
}

func calculateRelativeOffset(currentPC uint16, targetAddr uint32) int8 {
	// If targetAddr looks like a direct small relative displacement (-128..127)
	if int32(targetAddr) >= -128 && int32(targetAddr) <= 127 {
		return int8(targetAddr)
	}
	diff := int32(targetAddr) - int32(currentPC)
	return int8(diff)
}
