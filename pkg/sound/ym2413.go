package sound

import (
	"sync"
)

// YM2413 Channel and Operator constants
const (
	OPLLChannels  = 9
	OPLLOperators = 18 // 2 operators per channel (Modulator and Carrier)
	OPLLBaseClock = 3579545
)

// Envelope generator states
const (
	EGStateOff = iota
	EGStateAttack
	EGStateDecay
	EGStateSustain
	EGStateRelease
)

// Logarithmic Sine Table (256 entries for quarter wave)
var logSinTable = [256]uint16{
	0x859, 0x6c3, 0x607, 0x58b, 0x52e, 0x4e4, 0x4a6, 0x471,
	0x443, 0x41a, 0x3f5, 0x3d3, 0x3b5, 0x398, 0x37e, 0x365,
	0x34e, 0x339, 0x324, 0x311, 0x2ff, 0x2ed, 0x2dc, 0x2cd,
	0x2bd, 0x2af, 0x2a0, 0x293, 0x286, 0x279, 0x26d, 0x261,
	0x256, 0x24b, 0x240, 0x236, 0x22c, 0x222, 0x218, 0x20f,
	0x206, 0x1fd, 0x1f5, 0x1ec, 0x1e4, 0x1dc, 0x1d4, 0x1cd,
	0x1c5, 0x1be, 0x1b7, 0x1b0, 0x1a9, 0x1a2, 0x19b, 0x195,
	0x18f, 0x188, 0x182, 0x17c, 0x177, 0x171, 0x16b, 0x166,
	0x160, 0x15b, 0x155, 0x150, 0x14b, 0x146, 0x141, 0x13c,
	0x137, 0x133, 0x12e, 0x129, 0x125, 0x121, 0x11c, 0x118,
	0x114, 0x10f, 0x10b, 0x107, 0x103, 0x0ff, 0x0fb, 0x0f8,
	0x0f4, 0x0f0, 0x0ec, 0x0e9, 0x0e5, 0x0e2, 0x0de, 0x0db,
	0x0d7, 0x0d4, 0x0d1, 0x0cd, 0x0ca, 0x0c7, 0x0c4, 0x0c1,
	0x0be, 0x0bb, 0x0b8, 0x0b5, 0x0b2, 0x0af, 0x0ac, 0x0a9,
	0x0a7, 0x0a4, 0x0a1, 0x09f, 0x09c, 0x099, 0x097, 0x094,
	0x092, 0x08f, 0x08d, 0x08a, 0x088, 0x086, 0x083, 0x081,
	0x07f, 0x07d, 0x07a, 0x078, 0x076, 0x074, 0x072, 0x070,
	0x06e, 0x06c, 0x06a, 0x068, 0x066, 0x064, 0x062, 0x060,
	0x05e, 0x05c, 0x05b, 0x059, 0x057, 0x055, 0x053, 0x052,
	0x050, 0x04e, 0x04d, 0x04b, 0x04a, 0x048, 0x046, 0x045,
	0x043, 0x042, 0x040, 0x03f, 0x03e, 0x03c, 0x03b, 0x039,
	0x038, 0x037, 0x035, 0x034, 0x033, 0x031, 0x030, 0x02f,
	0x02e, 0x02d, 0x02b, 0x02a, 0x029, 0x028, 0x027, 0x026,
	0x025, 0x024, 0x023, 0x022, 0x021, 0x020, 0x01f, 0x01e,
	0x01d, 0x01c, 0x01b, 0x01a, 0x019, 0x018, 0x017, 0x017,
	0x016, 0x015, 0x014, 0x014, 0x013, 0x012, 0x011, 0x011,
	0x010, 0x00f, 0x00f, 0x00e, 0x00d, 0x00d, 0x00c, 0x00c,
	0x00b, 0x00a, 0x00a, 0x009, 0x009, 0x008, 0x008, 0x007,
	0x007, 0x007, 0x006, 0x006, 0x005, 0x005, 0x005, 0x004,
	0x004, 0x004, 0x003, 0x003, 0x003, 0x002, 0x002, 0x002,
	0x002, 0x001, 0x001, 0x001, 0x001, 0x001, 0x001, 0x001,
	0x000, 0x000, 0x000, 0x000, 0x000, 0x000, 0x000, 0x000,
}

// Exponential Table (256 entries for conversion from attenuation to linear)
var expTable = [256]uint16{
	0x7fa, 0x7f5, 0x7ef, 0x7ea, 0x7e4, 0x7df, 0x7da, 0x7d4,
	0x7cf, 0x7c9, 0x7c4, 0x7bf, 0x7b9, 0x7b4, 0x7ae, 0x7a9,
	0x7a4, 0x79f, 0x799, 0x794, 0x78f, 0x78a, 0x784, 0x77f,
	0x77a, 0x775, 0x770, 0x76a, 0x765, 0x760, 0x75b, 0x756,
	0x751, 0x74c, 0x747, 0x742, 0x73d, 0x738, 0x733, 0x72e,
	0x729, 0x724, 0x71f, 0x71a, 0x715, 0x710, 0x70b, 0x706,
	0x702, 0x6fd, 0x6f8, 0x6f3, 0x6ee, 0x6e9, 0x6e5, 0x6e0,
	0x6db, 0x6d6, 0x6d2, 0x6cd, 0x6c8, 0x6c4, 0x6bf, 0x6ba,
	0x6b5, 0x6b1, 0x6ac, 0x6a8, 0x6a3, 0x69e, 0x69a, 0x695,
	0x691, 0x68c, 0x688, 0x683, 0x67f, 0x67a, 0x676, 0x671,
	0x66d, 0x668, 0x664, 0x65f, 0x65b, 0x657, 0x652, 0x64e,
	0x649, 0x645, 0x641, 0x63c, 0x638, 0x634, 0x630, 0x62b,
	0x627, 0x623, 0x61e, 0x61a, 0x616, 0x612, 0x60e, 0x609,
	0x605, 0x601, 0x5fd, 0x5f9, 0x5f5, 0x5f0, 0x5ec, 0x5e8,
	0x5e4, 0x5e0, 0x5dc, 0x5d8, 0x5d4, 0x5d0, 0x5cc, 0x5c8,
	0x5c4, 0x5c0, 0x5bc, 0x5b8, 0x5b4, 0x5b0, 0x5ac, 0x5a8,
	0x5a4, 0x5a0, 0x59c, 0x599, 0x595, 0x591, 0x58d, 0x589,
	0x585, 0x581, 0x57e, 0x57a, 0x576, 0x572, 0x56f, 0x56b,
	0x567, 0x563, 0x560, 0x55c, 0x558, 0x554, 0x551, 0x54d,
	0x549, 0x546, 0x542, 0x53e, 0x53b, 0x537, 0x534, 0x530,
	0x52c, 0x529, 0x525, 0x522, 0x51e, 0x51b, 0x517, 0x514,
	0x510, 0x50d, 0x509, 0x506, 0x502, 0x4ff, 0x4fb, 0x4f8,
	0x4f4, 0x4f1, 0x4ed, 0x4ea, 0x4e6, 0x4e3, 0x4df, 0x4dc,
	0x4d8, 0x4d5, 0x4d2, 0x4ce, 0x4cb, 0x4c7, 0x4c4, 0x4c1,
	0x4bd, 0x4ba, 0x4b7, 0x4b3, 0x4b0, 0x4ad, 0x4a9, 0x4a6,
	0x4a3, 0x49f, 0x49c, 0x499, 0x496, 0x492, 0x48f, 0x48c,
	0x488, 0x485, 0x482, 0x47f, 0x47b, 0x478, 0x475, 0x472,
	0x46e, 0x46b, 0x468, 0x465, 0x462, 0x45e, 0x45b, 0x458,
	0x455, 0x452, 0x44e, 0x44b, 0x448, 0x445, 0x442, 0x43f,
	0x43b, 0x438, 0x435, 0x432, 0x42f, 0x42c, 0x429, 0x425,
	0x422, 0x41f, 0x41c, 0x419, 0x416, 0x413, 0x410, 0x40d,
	0x40a, 0x407, 0x404, 0x401, 0x3fe, 0x3fb, 0x3f8, 0x3f5,
}

// Frequency Multipliers (0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 12, 12, 15, 15)
var mlTable = [16]uint32{
	1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30,
}

// Key Scale Level Table (KL)
var klTable = [16]int{
	0, 24, 32, 37, 40, 43, 45, 47, 48, 50, 51, 52, 53, 54, 55, 56,
}

// YM2413 16 Pre-programmed Instrument Patches (15 ROM + 3 Rhythm sets)
var romPatches = [19][8]uint8{
	// 0: User custom instrument (from registers 0x00..0x07)
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	// 1: Violin
	{0x61, 0x61, 0x1e, 0x17, 0xf0, 0x7f, 0x00, 0x17},
	// 2: Guitar
	{0x13, 0x41, 0x16, 0x0e, 0xfd, 0xf4, 0x23, 0x23},
	// 3: Piano
	{0x03, 0x01, 0x9a, 0x04, 0xf3, 0xf3, 0x13, 0xf3},
	// 4: Flute
	{0x11, 0x61, 0x0e, 0x07, 0xfa, 0x64, 0x70, 0x17},
	// 5: Clarinet
	{0x22, 0x21, 0x1e, 0x06, 0xf0, 0x76, 0x00, 0x28},
	// 6: Oboe
	{0x21, 0x22, 0x16, 0x05, 0xf0, 0x71, 0x00, 0x18},
	// 7: Trumpet
	{0x21, 0x61, 0x1d, 0x07, 0x82, 0x80, 0x17, 0x17},
	// 8: Organ
	{0x23, 0x21, 0x2d, 0x16, 0x90, 0x90, 0x00, 0x07},
	// 9: Horn
	{0x21, 0x21, 0x1b, 0x06, 0x64, 0x65, 0x10, 0x17},
	// 10: Synthesizer
	{0x21, 0x21, 0x0b, 0x1a, 0x85, 0xa0, 0x70, 0x07},
	// 11: Harpsichord
	{0x23, 0x01, 0x83, 0x10, 0xff, 0xb4, 0x10, 0xf4},
	// 12: Vibraphone
	{0x97, 0xc1, 0x20, 0x07, 0xff, 0xf4, 0x22, 0x22},
	// 13: Synthesizer Bass
	{0x61, 0x00, 0x0c, 0x05, 0xc2, 0xf6, 0x40, 0x44},
	// 14: Acoustic Bass
	{0x01, 0x01, 0x56, 0x03, 0x94, 0xc2, 0x03, 0x12},
	// 15: Electric Guitar
	{0x21, 0x01, 0x89, 0x03, 0xf1, 0xe4, 0xf0, 0x23},

	// Rhythm Instruments:
	// 16: Bass Drum
	{0x01, 0x01, 0x16, 0x00, 0xfd, 0xf8, 0x2f, 0x6d},
	// 17: High Hat / Snare Drum
	{0x01, 0x01, 0x00, 0x00, 0xd8, 0xd8, 0xf9, 0xf8},
	// 18: Tom-Tom / Top Cymbal
	{0x05, 0x01, 0x00, 0x00, 0xf8, 0xba, 0x49, 0x55},
}

// Operator represents one of the two FM synthesis operators (Modulator or Carrier).
type Operator struct {
	Phase        uint32 // Phase accumulator (18 bits: 10 integer, 8 fractional)
	PhaseStep    uint32 // Frequency step per sample
	WaveForm     uint8  // 0: full sine, 1: half-sine rectified
	Feedback     uint8  // Modulator feedback level (0..7)
	FeedbackBuf  [2]int // 2-stage feedback delay buffer
	AM           bool   // Amplitude modulation (tremolo) enable
	VIB          bool   // Vibrato (pitch modulation) enable
	EGType       bool   // Envelope type (0: decaying, 1: sustained)
	KSR          bool   // Key scale rate
	ML           uint8  // Frequency multiplier (0..15)
	TL           uint8  // Total level attenuation (0..63)
	KSL          uint8  // Key scale level (0..3)
	AR           uint8  // Attack rate (0..15)
	DR           uint8  // Decay rate (0..15)
	SL           uint8  // Sustain level (0..15)
	RR           uint8  // Release rate (0..15)

	// Envelope state
	EGState      int    // EGStateOff, Attack, Decay, Sustain, Release
	EGVolume     uint16 // Current attenuation (0 = max, 127 = silence)
	EGStepCount  uint32 // Sub-sample envelope progression counter
}

// Channel represents one of the 9 OPLL FM channels.
type Channel struct {
	Mod          Operator
	Car          Operator
	FNum         uint16 // 9-bit frequency number (0..511)
	Block        uint8  // 3-bit octave/block (0..7)
	KeyOn        bool   // Note on / key on
	Sustain      bool   // Sustain pedal on/off
	PatchNum     uint8  // Active patch (0..15)
	Volume       uint8  // Carrier volume (0: max, 15: min, -3dB/step)
}

// YM2413 represents the Yamaha YM2413 (OPLL / MSX-MUSIC) sound chip.
type YM2413 struct {
	mu sync.Mutex

	Clock        int
	SampleRate   int
	Regs         [64]uint8 // 64 registers
	Latch        uint8     // Current register latch
	Channels     [OPLLChannels]Channel
	RhythmMode   bool      // True if rhythm mode is active (channels 6..8)
	RhythmKeys   uint8     // Bitmask of active rhythm drums (Reg 0x0E bits 0..4)

	// Low Frequency Oscillators (LFO)
	LFOPhasePM   uint32 // Vibrato phase
	LFOPhaseAM   uint32 // Tremolo phase
	NoiseLFSR    uint32 // 17-bit noise shift register for percussion

	// Volume and Frequency cache for fMSX state compatibility
	FreqCache    [OPLLChannels]int
	VolCache     [OPLLChannels]int
}

// NewYM2413 creates and initializes a YM2413 OPLL chip instance.
func NewYM2413(clock int) *YM2413 {
	if clock <= 0 {
		clock = OPLLBaseClock
	}
	y := &YM2413{
		Clock:      clock,
		SampleRate: DefaultSampleRate,
		NoiseLFSR:  0x10000,
	}
	y.Reset()
	return y
}

// Reset resets all registers, operators, and channels to power-on state.
func (y *YM2413) Reset() {
	y.mu.Lock()
	defer y.mu.Unlock()

	for i := range y.Regs {
		y.Regs[i] = 0
	}
	y.Latch = 0
	y.RhythmMode = false
	y.RhythmKeys = 0
	y.LFOPhasePM = 0
	y.LFOPhaseAM = 0
	y.NoiseLFSR = 0x10000

	for ch := 0; ch < OPLLChannels; ch++ {
		y.Channels[ch] = Channel{
			Mod: Operator{EGState: EGStateOff, EGVolume: 127},
			Car: Operator{EGState: EGStateOff, EGVolume: 127},
		}
		y.applyPatch(ch, 0)
		y.FreqCache[ch] = 0
		y.VolCache[ch] = 0
	}
}

// WriteAddress selects the active YM2413 register (Port 0x7C).
func (y *YM2413) WriteAddress(reg uint8) {
	y.mu.Lock()
	defer y.mu.Unlock()
	y.Latch = reg & 0x3F
}

// WriteData writes a value into the currently latched register (Port 0x7D).
func (y *YM2413) WriteData(val uint8) {
	y.mu.Lock()
	defer y.mu.Unlock()
	y.writeRegister(y.Latch, val)
}

// Write outputs a value directly into register reg.
func (y *YM2413) Write(reg uint8, val uint8) {
	y.mu.Lock()
	defer y.mu.Unlock()
	y.writeRegister(reg&0x3F, val)
}

// writeRegister internal handler for register writes (mutex must be held).
func (y *YM2413) writeRegister(reg uint8, val uint8) {
	y.Regs[reg] = val

	switch {
	case reg <= 0x07:
		// User custom instrument patch (registers 0x00..0x07)
		for ch := 0; ch < OPLLChannels; ch++ {
			if y.Channels[ch].PatchNum == 0 {
				y.applyPatch(ch, 0)
			}
		}

	case reg == 0x0E:
		// Rhythm control register
		prevRhythm := y.RhythmMode
		y.RhythmMode = (val & 0x20) != 0
		y.RhythmKeys = val & 0x1F

		if y.RhythmMode && !prevRhythm {
			// Switch channels 6..8 to rhythm instruments
			y.applyRhythmPatches()
		}

		// Handle rhythm Key-On triggers
		if y.RhythmMode {
			y.triggerDrums(val & 0x1F)
		}

	case reg >= 0x10 && reg <= 0x18:
		// F-Number LSB for channel 0..8
		ch := int(reg - 0x10)
		y.Channels[ch].FNum = (y.Channels[ch].FNum & 0x100) | uint16(val)
		y.updateChannelFreq(ch)

	case reg >= 0x20 && reg <= 0x28:
		// Block, F-Number MSB, KeyOn, Sustain
		ch := int(reg - 0x20)
		c := &y.Channels[ch]
		prevKeyOn := c.KeyOn
		c.Sustain = (val & 0x20) != 0
		c.KeyOn = (val & 0x10) != 0
		c.Block = (val >> 1) & 0x07
		c.FNum = (c.FNum & 0xFF) | (uint16(val&0x01) << 8)
		y.updateChannelFreq(ch)

		if c.KeyOn && !prevKeyOn {
			// Note On: trigger Attack phase for Modulator and Carrier
			y.keyOn(ch)
		} else if !c.KeyOn && prevKeyOn {
			// Note Off: trigger Release phase
			y.keyOff(ch)
		}

	case reg >= 0x30 && reg <= 0x38:
		// Instrument selection (bits 7..4) and Volume (bits 3..0)
		ch := int(reg - 0x30)
		c := &y.Channels[ch]
		patch := val >> 4
		vol := val & 0x0F
		c.Volume = vol
		y.VolCache[ch] = int((15 - vol) * 17)

		if patch != c.PatchNum {
			c.PatchNum = patch
			y.applyPatch(ch, int(patch))
		}
	}
}

// keyOn triggers the attack phase of both operators in channel ch.
func (y *YM2413) keyOn(ch int) {
	c := &y.Channels[ch]
	c.Mod.EGState = EGStateAttack
	c.Mod.Phase = 0
	c.Mod.FeedbackBuf = [2]int{0, 0}

	c.Car.EGState = EGStateAttack
	c.Car.Phase = 0
}

// keyOff triggers the release phase of both operators in channel ch.
func (y *YM2413) keyOff(ch int) {
	c := &y.Channels[ch]
	if c.Mod.EGState != EGStateOff {
		c.Mod.EGState = EGStateRelease
	}
	if c.Car.EGState != EGStateOff {
		c.Car.EGState = EGStateRelease
	}
}

// triggerDrums triggers attack or release for the 5 rhythm drums.
func (y *YM2413) triggerDrums(keys uint8) {
	// Bass Drum (BD): Channel 6 Modulator & Carrier
	if (keys & 0x10) != 0 {
		y.keyOn(6)
	} else {
		y.keyOff(6)
	}

	// Snare Drum (SD): Channel 7 Carrier
	if (keys & 0x08) != 0 {
		y.Channels[7].Car.EGState = EGStateAttack
		y.Channels[7].Car.Phase = 0
	} else {
		y.Channels[7].Car.EGState = EGStateRelease
	}

	// Tom-Tom (TOM): Channel 8 Modulator
	if (keys & 0x04) != 0 {
		y.Channels[8].Mod.EGState = EGStateAttack
		y.Channels[8].Mod.Phase = 0
	} else {
		y.Channels[8].Mod.EGState = EGStateRelease
	}

	// Top Cymbal (CYM): Channel 8 Carrier
	if (keys & 0x02) != 0 {
		y.Channels[8].Car.EGState = EGStateAttack
		y.Channels[8].Car.Phase = 0
	} else {
		y.Channels[8].Car.EGState = EGStateRelease
	}

	// High Hat (HH): Channel 7 Modulator
	if (keys & 0x01) != 0 {
		y.Channels[7].Mod.EGState = EGStateAttack
		y.Channels[7].Mod.Phase = 0
	} else {
		y.Channels[7].Mod.EGState = EGStateRelease
	}
}

// applyPatch sets the patch parameters for channel ch.
func (y *YM2413) applyPatch(ch int, patchNum int) {
	var raw [8]uint8
	if patchNum == 0 {
		// Custom patch from registers 0x00..0x07
		copy(raw[:], y.Regs[0:8])
	} else if patchNum < len(romPatches) {
		raw = romPatches[patchNum]
	}

	c := &y.Channels[ch]

	// Modulator (registers 0, 2, 4, 6)
	c.Mod.AM = (raw[0] & 0x80) != 0
	c.Mod.VIB = (raw[0] & 0x40) != 0
	c.Mod.EGType = (raw[0] & 0x20) != 0
	c.Mod.KSR = (raw[0] & 0x10) != 0
	c.Mod.ML = raw[0] & 0x0F
	c.Mod.KSL = (raw[2] >> 6) & 0x03
	c.Mod.TL = raw[2] & 0x3F
	c.Mod.WaveForm = (raw[3] >> 3) & 0x01
	c.Mod.Feedback = raw[3] & 0x07
	c.Mod.AR = (raw[4] >> 4) & 0x0F
	c.Mod.DR = raw[4] & 0x0F
	c.Mod.SL = (raw[6] >> 4) & 0x0F
	c.Mod.RR = raw[6] & 0x0F

	// Carrier (registers 1, 3, 5, 7)
	c.Car.AM = (raw[1] & 0x80) != 0
	c.Car.VIB = (raw[1] & 0x40) != 0
	c.Car.EGType = (raw[1] & 0x20) != 0
	c.Car.KSR = (raw[1] & 0x10) != 0
	c.Car.ML = raw[1] & 0x0F
	c.Car.KSL = (raw[3] >> 6) & 0x03
	c.Car.TL = 0 // Carrier total level comes from channel volume register 0x30..0x38
	c.Car.WaveForm = (raw[3] >> 4) & 0x01
	c.Car.Feedback = 0
	c.Car.AR = (raw[5] >> 4) & 0x0F
	c.Car.DR = raw[5] & 0x0F
	c.Car.SL = (raw[7] >> 4) & 0x0F
	c.Car.RR = raw[7] & 0x0F

	y.updateChannelFreq(ch)
}

// applyRhythmPatches applies default rhythm patches to channels 6..8.
func (y *YM2413) applyRhythmPatches() {
	// Channel 6: Bass Drum
	y.applyRawPatch(6, romPatches[16])
	// Channel 7: High Hat (Mod) & Snare Drum (Car)
	y.applyRawPatch(7, romPatches[17])
	// Channel 8: Tom-Tom (Mod) & Top Cymbal (Car)
	y.applyRawPatch(8, romPatches[18])
}

func (y *YM2413) applyRawPatch(ch int, raw [8]uint8) {
	c := &y.Channels[ch]
	c.Mod.AM = (raw[0] & 0x80) != 0
	c.Mod.VIB = (raw[0] & 0x40) != 0
	c.Mod.EGType = (raw[0] & 0x20) != 0
	c.Mod.KSR = (raw[0] & 0x10) != 0
	c.Mod.ML = raw[0] & 0x0F
	c.Mod.KSL = (raw[2] >> 6) & 0x03
	c.Mod.TL = raw[2] & 0x3F
	c.Mod.WaveForm = (raw[3] >> 3) & 0x01
	c.Mod.Feedback = raw[3] & 0x07
	c.Mod.AR = (raw[4] >> 4) & 0x0F
	c.Mod.DR = raw[4] & 0x0F
	c.Mod.SL = (raw[6] >> 4) & 0x0F
	c.Mod.RR = raw[6] & 0x0F

	c.Car.AM = (raw[1] & 0x80) != 0
	c.Car.VIB = (raw[1] & 0x40) != 0
	c.Car.EGType = (raw[1] & 0x20) != 0
	c.Car.KSR = (raw[1] & 0x10) != 0
	c.Car.ML = raw[1] & 0x0F
	c.Car.KSL = (raw[3] >> 6) & 0x03
	c.Car.WaveForm = (raw[3] >> 4) & 0x01
	c.Car.AR = (raw[5] >> 4) & 0x0F
	c.Car.DR = raw[5] & 0x0F
	c.Car.SL = (raw[7] >> 4) & 0x0F
	c.Car.RR = raw[7] & 0x0F
}

// updateChannelFreq calculates phase steps for modulator and carrier.
func (y *YM2413) updateChannelFreq(ch int) {
	c := &y.Channels[ch]
	if y.SampleRate <= 0 {
		return
	}

	// Phase step calculation:
	// Base frequency: Freq = FNum * 49716 / 2^(19 - Block)
	// Base phase step in 10.8 fixed point:
	baseStep := (uint32(c.FNum) << c.Block) >> 1
	c.Mod.PhaseStep = (baseStep * mlTable[c.Mod.ML&0x0F]) / 2
	c.Car.PhaseStep = (baseStep * mlTable[c.Car.ML&0x0F]) / 2

	// Update cached frequency for .sta snapshot
	y.FreqCache[ch] = int((uint32(c.FNum) * 49716) >> (19 - c.Block))
}

// updateEnvelope advances the envelope generator state for an operator.
func (op *Operator) updateEnvelope(ksrCode int, sustain bool) {
	if op.EGState == EGStateOff {
		op.EGVolume = 127
		return
	}

	// Calculate effective rate (0..63)
	var rate uint8
	switch op.EGState {
	case EGStateAttack:
		rate = op.AR
	case EGStateDecay:
		rate = op.DR
	case EGStateSustain:
		if !op.EGType {
			rate = op.RR
		} else {
			return
		}
	case EGStateRelease:
		if sustain {
			rate = 5 // Slow release when sustain pedal is down
		} else {
			rate = op.RR
		}
	}

	if rate == 0 {
		return
	}

	rks := ksrCode
	if !op.KSR {
		rks >>= 2
	}
	effRate := int(rate)*4 + rks
	if effRate > 63 {
		effRate = 63
	}

	// Rate speed table
	op.EGStepCount += uint32(1 << (effRate >> 2))
	if (op.EGStepCount & 0x07) == 0 {
		switch op.EGState {
		case EGStateAttack:
			// Attack attenuation goes towards 0
			if op.EGVolume > 0 {
				step := (op.EGVolume >> 3) + 1
				if op.EGVolume > step {
					op.EGVolume -= step
				} else {
					op.EGVolume = 0
					op.EGState = EGStateDecay
				}
			} else {
				op.EGState = EGStateDecay
			}

		case EGStateDecay:
			sustainAtt := uint16(op.SL) * 8
			if op.EGVolume < sustainAtt {
				op.EGVolume++
			} else {
				op.EGVolume = sustainAtt
				op.EGState = EGStateSustain
			}

		case EGStateSustain, EGStateRelease:
			if op.EGVolume < 127 {
				op.EGVolume++
			} else {
				op.EGVolume = 127
				op.EGState = EGStateOff
			}
		}
	}
}

// sinLookup computes logarithmic sine attenuation and sign bit.
func sinLookup(phase uint32, waveForm uint8) (uint16, bool) {
	p := (phase >> 8) & 0x3FF // 10-bit phase: 0..1023
	var sinAtt uint16
	var sign bool

	if (p & 0x200) != 0 {
		// Second half of wave (quadrants 2 and 3)
		if waveForm != 0 {
			return 0xFFF, false // Muted during negative half of half-sine
		}
		sign = true
	}

	if (p & 0x100) != 0 {
		// Quadrants 1 and 3 (descending)
		sinAtt = logSinTable[(^p)&0xFF]
	} else {
		// Quadrants 0 and 2 (ascending)
		sinAtt = logSinTable[p&0xFF]
	}

	return sinAtt, sign
}

// logToLin converts logarithmic attenuation back into a linear waveform value.
func logToLin(logAtt uint16, sign bool) int {
	if logAtt > 0xFFF {
		return 0
	}
	shift := logAtt >> 8
	if shift > 12 {
		return 0
	}
	v := int((expTable[logAtt&0xFF] | 0x800) >> (shift + 1))
	if sign {
		return -v
	}
	return v
}

// GenerateSample synthesizes a single audio sample from the 9 OPLL channels.
func (y *YM2413) GenerateSample() int {
	y.mu.Lock()
	defer y.mu.Unlock()

	// Advance LFOs
	y.LFOPhaseAM = (y.LFOPhaseAM + 37) & 0xFFFF // ~3.7 Hz
	y.LFOPhasePM = (y.LFOPhasePM + 64) & 0xFFFF // ~6.4 Hz

	// Update noise LFSR
	feedback := ((y.NoiseLFSR >> 16) ^ (y.NoiseLFSR >> 14)) & 1
	y.NoiseLFSR = ((y.NoiseLFSR << 1) & 0x1FFFF) | feedback

	var outSum int

	// Melody channels count: 9 if normal, 6 if rhythm mode is active
	melodyCount := OPLLChannels
	if y.RhythmMode {
		melodyCount = 6
	}

	for ch := 0; ch < melodyCount; ch++ {
		c := &y.Channels[ch]
		if c.Car.EGState == EGStateOff && c.Mod.EGState == EGStateOff {
			continue
		}

		ksr := int(c.Block)
		c.Mod.updateEnvelope(ksr, c.Sustain)
		c.Car.updateEnvelope(ksr, c.Sustain)

		// 1. Modulator output
		modPhase := c.Mod.Phase
		if c.Mod.Feedback > 0 {
			fb := ((c.Mod.FeedbackBuf[0] + c.Mod.FeedbackBuf[1]) >> (9 - c.Mod.Feedback))
			modPhase += uint32(fb << 8)
		}

		modAtt := (uint16(c.Mod.TL) * 8) + (c.Mod.EGVolume * 8)
		sinAttM, signM := sinLookup(modPhase, c.Mod.WaveForm)
		modOut := logToLin(modAtt+sinAttM, signM)

		c.Mod.FeedbackBuf[0] = c.Mod.FeedbackBuf[1]
		c.Mod.FeedbackBuf[1] = modOut
		c.Mod.Phase += c.Mod.PhaseStep

		// 2. Carrier output modulated by Modulator
		carPhase := c.Car.Phase + uint32(modOut<<7)
		carAtt := (uint16(c.Volume) * 32) + (c.Car.EGVolume * 8)
		sinAttC, signC := sinLookup(carPhase, c.Car.WaveForm)
		carOut := logToLin(carAtt+sinAttC, signC)

		c.Car.Phase += c.Car.PhaseStep

		outSum += carOut
	}

	// Synthesize Rhythm drums if enabled
	if y.RhythmMode {
		outSum += y.synthesizeDrums()
	}

	return outSum
}

// synthesizeDrums synthesizes the 5 OPLL rhythm drums when rhythm mode is active.
func (y *YM2413) synthesizeDrums() int {
	var drumSum int
	noiseBit := (y.NoiseLFSR & 1) != 0

	// 1. Bass Drum (Channel 6)
	c6 := &y.Channels[6]
	c6.Mod.updateEnvelope(int(c6.Block), false)
	c6.Car.updateEnvelope(int(c6.Block), false)
	if c6.Car.EGState != EGStateOff {
		sinAttM, signM := sinLookup(c6.Mod.Phase, c6.Mod.WaveForm)
		modOut := logToLin((uint16(c6.Mod.TL)*8)+(c6.Mod.EGVolume*8)+sinAttM, signM)
		c6.Mod.Phase += c6.Mod.PhaseStep

		carPhase := c6.Car.Phase + uint32(modOut<<7)
		sinAttC, signC := sinLookup(carPhase, c6.Car.WaveForm)
		carOut := logToLin((uint16(c6.Volume)*32)+(c6.Car.EGVolume*8)+sinAttC, signC)
		c6.Car.Phase += c6.Car.PhaseStep
		drumSum += carOut * 2
	}

	// 2. Snare Drum (Channel 7 Carrier + noise)
	c7 := &y.Channels[7]
	c7.Car.updateEnvelope(int(c7.Block), false)
	if c7.Car.EGState != EGStateOff {
		var phase uint32 = c7.Car.Phase
		if noiseBit {
			phase ^= 0x10000
		}
		sinAtt, sign := sinLookup(phase, c7.Car.WaveForm)
		drumSum += logToLin((uint16(c7.Volume)*32)+(c7.Car.EGVolume*8)+sinAtt, sign)
		c7.Car.Phase += c7.Car.PhaseStep
	}

	// 3. Tom-Tom (Channel 8 Modulator)
	c8 := &y.Channels[8]
	c8.Mod.updateEnvelope(int(c8.Block), false)
	if c8.Mod.EGState != EGStateOff {
		sinAtt, sign := sinLookup(c8.Mod.Phase, c8.Mod.WaveForm)
		drumSum += logToLin((uint16(c8.Volume)*32)+(c8.Mod.EGVolume*8)+sinAtt, sign)
		c8.Mod.Phase += c8.Mod.PhaseStep
	}

	// 4. Top Cymbal (Channel 8 Carrier)
	c8.Car.updateEnvelope(int(c8.Block), false)
	if c8.Car.EGState != EGStateOff {
		phase := c8.Car.Phase ^ (c7.Mod.Phase >> 2)
		sinAtt, sign := sinLookup(phase, c8.Car.WaveForm)
		drumSum += logToLin((uint16(c8.Volume)*32)+(c8.Car.EGVolume*8)+sinAtt, sign)
		c8.Car.Phase += c8.Car.PhaseStep
	}

	// 5. High Hat (Channel 7 Modulator)
	c7.Mod.updateEnvelope(int(c7.Block), false)
	if c7.Mod.EGState != EGStateOff {
		phase := c7.Mod.Phase
		if noiseBit {
			phase ^= 0x8000
		}
		sinAtt, sign := sinLookup(phase, c7.Mod.WaveForm)
		drumSum += logToLin((uint16(c7.Volume)*32)+(c7.Mod.EGVolume*8)+sinAtt, sign)
		c7.Mod.Phase += c7.Mod.PhaseStep
	}

	return drumSum
}

// GenerateSamples generates a buffer of audio samples.
func (y *YM2413) GenerateSamples(buf []int) {
	for i := range buf {
		buf[i] = y.GenerateSample()
	}
}
