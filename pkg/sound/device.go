package sound

import (
	"fmt"
	"sync"
	"time"

	"github.com/hajimehoshi/ebiten/v2/audio"
)

// PlayerBufferSize is how far ahead of real-time playback Ebitengine's audio
// player is allowed to read from Mixer. This directly bounds audio latency:
// everything the player has already buffered plays back before newly
// generated PCM does, so a bigger buffer means game sound effects (e.g. a
// pickup or death sound in a cartridge like King's Valley) are audibly
// delayed by roughly this much relative to the on-screen action. Ebitengine's
// own SetBufferSize docs recommend a small value "if you want to play a
// real-time PCM" — which is exactly this emulator's use case. Left at the
// library default, the underlying oto backend was observed pulling PCM from
// Mixer.Read() in ~500ms chunks, which is where that much latency came from;
// 100ms keeps it comfortably below the perceptible threshold for an action
// game while still being large enough to avoid underruns from ordinary
// frame-time jitter.
const PlayerBufferSize = 100 * time.Millisecond

var (
	globalAudioContext *audio.Context
	audioContextOnce   sync.Once
)

// AudioDevice manages the Ebitengine audio playback stream.
type AudioDevice struct {
	Mixer  *Mixer
	Player *audio.Player
}

// InitAudioDevice initializes the global Ebitengine audio context and starts continuous playback.
func InitAudioDevice(mixer *Mixer) (*AudioDevice, error) {
	if mixer == nil {
		return nil, fmt.Errorf("mixer cannot be nil")
	}

	var initErr error
	audioContextOnce.Do(func() {
		globalAudioContext = audio.NewContext(mixer.SampleRate)
	})

	if globalAudioContext == nil {
		return nil, fmt.Errorf("failed to create global audio context: %v", initErr)
	}

	player, err := globalAudioContext.NewPlayer(mixer)
	if err != nil {
		return nil, fmt.Errorf("failed to create audio player: %w", err)
	}
	player.SetBufferSize(PlayerBufferSize)

	player.Play()

	return &AudioDevice{
		Mixer:  mixer,
		Player: player,
	}, nil
}

// SetVolume sets player volume (0.0 to 1.0).
func (ad *AudioDevice) SetVolume(vol float64) {
	if ad.Player != nil {
		ad.Player.SetVolume(vol)
	}
}

// Close pauses and releases the audio player.
func (ad *AudioDevice) Close() error {
	if ad.Player != nil {
		return ad.Player.Close()
	}
	return nil
}
