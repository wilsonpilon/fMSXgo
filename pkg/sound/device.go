package sound

import (
	"fmt"
	"sync"

	"github.com/hajimehoshi/ebiten/v2/audio"
)

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
