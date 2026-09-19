package msx

import (
	"fmt"
)

// WD1793 register indices and commands matching fMSX EMULib/WD1793.h
const (
	WD1793Keep  = 0
	WD1793Init  = 1
	WD1793Eject = 2

	WD1793Command = 0
	WD1793Status  = 0
	WD1793Track   = 1
	WD1793Sector  = 2
	WD1793Data    = 3
	WD1793System  = 4
	WD1793Ready   = 4

	WD1793IRQ = 0x80
	WD1793DRQ = 0x40

	// Common status bits
	FBusy     = 0x01 // Controller is executing a command
	FDRQ      = 0x02 // Data request pending
	FIndex    = 0x02 // Index mark detected (Type 1)
	FTrack0   = 0x04 // Head positioned at track #0 (Type 1)
	FLostData = 0x04 // Data lost (missed DRQ, Type 2/3)
	FCRCErr   = 0x08 // CRC error in ID field (Type 1)
	FBadData  = 0x08 // Bad data CRC (Type 2/3)
	FSeekErr  = 0x10 // Seek error (Type 1)
	FNotFound = 0x10 // Sector not found (Type 2/3)
	FHeadLoad = 0x20 // Head loaded (Type 1)
	FDeleted  = 0x20 // Deleted data mark (Type 2/3)
	FWrFault  = 0x20 // Write fault (Type 2/3)
	FReadOnly = 0x40 // The disk is write-protected
	FNotReady = 0x80 // Drive not ready

	FErrCode = 0x18 // Error code bits

	// Command modifiers
	CDelMark  = 0x01
	CSideComp = 0x02
	CStepRate = 0x03
	CVerify   = 0x04
	CWait15MS = 0x04
	CLoadHead = 0x08
	CSide     = 0x08
	CIRQ      = 0x08
	CSetTrack = 0x10
	CMultiRec = 0x10

	// System register bits
	SDrive   = 0x03
	SReset   = 0x04
	SHalt    = 0x08
	SSide    = 0x10
	SDensity = 0x20
)

// WD1793 represents the Western Digital WD1793 / WD2793 Floppy Disk Controller.
// Faithful 1:1 port of Marat Fayzullin's WD1793.c and WD1793.h.
type WD1793 struct {
	R        [5]byte         // Registers: 0: Command/Status, 1: Track, 2: Sector, 3: Data, 4: System
	Drive    byte            // Current drive index (0..3)
	Side     byte            // Current side (0 or 1)
	Track    [4]byte         // Current physical track per drive (0..3)
	LastS    byte            // Last STEP direction (0x20: Out/decrement, 0x00: In/increment)
	IRQ      byte            // 0x80: IRQ pending, 0x40: DRQ pending
	Wait     byte            // Expiration watchdog counter
	Cmd      byte            // Last command
	WRLength int             // Data bytes remaining to write
	RDLength int             // Data bytes remaining to read
	DataPtr  int             // Current byte offset in active disk buffer
	Header   [6]byte         // Sector header for READ-ADDRESS command
	Disk     [4]*FloppyDrive // Connected virtual floppy disk drives
	Verbose  bool
}

// NewWD1793 creates and initializes a WD1793 controller.
func NewWD1793(fdd0, fdd1 *FloppyDrive) *WD1793 {
	fdc := &WD1793{}
	fdc.Disk[0] = fdd0
	fdc.Disk[1] = fdd1
	fdc.Reset(false)
	return fdc
}

// Reset resets the controller to power-on defaults.
func (w *WD1793) Reset(eject bool) {
	w.R[0] = 0x00
	w.R[1] = 0x00
	w.R[2] = 0x00
	w.R[3] = 0x00
	w.R[4] = SReset | SHalt
	w.Drive = 0
	w.Side = 0
	w.LastS = 0
	w.IRQ = 0
	w.WRLength = 0
	w.RDLength = 0
	w.Wait = 0
	w.Cmd = 0xD0
	w.DataPtr = 0

	for j := 0; j < 4; j++ {
		w.Track[j] = 0
		if eject && w.Disk[j] != nil {
			w.Disk[j] = &FloppyDrive{ID: j, SecSize: 512}
		}
	}
}

// Read reads from WD1793 register a (0: Status, 1: Track, 2: Sector, 3: Data, 4: Ready/System).
func (w *WD1793) Read(a byte) byte {
	switch a {
	case WD1793Status:
		val := w.R[0]
		curDrive := int(w.Drive)
		if curDrive >= 4 || w.Disk[curDrive] == nil || len(w.Disk[curDrive].Data) == 0 {
			val |= FNotReady
		}
		if w.Cmd < 0x80 || w.Cmd == 0xD0 {
			// Flip index bit to simulate rotating disk
			w.R[0] = (w.R[0] ^ FIndex) & (FIndex | FBusy | FNotReady | FReadOnly | FTrack0)
		} else {
			// Clear all flags except Busy, NotReady, ReadOnly, DRQ
			w.R[0] &= (FBusy | FNotReady | FReadOnly | FDRQ)
		}
		return val

	case WD1793Track:
		return w.R[1]

	case WD1793Sector:
		return w.R[2]

	case WD1793Data:
		if w.RDLength <= 0 {
			if w.Verbose {
				fmt.Println("[WD1793] Extra data read past buffer end")
			}
			return 0xFF
		}

		curDrive := int(w.Drive)
		if curDrive < 4 && w.Disk[curDrive] != nil && w.DataPtr < len(w.Disk[curDrive].Data) {
			w.R[3] = w.Disk[curDrive].Data[w.DataPtr]
			w.DataPtr++
		} else if w.Cmd == 0xC0 && w.DataPtr < len(w.Header) {
			// READ-ADDRESS command returning sector header
			w.R[3] = w.Header[w.DataPtr]
			w.DataPtr++
		}

		w.RDLength--
		if w.RDLength > 0 {
			w.Wait = 255
			secSize := 512
			if curDrive < 4 && w.Disk[curDrive] != nil && w.Disk[curDrive].SecSize > 0 {
				secSize = w.Disk[curDrive].SecSize
			}
			// If sector boundary crossed, increment sector register
			if (w.RDLength & (secSize - 1)) == 0 {
				w.R[2]++
			}
		} else {
			// Read completed
			w.R[0] &^= (FDRQ | FBusy)
			w.IRQ = WD1793IRQ
		}
		return w.R[3]

	case WD1793Ready:
		if w.Wait > 0 {
			w.Wait--
			if w.Wait == 0 {
				if w.Verbose {
					fmt.Println("[WD1793] Command timed out")
				}
				w.RDLength = 0
				w.WRLength = 0
				w.R[0] = (w.R[0] &^ (FDRQ | FBusy)) | FLostData
				w.IRQ = WD1793IRQ
			}
		}
		return w.IRQ
	}

	return 0xFF
}

// Write writes byte v into register a. Returns current IRQ/DRQ state.
func (w *WD1793) Write(a byte, v byte) byte {
	switch a {
	case WD1793Command:
		w.IRQ = 0
		// FORCE-INTERRUPT (0xD0)
		if (v & 0xF0) == 0xD0 {
			w.RDLength = 0
			w.WRLength = 0
			w.Cmd = 0xD0
			if (w.R[0] & FBusy) != 0 {
				w.R[0] &^= FBusy
			} else {
				tr0 := byte(0)
				if int(w.Drive) < 4 && w.Track[w.Drive] == 0 {
					tr0 = FTrack0
				}
				w.R[0] = tr0 | FIndex
			}
			if (v & CIRQ) != 0 {
				w.IRQ = WD1793IRQ
			}
			return w.IRQ
		}

		// If busy executing another command, ignore
		if (w.R[0] & FBusy) != 0 {
			break
		}

		w.R[0] = 0x00
		w.Cmd = v

		switch v & 0xF0 {
		case 0x00: // RESTORE (Seek track 0)
			if int(w.Drive) < 4 {
				w.Track[w.Drive] = 0
			}
			hl := byte(0)
			if (v & CLoadHead) != 0 {
				hl = FHeadLoad
			}
			w.R[0] = FIndex | FTrack0 | hl
			w.R[1] = 0
			w.IRQ = WD1793IRQ

		case 0x10: // SEEK
			w.RDLength = 0
			w.WRLength = 0
			if int(w.Drive) < 4 {
				w.Track[w.Drive] = w.R[3]
			}
			tr0 := byte(0)
			if int(w.Drive) < 4 && w.Track[w.Drive] == 0 {
				tr0 = FTrack0
			}
			hl := byte(0)
			if (v & CLoadHead) != 0 {
				hl = FHeadLoad
			}
			w.R[0] = FIndex | tr0 | hl
			w.R[1] = w.Track[w.Drive]
			w.IRQ = WD1793IRQ

		case 0x20, 0x30, 0x40, 0x50, 0x60, 0x70: // STEP variants
			if (v & 0x40) != 0 {
				w.LastS = v & 0x20
			} else {
				v = (v &^ 0x20) | w.LastS
			}
			if int(w.Drive) < 4 {
				if (v & 0x20) != 0 {
					if w.Track[w.Drive] > 0 {
						w.Track[w.Drive]--
					}
				} else {
					if w.Track[w.Drive] < 85 {
						w.Track[w.Drive]++
					}
				}
				if (v & CSetTrack) != 0 {
					w.R[1] = w.Track[w.Drive]
				}
				tr0 := byte(0)
				if w.Track[w.Drive] == 0 {
					tr0 = FTrack0
				}
				w.R[0] = FIndex | tr0
			}
			w.IRQ = WD1793IRQ

		case 0x80, 0x90: // READ-SECTORS
			offset, secSize, sectorsLeft, ok := w.seekCurrentSector(v)
			if !ok {
				w.R[0] = (w.R[0] &^ FErrCode) | FNotFound
				w.IRQ = WD1793IRQ
			} else {
				w.DataPtr = offset
				if (v & CMultiRec) != 0 {
					w.RDLength = secSize * sectorsLeft
				} else {
					w.RDLength = secSize
				}
				w.R[0] |= FBusy | FDRQ
				w.IRQ = WD1793DRQ
				w.Wait = 255
			}

		case 0xA0, 0xB0: // WRITE-SECTORS
			offset, secSize, sectorsLeft, ok := w.seekCurrentSector(v)
			if !ok {
				w.R[0] = (w.R[0] &^ FErrCode) | FNotFound
				w.IRQ = WD1793IRQ
			} else {
				w.DataPtr = offset
				if (v & CMultiRec) != 0 {
					w.WRLength = secSize * sectorsLeft
				} else {
					w.WRLength = secSize
				}
				w.R[0] |= FBusy | FDRQ
				w.IRQ = WD1793DRQ
				w.Wait = 255
			}

		case 0xC0: // READ-ADDRESS
			curDrive := int(w.Drive)
			if curDrive >= 4 || w.Disk[curDrive] == nil || len(w.Disk[curDrive].Data) == 0 {
				w.R[0] |= FNotFound
				w.IRQ = WD1793IRQ
			} else {
				w.Header[0] = w.R[1] // Track
				w.Header[1] = w.Side // Side
				w.Header[2] = w.R[2] // Sector
				w.Header[3] = 2      // 512 bytes (size code: 128 << 2 = 512)
				w.Header[4] = 0x00   // CRC 1
				w.Header[5] = 0x00   // CRC 2
				w.DataPtr = 0
				w.RDLength = 6
				w.R[0] |= FBusy | FDRQ
				w.IRQ = WD1793DRQ
				w.Wait = 255
			}

		default:
			// Unsupported or unknown
			w.IRQ = WD1793IRQ
		}

	case WD1793Track, WD1793Sector:
		if (w.R[0] & FBusy) == 0 {
			w.R[a] = v
		}

	case WD1793System:
		if ((w.R[4] ^ v) & v & SReset) != 0 {
			w.Reset(false)
		}
		w.Drive = v & SDrive
		if (v & SSide) != 0 {
			w.Side = 0
		} else {
			w.Side = 1
		}
		w.R[4] = v

	case WD1793Data:
		if w.WRLength <= 0 {
			if w.Verbose {
				fmt.Printf("[WD1793] Extra data write (%02Xh)\n", v)
			}
		} else {
			curDrive := int(w.Drive)
			if curDrive < 4 && w.Disk[curDrive] != nil && w.DataPtr < len(w.Disk[curDrive].Data) {
				w.Disk[curDrive].Data[w.DataPtr] = v
				w.Disk[curDrive].Modified = true
				w.DataPtr++
			}
			w.WRLength--
			if w.WRLength > 0 {
				w.Wait = 255
				secSize := 512
				if curDrive < 4 && w.Disk[curDrive] != nil && w.Disk[curDrive].SecSize > 0 {
					secSize = w.Disk[curDrive].SecSize
				}
				if (w.WRLength & (secSize - 1)) == 0 {
					w.R[2]++
				}
			} else {
				// Write completed
				w.R[0] &^= (FDRQ | FBusy)
				w.IRQ = WD1793IRQ
			}
		}
		w.R[3] = v
	}

	return w.IRQ
}

// seekCurrentSector calculates disk buffer byte offset for the currently selected track, side, and sector.
func (w *WD1793) seekCurrentSector(cmd byte) (offset int, secSize int, sectorsLeft int, ok bool) {
	curDrive := int(w.Drive)
	if curDrive >= 4 || w.Disk[curDrive] == nil || len(w.Disk[curDrive].Data) == 0 {
		return 0, 0, 0, false
	}

	d := w.Disk[curDrive]
	secSize = d.SecSize
	if secSize == 0 {
		secSize = 512
	}
	secPerTrack := d.SecPerTrack
	if secPerTrack == 0 {
		secPerTrack = 9
	}
	sides := d.Sides
	if sides == 0 {
		sides = 2
	}

	track := int(w.Track[w.Drive])
	side := int(w.Side)
	if (cmd & CSideComp) != 0 {
		if (cmd & CSide) != 0 {
			side = 1
		} else {
			side = 0
		}
	}

	sectorID := int(w.R[2])
	if sectorID < 1 || sectorID > secPerTrack {
		return 0, 0, 0, false
	}

	linearSector := (track*sides+side)*secPerTrack + (sectorID - 1)
	byteOffset := linearSector * secSize
	if byteOffset < 0 || byteOffset+secSize > len(d.Data) {
		return 0, 0, 0, false
	}

	sectorsLeft = secPerTrack - sectorID + 1
	return byteOffset, secSize, sectorsLeft, true
}
