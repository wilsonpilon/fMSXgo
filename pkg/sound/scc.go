package sound

const (
	NumSCCChannels = 5
)

// SCCChannel represents an individual Konami SCC sound channel.
type SCCChannel struct {
	Wave    [32]int8 // 32 8-bit signed waveform samples (-128..127)
	Freq    int      // Frequency in Hz
	Volume  int      // Volume 0..255
	Period  int      // 12-bit period
	Pos     int      // Current waveform index (0..31)
	Count   int      // Phase accumulator
	Enabled bool
}

// SCC represents the Konami Sound Creative Chip (SCC and SCC+).
// Directly mirrors fMSX EMULib/SCC.c and SCC.h.
type SCC struct {
	Regs     [256]uint8
	Channels [NumSCCChannels]SCCChannel
	Clock    int // Fin / 16 (3579545 / 16 = 223721 Hz)
	IsPlus   bool
}

// NewSCC creates and initializes a Konami SCC sound chip emulator.
func NewSCC(clockHz int) *SCC {
	if clockHz <= 0 {
		clockHz = 3579545
	}
	scc := &SCC{
		Clock: clockHz >> 4,
	}
	scc.Reset()
	return scc
}

// Reset resets all registers and waveform data to zero.
func (scc *SCC) Reset() {
	for i := range scc.Regs {
		scc.Regs[i] = 0
	}
	for ch := range scc.Channels {
		scc.Channels[ch].Freq = 0
		scc.Channels[ch].Volume = 0
		scc.Channels[ch].Period = 0
		scc.Channels[ch].Pos = 0
		scc.Channels[ch].Count = 0
		scc.Channels[ch].Enabled = false
		for w := range scc.Channels[ch].Wave {
			scc.Channels[ch].Wave[w] = 0
		}
	}
}

// Read reads an SCC register (0x9800..0x98FF memory space in cartridge).
func (scc *SCC) Read(addr uint8) uint8 {
	if addr < 0x80 {
		return scc.Regs[addr]
	}
	return 0xFF
}

// Write outputs a byte into the standard Konami SCC register space.
// Directly mirrors fMSX EMULib/SCC.c WriteSCC.
func (scc *SCC) Write(addr uint8, val uint8) {
	if addr >= 0xE0 {
		return
	}
	// Generic SCC has one waveform less than SCC+ (channel 3 and 4 share waveform 3)
	if addr >= 0x80 {
		scc.WritePlus(addr+0x20, val)
		return
	}
	if addr >= 0x60 {
		// Waveform 3 applies to both channels 3 and 4 in standard SCC
		scc.WritePlus(addr, val)
		scc.WritePlus(addr+0x20, val)
		return
	}
	scc.WritePlus(addr, val)
}

// WritePlus writes into the newer SCC+ register layout.
func (scc *SCC) WritePlus(addr uint8, val uint8) {
	if scc.Regs[addr] == val {
		return
	}

	if (addr & 0xE0) == 0xA0 {
		// Frequency, Volume, and Channel Enable registers (0xA0..0xAF)
		r := addr & 0x0F
		scc.Regs[addr] = val

		switch {
		case r < 10:
			// Frequency period: 2 bytes per channel (low 8 bits, high 4 bits)
			ch := r >> 1
			if (r & 1) == 0 {
				scc.Channels[ch].Period = (scc.Channels[ch].Period & 0x0F00) | int(val)
			} else {
				scc.Channels[ch].Period = (scc.Channels[ch].Period & 0x00FF) | (int(val&0x0F) << 8)
			}
			if scc.Channels[ch].Period > 0 && scc.Clock > 0 {
				scc.Channels[ch].Freq = scc.Clock / (scc.Channels[ch].Period + 1)
			} else {
				scc.Channels[ch].Freq = 0
			}

		case r >= 10 && r < 15:
			// Volume: 4 bits (0..15)
			ch := r - 10
			scc.Channels[ch].Volume = Volumes[val&0x0F]

		case r == 15:
			// Channel enable mask (bits 0..4)
			for ch := 0; ch < NumSCCChannels; ch++ {
				scc.Channels[ch].Enabled = (val & (1 << ch)) != 0
			}
		}
	} else if addr < 0xA0 {
		// 32-byte waveform RAM
		scc.Regs[addr] = val
		ch := addr >> 5 // 32 bytes per channel (0..4)
		pos := addr & 0x1F
		if ch < NumSCCChannels {
			scc.Channels[ch].Wave[pos] = int8(val)
		}
	}
}
