package sound

import (
	"testing"
)

func TestAY8910Basic(t *testing.T) {
	psg := NewAY8910(3579545)
	if psg == nil {
		t.Fatal("expected non-nil PSG")
	}

	// 1. Check initial reset state
	if psg.Regs[7] != 0xFD {
		t.Fatalf("expected R7 to be 0xFD, got 0x%02X", psg.Regs[7])
	}

	// 2. Set Channel A frequency and volume
	// Channel A period = 100 -> Freq = Clock / 100 = 223721 / 100 = 2237 Hz
	psg.WriteControl(0)
	psg.WriteData(100) // R0 = 100
	psg.WriteControl(1)
	psg.WriteData(0)   // R1 = 0

	psg.WriteControl(7)
	psg.WriteData(0x3E) // Enable tone on Channel A only (bit 0 = 0)

	psg.WriteControl(8)
	psg.WriteData(15) // R8 = max volume (15)

	if psg.Channels[0].Volume != 255 {
		t.Fatalf("expected channel A volume 255, got %d", psg.Channels[0].Volume)
	}
	if psg.Channels[0].Freq < 1100 || psg.Channels[0].Freq > 1150 {
		t.Fatalf("expected channel A freq ~1118, got %d", psg.Channels[0].Freq)
	}

	// 3. Test hardware envelope
	psg.WriteControl(11)
	psg.WriteData(50) // R11 = 50
	psg.WriteControl(12)
	psg.WriteData(0)  // R12 = 0
	psg.WriteControl(13)
	psg.WriteData(0x0E) // Envelope pattern 14 (alternating)

	psg.WriteControl(8)
	psg.WriteData(0x10) // Set bit 4 = use envelope on Channel A

	// Advance envelope by stepping
	psg.Step(1000)
	if psg.Channels[0].Volume < 0 || psg.Channels[0].Volume > 255 {
		t.Fatalf("envelope volume out of range: %d", psg.Channels[0].Volume)
	}
}

func TestSCCBasic(t *testing.T) {
	scc := NewSCC(3579545)
	if scc == nil {
		t.Fatal("expected non-nil SCC")
	}

	// 1. Write custom waveform to Channel 0 (32 bytes)
	for i := 0; i < 32; i++ {
		scc.Write(uint8(i), uint8(i*4-64))
	}
	if scc.Channels[0].Wave[0] != -64 {
		t.Fatalf("expected wave[0] = -64, got %d", scc.Channels[0].Wave[0])
	}

	// 2. Set Channel 0 period = 200, Volume = 15, Enable = bit 0 (generic SCC at 0x80..0x8F)
	scc.Write(0x80, 200)  // Period low
	scc.Write(0x81, 0)    // Period high
	scc.Write(0x8A, 15)   // Volume
	scc.Write(0x8F, 0x01) // Enable channel 0

	if !scc.Channels[0].Enabled {
		t.Fatal("expected channel 0 to be enabled")
	}
	if scc.Channels[0].Volume != 255 {
		t.Fatalf("expected volume 255, got %d", scc.Channels[0].Volume)
	}
	if scc.Channels[0].Freq <= 0 {
		t.Fatalf("expected valid freq, got %d", scc.Channels[0].Freq)
	}
}

func TestMixerSynthesis(t *testing.T) {
	psg := NewAY8910(3579545)
	scc := NewSCC(3579545)
	opll := NewYM2413(3579545)
	mixer := NewMixer(44100, psg, scc, opll)

	// Configure Channel A tone on PSG
	psg.Write(0, 100)
	psg.Write(1, 0)
	psg.Write(7, 0x3E) // Enable tone A
	psg.Write(8, 15)   // Max volume

	// Generate 441 samples (10ms at 44.1kHz)
	mixer.GenerateSamples(441)

	// Read samples through io.Reader
	buf := make([]byte, 441*4)
	n, err := mixer.Read(buf)
	if err != nil {
		t.Fatalf("mixer read error: %v", err)
	}
	if n != len(buf) {
		t.Fatalf("expected to read %d bytes, got %d", len(buf), n)
	}

	// Verify that not all samples are silence (0)
	hasSound := false
	for _, b := range buf {
		if b != 0 {
			hasSound = true
			break
		}
	}
	if !hasSound {
		t.Fatal("expected non-zero audio samples from active PSG channel")
	}
}
