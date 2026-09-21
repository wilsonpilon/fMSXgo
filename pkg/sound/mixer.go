package sound

import (
	"io"
	"sync"
)

const (
	DefaultSampleRate = 44100
	BufferSize        = 16384 // Ring buffer size in samples (approx 370ms at 44.1kHz)
)

// ChannelPhase tracks the phase accumulator for melodic, noise, or wave generators.
type ChannelPhase struct {
	Count int
	Pos   int
}

// Mixer synthesizes, mixes, and buffers PCM audio from PSG and SCC sound chips.
// Directly mirrors fMSX EMULib/Sound.c RenderAudio.
type Mixer struct {
	mu sync.Mutex

	SampleRate int
	PSG        *AY8910
	SCC        *SCC
	OPLL       *YM2413

	// Phase accumulators for PSG melodic (3) and noise (3)
	PSGPhase [NumChannels]ChannelPhase

	// 17-bit Linear Feedback Shift Register (LFSR) for white noise
	NoiseGen int

	// Master volume (0..255) and mute
	MasterVolume int
	Muted        bool

	// Static mixing buffer to eliminate heap allocations and GC pressure in GenerateSamples
	mixBuf [1024]int

	// Ring buffer of 16-bit signed stereo PCM bytes (Little Endian)
	ringBuffer  []byte
	readIdx     int
	writeIdx    int
	available   int
	lastL       byte
	lastH       byte
	prebuffered bool
}

// NewMixer creates a new audio mixer and synthesis engine.
func NewMixer(sampleRate int, psg *AY8910, scc *SCC, opll *YM2413) *Mixer {
	if sampleRate <= 0 {
		sampleRate = DefaultSampleRate
	}
	m := &Mixer{
		SampleRate:   sampleRate,
		PSG:          psg,
		SCC:          scc,
		OPLL:         opll,
		NoiseGen:     0x10000,
		MasterVolume: 192,
		ringBuffer:   make([]byte, BufferSize*4), // 4 bytes per stereo sample (2 channels * 2 bytes)
	}
	if opll != nil {
		opll.SampleRate = sampleRate
	}
	m.Reset()
	return m
}

// Reset restores mixer buffer and channel phase state.
func (m *Mixer) Reset() {
	m.mu.Lock()
	defer m.mu.Unlock()

	for i := range m.ringBuffer {
		m.ringBuffer[i] = 0
	}
	m.readIdx = 0
	m.writeIdx = 0
	m.available = 0
	m.lastL = 0
	m.lastH = 0
	m.NoiseGen = 0x10000
	for i := range m.PSGPhase {
		m.PSGPhase[i] = ChannelPhase{}
	}
}


// SetVolume sets the master volume (0..255).
func (m *Mixer) SetVolume(vol int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if vol < 0 {
		vol = 0
	}
	if vol > 255 {
		vol = 255
	}
	m.MasterVolume = vol
}

// SetMute toggles mute on or off.
func (m *Mixer) SetMute(mute bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.Muted = mute
}

// GenerateSamples synthesizes `samples` audio frames and pushes them into the ring buffer.
func (m *Mixer) GenerateSamples(samples int) {
	if samples <= 0 || m.SampleRate <= 0 {
		return
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	var mix []int
	if samples <= len(m.mixBuf) {
		mix = m.mixBuf[:samples]
		for i := 0; i < samples; i++ {
			mix[i] = 0
		}
	} else {
		mix = make([]int, samples)
	}

	// 1. Synthesize PSG channels (Melodic 0..2, Noise 3..5)
	if m.PSG != nil {
		for ch := 0; ch < NumChannels; ch++ {
			c := &m.PSG.Channels[ch]
			if c.Freq <= 0 || c.Volume <= 0 {
				continue
			}

			if !c.IsNoise {
				// Melodic (Square Wave) - 100% faithful fMSX EMULib/Sound.c:813
				if c.Freq >= m.SampleRate/2 {
					continue
				}
				step := (0x10000 * c.Freq) / m.SampleRate
				count := m.PSGPhase[ch].Count

				vol := c.Volume
				for i := 0; i < samples; i++ {
					l1 := count
					l2 := count + step
					l0 := count - step
					if ((l0 ^ l2) & 0x8000) != 0 {
						// Edge transition blending matching fMSX Sound.c line 813
						mix[i] += 0
					} else if (l1 & 0x8000) != 0 {
						mix[i] += 127 * vol
					} else {
						mix[i] -= 128 * vol
					}
					count += step
				}
				m.PSGPhase[ch].Count = count & 0xFFFF
			} else {
				// White Noise (17-bit LFSR, output bit 16, XOR bit 14)
				var step int
				vol := c.Volume
				if c.Freq < m.SampleRate {
					step = (c.Freq << 16) / m.SampleRate
				} else {
					vol = (vol * m.SampleRate) / c.Freq
					step = 0x10000
				}
				count := m.PSGPhase[ch].Count

				for i := 0; i < samples; i++ {
					if ((m.NoiseGen >> 16) & 1) != 0 {
						mix[i] += 127 * vol
					} else {
						mix[i] -= 128 * vol
					}
					count += step
					if (count & 0xFFFF0000) != 0 {
						feedback := ((m.NoiseGen >> 16) ^ (m.NoiseGen >> 14)) & 1
						m.NoiseGen = ((m.NoiseGen << 1) & 0x1FFFF) | feedback
						count &= 0xFFFF
					}
				}
				m.PSGPhase[ch].Count = count
			}
		}
	}

	// 2. Synthesize Konami SCC channels (5 wavetable channels)
	if m.SCC != nil {
		for ch := 0; ch < NumSCCChannels; ch++ {
			c := &m.SCC.Channels[ch]
			if !c.Enabled || c.Freq <= 0 || c.Volume <= 0 {
				continue
			}

			// 32 samples per wave period
			step := (c.Freq * 32 * 0x10000) / m.SampleRate
			count := c.Count
			pos := c.Pos
			vol := c.Volume

			for i := 0; i < samples; i++ {
				mix[i] += int(c.Wave[pos]) * vol
				count += step
				if count >= 0x10000 {
					adv := count >> 16
					pos = (pos + adv) & 31
					count &= 0xFFFF
				}
			}
			c.Count = count
			c.Pos = pos
		}
	}

	// 3. Synthesize Yamaha YM2413 (OPLL / MSX-MUSIC) FM channels
	if m.OPLL != nil {
		for i := 0; i < samples; i++ {
			mix[i] += m.OPLL.GenerateSample() * 4
		}
	}

	// 4. Normalize, scale master volume, and convert to 16-bit Signed Little Endian Stereo PCM
	gain := m.MasterVolume
	if m.Muted {
		gain = 0
	}

	for i := 0; i < samples; i++ {
		val := (mix[i] * gain) >> 8
		// Clamp to int16 range
		if val > 32767 {
			val = 32767
		} else if val < -32768 {
			val = -32768
		}
		s16 := int16(val)
		b0 := byte(s16)
		b1 := byte(s16 >> 8)

		// Check buffer overflow before writing (drop oldest if full)
		if m.available >= len(m.ringBuffer) {
			// Advance read index by 4 bytes (drop one stereo sample)
			m.readIdx = (m.readIdx + 4) % len(m.ringBuffer)
			m.available -= 4
		}

		// Left channel
		m.ringBuffer[m.writeIdx] = b0
		m.ringBuffer[m.writeIdx+1] = b1
		// Right channel
		m.ringBuffer[m.writeIdx+2] = b0
		m.ringBuffer[m.writeIdx+3] = b1

		m.writeIdx = (m.writeIdx + 4) % len(m.ringBuffer)
		m.available += 4
	}
}

// Read implements io.Reader to supply stereo 16-bit PCM bytes to Ebitengine's audio player.
func (m *Mixer) Read(p []byte) (int, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	toRead := len(p)
	if toRead > m.available {
		toRead = m.available &^ 3 // Align to 4-byte stereo boundary
	}

	for i := 0; i < toRead; i += 2 {
		m.lastL = m.ringBuffer[m.readIdx]
		m.lastH = m.ringBuffer[m.readIdx+1]
		p[i] = m.lastL
		p[i+1] = m.lastH
		m.readIdx = (m.readIdx + 2) % len(m.ringBuffer)
	}
	m.available -= toRead

	// Fill remainder if requested more than available with smooth sample hold
	for i := toRead; i < len(p)-1; i += 2 {
		p[i] = m.lastL
		p[i+1] = m.lastH
	}

	return len(p), nil
}

// Ensure Mixer implements io.Reader
var _ io.Reader = (*Mixer)(nil)
