package msxdisk

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestCreateAndFormatDisk(t *testing.T) {
	// Test 720K
	d720, err := CreateMemory(Format720K, nil)
	if err != nil {
		t.Fatalf("CreateMemory 720K failed: %v", err)
	}
	if len(d720.Data) != 1440*512 {
		t.Errorf("Expected 720K size %d, got %d", 1440*512, len(d720.Data))
	}
	if d720.Data[0x15] != 0xF9 {
		t.Errorf("Expected 720K Media ID 0xF9, got %02X", d720.Data[0x15])
	}

	// Test 360K
	d360, err := CreateMemory(Format360K, nil)
	if err != nil {
		t.Fatalf("CreateMemory 360K failed: %v", err)
	}
	if len(d360.Data) != 720*512 {
		t.Errorf("Expected 360K size %d, got %d", 720*512, len(d360.Data))
	}

	// Test 180K
	d180, err := CreateMemory(Format180K, nil)
	if err != nil {
		t.Fatalf("CreateMemory 180K failed: %v", err)
	}
	if len(d180.Data) != 360*512 {
		t.Errorf("Expected 180K size %d, got %d", 360*512, len(d180.Data))
	}
}

func TestDiskFileOperations(t *testing.T) {
	d, err := CreateMemory(Format720K, nil)
	if err != nil {
		t.Fatalf("Failed to create disk: %v", err)
	}

	// 1. Check initial empty directory
	files, err := d.ListFiles()
	if err != nil {
		t.Fatalf("ListFiles failed: %v", err)
	}
	if len(files) != 0 {
		t.Errorf("Expected 0 files on new disk, got %d", len(files))
	}

	// 2. Add small file (< cluster length)
	smallData := []byte("10 PRINT \"HELLO MSX\"\r\n20 GOTO 10\r\n")
	testTime := time.Date(1986, 4, 1, 12, 30, 0, 0, time.Local)
	err = d.AddFileData("HELLO.BAS", smallData, testTime)
	if err != nil {
		t.Fatalf("AddFileData failed: %v", err)
	}

	// 3. Add multi-cluster file (> 1024 bytes)
	largeData := make([]byte, 3500)
	for i := range largeData {
		largeData[i] = byte((i % 256))
	}
	err = d.AddFileData("BIGFILE.DAT", largeData, testTime)
	if err != nil {
		t.Fatalf("AddFileData large file failed: %v", err)
	}

	// 4. List files and verify
	files, err = d.ListFiles()
	if err != nil {
		t.Fatalf("ListFiles failed: %v", err)
	}
	if len(files) != 2 {
		t.Fatalf("Expected 2 files, got %d", len(files))
	}

	fileMap := make(map[string]FileInfo)
	for _, f := range files {
		fileMap[f.Name] = f
	}

	helloInfo, ok := fileMap["HELLO.BAS"]
	if !ok {
		t.Fatalf("HELLO.BAS not found in directory listing")
	}
	if helloInfo.Size != uint32(len(smallData)) {
		t.Errorf("HELLO.BAS size mismatch: expected %d, got %d", len(smallData), helloInfo.Size)
	}
	if helloInfo.Clusters != 1 {
		t.Errorf("HELLO.BAS clusters: expected 1, got %d", helloInfo.Clusters)
	}

	bigInfo, ok := fileMap["BIGFILE.DAT"]
	if !ok {
		t.Fatalf("BIGFILE.DAT not found in directory listing")
	}
	if bigInfo.Size != uint32(len(largeData)) {
		t.Errorf("BIGFILE.DAT size mismatch: expected %d, got %d", len(largeData), bigInfo.Size)
	}
	// 3500 bytes with 1024 bytes/cluster = 4 clusters
	if bigInfo.Clusters != 4 {
		t.Errorf("BIGFILE.DAT clusters: expected 4, got %d", bigInfo.Clusters)
	}

	// 5. Extract files and verify content bit-for-bit
	extSmall, _, err := d.ExtractFileData("HELLO.BAS")
	if err != nil {
		t.Fatalf("ExtractFileData HELLO.BAS failed: %v", err)
	}
	if !bytes.Equal(extSmall, smallData) {
		t.Errorf("Extracted HELLO.BAS content differs from original")
	}

	extLarge, _, err := d.ExtractFileData("BIGFILE.DAT")
	if err != nil {
		t.Fatalf("ExtractFileData BIGFILE.DAT failed: %v", err)
	}
	if !bytes.Equal(extLarge, largeData) {
		t.Errorf("Extracted BIGFILE.DAT content differs from original")
	}

	// 6. Delete file and verify FAT reclamation
	err = d.DeleteFile("BIGFILE.DAT")
	if err != nil {
		t.Fatalf("DeleteFile failed: %v", err)
	}

	files, _ = d.ListFiles()
	if len(files) != 1 {
		t.Fatalf("Expected 1 file after deletion, got %d", len(files))
	}
	if files[0].Name != "HELLO.BAS" {
		t.Errorf("Expected remaining file to be HELLO.BAS, got %s", files[0].Name)
	}
}

func TestDiskWildcards(t *testing.T) {
	if !MatchesMask("AUTOEXEC.BAT", "*.BAT") {
		t.Errorf("Expected AUTOEXEC.BAT to match *.BAT")
	}
	if !MatchesMask("TEST.BAS", "*.BAS") {
		t.Errorf("Expected TEST.BAS to match *.BAS")
	}
	if MatchesMask("GAME.ROM", "*.BAS") {
		t.Errorf("Expected GAME.ROM NOT to match *.BAS")
	}
	if !MatchesMask("README.TXT", "READ*.*") {
		t.Errorf("Expected README.TXT to match READ*.*")
	}
	if !MatchesMask("FILE1.DAT", "FILE?.DAT") {
		t.Errorf("Expected FILE1.DAT to match FILE?.DAT")
	}
}

func TestDiskFilePersistence(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "msxdisk_test_*")
	if err != nil {
		t.Fatalf("MkdirTemp failed: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	dskPath := filepath.Join(tmpDir, "test.dsk")
	d, err := Create(dskPath, Format720K, nil)
	if err != nil {
		t.Fatalf("Create failed: %v", err)
	}

	testData := []byte("MSX-DOS Persistence Test Payload")
	err = d.AddFileData("PAYLOAD.BIN", testData, time.Now())
	if err != nil {
		t.Fatalf("AddFileData failed: %v", err)
	}

	err = d.Save()
	if err != nil {
		t.Fatalf("Save failed: %v", err)
	}

	// Reopen disk from host file
	reopened, err := Open(dskPath)
	if err != nil {
		t.Fatalf("Open reopened disk failed: %v", err)
	}

	files, err := reopened.ListFiles()
	if err != nil {
		t.Fatalf("ListFiles failed: %v", err)
	}
	if len(files) != 1 || files[0].Name != "PAYLOAD.BIN" {
		t.Fatalf("Reopened disk files unexpected: %+v", files)
	}

	data, _, err := reopened.ExtractFileData("PAYLOAD.BIN")
	if err != nil {
		t.Fatalf("ExtractFileData failed: %v", err)
	}
	if !bytes.Equal(data, testData) {
		t.Errorf("Extracted data mismatch on reopened disk")
	}
}
