package z80

import (
	"fmt"
)

// Disassemble decodes the instruction at address pc from the given Bus.
// It returns the textual mnemonic representation and the instruction size in bytes.
func Disassemble(bus Bus, pc uint16) (string, int) {
	op := bus.Read(pc)

	switch op {
	case 0xCB:
		cbOp := bus.Read(pc + 1)
		return disasmCB(cbOp), 2

	case 0xED:
		edOp := bus.Read(pc + 1)
		return disasmED(bus, pc+2, edOp)

	case 0xDD:
		return disasmIndex(bus, pc+1, "IX")

	case 0xFD:
		return disasmIndex(bus, pc+1, "IY")

	default:
		return disasmBase(bus, pc, op)
	}
}

func disasmBase(bus Bus, pc uint16, op uint8) (string, int) {
	readByte := func() uint8 { return bus.Read(pc + 1) }
	readWord := func() uint16 {
		low := uint16(bus.Read(pc + 1))
		high := uint16(bus.Read(pc + 2))
		return (high << 8) | low
	}

	switch op {
	case 0x00:
		return "NOP", 1
	case 0x01:
		return fmt.Sprintf("LD BC, %04Xh", readWord()), 3
	case 0x02:
		return "LD (BC), A", 1
	case 0x03:
		return "INC BC", 1
	case 0x04:
		return "INC B", 1
	case 0x05:
		return "DEC B", 1
	case 0x06:
		return fmt.Sprintf("LD B, %02Xh", readByte()), 2
	case 0x07:
		return "RLCA", 1
	case 0x08:
		return "EX AF, AF'", 1
	case 0x09:
		return "ADD HL, BC", 1
	case 0x0A:
		return "LD A, (BC)", 1
	case 0x0B:
		return "DEC BC", 1
	case 0x0C:
		return "INC C", 1
	case 0x0D:
		return "DEC C", 1
	case 0x0E:
		return fmt.Sprintf("LD C, %02Xh", readByte()), 2
	case 0x0F:
		return "RRCA", 1

	case 0x10:
		d := int8(readByte())
		target := uint16(int32(pc+2) + int32(d))
		return fmt.Sprintf("DJNZ %04Xh", target), 2
	case 0x11:
		return fmt.Sprintf("LD DE, %04Xh", readWord()), 3
	case 0x12:
		return "LD (DE), A", 1
	case 0x13:
		return "INC DE", 1
	case 0x14:
		return "INC D", 1
	case 0x15:
		return "DEC D", 1
	case 0x16:
		return fmt.Sprintf("LD D, %02Xh", readByte()), 2
	case 0x17:
		return "RLA", 1
	case 0x18:
		d := int8(readByte())
		target := uint16(int32(pc+2) + int32(d))
		return fmt.Sprintf("JR %04Xh", target), 2
	case 0x19:
		return "ADD HL, DE", 1
	case 0x1A:
		return "LD A, (DE)", 1
	case 0x1B:
		return "DEC DE", 1
	case 0x1C:
		return "INC E", 1
	case 0x1D:
		return "DEC E", 1
	case 0x1E:
		return fmt.Sprintf("LD E, %02Xh", readByte()), 2
	case 0x1F:
		return "RRA", 1

	case 0x20:
		d := int8(readByte())
		target := uint16(int32(pc+2) + int32(d))
		return fmt.Sprintf("JR NZ, %04Xh", target), 2
	case 0x21:
		return fmt.Sprintf("LD HL, %04Xh", readWord()), 3
	case 0x22:
		return fmt.Sprintf("LD (%04Xh), HL", readWord()), 3
	case 0x23:
		return "INC HL", 1
	case 0x24:
		return "INC H", 1
	case 0x25:
		return "DEC H", 1
	case 0x26:
		return fmt.Sprintf("LD H, %02Xh", readByte()), 2
	case 0x27:
		return "DAA", 1
	case 0x28:
		d := int8(readByte())
		target := uint16(int32(pc+2) + int32(d))
		return fmt.Sprintf("JR Z, %04Xh", target), 2
	case 0x29:
		return "ADD HL, HL", 1
	case 0x2A:
		return fmt.Sprintf("LD HL, (%04Xh)", readWord()), 3
	case 0x2B:
		return "DEC HL", 1
	case 0x2C:
		return "INC L", 1
	case 0x2D:
		return "DEC L", 1
	case 0x2E:
		return fmt.Sprintf("LD L, %02Xh", readByte()), 2
	case 0x2F:
		return "CPL", 1

	case 0x30:
		d := int8(readByte())
		target := uint16(int32(pc+2) + int32(d))
		return fmt.Sprintf("JR NC, %04Xh", target), 2
	case 0x31:
		return fmt.Sprintf("LD SP, %04Xh", readWord()), 3
	case 0x32:
		return fmt.Sprintf("LD (%04Xh), A", readWord()), 3
	case 0x33:
		return "INC SP", 1
	case 0x34:
		return "INC (HL)", 1
	case 0x35:
		return "DEC (HL)", 1
	case 0x36:
		return fmt.Sprintf("LD (HL), %02Xh", readByte()), 2
	case 0x37:
		return "SCF", 1
	case 0x38:
		d := int8(readByte())
		target := uint16(int32(pc+2) + int32(d))
		return fmt.Sprintf("JR C, %04Xh", target), 2
	case 0x39:
		return "ADD HL, SP", 1
	case 0x3A:
		return fmt.Sprintf("LD A, (%04Xh)", readWord()), 3
	case 0x3B:
		return "DEC SP", 1
	case 0x3C:
		return "INC A", 1
	case 0x3D:
		return "DEC A", 1
	case 0x3E:
		return fmt.Sprintf("LD A, %02Xh", readByte()), 2
	case 0x3F:
		return "CCF", 1

	case 0x76:
		return "HALT", 1

	case 0xC0:
		return "RET NZ", 1
	case 0xC1:
		return "POP BC", 1
	case 0xC2:
		return fmt.Sprintf("JP NZ, %04Xh", readWord()), 3
	case 0xC3:
		return fmt.Sprintf("JP %04Xh", readWord()), 3
	case 0xC4:
		return fmt.Sprintf("CALL NZ, %04Xh", readWord()), 3
	case 0xC5:
		return "PUSH BC", 1
	case 0xC6:
		return fmt.Sprintf("ADD A, %02Xh", readByte()), 2
	case 0xC7:
		return "RST 00h", 1
	case 0xC8:
		return "RET Z", 1
	case 0xC9:
		return "RET", 1
	case 0xCA:
		return fmt.Sprintf("JP Z, %04Xh", readWord()), 3
	case 0xCC:
		return fmt.Sprintf("CALL Z, %04Xh", readWord()), 3
	case 0xCD:
		return fmt.Sprintf("CALL %04Xh", readWord()), 3
	case 0xCE:
		return fmt.Sprintf("ADC A, %02Xh", readByte()), 2
	case 0xCF:
		return "RST 08h", 1

	case 0xD0:
		return "RET NC", 1
	case 0xD1:
		return "POP DE", 1
	case 0xD2:
		return fmt.Sprintf("JP NC, %04Xh", readWord()), 3
	case 0xD3:
		return fmt.Sprintf("OUT (%02Xh), A", readByte()), 2
	case 0xD4:
		return fmt.Sprintf("CALL NC, %04Xh", readWord()), 3
	case 0xD5:
		return "PUSH DE", 1
	case 0xD6:
		return fmt.Sprintf("SUB %02Xh", readByte()), 2
	case 0xD7:
		return "RST 10h", 1
	case 0xD8:
		return "RET C", 1
	case 0xD9:
		return "EXX", 1
	case 0xDA:
		return fmt.Sprintf("JP C, %04Xh", readWord()), 3
	case 0xDB:
		return fmt.Sprintf("IN A, (%02Xh)", readByte()), 2
	case 0xDC:
		return fmt.Sprintf("CALL C, %04Xh", readWord()), 3
	case 0xDE:
		return fmt.Sprintf("SBC A, %02Xh", readByte()), 2
	case 0xDF:
		return "RST 18h", 1

	case 0xE0:
		return "RET PO", 1
	case 0xE1:
		return "POP HL", 1
	case 0xE2:
		return fmt.Sprintf("JP PO, %04Xh", readWord()), 3
	case 0xE3:
		return "EX (SP), HL", 1
	case 0xE4:
		return fmt.Sprintf("CALL PO, %04Xh", readWord()), 3
	case 0xE5:
		return "PUSH HL", 1
	case 0xE6:
		return fmt.Sprintf("AND %02Xh", readByte()), 2
	case 0xE7:
		return "RST 20h", 1
	case 0xE8:
		return "RET PE", 1
	case 0xE9:
		return "JP (HL)", 1
	case 0xEA:
		return fmt.Sprintf("JP PE, %04Xh", readWord()), 3
	case 0xEB:
		return "EX DE, HL", 1
	case 0xEC:
		return fmt.Sprintf("CALL PE, %04Xh", readWord()), 3
	case 0xEE:
		return fmt.Sprintf("XOR %02Xh", readByte()), 2
	case 0xEF:
		return "RST 28h", 1

	case 0xF0:
		return "RET P", 1
	case 0xF1:
		return "POP AF", 1
	case 0xF2:
		return fmt.Sprintf("JP P, %04Xh", readWord()), 3
	case 0xF3:
		return "DI", 1
	case 0xF4:
		return fmt.Sprintf("CALL P, %04Xh", readWord()), 3
	case 0xF5:
		return "PUSH AF", 1
	case 0xF6:
		return fmt.Sprintf("OR %02Xh", readByte()), 2
	case 0xF7:
		return "RST 30h", 1
	case 0xF8:
		return "RET M", 1
	case 0xF9:
		return "LD SP, HL", 1
	case 0xFA:
		return fmt.Sprintf("JP M, %04Xh", readWord()), 3
	case 0xFB:
		return "EI", 1
	case 0xFC:
		return fmt.Sprintf("CALL M, %04Xh", readWord()), 3
	case 0xFE:
		return fmt.Sprintf("CP %02Xh", readByte()), 2
	case 0xFF:
		return "RST 38h", 1
	}

	// 0x40 - 0x7F: LD r, r'
	regs := []string{"B", "C", "D", "E", "H", "L", "(HL)", "A"}
	if op >= 0x40 && op < 0x80 {
		src := regs[op&0x07]
		dst := regs[(op>>3)&0x07]
		return fmt.Sprintf("LD %s, %s", dst, src), 1
	}

	// 0x80 - 0xBF: ALU
	aluOps := []string{"ADD A,", "ADC A,", "SUB", "SBC A,", "AND", "XOR", "OR", "CP"}
	if op >= 0x80 && op < 0xC0 {
		aluOp := aluOps[(op>>3)&0x07]
		src := regs[op&0x07]
		return fmt.Sprintf("%s %s", aluOp, src), 1
	}

	return fmt.Sprintf("DB %02Xh", op), 1
}

func disasmCB(op uint8) string {
	regs := []string{"B", "C", "D", "E", "H", "L", "(HL)", "A"}
	shifts := []string{"RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"}

	reg := regs[op&0x07]
	bit := (op >> 3) & 0x07

	if op < 0x40 {
		return fmt.Sprintf("%s %s", shifts[bit], reg)
	} else if op < 0x80 {
		return fmt.Sprintf("BIT %d, %s", bit, reg)
	} else if op < 0xC0 {
		return fmt.Sprintf("RES %d, %s", bit, reg)
	} else {
		return fmt.Sprintf("SET %d, %s", bit, reg)
	}
}

func disasmED(bus Bus, paramAddr uint16, op uint8) (string, int) {
	readWord := func() uint16 {
		low := uint16(bus.Read(paramAddr))
		high := uint16(bus.Read(paramAddr + 1))
		return (high << 8) | low
	}

	switch op {
	case 0xFE:
		return "PATCH (ED FE)", 2

	case 0x40:
		return "IN B, (C)", 2
	case 0x41:
		return "OUT (C), B", 2
	case 0x42:
		return "SBC HL, BC", 2
	case 0x43:
		return fmt.Sprintf("LD (%04Xh), BC", readWord()), 4
	case 0x44:
		return "NEG", 2
	case 0x45:
		return "RETN", 2
	case 0x46:
		return "IM 0", 2
	case 0x47:
		return "LD I, A", 2
	case 0x48:
		return "IN C, (C)", 2
	case 0x49:
		return "OUT (C), C", 2
	case 0x4A:
		return "ADC HL, BC", 2
	case 0x4B:
		return fmt.Sprintf("LD BC, (%04Xh)", readWord()), 4
	case 0x4D:
		return "RETI", 2
	case 0x4F:
		return "LD R, A", 2

	case 0x50:
		return "IN D, (C)", 2
	case 0x51:
		return "OUT (C), D", 2
	case 0x52:
		return "SBC HL, DE", 2
	case 0x53:
		return fmt.Sprintf("LD (%04Xh), DE", readWord()), 4
	case 0x56:
		return "IM 1", 2
	case 0x57:
		return "LD A, I", 2
	case 0x58:
		return "IN E, (C)", 2
	case 0x59:
		return "OUT (C), E", 2
	case 0x5A:
		return "ADC HL, DE", 2
	case 0x5B:
		return fmt.Sprintf("LD DE, (%04Xh)", readWord()), 4
	case 0x5E:
		return "IM 2", 2
	case 0x5F:
		return "LD A, R", 2

	case 0x60:
		return "IN H, (C)", 2
	case 0x61:
		return "OUT (C), H", 2
	case 0x62:
		return "SBC HL, HL", 2
	case 0x63:
		return fmt.Sprintf("LD (%04Xh), HL", readWord()), 4
	case 0x67:
		return "RRD", 2
	case 0x68:
		return "IN L, (C)", 2
	case 0x69:
		return "OUT (C), L", 2
	case 0x6A:
		return "ADC HL, HL", 2
	case 0x6B:
		return fmt.Sprintf("LD HL, (%04Xh)", readWord()), 4
	case 0x6F:
		return "RLD", 2

	case 0x70:
		return "IN (C)", 2
	case 0x71:
		return "OUT (C), 0", 2
	case 0x72:
		return "SBC HL, SP", 2
	case 0x73:
		return fmt.Sprintf("LD (%04Xh), SP", readWord()), 4
	case 0x78:
		return "IN A, (C)", 2
	case 0x79:
		return "OUT (C), A", 2
	case 0x7A:
		return "ADC HL, SP", 2
	case 0x7B:
		return fmt.Sprintf("LD SP, (%04Xh)", readWord()), 4

	case 0xA0:
		return "LDI", 2
	case 0xA1:
		return "CPI", 2
	case 0xA2:
		return "INI", 2
	case 0xA3:
		return "OUTI", 2
	case 0xA8:
		return "LDD", 2
	case 0xA9:
		return "CPD", 2
	case 0xAA:
		return "IND", 2
	case 0xAB:
		return "OUTD", 2

	case 0xB0:
		return "LDIR", 2
	case 0xB1:
		return "CPIR", 2
	case 0xB2:
		return "INIR", 2
	case 0xB3:
		return "OTIR", 2
	case 0xB8:
		return "LDDR", 2
	case 0xB9:
		return "CPDR", 2
	case 0xBA:
		return "INDR", 2
	case 0xBB:
		return "OTDR", 2

	default:
		return fmt.Sprintf("ED %02Xh", op), 2
	}
}

func disasmIndex(bus Bus, pc uint16, regName string) (string, int) {
	op := bus.Read(pc)
	d := int8(bus.Read(pc + 1))
	dispStr := fmt.Sprintf("(%s%+d)", regName, d)

	switch op {
	case 0x21:
		low := uint16(bus.Read(pc + 1))
		high := uint16(bus.Read(pc + 2))
		return fmt.Sprintf("LD %s, %04Xh", regName, (high<<8)|low), 4
	case 0x22:
		low := uint16(bus.Read(pc + 1))
		high := uint16(bus.Read(pc + 2))
		return fmt.Sprintf("LD (%04Xh), %s", (high<<8)|low, regName), 4
	case 0x2A:
		low := uint16(bus.Read(pc + 1))
		high := uint16(bus.Read(pc + 2))
		return fmt.Sprintf("LD %s, (%04Xh)", regName, (high<<8)|low), 4
	case 0x23:
		return fmt.Sprintf("INC %s", regName), 2
	case 0x2B:
		return fmt.Sprintf("DEC %s", regName), 2
	case 0xE1:
		return fmt.Sprintf("POP %s", regName), 2
	case 0xE5:
		return fmt.Sprintf("PUSH %s", regName), 2
	case 0xE9:
		return fmt.Sprintf("JP (%s)", regName), 2
	case 0x34:
		return fmt.Sprintf("INC %s", dispStr), 3
	case 0x35:
		return fmt.Sprintf("DEC %s", dispStr), 3
	case 0x36:
		n := bus.Read(pc + 2)
		return fmt.Sprintf("LD %s, %02Xh", dispStr, n), 4
	case 0x77:
		return fmt.Sprintf("LD %s, A", dispStr), 3
	case 0x7E:
		return fmt.Sprintf("LD A, %s", dispStr), 3
	case 0x86:
		return fmt.Sprintf("ADD A, %s", dispStr), 3
	case 0x96:
		return fmt.Sprintf("SUB %s", dispStr), 3
	case 0xAE:
		return fmt.Sprintf("XOR %s", dispStr), 3
	case 0xB6:
		return fmt.Sprintf("OR %s", dispStr), 3
	case 0xBE:
		return fmt.Sprintf("CP %s", dispStr), 3

	case 0xCB:
		cbOp := bus.Read(pc + 2)
		bit := (cbOp >> 3) & 0x07
		shifts := []string{"RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"}
		if cbOp < 0x40 {
			return fmt.Sprintf("%s %s", shifts[bit], dispStr), 4
		} else if cbOp < 0x80 {
			return fmt.Sprintf("BIT %d, %s", bit, dispStr), 4
		} else if cbOp < 0xC0 {
			return fmt.Sprintf("RES %d, %s", bit, dispStr), 4
		} else {
			return fmt.Sprintf("SET %d, %s", bit, dispStr), 4
		}

	default:
		return fmt.Sprintf("PREFIX_%s %02Xh", regName, op), 2
	}
}
