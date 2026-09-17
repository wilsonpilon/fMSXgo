package msxdisk

import (
	"encoding/binary"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	SectorSize = 512
	FatEof     = 0x0FFF
)

// DiskFormat represents predefined MSX disk geometries.
type DiskFormat string

const (
	Format720K DiskFormat = "720K" // 3.5" 2DD, 80 tracks, 2 sides, 9 sectors/track (1440 sectors, 720KB)
	Format360K DiskFormat = "360K" // 5.25" 2D or 3.5" 1DD, 40 tracks, 2 sides, 9 sectors/track (720 sectors, 360KB)
	Format180K DiskFormat = "180K" // 5.25" 1D, 40 tracks, 1 side, 9 sectors/track (360 sectors, 180KB)
)

// DiskGeometry defines physical and logical layout parameters.
type DiskGeometry struct {
	Format        DiskFormat
	Description   string
	TotalSectors  int
	SecPerTrack   int
	Sides         int
	Tracks        int
	MediaID       byte
	SecPerFat     int
	NumFats       int
	RootDirEnts   int
	SecPerCluster int
}

var (
	Geometry720K = DiskGeometry{
		Format:        Format720K,
		Description:   "3.5\" 720KB (2 sides, 80 tracks, 9 sec/track)",
		TotalSectors:  1440,
		SecPerTrack:   9,
		Sides:         2,
		Tracks:        80,
		MediaID:       0xF9,
		SecPerFat:     3,
		NumFats:       2,
		RootDirEnts:   112,
		SecPerCluster: 2,
	}

	Geometry360K = DiskGeometry{
		Format:        Format360K,
		Description:   "3.5\"/5.25\" 360KB (2 sides, 40 tracks, 9 sec/track)",
		TotalSectors:  720,
		SecPerTrack:   9,
		Sides:         2,
		Tracks:        40,
		MediaID:       0xF8,
		SecPerFat:     2,
		NumFats:       2,
		RootDirEnts:   112,
		SecPerCluster: 2,
	}

	Geometry180K = DiskGeometry{
		Format:        Format180K,
		Description:   "5.25\" 180KB (1 side, 40 tracks, 9 sec/track)",
		TotalSectors:  360,
		SecPerTrack:   9,
		Sides:         1,
		Tracks:        40,
		MediaID:       0xF8,
		SecPerFat:     2,
		NumFats:       2,
		RootDirEnts:   112,
		SecPerCluster: 1,
	}
)

// DefaultMSXBootBlock contains the classic MSX boot sector image (512 bytes)
// with valid BPB, boot error routine, and MSX-DOS loader stub.
var DefaultMSXBootBlock = []byte{
	0xEB, 0xFE, 0x90, 0x56, 0x46, 0x42, 0x2D, 0x31, 0x39, 0x38, 0x39, 0x00, 0x02, 0x02, 0x01, 0x00,
	0x02, 0x70, 0x00, 0xA0, 0x05, 0xF9, 0x03, 0x00, 0x09, 0x00, 0x02, 0x00, 0x00, 0x00, 0xD0, 0xED,
	0x53, 0x58, 0xC0, 0x32, 0xC2, 0xC0, 0x36, 0x55, 0x23, 0x36, 0xC0, 0x31, 0x1F, 0xF5, 0x11, 0x9D,
	0xC0, 0x0E, 0x0F, 0xCD, 0x7D, 0xF3, 0x3C, 0x28, 0x28, 0x11, 0x00, 0x01, 0x0E, 0x1A, 0xCD, 0x7D,
	0xF3, 0x21, 0x01, 0x00, 0x22, 0xAB, 0xC0, 0x21, 0x00, 0x3F, 0x11, 0x9D, 0xC0, 0x0E, 0x27, 0xCD,
	0x7D, 0xF3, 0xC3, 0x00, 0x01, 0x57, 0xC0, 0xCD, 0x00, 0x00, 0x79, 0xE6, 0xFE, 0xFE, 0x02, 0x20,
	0x07, 0x3A, 0xC2, 0xC0, 0xA7, 0xCA, 0x22, 0x40, 0x11, 0x77, 0xC0, 0x0E, 0x09, 0xCD, 0x7D, 0xF3,
	0x0E, 0x07, 0xCD, 0x7D, 0xF3, 0x18, 0xB4, 0x42, 0x6F, 0x6F, 0x74, 0x20, 0x65, 0x72, 0x72, 0x6F,
	0x72, 0x0D, 0x0A, 0x50, 0x72, 0x65, 0x73, 0x73, 0x20, 0x61, 0x6E, 0x79, 0x20, 0x6B, 0x65, 0x79,
	0x20, 0x66, 0x6F, 0x72, 0x20, 0x72, 0x65, 0x74, 0x72, 0x79, 0x0D, 0x0A, 0x24, 0x00, 0x4D, 0x53,
	0x58, 0x44, 0x4F, 0x53, 0x20, 0x20, 0x53, 0x59, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF3, 0x2A,
	0x51, 0xF3, 0x11, 0x00, 0x01, 0x19, 0x01, 0x00, 0x01, 0x11, 0x00, 0xC1, 0xED, 0xB0, 0x3A, 0xEE,
	0xC0, 0x47, 0x11, 0xEF, 0xC0, 0x21, 0x00, 0x00, 0xCD, 0x51, 0x52, 0xF3, 0x76, 0xC9, 0x18, 0x64,
	0x3A, 0xAF, 0x80, 0xF9, 0xCA, 0x6D, 0x48, 0xD3, 0xA5, 0x0C, 0x8C, 0x2F, 0x9C, 0xCB, 0xE9, 0x89,
	0xD2, 0x00, 0x32, 0x26, 0x40, 0x94, 0x61, 0x19, 0x20, 0xE6, 0x80, 0x6D, 0x8A, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
}

// FileInfo provides metadata about a file stored on the MSX disk.
type FileInfo struct {
	Name         string
	Size         uint32
	ModTime      time.Time
	Attr         byte
	FirstCluster uint16
	Clusters     int
}

// RawDirEntry represents the on-disk 32-byte MSX-DOS directory entry.
type RawDirEntry struct {
	Name         [8]byte
	Ext          [3]byte
	Attr         byte
	Reserved     [10]byte
	Time         uint16
	Date         uint16
	FirstCluster uint16
	Size         uint32
}

// Disk represents an in-memory MSX FAT12 disk image.
type Disk struct {
	Path        string
	Data        []byte
	Geometry    DiskGeometry
	Modified    bool
	DirOffset   int
	DataOffset  int
	ClusterLen  int
	MaxCluster  uint16
	NumDir      int
	SecPerFat   int
	NumFats     int
	SecPerClust int
}

// ResolveGeometry returns standard DiskGeometry for a format name or sector count.
func ResolveGeometry(fmtOrSize string) DiskGeometry {
	clean := strings.ToUpper(strings.TrimSpace(fmtOrSize))
	switch clean {
	case "360", "360K", "360KB":
		return Geometry360K
	case "180", "180K", "180KB":
		return Geometry180K
	default:
		return Geometry720K
	}
}

// CreateMemory formats a new MSX FAT12 disk image entirely in memory.
func CreateMemory(format DiskFormat, customBoot []byte) (*Disk, error) {
	var geom DiskGeometry
	switch format {
	case Format360K:
		geom = Geometry360K
	case Format180K:
		geom = Geometry180K
	default:
		geom = Geometry720K
	}

	totalBytes := geom.TotalSectors * SectorSize
	data := make([]byte, totalBytes)

	// 1. Prepare Boot Sector (512 bytes)
	boot := make([]byte, SectorSize)
	if len(customBoot) >= SectorSize {
		copy(boot, customBoot[:SectorSize])
	} else {
		copy(boot, DefaultMSXBootBlock)
	}

	// Patch BPB parameters into Boot Sector
	binary.LittleEndian.PutUint16(boot[11:], uint16(SectorSize))
	boot[13] = byte(geom.SecPerCluster)
	binary.LittleEndian.PutUint16(boot[14:], 1) // 1 reserved sector
	boot[16] = byte(geom.NumFats)
	binary.LittleEndian.PutUint16(boot[17:], uint16(geom.RootDirEnts))
	binary.LittleEndian.PutUint16(boot[19:], uint16(geom.TotalSectors))
	boot[21] = geom.MediaID
	binary.LittleEndian.PutUint16(boot[22:], uint16(geom.SecPerFat))
	binary.LittleEndian.PutUint16(boot[24:], uint16(geom.SecPerTrack))
	binary.LittleEndian.PutUint16(boot[26:], uint16(geom.Sides))

	copy(data[0:SectorSize], boot)

	// 2. Initialize FAT12 tables
	fatLen := geom.SecPerFat * SectorSize
	fat := make([]byte, fatLen)

	// Cluster 0 = MediaID | 0xF00; Cluster 1 = 0xFFF
	fat[0] = geom.MediaID
	fat[1] = 0xFF
	fat[2] = 0xFF

	// Write FAT copies
	fatStart := SectorSize
	for f := 0; f < geom.NumFats; f++ {
		offset := fatStart + f*fatLen
		copy(data[offset:offset+fatLen], fat)
	}

	// 3. Root directory begins right after FAT tables (already zeros)
	d, err := OpenMemory(data)
	if err != nil {
		return nil, err
	}
	d.Geometry = geom
	d.Modified = true
	return d, nil
}

// Create formats and saves a new MSX disk image file to host filesystem.
func Create(path string, format DiskFormat, customBoot []byte) (*Disk, error) {
	d, err := CreateMemory(format, customBoot)
	if err != nil {
		return nil, err
	}
	d.Path = path
	if err := d.SaveAs(path); err != nil {
		return nil, err
	}
	return d, nil
}

// Open loads an existing MSX disk image file from host filesystem.
func Open(path string) (*Disk, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read disk file: %w", err)
	}
	d, err := OpenMemory(data)
	if err != nil {
		return nil, err
	}
	d.Path = path
	return d, nil
}

// OpenMemory parses an in-memory byte slice as an MSX FAT12 disk image.
func OpenMemory(data []byte) (*Disk, error) {
	if len(data) < SectorSize {
		return nil, errors.New("image too small to contain MSX boot sector")
	}

	secSize := int(binary.LittleEndian.Uint16(data[11:13]))
	if secSize != SectorSize {
		secSize = SectorSize
	}

	secPerCluster := int(data[13])
	if secPerCluster <= 0 {
		secPerCluster = 2
	}

	reservedSecs := int(binary.LittleEndian.Uint16(data[14:16]))
	if reservedSecs <= 0 {
		reservedSecs = 1
	}

	numFats := int(data[16])
	if numFats <= 0 {
		numFats = 2
	}

	numDir := int(binary.LittleEndian.Uint16(data[17:19]))
	if numDir <= 0 {
		numDir = 112
	}

	totalSectors := int(binary.LittleEndian.Uint16(data[19:21]))
	if totalSectors <= 0 {
		totalSectors = len(data) / SectorSize
	}

	mediaID := data[21]
	secPerFat := int(binary.LittleEndian.Uint16(data[22:24]))
	if secPerFat <= 0 {
		secPerFat = 3
	}

	secPerTrack := int(binary.LittleEndian.Uint16(data[24:26]))
	if secPerTrack <= 0 {
		secPerTrack = 9
	}

	sides := int(binary.LittleEndian.Uint16(data[26:28]))
	if sides <= 0 {
		sides = 2
	}

	dirOffset := secSize * (reservedSecs + numFats*secPerFat)
	dirSize := numDir * 32
	dataOffset := dirOffset + dirSize
	clusterLen := secSize * secPerCluster
	dataSectors := totalSectors - (dataOffset / secSize)
	maxCluster := uint16(dataSectors/secPerCluster + 1)

	// Detect format geometry
	geom := Geometry720K
	if totalSectors <= 360 {
		geom = Geometry180K
	} else if totalSectors <= 720 {
		geom = Geometry360K
	}
	geom.TotalSectors = totalSectors
	geom.SecPerCluster = secPerCluster
	geom.SecPerFat = secPerFat
	geom.RootDirEnts = numDir
	geom.MediaID = mediaID
	geom.SecPerTrack = secPerTrack
	geom.Sides = sides

	d := &Disk{
		Data:        data,
		Geometry:    geom,
		DirOffset:   dirOffset,
		DataOffset:  dataOffset,
		ClusterLen:  clusterLen,
		MaxCluster:  maxCluster,
		NumDir:      numDir,
		SecPerFat:   secPerFat,
		NumFats:     numFats,
		SecPerClust: secPerCluster,
	}

	return d, nil
}

// ReadFAT retrieves the 12-bit cluster value for cluster clnr from FAT.
func (d *Disk) ReadFAT(clnr uint16) uint16 {
	fatOffset := SectorSize // FAT 0 begins right after Boot Sector
	p := fatOffset + int((clnr*3)/2)
	if p+1 >= len(d.Data) {
		return FatEof
	}

	val := uint16(d.Data[p]) | (uint16(d.Data[p+1]) << 8)
	if (clnr & 1) != 0 {
		return (val >> 4) & 0x0FFF
	}
	return val & 0x0FFF
}

// WriteFAT sets the 12-bit cluster value for cluster clnr in all FAT copies.
func (d *Disk) WriteFAT(clnr uint16, val uint16) {
	val &= 0x0FFF
	fatLen := d.SecPerFat * SectorSize

	for f := 0; f < d.NumFats; f++ {
		fatBase := SectorSize + f*fatLen
		p := fatBase + int((clnr*3)/2)
		if p+1 >= len(d.Data) {
			continue
		}

		if (clnr & 1) != 0 {
			d.Data[p] = (d.Data[p] & 0x0F) | byte((val&0x0F)<<4)
			d.Data[p+1] = byte((val >> 4) & 0xFF)
		} else {
			d.Data[p] = byte(val & 0xFF)
			d.Data[p+1] = (d.Data[p+1] & 0xF0) | byte((val>>8)&0x0F)
		}
	}
	d.Modified = true
}

// ListFiles enumerates all active files in the root directory.
func (d *Disk) ListFiles() ([]FileInfo, error) {
	var files []FileInfo
	for i := 0; i < d.NumDir; i++ {
		entryOffset := d.DirOffset + i*32
		if entryOffset+32 > len(d.Data) {
			break
		}

		firstByte := d.Data[entryOffset]
		if firstByte == 0x00 {
			// 0x00 means remaining entries are free / unallocated
			break
		}
		if firstByte == 0xE5 {
			// Deleted entry
			continue
		}

		attr := d.Data[entryOffset+11]
		if (attr & 0x08) != 0 {
			// Volume label entry, skip file list
			continue
		}

		name := decodeFAT11(d.Data[entryOffset : entryOffset+11])
		t := binary.LittleEndian.Uint16(d.Data[entryOffset+22 : entryOffset+24])
		date := binary.LittleEndian.Uint16(d.Data[entryOffset+24 : entryOffset+26])
		firstCluster := binary.LittleEndian.Uint16(d.Data[entryOffset+26 : entryOffset+28])
		size := binary.LittleEndian.Uint32(d.Data[entryOffset+28 : entryOffset+32])

		// Count allocated clusters
		clusters := 0
		cur := firstCluster
		for cur >= 2 && cur <= d.MaxCluster {
			clusters++
			next := d.ReadFAT(cur)
			if next >= 0x0FF8 {
				break
			}
			cur = next
		}

		files = append(files, FileInfo{
			Name:         name,
			Size:         size,
			ModTime:      msxTimeToTime(t, date),
			Attr:         attr,
			FirstCluster: firstCluster,
			Clusters:     clusters,
		})
	}
	return files, nil
}

// AddFile reads a local host file and writes it to the MSX disk image.
func (d *Disk) AddFile(localPath string, msxName string) error {
	data, err := os.ReadFile(localPath)
	if err != nil {
		return fmt.Errorf("cannot read local file %q: %w", localPath, err)
	}

	fi, err := os.Stat(localPath)
	var modTime time.Time
	if err == nil {
		modTime = fi.ModTime()
	} else {
		modTime = time.Now()
	}

	if msxName == "" {
		msxName = filepath.Base(localPath)
	}

	return d.AddFileData(msxName, data, modTime)
}

// AddFileData inserts raw file bytes into the MSX disk image with given name and timestamp.
func (d *Disk) AddFileData(msxName string, fileData []byte, modTime time.Time) error {
	fat11 := convertToFAT11(msxName)
	if fat11 == "" {
		return fmt.Errorf("invalid MSX filename: %q", msxName)
	}

	// Delete any existing file with identical name
	_ = d.DeleteFile(msxName)

	// Find free directory entry
	dirSlot := -1
	for i := 0; i < d.NumDir; i++ {
		offset := d.DirOffset + i*32
		if offset+32 > len(d.Data) {
			break
		}
		b := d.Data[offset]
		if b == 0x00 || b == 0xE5 {
			dirSlot = i
			break
		}
	}
	if dirSlot == -1 {
		return errors.New("MSX disk root directory is full (max 112 files)")
	}

	size := uint32(len(fileData))
	var firstCluster uint16 = 0

	if size > 0 {
		// Calculate required clusters
		reqClusters := (int(size) + d.ClusterLen - 1) / d.ClusterLen

		// Find free clusters in FAT
		var allocated []uint16
		for cl := uint16(2); cl <= d.MaxCluster; cl++ {
			if d.ReadFAT(cl) == 0 {
				allocated = append(allocated, cl)
				if len(allocated) == reqClusters {
					break
				}
			}
		}

		if len(allocated) < reqClusters {
			return fmt.Errorf("insufficient disk space: need %d clusters (%d KB), only %d free",
				reqClusters, (reqClusters*d.ClusterLen)/1024, len(allocated))
		}

		firstCluster = allocated[0]

		// Write cluster chain into FAT
		for i := 0; i < len(allocated); i++ {
			cur := allocated[i]
			if i == len(allocated)-1 {
				d.WriteFAT(cur, FatEof)
			} else {
				d.WriteFAT(cur, allocated[i+1])
			}

			// Write data to cluster on disk
			clusterOffset := d.DataOffset + int(cur-2)*d.ClusterLen
			chunkStart := i * d.ClusterLen
			chunkEnd := chunkStart + d.ClusterLen
			if chunkEnd > len(fileData) {
				chunkEnd = len(fileData)
			}

			chunk := fileData[chunkStart:chunkEnd]
			copy(d.Data[clusterOffset:], chunk)

			// Zero pad remaining bytes in cluster
			if len(chunk) < d.ClusterLen {
				rem := d.ClusterLen - len(chunk)
				for z := 0; z < rem; z++ {
					d.Data[clusterOffset+len(chunk)+z] = 0
				}
			}
		}
	}

	// Write Directory Entry (32 bytes)
	entryOffset := d.DirOffset + dirSlot*32
	copy(d.Data[entryOffset:entryOffset+11], []byte(fat11))
	d.Data[entryOffset+11] = 0 // Normal file attribute
	for z := 12; z < 22; z++ {
		d.Data[entryOffset+z] = 0 // Reserved
	}

	tVal, dVal := timeToMSXTime(modTime)
	binary.LittleEndian.PutUint16(d.Data[entryOffset+22:entryOffset+24], tVal)
	binary.LittleEndian.PutUint16(d.Data[entryOffset+24:entryOffset+26], dVal)
	binary.LittleEndian.PutUint16(d.Data[entryOffset+26:entryOffset+28], firstCluster)
	binary.LittleEndian.PutUint32(d.Data[entryOffset+28:entryOffset+32], size)

	d.Modified = true
	return nil
}

// ExtractFileData retrieves the raw content of a file stored in the disk.
func (d *Disk) ExtractFileData(msxName string) ([]byte, time.Time, error) {
	fat11 := convertToFAT11(msxName)
	for i := 0; i < d.NumDir; i++ {
		offset := d.DirOffset + i*32
		if offset+32 > len(d.Data) {
			break
		}
		if d.Data[offset] == 0x00 {
			break
		}
		if d.Data[offset] == 0xE5 {
			continue
		}

		if string(d.Data[offset:offset+11]) == fat11 {
			size := binary.LittleEndian.Uint32(d.Data[offset+28 : offset+32])
			firstCl := binary.LittleEndian.Uint16(d.Data[offset+26 : offset+28])
			tVal := binary.LittleEndian.Uint16(d.Data[offset+22 : offset+24])
			dVal := binary.LittleEndian.Uint16(d.Data[offset+24 : offset+26])
			modTime := msxTimeToTime(tVal, dVal)

			out := make([]byte, 0, size)
			cur := firstCl
			bytesLeft := int(size)

			for bytesLeft > 0 && cur >= 2 && cur <= d.MaxCluster {
				clOffset := d.DataOffset + int(cur-2)*d.ClusterLen
				take := d.ClusterLen
				if take > bytesLeft {
					take = bytesLeft
				}
				if clOffset+take > len(d.Data) {
					take = len(d.Data) - clOffset
				}
				out = append(out, d.Data[clOffset:clOffset+take]...)
				bytesLeft -= take

				next := d.ReadFAT(cur)
				if next >= 0x0FF8 {
					break
				}
				cur = next
			}

			return out, modTime, nil
		}
	}
	return nil, time.Time{}, fmt.Errorf("file %q not found on MSX disk", msxName)
}

// ExtractFile extracts an MSX file to a destination path on the host filesystem.
func (d *Disk) ExtractFile(msxName string, destPath string) error {
	data, modTime, err := d.ExtractFileData(msxName)
	if err != nil {
		return err
	}

	if fi, err := os.Stat(destPath); err == nil && fi.IsDir() {
		destPath = filepath.Join(destPath, msxName)
	}

	if err := os.WriteFile(destPath, data, 0644); err != nil {
		return fmt.Errorf("cannot write destination file %q: %w", destPath, err)
	}

	_ = os.Chtimes(destPath, modTime, modTime)
	return nil
}

// DeleteFile removes a file from the disk, freeing its directory entry and FAT cluster chain.
func (d *Disk) DeleteFile(msxName string) error {
	fat11 := convertToFAT11(msxName)
	for i := 0; i < d.NumDir; i++ {
		offset := d.DirOffset + i*32
		if offset+32 > len(d.Data) {
			break
		}
		if d.Data[offset] == 0x00 {
			break
		}
		if d.Data[offset] == 0xE5 {
			continue
		}

		if string(d.Data[offset:offset+11]) == fat11 {
			firstCl := binary.LittleEndian.Uint16(d.Data[offset+26 : offset+28])

			// Free FAT chain
			cur := firstCl
			for cur >= 2 && cur <= d.MaxCluster {
				next := d.ReadFAT(cur)
				d.WriteFAT(cur, 0)
				if next >= 0x0FF8 || next == 0 {
					break
				}
				cur = next
			}

			// Mark directory entry as deleted
			d.Data[offset] = 0xE5
			d.Modified = true
			return nil
		}
	}
	return nil // Not found is harmless
}

// Save writes modifications back to the disk's original file path.
func (d *Disk) Save() error {
	if d.Path == "" {
		return errors.New("cannot save disk image: no file path specified")
	}
	return d.SaveAs(d.Path)
}

// SaveAs writes the disk image to the specified host file path.
func (d *Disk) SaveAs(path string) error {
	dir := filepath.Dir(path)
	if dir != "" && dir != "." {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %q: %w", dir, err)
		}
	}

	if err := os.WriteFile(path, d.Data, 0644); err != nil {
		return fmt.Errorf("failed to save disk image %q: %w", path, err)
	}

	d.Path = path
	d.Modified = false
	return nil
}

// Bytes returns the complete raw byte buffer of the disk image.
func (d *Disk) Bytes() []byte {
	return d.Data
}

// --- Helpers: FAT11 conversion, Wildcard Matching, MSX Time Encoding ---

// convertToFAT11 converts standard filename (e.g. "AUTOEXEC.BAT" or "test.bas")
// to 11-byte space-padded uppercase FAT representation (e.g. "AUTOEXECBAT").
func convertToFAT11(name string) string {
	name = strings.ToUpper(filepath.Base(name))
	var res [11]byte
	for i := range res {
		res[i] = ' '
	}

	parts := strings.Split(name, ".")
	mainName := parts[0]
	ext := ""
	if len(parts) > 1 {
		ext = parts[len(parts)-1]
	}

	for i := 0; i < len(mainName) && i < 8; i++ {
		res[i] = mainName[i]
	}
	for i := 0; i < len(ext) && i < 3; i++ {
		res[8+i] = ext[i]
	}

	return string(res[:])
}

// decodeFAT11 converts 11-byte FAT representation to a readable filename string.
func decodeFAT11(fat11 []byte) string {
	name := strings.TrimRight(string(fat11[:8]), " ")
	ext := strings.TrimRight(string(fat11[8:11]), " ")
	if ext != "" {
		return strings.ToUpper(name + "." + ext)
	}
	return strings.ToUpper(name)
}

// MatchesMask returns true if a filename matches an MSX wildcard mask (*.BAS, AUTO*.*, etc.)
func MatchesMask(filename, mask string) bool {
	fn11 := convertToFAT11(filename)
	mask11 := convertToFAT11Mask(mask)
	for i := 0; i < 11; i++ {
		m := mask11[i]
		if m != '?' && m != fn11[i] {
			return false
		}
	}
	return true
}

func convertToFAT11Mask(mask string) string {
	mask = strings.ToUpper(filepath.Base(mask))
	var res [11]byte
	for i := range res {
		res[i] = ' '
	}

	parts := strings.Split(mask, ".")
	mainMask := parts[0]
	extMask := ""
	if len(parts) > 1 {
		extMask = parts[len(parts)-1]
	}

	// Main part
	k := 0
	for i := 0; i < len(mainMask) && k < 8; i++ {
		if mainMask[i] == '*' {
			for ; k < 8; k++ {
				res[k] = '?'
			}
			break
		}
		res[k] = mainMask[i]
		k++
	}

	// Extension part
	k = 8
	for i := 0; i < len(extMask) && k < 11; i++ {
		if extMask[i] == '*' {
			for ; k < 11; k++ {
				res[k] = '?'
			}
			break
		}
		res[k] = extMask[i]
		k++
	}

	return string(res[:])
}

func msxTimeToTime(msxTime, msxDate uint16) time.Time {
	day := int(msxDate & 0x1F)
	month := int((msxDate >> 5) & 0x0F)
	year := 1980 + int((msxDate>>9)&0x7F)

	sec := int(msxTime&0x1F) * 2
	min := int((msxTime >> 5) & 0x3F)
	hour := int((msxTime >> 11) & 0x1F)

	if month < 1 || month > 12 {
		month = 1
	}
	if day < 1 || day > 31 {
		day = 1
	}
	if hour > 23 {
		hour = 0
	}
	if min > 59 {
		min = 0
	}
	if sec > 59 {
		sec = 0
	}

	return time.Date(year, time.Month(month), day, hour, min, sec, 0, time.Local)
}

func timeToMSXTime(t time.Time) (uint16, uint16) {
	year := t.Year() - 1980
	if year < 0 {
		year = 0
	}
	if year > 127 {
		year = 127
	}
	dateVal := uint16(year<<9) | uint16(int(t.Month())<<5) | uint16(t.Day())

	timeVal := uint16(t.Hour()<<11) | uint16(t.Minute()<<5) | uint16(t.Second()/2)
	return timeVal, dateVal
}
