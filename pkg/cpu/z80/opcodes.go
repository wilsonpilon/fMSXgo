package z80

// Step executes one instruction and returns the number of CPU cycles consumed.
func (z *Z80) Step(bus Bus) int {
	if z.Halted {
		// While halted, CPU executes NOP-like cycles
		z.Cycles += 4
		return 4
	}

	z.EIWait = false

	// Refresh register R increments on each M1 fetch (bit 7 preserved)
	z.R = ((z.R + 1) & 0x7F) | (z.R & 0x80)

	pc := z.PC
	z.PC++
	opcode := bus.Read(pc)

	if z.HistoryEnabled {
		entry := TraceEntry{
			PC:     pc,
			AF:     z.AF(),
			BC:     z.BC(),
			DE:     z.DE(),
			HL:     z.HL(),
			IX:     z.IX,
			IY:     z.IY,
			SP:     z.SP,
			Cycles: z.Cycles,
		}
		entry.Opcode[0] = opcode
		entry.Opcode[1] = bus.Read(pc + 1)
		entry.Opcode[2] = bus.Read(pc + 2)
		entry.Opcode[3] = bus.Read(pc + 3)
		entry.OpLen = 4
		z.RecordHistory(entry)
	}

	cycles := z.execOpcode(bus, opcode)
	z.Cycles += int64(cycles)
	return cycles
}

func (z *Z80) fetchByte(bus Bus) uint8 {
	val := bus.Read(z.PC)
	z.PC++
	return val
}

func (z *Z80) fetchWord(bus Bus) uint16 {
	low := z.fetchByte(bus)
	high := z.fetchByte(bus)
	return (uint16(high) << 8) | uint16(low)
}

// 8-bit Arithmetic Helpers
func (z *Z80) add8(val uint8) {
	a := z.A
	res := uint16(a) + uint16(val)
	res8 := uint8(res)

	// Half-carry: bit 3 to 4 carry
	h := ((a & 0x0F) + (val & 0x0F)) > 0x0F
	// Overflow: same sign inputs, different sign result
	v := ((a ^ res8) & (val ^ res8) & 0x80) != 0

	var f uint8 = ZSTable[res8]
	if (res & 0x100) != 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
	z.A = res8
}

func (z *Z80) adc8(val uint8) {
	a := z.A
	c := uint16(0)
	if (z.F & FlagC) != 0 {
		c = 1
	}
	res := uint16(a) + uint16(val) + c
	res8 := uint8(res)

	h := ((a & 0x0F) + (val & 0x0F) + uint8(c)) > 0x0F
	v := ((a ^ res8) & (val ^ res8) & 0x80) != 0

	var f uint8 = ZSTable[res8]
	if (res & 0x100) != 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
	z.A = res8
}

func (z *Z80) sub8(val uint8) {
	a := z.A
	res := int16(a) - int16(val)
	res8 := uint8(res)

	h := int8(a&0x0F)-int8(val&0x0F) < 0
	v := ((a ^ val) & (a ^ res8) & 0x80) != 0

	var f uint8 = ZSTable[res8] | FlagN
	if res < 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
	z.A = res8
}

func (z *Z80) sbc8(val uint8) {
	a := z.A
	c := int16(0)
	if (z.F & FlagC) != 0 {
		c = 1
	}
	res := int16(a) - int16(val) - c
	res8 := uint8(res)

	h := int8(a&0x0F)-int8(val&0x0F)-int8(c) < 0
	v := ((a ^ val) & (a ^ res8) & 0x80) != 0

	var f uint8 = ZSTable[res8] | FlagN
	if res < 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
	z.A = res8
}

func (z *Z80) cp8(val uint8) {
	a := z.A
	res := int16(a) - int16(val)
	res8 := uint8(res)

	h := int8(a&0x0F)-int8(val&0x0F) < 0
	v := ((a ^ val) & (a ^ res8) & 0x80) != 0

	var f uint8 = ZSTable[res8] | FlagN
	if res < 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
}

func (z *Z80) and8(val uint8) {
	z.A &= val
	z.F = PZSTable[z.A] | FlagH
}

func (z *Z80) xor8(val uint8) {
	z.A ^= val
	z.F = PZSTable[z.A]
}

func (z *Z80) or8(val uint8) {
	z.A |= val
	z.F = PZSTable[z.A]
}

func (z *Z80) inc8(val uint8) uint8 {
	res := val + 1
	z.F = (z.F & FlagC) | ZSTable[res]
	if (val & 0x0F) == 0x0F {
		z.F |= FlagH
	}
	if val == 0x7F {
		z.F |= FlagV
	}
	return res
}

func (z *Z80) dec8(val uint8) uint8 {
	res := val - 1
	z.F = (z.F & FlagC) | FlagN | ZSTable[res]
	if (val & 0x0F) == 0x00 {
		z.F |= FlagH
	}
	if val == 0x80 {
		z.F |= FlagV
	}
	return res
}

// 16-bit Arithmetic Helpers
func (z *Z80) add16(dest *uint16, src uint16) {
	d := *dest
	res := uint32(d) + uint32(src)
	h := ((d & 0x0FFF) + (src & 0x0FFF)) > 0x0FFF

	z.F &^= (FlagN | FlagC | FlagH)
	if (res & 0x10000) != 0 {
		z.F |= FlagC
	}
	if h {
		z.F |= FlagH
	}
	*dest = uint16(res)
}

func (z *Z80) adc16(src uint16) {
	hl := z.HL()
	c := uint32(0)
	if (z.F & FlagC) != 0 {
		c = 1
	}
	res := uint32(hl) + uint32(src) + c
	res16 := uint16(res)

	h := ((hl & 0x0FFF) + (src & 0x0FFF) + uint16(c)) > 0x0FFF
	v := ((hl ^ res16) & (src ^ res16) & 0x8000) != 0

	var f uint8
	if res16 == 0 {
		f |= FlagZ
	}
	if (res16 & 0x8000) != 0 {
		f |= FlagS
	}
	if (res & 0x10000) != 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
	z.SetHL(res16)
}

func (z *Z80) sbc16(src uint16) {
	hl := z.HL()
	c := int32(0)
	if (z.F & FlagC) != 0 {
		c = 1
	}
	res := int32(hl) - int32(src) - c
	res16 := uint16(res)

	h := int32(hl&0x0FFF)-int32(src&0x0FFF)-c < 0
	v := ((hl ^ src) & (hl ^ res16) & 0x8000) != 0

	var f uint8 = FlagN
	if res16 == 0 {
		f |= FlagZ
	}
	if (res16 & 0x8000) != 0 {
		f |= FlagS
	}
	if res < 0 {
		f |= FlagC
	}
	if h {
		f |= FlagH
	}
	if v {
		f |= FlagV
	}
	z.F = f
	z.SetHL(res16)
}

func (z *Z80) daa() {
	idx := uint16(z.A)
	if (z.F & FlagC) != 0 {
		idx |= 256
	}
	if (z.F & FlagH) != 0 {
		idx |= 512
	}
	if (z.F & FlagN) != 0 {
		idx |= 1024
	}
	af := DAATable[idx]
	z.A = uint8(af >> 8)
	z.F = uint8(af)
}

// Bit Rotate / Shift Helpers
func (z *Z80) rlc(val uint8) uint8 {
	c := (val >> 7) & 1
	res := (val << 1) | c
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) rrc(val uint8) uint8 {
	c := val & 1
	res := (val >> 1) | (c << 7)
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) rl(val uint8) uint8 {
	c := (val >> 7) & 1
	oldC := z.F & FlagC
	res := (val << 1) | oldC
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) rr(val uint8) uint8 {
	c := val & 1
	oldC := (z.F & FlagC) << 7
	res := (val >> 1) | oldC
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) sla(val uint8) uint8 {
	c := (val >> 7) & 1
	res := val << 1
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) sra(val uint8) uint8 {
	c := val & 1
	res := (val >> 1) | (val & 0x80)
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) sll(val uint8) uint8 {
	c := (val >> 7) & 1
	res := (val << 1) | 1
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) srl(val uint8) uint8 {
	c := val & 1
	res := val >> 1
	z.F = PZSTable[res] | c
	return res
}

func (z *Z80) bit(b uint8, val uint8) {
	z.F = (z.F & FlagC) | FlagH | (ZSTable[val&(1<<b)] & (FlagZ | FlagS))
	if (val & (1 << b)) == 0 {
		z.F |= FlagP
	}
}

// Primary Opcode Dispatcher
func (z *Z80) execOpcode(bus Bus, op uint8) int {
	cycles := Cycles[op]

	switch op {
	case 0x00: // NOP

	case 0x01: // LD BC, nn
		z.SetBC(z.fetchWord(bus))
	case 0x02: // LD (BC), A
		bus.Write(z.BC(), z.A)
	case 0x03: // INC BC
		z.SetBC(z.BC() + 1)
	case 0x04: // INC B
		z.B = z.inc8(z.B)
	case 0x05: // DEC B
		z.B = z.dec8(z.B)
	case 0x06: // LD B, n
		z.B = z.fetchByte(bus)
	case 0x07: // RLCA
		c := (z.A >> 7) & 1
		z.A = (z.A << 1) | c
		z.F = (z.F & (FlagS | FlagZ | FlagP)) | c

	case 0x08: // EX AF, AF'
		af := z.AF()
		z.SetAF(z.AF1())
		z.SetAF1(af)
	case 0x09: // ADD HL, BC
		hl := z.HL()
		z.add16(&hl, z.BC())
		z.SetHL(hl)
	case 0x0A: // LD A, (BC)
		z.A = bus.Read(z.BC())
	case 0x0B: // DEC BC
		z.SetBC(z.BC() - 1)
	case 0x0C: // INC C
		z.C = z.inc8(z.C)
	case 0x0D: // DEC C
		z.C = z.dec8(z.C)
	case 0x0E: // LD C, n
		z.C = z.fetchByte(bus)
	case 0x0F: // RRCA
		c := z.A & 1
		z.A = (z.A >> 1) | (c << 7)
		z.F = (z.F & (FlagS | FlagZ | FlagP)) | c

	case 0x10: // DJNZ d
		d := int8(z.fetchByte(bus))
		z.B--
		if z.B != 0 {
			z.PC = uint16(int32(z.PC) + int32(d))
			cycles += 5
		}
	case 0x11: // LD DE, nn
		z.SetDE(z.fetchWord(bus))
	case 0x12: // LD (DE), A
		bus.Write(z.DE(), z.A)
	case 0x13: // INC DE
		z.SetDE(z.DE() + 1)
	case 0x14: // INC D
		z.D = z.inc8(z.D)
	case 0x15: // DEC D
		z.D = z.dec8(z.D)
	case 0x16: // LD D, n
		z.D = z.fetchByte(bus)
	case 0x17: // RLA
		c := (z.A >> 7) & 1
		oldC := z.F & FlagC
		z.A = (z.A << 1) | oldC
		z.F = (z.F & (FlagS | FlagZ | FlagP)) | c

	case 0x18: // JR d
		d := int8(z.fetchByte(bus))
		z.PC = uint16(int32(z.PC) + int32(d))
	case 0x19: // ADD HL, DE
		hl := z.HL()
		z.add16(&hl, z.DE())
		z.SetHL(hl)
	case 0x1A: // LD A, (DE)
		z.A = bus.Read(z.DE())
	case 0x1B: // DEC DE
		z.SetDE(z.DE() - 1)
	case 0x1C: // INC E
		z.E = z.inc8(z.E)
	case 0x1D: // DEC E
		z.E = z.dec8(z.E)
	case 0x1E: // LD E, n
		z.E = z.fetchByte(bus)
	case 0x1F: // RRA
		c := z.A & 1
		oldC := (z.F & FlagC) << 7
		z.A = (z.A >> 1) | oldC
		z.F = (z.F & (FlagS | FlagZ | FlagP)) | c

	case 0x20: // JR NZ, d
		d := int8(z.fetchByte(bus))
		if (z.F & FlagZ) == 0 {
			z.PC = uint16(int32(z.PC) + int32(d))
			cycles += 5
		}
	case 0x21: // LD HL, nn
		z.SetHL(z.fetchWord(bus))
	case 0x22: // LD (nn), HL
		addr := z.fetchWord(bus)
		bus.Write(addr, z.L)
		bus.Write(addr+1, z.H)
	case 0x23: // INC HL
		z.SetHL(z.HL() + 1)
	case 0x24: // INC H
		z.H = z.inc8(z.H)
	case 0x25: // DEC H
		z.H = z.dec8(z.H)
	case 0x26: // LD H, n
		z.H = z.fetchByte(bus)
	case 0x27: // DAA
		z.daa()

	case 0x28: // JR Z, d
		d := int8(z.fetchByte(bus))
		if (z.F & FlagZ) != 0 {
			z.PC = uint16(int32(z.PC) + int32(d))
			cycles += 5
		}
	case 0x29: // ADD HL, HL
		hl := z.HL()
		z.add16(&hl, hl)
		z.SetHL(hl)
	case 0x2A: // LD HL, (nn)
		addr := z.fetchWord(bus)
		z.L = bus.Read(addr)
		z.H = bus.Read(addr + 1)
	case 0x2B: // DEC HL
		z.SetHL(z.HL() - 1)
	case 0x2C: // INC L
		z.L = z.inc8(z.L)
	case 0x2D: // DEC L
		z.L = z.dec8(z.L)
	case 0x2E: // LD L, n
		z.L = z.fetchByte(bus)
	case 0x2F: // CPL
		z.A = ^z.A
		z.F |= FlagH | FlagN

	case 0x30: // JR NC, d
		d := int8(z.fetchByte(bus))
		if (z.F & FlagC) == 0 {
			z.PC = uint16(int32(z.PC) + int32(d))
			cycles += 5
		}
	case 0x31: // LD SP, nn
		z.SP = z.fetchWord(bus)
	case 0x32: // LD (nn), A
		addr := z.fetchWord(bus)
		bus.Write(addr, z.A)
	case 0x33: // INC SP
		z.SP++
	case 0x34: // INC (HL)
		hl := z.HL()
		bus.Write(hl, z.inc8(bus.Read(hl)))
	case 0x35: // DEC (HL)
		hl := z.HL()
		bus.Write(hl, z.dec8(bus.Read(hl)))
	case 0x36: // LD (HL), n
		bus.Write(z.HL(), z.fetchByte(bus))
	case 0x37: // SCF
		z.F = (z.F & (FlagS | FlagZ | FlagP)) | FlagC

	case 0x38: // JR C, d
		d := int8(z.fetchByte(bus))
		if (z.F & FlagC) != 0 {
			z.PC = uint16(int32(z.PC) + int32(d))
			cycles += 5
		}
	case 0x39: // ADD HL, SP
		hl := z.HL()
		z.add16(&hl, z.SP)
		z.SetHL(hl)
	case 0x3A: // LD A, (nn)
		addr := z.fetchWord(bus)
		z.A = bus.Read(addr)
	case 0x3B: // DEC SP
		z.SP--
	case 0x3C: // INC A
		z.A = z.inc8(z.A)
	case 0x3D: // DEC A
		z.A = z.dec8(z.A)
	case 0x3E: // LD A, n
		z.A = z.fetchByte(bus)
	case 0x3F: // CCF
		z.F = ((z.F & (FlagS | FlagZ | FlagP | FlagC)) ^ FlagC) | ((z.F & FlagC) << 4)

	// 0x40 - 0x7F: LD r, r'
	case 0x40: // LD B, B
	case 0x41: // LD B, C
		z.B = z.C
	case 0x42: // LD B, D
		z.B = z.D
	case 0x43: // LD B, E
		z.B = z.E
	case 0x44: // LD B, H
		z.B = z.H
	case 0x45: // LD B, L
		z.B = z.L
	case 0x46: // LD B, (HL)
		z.B = bus.Read(z.HL())
	case 0x47: // LD B, A
		z.B = z.A

	case 0x48: // LD C, B
		z.C = z.B
	case 0x49: // LD C, C
	case 0x4A: // LD C, D
		z.C = z.D
	case 0x4B: // LD C, E
		z.C = z.E
	case 0x4C: // LD C, H
		z.C = z.H
	case 0x4D: // LD C, L
		z.C = z.L
	case 0x4E: // LD C, (HL)
		z.C = bus.Read(z.HL())
	case 0x4F: // LD C, A
		z.C = z.A

	case 0x50: // LD D, B
		z.D = z.B
	case 0x51: // LD D, C
		z.D = z.C
	case 0x52: // LD D, D
	case 0x53: // LD D, E
		z.D = z.E
	case 0x54: // LD D, H
		z.D = z.H
	case 0x55: // LD D, L
		z.D = z.L
	case 0x56: // LD D, (HL)
		z.D = bus.Read(z.HL())
	case 0x57: // LD D, A
		z.D = z.A

	case 0x58: // LD E, B
		z.E = z.B
	case 0x59: // LD E, C
		z.E = z.C
	case 0x5A: // LD E, D
		z.E = z.D
	case 0x5B: // LD E, E
	case 0x5C: // LD E, H
		z.E = z.H
	case 0x5D: // LD E, L
		z.E = z.L
	case 0x5E: // LD E, (HL)
		z.E = bus.Read(z.HL())
	case 0x5F: // LD E, A
		z.E = z.A

	case 0x60: // LD H, B
		z.H = z.B
	case 0x61: // LD H, C
		z.H = z.C
	case 0x62: // LD H, D
		z.H = z.D
	case 0x63: // LD H, E
		z.H = z.E
	case 0x64: // LD H, H
	case 0x65: // LD H, L
		z.H = z.L
	case 0x66: // LD H, (HL)
		z.H = bus.Read(z.HL())
	case 0x67: // LD H, A
		z.H = z.A

	case 0x68: // LD L, B
		z.L = z.B
	case 0x69: // LD L, C
		z.L = z.C
	case 0x6A: // LD L, D
		z.L = z.D
	case 0x6B: // LD L, E
		z.L = z.E
	case 0x6C: // LD L, H
		z.L = z.H
	case 0x6D: // LD L, L
	case 0x6E: // LD L, (HL)
		z.L = bus.Read(z.HL())
	case 0x6F: // LD L, A
		z.L = z.A

	case 0x70: // LD (HL), B
		bus.Write(z.HL(), z.B)
	case 0x71: // LD (HL), C
		bus.Write(z.HL(), z.C)
	case 0x72: // LD (HL), D
		bus.Write(z.HL(), z.D)
	case 0x73: // LD (HL), E
		bus.Write(z.HL(), z.E)
	case 0x74: // LD (HL), H
		bus.Write(z.HL(), z.H)
	case 0x75: // LD (HL), L
		bus.Write(z.HL(), z.L)
	case 0x76: // HALT
		z.Halted = true
	case 0x77: // LD (HL), A
		bus.Write(z.HL(), z.A)

	case 0x78: // LD A, B
		z.A = z.B
	case 0x79: // LD A, C
		z.A = z.C
	case 0x7A: // LD A, D
		z.A = z.D
	case 0x7B: // LD A, E
		z.A = z.E
	case 0x7C: // LD A, H
		z.A = z.H
	case 0x7D: // LD A, L
		z.A = z.L
	case 0x7E: // LD A, (HL)
		z.A = bus.Read(z.HL())
	case 0x7F: // LD A, A

	// 0x80 - 0xBF: ALU A, r
	case 0x80: // ADD A, B
		z.add8(z.B)
	case 0x81: // ADD A, C
		z.add8(z.C)
	case 0x82: // ADD A, D
		z.add8(z.D)
	case 0x83: // ADD A, E
		z.add8(z.E)
	case 0x84: // ADD A, H
		z.add8(z.H)
	case 0x85: // ADD A, L
		z.add8(z.L)
	case 0x86: // ADD A, (HL)
		z.add8(bus.Read(z.HL()))
	case 0x87: // ADD A, A
		z.add8(z.A)

	case 0x88: // ADC A, B
		z.adc8(z.B)
	case 0x89: // ADC A, C
		z.adc8(z.C)
	case 0x8A: // ADC A, D
		z.adc8(z.D)
	case 0x8B: // ADC A, E
		z.adc8(z.E)
	case 0x8C: // ADC A, H
		z.adc8(z.H)
	case 0x8D: // ADC A, L
		z.adc8(z.L)
	case 0x8E: // ADC A, (HL)
		z.adc8(bus.Read(z.HL()))
	case 0x8F: // ADC A, A
		z.adc8(z.A)

	case 0x90: // SUB B
		z.sub8(z.B)
	case 0x91: // SUB C
		z.sub8(z.C)
	case 0x92: // SUB D
		z.sub8(z.D)
	case 0x93: // SUB E
		z.sub8(z.E)
	case 0x94: // SUB H
		z.sub8(z.H)
	case 0x95: // SUB L
		z.sub8(z.L)
	case 0x96: // SUB (HL)
		z.sub8(bus.Read(z.HL()))
	case 0x97: // SUB A
		z.sub8(z.A)

	case 0x98: // SBC A, B
		z.sbc8(z.B)
	case 0x99: // SBC A, C
		z.sbc8(z.C)
	case 0x9A: // SBC A, D
		z.sbc8(z.D)
	case 0x9B: // SBC A, E
		z.sbc8(z.E)
	case 0x9C: // SBC A, H
		z.sbc8(z.H)
	case 0x9D: // SBC A, L
		z.sbc8(z.L)
	case 0x9E: // SBC A, (HL)
		z.sbc8(bus.Read(z.HL()))
	case 0x9F: // SBC A, A
		z.sbc8(z.A)

	case 0xA0: // AND B
		z.and8(z.B)
	case 0xA1: // AND C
		z.and8(z.C)
	case 0xA2: // AND D
		z.and8(z.D)
	case 0xA3: // AND E
		z.and8(z.E)
	case 0xA4: // AND H
		z.and8(z.H)
	case 0xA5: // AND L
		z.and8(z.L)
	case 0xA6: // AND (HL)
		z.and8(bus.Read(z.HL()))
	case 0xA7: // AND A
		z.and8(z.A)

	case 0xA8: // XOR B
		z.xor8(z.B)
	case 0xA9: // XOR C
		z.xor8(z.C)
	case 0xAA: // XOR D
		z.xor8(z.D)
	case 0xAB: // XOR E
		z.xor8(z.E)
	case 0xAC: // XOR H
		z.xor8(z.H)
	case 0xAD: // XOR L
		z.xor8(z.L)
	case 0xAE: // XOR (HL)
		z.xor8(bus.Read(z.HL()))
	case 0xAF: // XOR A
		z.xor8(z.A)

	case 0xB0: // OR B
		z.or8(z.B)
	case 0xB1: // OR C
		z.or8(z.C)
	case 0xB2: // OR D
		z.or8(z.D)
	case 0xB3: // OR E
		z.or8(z.E)
	case 0xB4: // OR H
		z.or8(z.H)
	case 0xB5: // OR L
		z.or8(z.L)
	case 0xB6: // OR (HL)
		z.or8(bus.Read(z.HL()))
	case 0xB7: // OR A
		z.or8(z.A)

	case 0xB8: // CP B
		z.cp8(z.B)
	case 0xB9: // CP C
		z.cp8(z.C)
	case 0xBA: // CP D
		z.cp8(z.D)
	case 0xBB: // CP E
		z.cp8(z.E)
	case 0xBC: // CP H
		z.cp8(z.H)
	case 0xBD: // CP L
		z.cp8(z.L)
	case 0xBE: // CP (HL)
		z.cp8(bus.Read(z.HL()))
	case 0xBF: // CP A
		z.cp8(z.A)

	// 0xC0 - 0xFF: Control and Jump Instructions
	case 0xC0: // RET NZ
		if (z.F & FlagZ) == 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xC1: // POP BC
		z.SetBC(z.PopWord(bus))
	case 0xC2: // JP NZ, nn
		target := z.fetchWord(bus)
		if (z.F & FlagZ) == 0 {
			z.PC = target
		}
	case 0xC3: // JP nn
		z.PC = z.fetchWord(bus)
	case 0xC4: // CALL NZ, nn
		target := z.fetchWord(bus)
		if (z.F & FlagZ) == 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xC5: // PUSH BC
		z.PushWord(bus, z.BC())
	case 0xC6: // ADD A, n
		z.add8(z.fetchByte(bus))
	case 0xC7: // RST 00h
		z.PushWord(bus, z.PC)
		z.PC = 0x0000

	case 0xC8: // RET Z
		if (z.F & FlagZ) != 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xC9: // RET
		z.PC = z.PopWord(bus)
	case 0xCA: // JP Z, nn
		target := z.fetchWord(bus)
		if (z.F & FlagZ) != 0 {
			z.PC = target
		}
	case 0xCB: // Prefix CB (Bit & Shift Instructions)
		return z.execOpcodeCB(bus)
	case 0xCC: // CALL Z, nn
		target := z.fetchWord(bus)
		if (z.F & FlagZ) != 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xCD: // CALL nn
		target := z.fetchWord(bus)
		z.PushWord(bus, z.PC)
		z.PC = target
	case 0xCE: // ADC A, n
		z.adc8(z.fetchByte(bus))
	case 0xCF: // RST 08h
		z.PushWord(bus, z.PC)
		z.PC = 0x0008

	case 0xD0: // RET NC
		if (z.F & FlagC) == 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xD1: // POP DE
		z.SetDE(z.PopWord(bus))
	case 0xD2: // JP NC, nn
		target := z.fetchWord(bus)
		if (z.F & FlagC) == 0 {
			z.PC = target
		}
	case 0xD3: // OUT (n), A
		port := uint16(z.fetchByte(bus)) | (uint16(z.A) << 8)
		bus.Out(port, z.A)
	case 0xD4: // CALL NC, nn
		target := z.fetchWord(bus)
		if (z.F & FlagC) == 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xD5: // PUSH DE
		z.PushWord(bus, z.DE())
	case 0xD6: // SUB n
		z.sub8(z.fetchByte(bus))
	case 0xD7: // RST 10h
		z.PushWord(bus, z.PC)
		z.PC = 0x0010

	case 0xD8: // RET C
		if (z.F & FlagC) != 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xD9: // EXX
		bc, de, hl := z.BC(), z.DE(), z.HL()
		z.SetBC(z.BC1())
		z.SetDE(z.DE1())
		z.SetHL(z.HL1())
		z.SetBC1(bc)
		z.SetDE1(de)
		z.SetHL1(hl)
	case 0xDA: // JP C, nn
		target := z.fetchWord(bus)
		if (z.F & FlagC) != 0 {
			z.PC = target
		}
	case 0xDB: // IN A, (n)
		port := uint16(z.fetchByte(bus)) | (uint16(z.A) << 8)
		z.A = bus.In(port)
	case 0xDC: // CALL C, nn
		target := z.fetchWord(bus)
		if (z.F & FlagC) != 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xDD: // Prefix DD (IX instructions)
		return z.execOpcodeIndex(bus, &z.IX)
	case 0xDE: // SBC A, n
		z.sbc8(z.fetchByte(bus))
	case 0xDF: // RST 18h
		z.PushWord(bus, z.PC)
		z.PC = 0x0018

	case 0xE0: // RET PO
		if (z.F & FlagP) == 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xE1: // POP HL
		z.SetHL(z.PopWord(bus))
	case 0xE2: // JP PO, nn
		target := z.fetchWord(bus)
		if (z.F & FlagP) == 0 {
			z.PC = target
		}
	case 0xE3: // EX (SP), HL
		low := bus.Read(z.SP)
		high := bus.Read(z.SP + 1)
		spVal := (uint16(high) << 8) | uint16(low)
		bus.Write(z.SP, z.L)
		bus.Write(z.SP+1, z.H)
		z.SetHL(spVal)
	case 0xE4: // CALL PO, nn
		target := z.fetchWord(bus)
		if (z.F & FlagP) == 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xE5: // PUSH HL
		z.PushWord(bus, z.HL())
	case 0xE6: // AND n
		z.and8(z.fetchByte(bus))
	case 0xE7: // RST 20h
		z.PushWord(bus, z.PC)
		z.PC = 0x0020

	case 0xE8: // RET PE
		if (z.F & FlagP) != 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xE9: // JP (HL)
		z.PC = z.HL()
	case 0xEA: // JP PE, nn
		target := z.fetchWord(bus)
		if (z.F & FlagP) != 0 {
			z.PC = target
		}
	case 0xEB: // EX DE, HL
		de := z.DE()
		z.SetDE(z.HL())
		z.SetHL(de)
	case 0xEC: // CALL PE, nn
		target := z.fetchWord(bus)
		if (z.F & FlagP) != 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xED: // Prefix ED
		return z.execOpcodeED(bus)
	case 0xEE: // XOR n
		z.xor8(z.fetchByte(bus))
	case 0xEF: // RST 28h
		z.PushWord(bus, z.PC)
		z.PC = 0x0028

	case 0xF0: // RET P (Positive)
		if (z.F & FlagS) == 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xF1: // POP AF
		z.SetAF(z.PopWord(bus))
	case 0xF2: // JP P, nn
		target := z.fetchWord(bus)
		if (z.F & FlagS) == 0 {
			z.PC = target
		}
	case 0xF3: // DI
		z.IFF1 = false
		z.IFF2 = false
	case 0xF4: // CALL P, nn
		target := z.fetchWord(bus)
		if (z.F & FlagS) == 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xF5: // PUSH AF
		z.PushWord(bus, z.AF())
	case 0xF6: // OR n
		z.or8(z.fetchByte(bus))
	case 0xF7: // RST 30h
		z.PushWord(bus, z.PC)
		z.PC = 0x0030

	case 0xF8: // RET M (Minus)
		if (z.F & FlagS) != 0 {
			z.PC = z.PopWord(bus)
			cycles += 6
		}
	case 0xF9: // LD SP, HL
		z.SP = z.HL()
	case 0xFA: // JP M, nn
		target := z.fetchWord(bus)
		if (z.F & FlagS) != 0 {
			z.PC = target
		}
	case 0xFB: // EI
		z.IFF1 = true
		z.IFF2 = true
		z.EIWait = true
	case 0xFC: // CALL M, nn
		target := z.fetchWord(bus)
		if (z.F & FlagS) != 0 {
			z.PushWord(bus, z.PC)
			z.PC = target
			cycles += 7
		}
	case 0xFD: // Prefix FD (IY instructions)
		return z.execOpcodeIndex(bus, &z.IY)
	case 0xFE: // CP n
		z.cp8(z.fetchByte(bus))
	case 0xFF: // RST 38h
		z.PushWord(bus, z.PC)
		z.PC = 0x0038
	}

	return cycles
}

// CB Opcode Dispatcher (Rotate, Shift, Bit)
func (z *Z80) execOpcodeCB(bus Bus) int {
	op := z.fetchByte(bus)
	cycles := CyclesCB[op]

	// Register mapping for lower 3 bits: 0=B, 1=C, 2=D, 3=E, 4=H, 5=L, 6=(HL), 7=A
	regIndex := op & 0x07
	var val uint8
	switch regIndex {
	case 0:
		val = z.B
	case 1:
		val = z.C
	case 2:
		val = z.D
	case 3:
		val = z.E
	case 4:
		val = z.H
	case 5:
		val = z.L
	case 6:
		val = bus.Read(z.HL())
	case 7:
		val = z.A
	}

	bitIndex := (op >> 3) & 0x07

	if op < 0x40 {
		// Rotates and shifts
		var res uint8
		switch bitIndex {
		case 0:
			res = z.rlc(val)
		case 1:
			res = z.rrc(val)
		case 2:
			res = z.rl(val)
		case 3:
			res = z.rr(val)
		case 4:
			res = z.sla(val)
		case 5:
			res = z.sra(val)
		case 6:
			res = z.sll(val)
		case 7:
			res = z.srl(val)
		}
		// Write result back
		switch regIndex {
		case 0:
			z.B = res
		case 1:
			z.C = res
		case 2:
			z.D = res
		case 3:
			z.E = res
		case 4:
			z.H = res
		case 5:
			z.L = res
		case 6:
			bus.Write(z.HL(), res)
		case 7:
			z.A = res
		}
	} else if op < 0x80 {
		// BIT b, r
		z.bit(bitIndex, val)
	} else if op < 0xC0 {
		// RES b, r
		res := val &^ (1 << bitIndex)
		switch regIndex {
		case 0:
			z.B = res
		case 1:
			z.C = res
		case 2:
			z.D = res
		case 3:
			z.E = res
		case 4:
			z.H = res
		case 5:
			z.L = res
		case 6:
			bus.Write(z.HL(), res)
		case 7:
			z.A = res
		}
	} else {
		// SET b, r
		res := val | (1 << bitIndex)
		switch regIndex {
		case 0:
			z.B = res
		case 1:
			z.C = res
		case 2:
			z.D = res
		case 3:
			z.E = res
		case 4:
			z.H = res
		case 5:
			z.L = res
		case 6:
			bus.Write(z.HL(), res)
		case 7:
			z.A = res
		}
	}

	return cycles
}

// ED Opcode Dispatcher (Extended Instructions & Patch)
func (z *Z80) execOpcodeED(bus Bus) int {
	op := z.fetchByte(bus)
	cycles := CyclesED[op]
	if cycles == 0 {
		cycles = 8
	}

	switch op {
	// BIOS Patch Hook: ED FE (DB FE in fMSX)
	case 0xFE:
		if z.PatchHook != nil {
			z.PatchHook(z, bus)
		}
		return 8

	// IN r, (C)
	case 0x40: // IN B, (C)
		z.B = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.B]
	case 0x48: // IN C, (C)
		z.C = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.C]
	case 0x50: // IN D, (C)
		z.D = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.D]
	case 0x58: // IN E, (C)
		z.E = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.E]
	case 0x60: // IN H, (C)
		z.H = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.H]
	case 0x68: // IN L, (C)
		z.L = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.L]
	case 0x70: // IN (C) / IN F, (C)
		inVal := bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[inVal]
	case 0x78: // IN A, (C)
		z.A = bus.In(z.BC())
		z.F = (z.F & FlagC) | PZSTable[z.A]

	// OUT (C), r
	case 0x41: // OUT (C), B
		bus.Out(z.BC(), z.B)
	case 0x49: // OUT (C), C
		bus.Out(z.BC(), z.C)
	case 0x51: // OUT (C), D
		bus.Out(z.BC(), z.D)
	case 0x59: // OUT (C), E
		bus.Out(z.BC(), z.E)
	case 0x61: // OUT (C), H
		bus.Out(z.BC(), z.H)
	case 0x69: // OUT (C), L
		bus.Out(z.BC(), z.L)
	case 0x71: // OUT (C), 0
		bus.Out(z.BC(), 0)
	case 0x79: // OUT (C), A
		bus.Out(z.BC(), z.A)

	// 16-bit SBC / ADC HL, rr
	case 0x42: // SBC HL, BC
		z.sbc16(z.BC())
	case 0x4A: // ADC HL, BC
		z.adc16(z.BC())
	case 0x52: // SBC HL, DE
		z.sbc16(z.DE())
	case 0x5A: // ADC HL, DE
		z.adc16(z.DE())
	case 0x62: // SBC HL, HL
		z.sbc16(z.HL())
	case 0x6A: // ADC HL, HL
		z.adc16(z.HL())
	case 0x72: // SBC HL, SP
		z.sbc16(z.SP)
	case 0x7A: // ADC HL, SP
		z.adc16(z.SP)

	// 16-bit LD (nn), rr
	case 0x43: // LD (nn), BC
		addr := z.fetchWord(bus)
		bus.Write(addr, z.C)
		bus.Write(addr+1, z.B)
	case 0x4B: // LD BC, (nn)
		addr := z.fetchWord(bus)
		z.C = bus.Read(addr)
		z.B = bus.Read(addr + 1)
	case 0x53: // LD (nn), DE
		addr := z.fetchWord(bus)
		bus.Write(addr, z.E)
		bus.Write(addr+1, z.D)
	case 0x5B: // LD DE, (nn)
		addr := z.fetchWord(bus)
		z.E = bus.Read(addr)
		z.D = bus.Read(addr + 1)
	case 0x63: // LD (nn), HL (same as 0x22, but with ED prefix)
		addr := z.fetchWord(bus)
		bus.Write(addr, z.L)
		bus.Write(addr+1, z.H)
	case 0x6B: // LD HL, (nn) (same as 0x2A)
		addr := z.fetchWord(bus)
		z.L = bus.Read(addr)
		z.H = bus.Read(addr + 1)
	case 0x73: // LD (nn), SP
		addr := z.fetchWord(bus)
		bus.Write(addr, uint8(z.SP))
		bus.Write(addr+1, uint8(z.SP>>8))
	case 0x7B: // LD SP, (nn)
		addr := z.fetchWord(bus)
		z.SP = (uint16(bus.Read(addr+1)) << 8) | uint16(bus.Read(addr))

	case 0x44: // NEG
		a := z.A
		z.A = 0
		z.sub8(a)
	case 0x46: // IM 0
		z.IM = 0
	case 0x56: // IM 1
		z.IM = 1
	case 0x5E: // IM 2
		z.IM = 2

	case 0x47: // LD I, A
		z.I = z.A
	case 0x57: // LD A, I
		z.A = z.I
		z.F = (z.F & FlagC) | ZSTable[z.A]
		if z.IFF2 {
			z.F |= FlagP
		}
	case 0x4F: // LD R, A
		z.R = z.A
	case 0x5F: // LD A, R
		z.A = z.R
		z.F = (z.F & FlagC) | ZSTable[z.A]
		if z.IFF2 {
			z.F |= FlagP
		}

	case 0x4D: // RETI
		z.PC = z.PopWord(bus)
	case 0x45: // RETN
		z.IFF1 = z.IFF2
		z.PC = z.PopWord(bus)

	case 0x67: // RRD
		hl := z.HL()
		val := bus.Read(hl)
		newHL := (val >> 4) | (z.A << 4)
		z.A = (z.A & 0xF0) | (val & 0x0F)
		bus.Write(hl, newHL)
		z.F = (z.F & FlagC) | PZSTable[z.A]

	case 0x6F: // RLD
		hl := z.HL()
		val := bus.Read(hl)
		newHL := (val << 4) | (z.A & 0x0F)
		z.A = (z.A & 0xF0) | (val >> 4)
		bus.Write(hl, newHL)
		z.F = (z.F & FlagC) | PZSTable[z.A]

	// Block Transfers
	case 0xA0: // LDI
		bus.Write(z.DE(), bus.Read(z.HL()))
		z.SetHL(z.HL() + 1)
		z.SetDE(z.DE() + 1)
		z.SetBC(z.BC() - 1)
		z.F &^= (FlagH | FlagN | FlagP)
		if z.BC() != 0 {
			z.F |= FlagP
		}
	case 0xB0: // LDIR
		bus.Write(z.DE(), bus.Read(z.HL()))
		z.SetHL(z.HL() + 1)
		z.SetDE(z.DE() + 1)
		z.SetBC(z.BC() - 1)
		z.F &^= (FlagH | FlagN | FlagP)
		if z.BC() != 0 {
			z.F |= FlagP
			z.PC -= 2 // repeat
			cycles = 21
		} else {
			cycles = 16
		}

	case 0xA8: // LDD
		bus.Write(z.DE(), bus.Read(z.HL()))
		z.SetHL(z.HL() - 1)
		z.SetDE(z.DE() - 1)
		z.SetBC(z.BC() - 1)
		z.F &^= (FlagH | FlagN | FlagP)
		if z.BC() != 0 {
			z.F |= FlagP
		}
	case 0xB8: // LDDR
		bus.Write(z.DE(), bus.Read(z.HL()))
		z.SetHL(z.HL() - 1)
		z.SetDE(z.DE() - 1)
		z.SetBC(z.BC() - 1)
		z.F &^= (FlagH | FlagN | FlagP)
		if z.BC() != 0 {
			z.F |= FlagP
			z.PC -= 2 // repeat
			cycles = 21
		} else {
			cycles = 16
		}

	case 0xA1: // CPI
		val := bus.Read(z.HL())
		res := z.A - val
		z.SetHL(z.HL() + 1)
		z.SetBC(z.BC() - 1)
		f := (z.F & FlagC) | FlagN | ZSTable[res]
		if (int8(z.A&0x0F) - int8(val&0x0F)) < 0 {
			f |= FlagH
		}
		if z.BC() != 0 {
			f |= FlagP
		}
		z.F = f
	case 0xB1: // CPIR
		val := bus.Read(z.HL())
		res := z.A - val
		z.SetHL(z.HL() + 1)
		z.SetBC(z.BC() - 1)
		f := (z.F & FlagC) | FlagN | ZSTable[res]
		if (int8(z.A&0x0F) - int8(val&0x0F)) < 0 {
			f |= FlagH
		}
		if z.BC() != 0 {
			f |= FlagP
			if res != 0 {
				z.PC -= 2 // repeat
				cycles = 21
			} else {
				cycles = 16
			}
		} else {
			cycles = 16
		}
		z.F = f

	case 0xA9: // CPD
		val := bus.Read(z.HL())
		res := z.A - val
		z.SetHL(z.HL() - 1)
		z.SetBC(z.BC() - 1)
		f := (z.F & FlagC) | FlagN | ZSTable[res]
		if (int8(z.A&0x0F) - int8(val&0x0F)) < 0 {
			f |= FlagH
		}
		if z.BC() != 0 {
			f |= FlagP
		}
		z.F = f
	case 0xB9: // CPDR
		val := bus.Read(z.HL())
		res := z.A - val
		z.SetHL(z.HL() - 1)
		z.SetBC(z.BC() - 1)
		f := (z.F & FlagC) | FlagN | ZSTable[res]
		if (int8(z.A&0x0F) - int8(val&0x0F)) < 0 {
			f |= FlagH
		}
		if z.BC() != 0 {
			f |= FlagP
			if res != 0 {
				z.PC -= 2 // repeat
				cycles = 21
			} else {
				cycles = 16
			}
		} else {
			cycles = 16
		}
		z.F = f

	case 0xA2: // INI
		bus.Write(z.HL(), bus.In(z.BC()))
		z.B--
		z.SetHL(z.HL() + 1)
		z.F = ZSTable[z.B] | FlagN
	case 0xB2: // INIR
		bus.Write(z.HL(), bus.In(z.BC()))
		z.B--
		z.SetHL(z.HL() + 1)
		z.F = ZSTable[z.B] | FlagN
		if z.B != 0 {
			z.PC -= 2
			cycles = 21
		} else {
			cycles = 16
		}

	case 0xAA: // IND
		bus.Write(z.HL(), bus.In(z.BC()))
		z.B--
		z.SetHL(z.HL() - 1)
		z.F = ZSTable[z.B] | FlagN
	case 0xBA: // INDR
		bus.Write(z.HL(), bus.In(z.BC()))
		z.B--
		z.SetHL(z.HL() - 1)
		z.F = ZSTable[z.B] | FlagN
		if z.B != 0 {
			z.PC -= 2
			cycles = 21
		} else {
			cycles = 16
		}

	case 0xA3: // OUTI
		z.B--
		val := bus.Read(z.HL())
		z.SetHL(z.HL() + 1)
		bus.Out(z.BC(), val)
		z.F = FlagN
		if z.B == 0 {
			z.F |= FlagZ
		}
		if uint16(z.L)+uint16(val) > 255 {
			z.F |= FlagC | FlagH
		}
	case 0xB3: // OTIR
		z.B--
		val := bus.Read(z.HL())
		z.SetHL(z.HL() + 1)
		bus.Out(z.BC(), val)
		z.F = FlagN
		if uint16(z.L)+uint16(val) > 255 {
			z.F |= FlagC | FlagH
		}
		if z.B != 0 {
			z.PC -= 2
			cycles = 21
		} else {
			z.F |= FlagZ
			cycles = 16
		}

	case 0xAB: // OUTD
		z.B--
		val := bus.Read(z.HL())
		z.SetHL(z.HL() - 1)
		bus.Out(z.BC(), val)
		z.F = FlagN
		if z.B == 0 {
			z.F |= FlagZ
		}
		if uint16(z.L)+uint16(val) > 255 {
			z.F |= FlagC | FlagH
		}
	case 0xBB: // OTDR
		z.B--
		val := bus.Read(z.HL())
		z.SetHL(z.HL() - 1)
		bus.Out(z.BC(), val)
		z.F = FlagN
		if uint16(z.L)+uint16(val) > 255 {
			z.F |= FlagC | FlagH
		}
		if z.B != 0 {
			z.PC -= 2
			cycles = 21
		} else {
			z.F |= FlagZ
			cycles = 16
		}
	}

	return cycles
}

// Index Register (IX or IY) Opcode Dispatcher (DD and FD prefixes)
func (z *Z80) execOpcodeIndex(bus Bus, idx *uint16) int {
	op := z.fetchByte(bus)
	cycles := CyclesXX[op]
	if cycles == 0 {
		cycles = 8
	}

	idxHigh := func() uint8 { return uint8(*idx >> 8) }
	idxLow := func() uint8 { return uint8(*idx) }
	setIdxHigh := func(val uint8) { *idx = (*idx & 0x00FF) | (uint16(val) << 8) }
	setIdxLow := func(val uint8) { *idx = (*idx & 0xFF00) | uint16(val) }

	offsetAddr := func() uint16 {
		d := int8(z.fetchByte(bus))
		return uint16(int32(*idx) + int32(d))
	}

	switch op {
	case 0x09: // ADD IX/IY, BC
		z.add16(idx, z.BC())
	case 0x19: // ADD IX/IY, DE
		z.add16(idx, z.DE())
	case 0x29: // ADD IX/IY, IX/IY
		z.add16(idx, *idx)
	case 0x39: // ADD IX/IY, SP
		z.add16(idx, z.SP)

	case 0x21: // LD IX/IY, nn
		*idx = z.fetchWord(bus)
	case 0x22: // LD (nn), IX/IY
		addr := z.fetchWord(bus)
		bus.Write(addr, idxLow())
		bus.Write(addr+1, idxHigh())
	case 0x2A: // LD IX/IY, (nn)
		addr := z.fetchWord(bus)
		low := bus.Read(addr)
		high := bus.Read(addr + 1)
		*idx = (uint16(high) << 8) | uint16(low)

	case 0x23: // INC IX/IY
		*idx++
	case 0x2B: // DEC IX/IY
		*idx--

	case 0x24: // INC IXh/IYh
		setIdxHigh(z.inc8(idxHigh()))
	case 0x25: // DEC IXh/IYh
		setIdxHigh(z.dec8(idxHigh()))
	case 0x26: // LD IXh/IYh, n
		setIdxHigh(z.fetchByte(bus))

	case 0x2C: // INC IXl/IYl
		setIdxLow(z.inc8(idxLow()))
	case 0x2D: // DEC IXl/IYl
		setIdxLow(z.dec8(idxLow()))
	case 0x2E: // LD IXl/IYl, n
		setIdxLow(z.fetchByte(bus))

	case 0x34: // INC (IX/IY+d)
		addr := offsetAddr()
		bus.Write(addr, z.inc8(bus.Read(addr)))
	case 0x35: // DEC (IX/IY+d)
		addr := offsetAddr()
		bus.Write(addr, z.dec8(bus.Read(addr)))
	case 0x36: // LD (IX/IY+d), n
		addr := offsetAddr()
		bus.Write(addr, z.fetchByte(bus))

	// LD r, (IX/IY+d)
	case 0x46: // LD B, (IX/IY+d)
		z.B = bus.Read(offsetAddr())
	case 0x4E: // LD C, (IX/IY+d)
		z.C = bus.Read(offsetAddr())
	case 0x56: // LD D, (IX/IY+d)
		z.D = bus.Read(offsetAddr())
	case 0x5E: // LD E, (IX/IY+d)
		z.E = bus.Read(offsetAddr())
	case 0x66: // LD H, (IX/IY+d)
		z.H = bus.Read(offsetAddr())
	case 0x6E: // LD L, (IX/IY+d)
		z.L = bus.Read(offsetAddr())
	case 0x7E: // LD A, (IX/IY+d)
		z.A = bus.Read(offsetAddr())

	// LD (IX/IY+d), r
	case 0x70: // LD (IX/IY+d), B
		bus.Write(offsetAddr(), z.B)
	case 0x71: // LD (IX/IY+d), C
		bus.Write(offsetAddr(), z.C)
	case 0x72: // LD (IX/IY+d), D
		bus.Write(offsetAddr(), z.D)
	case 0x73: // LD (IX/IY+d), E
		bus.Write(offsetAddr(), z.E)
	case 0x74: // LD (IX/IY+d), H
		bus.Write(offsetAddr(), z.H)
	case 0x75: // LD (IX/IY+d), L
		bus.Write(offsetAddr(), z.L)
	case 0x77: // LD (IX/IY+d), A
		bus.Write(offsetAddr(), z.A)

	// ALU (IX/IY+d)
	case 0x86: // ADD A, (IX/IY+d)
		z.add8(bus.Read(offsetAddr()))
	case 0x8E: // ADC A, (IX/IY+d)
		z.adc8(bus.Read(offsetAddr()))
	case 0x96: // SUB (IX/IY+d)
		z.sub8(bus.Read(offsetAddr()))
	case 0x9E: // SBC A, (IX/IY+d)
		z.sbc8(bus.Read(offsetAddr()))
	case 0xA6: // AND (IX/IY+d)
		z.and8(bus.Read(offsetAddr()))
	case 0xAE: // XOR (IX/IY+d)
		z.xor8(bus.Read(offsetAddr()))
	case 0xB6: // OR (IX/IY+d)
		z.or8(bus.Read(offsetAddr()))
	case 0xBE: // CP (IX/IY+d)
		z.cp8(bus.Read(offsetAddr()))

	case 0xE1: // POP IX/IY
		*idx = z.PopWord(bus)
	case 0xE5: // PUSH IX/IY
		z.PushWord(bus, *idx)
	case 0xE3: // EX (SP), IX/IY
		low := bus.Read(z.SP)
		high := bus.Read(z.SP + 1)
		spVal := (uint16(high) << 8) | uint16(low)
		bus.Write(z.SP, idxLow())
		bus.Write(z.SP+1, idxHigh())
		*idx = spVal
	case 0xE9: // JP (IX/IY)
		z.PC = *idx
	case 0xF9: // LD SP, IX/IY
		z.SP = *idx

	// Prefix DDCB / FDCB
	case 0xCB:
		d := int8(z.fetchByte(bus))
		cbOp := z.fetchByte(bus)
		addr := uint16(int32(*idx) + int32(d))
		return z.execOpcodeIndexCB(bus, addr, cbOp)

	default:
		// Unprefixed fallback if no IX/IY override
		return z.execOpcode(bus, op)
	}

	return cycles
}

// DDCB / FDCB Opcode Dispatcher
func (z *Z80) execOpcodeIndexCB(bus Bus, addr uint16, op uint8) int {
	val := bus.Read(addr)
	bitIndex := (op >> 3) & 0x07

	if op < 0x40 {
		var res uint8
		switch bitIndex {
		case 0:
			res = z.rlc(val)
		case 1:
			res = z.rrc(val)
		case 2:
			res = z.rl(val)
		case 3:
			res = z.rr(val)
		case 4:
			res = z.sla(val)
		case 5:
			res = z.sra(val)
		case 6:
			res = z.sll(val)
		case 7:
			res = z.srl(val)
		}
		bus.Write(addr, res)
	} else if op < 0x80 {
		z.bit(bitIndex, val)
	} else if op < 0xC0 {
		res := val &^ (1 << bitIndex)
		bus.Write(addr, res)
	} else {
		res := val | (1 << bitIndex)
		bus.Write(addr, res)
	}

	return 23
}
