package sound

// Envelopes defines the 16 envelope shapes (32 steps each) for the AY-3-8910 PSG.
// Directly mirrors fMSX EMULib/AY8910.c Envelopes table.
var Envelopes = [16][32]uint8{
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
	{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
}

// Volumes maps 4-bit PSG volume steps (0..15) to logarithmic amplitude (0..255).
var Volumes = [16]int{
	0, 1, 2, 4, 6, 8, 11, 16, 23, 32, 45, 64, 90, 128, 180, 255,
}

const (
	// Standard MSX Master Clock / 16 (3579545 Hz / 16 = 223721 Hz)
	DefaultPSGClock = 3579545 / 16
	NumChannels     = 6 // 3 Melodic + 3 Noise channels
)

// ChannelState represents the frequency and volume of a single sound generator channel.
type ChannelState struct {
	Freq    int  // Frequency in Hz
	Volume  int  // Volume 0..255
	IsNoise bool
}

// AY8910 represents the General Instrument AY-3-8910 / Yamaha YM2149 sound chip.
type AY8910 struct {
	Regs    [16]uint8
	Latch   uint8
	Clock   int
	Changed uint8

	EPeriod int // Envelope period in microseconds
	ECount  int // Envelope counter in microseconds
	EPhase  int // Current step in envelope (0..31)

	Channels [NumChannels]ChannelState

	// External callback or hook for Joy/Mouse on Reg 14 and Reg 15
	ReadPortA func() uint8
	ReadPortB func() uint8
}

// NewAY8910 creates and resets a new AY-3-8910 sound chip emulator.
func NewAY8910(clockHz int) *AY8910 {
	if clockHz <= 0 {
		clockHz = 3579545
	}
	psg := &AY8910{
		Clock: clockHz >> 4, // FIN / 16
	}
	psg.Reset()
	return psg
}

// Reset restores all PSG registers and envelope state to power-on default.
func (psg *AY8910) Reset() {
	var regInit = [16]uint8{
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFD,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00,
	}
	copy(psg.Regs[:], regInit[:])
	psg.Latch = 0
	psg.Changed = 0
	psg.EPeriod = -1
	psg.ECount = 0
	psg.EPhase = 0

	for i := range psg.Channels {
		psg.Channels[i].Freq = 0
		psg.Channels[i].Volume = 0
		psg.Channels[i].IsNoise = (i >= 3)
	}
}

// WriteControl selects the active register latch (Port 0xA0).
func (psg *AY8910) WriteControl(val uint8) {
	psg.Latch = val & 0x0F
}

// WriteData writes a value into the currently latched register (Port 0xA1).
func (psg *AY8910) WriteData(val uint8) {
	psg.Write(psg.Latch, val)
}

// ReadData reads the value of the currently latched register (Port 0xA2).
func (psg *AY8910) ReadData() uint8 {
	reg := psg.Latch
	switch reg {
	case 14:
		if psg.ReadPortA != nil {
			return psg.ReadPortA()
		}
		return psg.Regs[14]
	case 15:
		if psg.ReadPortB != nil {
			return psg.ReadPortB()
		}
		return psg.Regs[15] & 0xF0
	default:
		if reg < 14 {
			return psg.Regs[reg]
		}
		return 0xFF
	}
}

// Write sets an individual register and recalculates channel dirty flags.
// Directly mirrors fMSX EMULib/AY8910.c Write8910.
func (psg *AY8910) Write(reg uint8, val uint8) {
	switch reg {
	case 1, 3, 5:
		val &= 0x0F
		fallthrough
	case 0, 2, 4:
		if val != psg.Regs[reg] {
			psg.Changed |= (1 << (reg >> 1)) &^ psg.Regs[7]
			psg.Regs[reg] = val
		}

	case 6:
		val &= 0x1F
		if val != psg.Regs[reg] {
			psg.Changed |= 0x38 &^ psg.Regs[7]
			psg.Regs[reg] = val
		}

	case 7:
		psg.Changed |= (val ^ psg.Regs[7]) & 0x3F
		psg.Regs[7] = val

	case 8, 9, 10:
		val &= 0x1F
		if val != psg.Regs[reg] {
			psg.Changed |= (0x09 << (reg - 8)) &^ psg.Regs[7]
			psg.Regs[reg] = val
		}

	case 11, 12:
		if val != psg.Regs[reg] {
			psg.EPeriod = -1 // Recalculate envelope period on next cycle
			psg.Regs[reg] = val
		}
		return

	case 13:
		psg.Regs[13] = val & 0x0F
		psg.ECount = 0
		psg.EPhase = 0
		for j := 0; j < 3; j++ {
			if (psg.Regs[j+8] & 0x10) != 0 {
				psg.Changed |= (0x09 << j) &^ psg.Regs[7]
			}
		}

	case 14, 15:
		psg.Regs[reg] = val
		return

	default:
		return
	}

	psg.Sync()
}

// Step advances volume envelopes by uSec microseconds.
// Directly mirrors fMSX EMULib/AY8910.c Loop8910.
func (psg *AY8910) Step(uSec int) {
	if psg.EPeriod < 0 {
		period := (int(psg.Regs[12]) << 8) | int(psg.Regs[11])
		if period == 0 {
			period = 0x10000
		}
		if psg.Clock > 0 {
			psg.EPeriod = int(1000000 * int64(period) / int64(psg.Clock))
		} else {
			psg.EPeriod = 1000
		}
	}

	if psg.EPeriod <= 0 {
		return
	}

	psg.ECount += uSec
	if psg.ECount < psg.EPeriod {
		return
	}

	steps := psg.ECount / psg.EPeriod
	psg.ECount -= steps * psg.EPeriod

	psg.EPhase += steps
	if psg.EPhase > 31 {
		if (psg.Regs[13] & 0x09) == 0x08 {
			psg.EPhase &= 0x1F // Repeat envelope cycle
		} else {
			psg.EPhase = 31 // Hold final step
		}
	}

	// Update channels with hardware envelope enabled
	for j := 0; j < 3; j++ {
		if (psg.Regs[j+8] & 0x10) != 0 {
			psg.Changed |= (0x09 << j) &^ psg.Regs[7]
		}
	}

	if psg.Changed != 0 {
		psg.Sync()
	}
}

// Sync recalculates effective frequency and volume for all channels.
// Directly mirrors fMSX EMULib/AY8910.c Sync8910.
func (psg *AY8910) Sync() {
	mask := psg.Changed
	if mask == 0 {
		return
	}

	for ch := 0; ch < NumChannels; ch++ {
		if (mask & (1 << ch)) == 0 {
			continue
		}

		if (psg.Regs[7] & (1 << ch)) != 0 {
			// Channel disabled by mixer register R7
			psg.Channels[ch].Freq = 0
			psg.Channels[ch].Volume = 0
			continue
		}

		if ch < 3 {
			// Melodic Channels A, B, C
			volReg := psg.Regs[ch+8] & 0x1F
			var volIdx uint8
			if (volReg & 0x10) != 0 {
				volIdx = Envelopes[psg.Regs[13]&0x0F][psg.EPhase]
			} else {
				volIdx = volReg & 0x0F
			}
			psg.Channels[ch].Volume = Volumes[volIdx]

			k := (int(psg.Regs[(ch<<1)+1]&0x0F) << 8) | int(psg.Regs[ch<<1])
			if k > 0 && psg.Clock > 0 {
				psg.Channels[ch].Freq = psg.Clock / k
			} else {
				psg.Channels[ch].Freq = 0
			}
		} else {
			// Noise Channels A, B, C (mapped to noise generator R6)
			volReg := psg.Regs[(ch-3)+8] & 0x1F
			var volIdx uint8
			if (volReg & 0x10) != 0 {
				volIdx = Envelopes[psg.Regs[13]&0x0F][psg.EPhase]
			} else {
				volIdx = volReg & 0x0F
			}
			psg.Channels[ch].Volume = (Volumes[volIdx] + 1) >> 1

			noisePeriod := int(psg.Regs[6] & 0x1F)
			if noisePeriod == 0 {
				noisePeriod = 0x20
			}
			if psg.Clock > 0 {
				psg.Channels[ch].Freq = psg.Clock / (noisePeriod << 2)
			} else {
				psg.Channels[ch].Freq = 0
			}
		}
	}

	psg.Changed = 0
}
