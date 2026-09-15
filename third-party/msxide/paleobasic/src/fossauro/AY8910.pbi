; AY-3-8910 PSG Emulation and Win32 Audio Streaming for fossauro
; Derived from fMSX EMULib AY8910 by Marat Fayzullin

EnableExplicit

Structure PSGChannel
  Count.f        ; Tone period counter
  State.l        ; Tone output state (0 or 1)
EndStructure

Structure PSGenvelope
  Count.f        ; Envelope step counter
  Step.l         ; Current envelope step (0 to 15)
  Direction.l    ; 1 for up, -1 for down
  Holding.l      ; 1 if holding, 0 if active
  State.l        ; Current output volume (0 to 15)
EndStructure

Structure PSGState
  R.a[16]        ; PSG registers
  Latch.a        ; Latched register index
  
  Chan.PSGChannel[3]
  
  NoiseCount.f   ; Noise period counter
  NoiseState.l   ; Noise generator output (0 or 1)
  LFSR.l         ; 17-bit shift register for noise generation
  
  Env.PSGenvelope
EndStructure

Global PSG.PSGState
Global Dim PSGVolumeTable.w(15)

; Initialize PSG Volume Table (Logarithmic)
Procedure InitPSGVolumeTable()
  PSGVolumeTable(0)  = 0
  PSGVolumeTable(1)  = 350
  PSGVolumeTable(2)  = 500
  PSGVolumeTable(3)  = 700
  PSGVolumeTable(4)  = 1000
  PSGVolumeTable(5)  = 1400
  PSGVolumeTable(6)  = 2000
  PSGVolumeTable(7)  = 2800
  PSGVolumeTable(8)  = 4000
  PSGVolumeTable(9)  = 5600
  PSGVolumeTable(10) = 8000
  PSGVolumeTable(11) = 11200
  PSGVolumeTable(12) = 16000
  PSGVolumeTable(13) = 22400
  PSGVolumeTable(14) = 31500
  PSGVolumeTable(15) = 32767
EndProcedure

InitPSGVolumeTable()

; Reset PSG State
Procedure ResetPSG()
  Protected I.l
  For I = 0 To 15
    PSG\R[I] = 0
  Next I
  PSG\Latch = 0
  
  For I = 0 To 2
    PSG\Chan[I]\Count = 0.0
    PSG\Chan[I]\State = 0
  Next I
  
  PSG\NoiseCount = 0.0
  PSG\NoiseState = 0
  PSG\LFSR = 1 ; Must be non-zero to cycle
  
  PSG\Env\Count = 0.0
  PSG\Env\Step = 15
  PSG\Env\Direction = -1
  PSG\Env\Holding = 1
  PSG\Env\State = 0
EndProcedure

; Trigger envelope reset when register 13 is written
Procedure ResetPSGEnvelope()
  PSG\Env\Count = 0.0
  PSG\Env\Holding = 0
  
  If PSG\R[13] & $04 ; Attack
    PSG\Env\Step = 0
    PSG\Env\Direction = 1
  Else
    PSG\Env\Step = 15
    PSG\Env\Direction = -1
  EndIf
  PSG\Env\State = PSG\Env\Step
EndProcedure

; Synthesize PCM samples
Procedure PSG_Render(*Buffer, SamplesCount.l)
  ; Base clock: 3.579545 MHz / 32 = 111860.78 Hz
  ; Audio Sample Rate: 44100 Hz
  ; Ratio = 111860.78 / 44100.0 = 2.536525
  Protected step_val.f = 2.536525
  
  Protected i.l, c.l
  For i = 0 To SamplesCount - 1
    ; 1. Update Noise Generator (17-bit LFSR)
    Protected noise_period.l = PSG\R[6] & $1F
    If noise_period = 0 : noise_period = 1 : EndIf
    PSG\NoiseCount + step_val
    While PSG\NoiseCount >= noise_period
      PSG\NoiseCount - noise_period
      ; Shift LFSR
      Protected feedback.l = (PSG\LFSR & 1) ! ((PSG\LFSR >> 3) & 1)
      PSG\LFSR = (PSG\LFSR >> 1) | (feedback << 16)
      PSG\NoiseState = PSG\LFSR & 1
    Wend
    
    ; 2. Update Envelope Generator (occurs 256 times slower than master clock)
    Protected env_period.l = (PSG\R[12] << 8) | PSG\R[11]
    If env_period = 0 : env_period = 1 : EndIf
    Protected env_step.f = step_val / 256.0
    
    If Not PSG\Env\Holding
      PSG\Env\Count + env_step
      While PSG\Env\Count >= env_period
        PSG\Env\Count - env_period
        
        PSG\Env\Step + PSG\Env\Direction
        If PSG\Env\Step > 15 Or PSG\Env\Step < 0
          Protected shape.l = PSG\R[13] & $0F
          Protected cont.l = (shape >> 3) & 1
          Protected attack.l = (shape >> 2) & 1
          Protected alternate.l = (shape >> 1) & 1
          Protected hold.l = shape & 1
          
          If cont = 0
            PSG\Env\Step = 0
            PSG\Env\State = 0
            PSG\Env\Holding = 1
          Else
            If hold = 1
              If attack ! alternate
                PSG\Env\Step = 15
              Else
                PSG\Env\Step = 0
              EndIf
              PSG\Env\State = PSG\Env\Step
              PSG\Env\Holding = 1
            Else
              If alternate = 1
                PSG\Env\Direction = -PSG\Env\Direction
                PSG\Env\Step + PSG\Env\Direction
              Else
                If PSG\Env\Direction = 1
                  PSG\Env\Step = 0
                Else
                  PSG\Env\Step = 15
                EndIf
              EndIf
            EndIf
          EndIf
        EndIf
        
        If Not PSG\Env\Holding
          PSG\Env\State = PSG\Env\Step
        EndIf
      Wend
    EndIf
    
    ; 3. Update Tone Channels and Mix
    Protected sample_mix.l = 0
    For c = 0 To 2
      Protected period.l = (PSG\R[c*2+1] & $0F) << 8 | PSG\R[c*2]
      If period < 4 : period = 4 : EndIf
      
      PSG\Chan[c]\Count + step_val
      While PSG\Chan[c]\Count >= period
        PSG\Chan[c]\Count - period
        PSG\Chan[c]\State = ~PSG\Chan[c]\State & 1
      Wend
      
      Protected tone_disabled.l = (PSG\R[7] >> c) & 1
      Protected noise_disabled.l = (PSG\R[7] >> (c + 3)) & 1
      
      ; Combined state is ANDed
      Protected chan_out.l = (PSG\Chan[c]\State | tone_disabled) & (PSG\NoiseState | noise_disabled)
      
      If chan_out
        Protected vol.l = PSG\R[8 + c] & $0F
        If PSG\R[8 + c] & $10 ; Envelope flag
          vol = PSG\Env\State
        EndIf
        sample_mix + PSGVolumeTable(vol)
      EndIf
    Next c
    
    ; Master Mixing & Clipping
    sample_mix = sample_mix / 3
    If sample_mix > 32767 : sample_mix = 32767 : EndIf
    
    PokeW(*Buffer + i * 2, sample_mix)
  Next i
EndProcedure

; --- Win32 waveOut Streaming Implementation ---

#AUDIO_SAMPLE_RATE = 44100
#AUDIO_CHANNELS = 1
#AUDIO_BUFFER_SIZE = 1024 ; ~23ms latency
#AUDIO_BUFFERS_COUNT = 4

Global hWaveOut.i = 0
Global Dim AudioHeaders.WAVEHDR(#AUDIO_BUFFERS_COUNT - 1)
Global Dim AudioBuffers.i(#AUDIO_BUFFERS_COUNT - 1)
Global AudioThread.i = 0
Global AudioExit.l = 0

Procedure AudioThreadProc(*Param)
  Protected current_buffer.l = 0
  Protected format.WAVEFORMATEX
  format\wFormatTag = #WAVE_FORMAT_PCM
  format\nChannels = #AUDIO_CHANNELS
  format\nSamplesPerSec = #AUDIO_SAMPLE_RATE
  format\wBitsPerSample = 16
  format\nBlockAlign = (format\nChannels * format\wBitsPerSample) / 8
  format\nAvgBytesPerSec = format\nSamplesPerSec * format\nBlockAlign
  format\cbSize = 0
  
  If waveOutOpen_(@hWaveOut, #WAVE_MAPPER, @format, 0, 0, 0) <> 0
    ProcedureReturn ; Failed to open audio device
  EndIf
  
  Protected i.l
  For i = 0 To #AUDIO_BUFFERS_COUNT - 1
    AudioBuffers(i) = AllocateMemory(#AUDIO_BUFFER_SIZE * 2)
    AudioHeaders(i)\lpData = AudioBuffers(i)
    AudioHeaders(i)\dwBufferLength = #AUDIO_BUFFER_SIZE * 2
    AudioHeaders(i)\dwFlags = 0
    waveOutPrepareHeader_(hWaveOut, @AudioHeaders(i), SizeOf(WAVEHDR))
  Next i
  
  While Not AudioExit
    Protected buf_index.l = -1
    For i = 0 To #AUDIO_BUFFERS_COUNT - 1
      If (AudioHeaders(i)\dwFlags & #WHDR_PREPARED) And (AudioHeaders(i)\dwFlags & #WHDR_DONE Or AudioHeaders(i)\dwFlags & #WHDR_INQUEUE = 0)
        buf_index = i
        Break
      EndIf
    Next i
    
    If buf_index <> -1
      PSG_Render(AudioBuffers(buf_index), #AUDIO_BUFFER_SIZE)
      AudioHeaders(buf_index)\dwFlags & ~#WHDR_DONE
      waveOutWrite_(hWaveOut, @AudioHeaders(buf_index), SizeOf(WAVEHDR))
    Else
      Delay(5)
    EndIf
  Wend
  
  waveOutReset_(hWaveOut)
  For i = 0 To #AUDIO_BUFFERS_COUNT - 1
    waveOutUnprepareHeader_(hWaveOut, @AudioHeaders(i), SizeOf(WAVEHDR))
    FreeMemory(AudioBuffers(i))
  Next i
  waveOutClose_(hWaveOut)
EndProcedure

Procedure StartAudio()
  ResetPSG()
  AudioExit = 0
  AudioThread = CreateThread(@AudioThreadProc(), 0)
EndProcedure

Procedure StopAudio()
  AudioExit = 1
  If AudioThread
    WaitThread(AudioThread, 2000)
    AudioThread = 0
  EndIf
EndProcedure
