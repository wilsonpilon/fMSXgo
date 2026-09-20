package sound

import (
	"testing"
)

func TestYM2413Tables(t *testing.T) {
	// 1. Log-sine table:
	// Peak of sine is at index 255 (phase 90 degrees), where sin is 1.0, so log attenuation should be 0.
	if logSinTable[255] != 0 {
		t.Fatalf("expected logSinTable[255] to be 0 (0 dB attenuation), got 0x%X", logSinTable[255])
	}
	// Near zero phase (index 0), attenuation should be large
	if logSinTable[0] <= 0x800 {
		t.Fatalf("expected logSinTable[0] > 0x800, got 0x%X", logSinTable[0])
	}

	// 2. Exponential table:
	// Index 0 represents full scale (approx 2047)
	if expTable[0] < 0x7F0 {
		t.Fatalf("expected expTable[0] near 0x7FA, got 0x%X", expTable[0])
	}

	// 3. Sin lookup verification:
	// Phase 0 -> sin is 0 -> maximum attenuation
	att0, sign0 := sinLookup(0, 0)
	if sign0 {
		t.Errorf("expected sign false at phase 0")
	}
	if att0 == 0 {
		t.Errorf("expected non-zero attenuation at phase 0")
	}

	// Phase at 90 deg (256 in 10-bit phase, so 256 << 8 = 0x10000) -> peak of sine
	attPeak, signPeak := sinLookup(255<<8, 0)
	if signPeak {
		t.Errorf("expected sign false at peak")
	}
	if attPeak != 0 {
		t.Errorf("expected 0 attenuation at peak, got %d", attPeak)
	}

	// Negative half of wave (phase > 512 << 8)
	_, signNeg := sinLookup(768<<8, 0)
	if !signNeg {
		t.Errorf("expected sign true in negative half")
	}

	// Half-sine (rectified) waveform in negative half should be muted
	attMuted, _ := sinLookup(768<<8, 1)
	if attMuted != 0xFFF {
		t.Errorf("expected half-sine to mute negative half (0xFFF), got 0x%X", attMuted)
	}

	// 4. logToLin conversion
	vMax := logToLin(0, false)
	if vMax < 1800 || vMax > 2200 {
		t.Errorf("expected logToLin(0) ~ 2048, got %d", vMax)
	}
	vNeg := logToLin(0, true)
	if vNeg != -vMax {
		t.Errorf("expected negative linear output, got %d", vNeg)
	}
	vMute := logToLin(0xFFF, false)
	if vMute != 0 {
		t.Errorf("expected logToLin(0xFFF) == 0, got %d", vMute)
	}
}

func TestYM2413MelodySynthesis(t *testing.T) {
	opll := NewYM2413(3579545)
	if opll == nil {
		t.Fatal("expected non-nil YM2413")
	}

	// Initially, all channels off -> silence
	s0 := opll.GenerateSample()
	if s0 != 0 {
		t.Fatalf("expected silence initially, got %d", s0)
	}

	// Configure Channel 0:
	// 1. Select Violin patch (patch 1, sustained): Reg 0x30 = 0x10 (patch 1, vol 0)
	opll.WriteAddress(0x30)
	opll.WriteData(0x10)

	// 2. Set F-Num = 288, Block = 4:
	// Reg 0x10 = FNum LSB = 0x20
	opll.WriteAddress(0x10)
	opll.WriteData(0x20)

	// Reg 0x20 = [Sustain(0) | KeyOn(1) | Block(4: 100b) | FNum MSB(1)] = 0x19
	opll.WriteAddress(0x20)
	opll.WriteData(0x19)

	if !opll.Channels[0].KeyOn {
		t.Fatalf("expected Channel 0 KeyOn to be true")
	}
	if opll.Channels[0].Mod.EGState != EGStateAttack {
		t.Fatalf("expected Modulator EGState to be Attack, got %d", opll.Channels[0].Mod.EGState)
	}

	// Generate 1000 samples and verify non-zero sound output
	hasSound := false
	for i := 0; i < 1000; i++ {
		sample := opll.GenerateSample()
		if sample != 0 {
			hasSound = true
		}
	}
	if !hasSound {
		t.Fatalf("expected non-zero audio output while note is played")
	}

	// Note Off: KeyOn = 0
	opll.WriteAddress(0x20)
	opll.WriteData(0x09) // KeyOn = 0

	if opll.Channels[0].KeyOn {
		t.Fatalf("expected Channel 0 KeyOn to be false")
	}
	if opll.Channels[0].Car.EGState != EGStateRelease {
		t.Fatalf("expected Carrier EGState to be Release, got %d", opll.Channels[0].Car.EGState)
	}
}

func TestYM2413CustomPatch(t *testing.T) {
	opll := NewYM2413(3579545)

	// Define user patch in registers 0x00..0x07
	// Modulator: AM=0, VIB=0, EG=1, KSR=0, MULT=1 -> 0x21
	opll.Write(0x00, 0x21)
	// Carrier: AM=0, VIB=0, EG=1, KSR=0, MULT=1 -> 0x21
	opll.Write(0x01, 0x21)
	// Modulator TL = 30 -> 0x1E
	opll.Write(0x02, 0x1E)
	// Feedback = 4 -> 0x04
	opll.Write(0x03, 0x04)
	// Modulator AR=15, DR=0 -> 0xF0
	opll.Write(0x04, 0xF0)
	// Carrier AR=15, DR=0 -> 0xF0
	opll.Write(0x05, 0xF0)
	// Modulator SL=0, RR=15 -> 0x0F
	opll.Write(0x06, 0x0F)
	// Carrier SL=0, RR=15 -> 0x0F
	opll.Write(0x07, 0x0F)

	// Channel 0 uses patch 0 (user instrument)
	opll.Write(0x30, 0x00)

	// Verify patch applied to channel 0
	if opll.Channels[0].Mod.Feedback != 4 {
		t.Fatalf("expected Modulator feedback 4, got %d", opll.Channels[0].Mod.Feedback)
	}
	if opll.Channels[0].Mod.TL != 0x1E {
		t.Fatalf("expected Modulator TL 0x1E, got %d", opll.Channels[0].Mod.TL)
	}

	// Trigger note on
	opll.Write(0x10, 0x50)
	opll.Write(0x20, 0x19) // KeyOn = true

	// Generate samples
	buf := make([]int, 500)
	opll.GenerateSamples(buf)

	hasSound := false
	for _, v := range buf {
		if v != 0 {
			hasSound = true
			break
		}
	}
	if !hasSound {
		t.Fatalf("expected custom patch to produce sound output")
	}
}

func TestYM2413RhythmMode(t *testing.T) {
	opll := NewYM2413(3579545)

	// Enable rhythm mode (Reg 0x0E bit 5 = 1)
	opll.Write(0x0E, 0x20)
	if !opll.RhythmMode {
		t.Fatalf("expected RhythmMode to be true")
	}

	// Set frequencies for rhythm channels 6, 7, 8
	opll.Write(0x16, 0x50)
	opll.Write(0x26, 0x05) // Ch 6 (Bass Drum)
	opll.Write(0x17, 0x50)
	opll.Write(0x27, 0x05) // Ch 7 (High Hat / Snare)
	opll.Write(0x18, 0x50)
	opll.Write(0x28, 0x05) // Ch 8 (Tom / Cymbal)

	// Trigger Bass Drum (bit 4)
	opll.Write(0x0E, 0x30)
	buf := make([]int, 500)
	opll.GenerateSamples(buf)

	hasBD := false
	for _, s := range buf {
		if s != 0 {
			hasBD = true
			break
		}
	}
	if !hasBD {
		t.Fatalf("expected Bass Drum to produce audio")
	}

	// Trigger Snare Drum (bit 3) + Cymbal (bit 1)
	opll.Write(0x0E, 0x2A)
	buf = make([]int, 500)
	opll.GenerateSamples(buf)

	hasDrums := false
	for _, s := range buf {
		if s != 0 {
			hasDrums = true
			break
		}
	}
	if !hasDrums {
		t.Fatalf("expected Snare/Cymbal to produce audio")
	}
}

func TestYM2413MixerIntegration(t *testing.T) {
	psg := NewAY8910(3579545)
	scc := NewSCC(3579545)
	opll := NewYM2413(3579545)
	mixer := NewMixer(44100, psg, scc, opll)

	// Play note on OPLL
	opll.Write(0x30, 0x10) // Violin, volume 0 (max)
	opll.Write(0x10, 0x80)
	opll.Write(0x20, 0x18) // KeyOn = true, Block = 4

	// Generate 441 samples
	mixer.GenerateSamples(441)

	buf := make([]byte, 441*4)
	n, err := mixer.Read(buf)
	if err != nil || n != len(buf) {
		t.Fatalf("mixer read error: %v, n=%d", err, n)
	}

	// Verify buffer contains non-zero PCM audio
	nonZero := false
	for _, b := range buf {
		if b != 0 {
			nonZero = true
			break
		}
	}
	if !nonZero {
		t.Fatalf("expected Mixer to output non-zero audio from OPLL")
	}
}
