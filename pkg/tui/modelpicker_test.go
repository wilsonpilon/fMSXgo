package tui

import (
	"bytes"
	"strings"
	"testing"
)

func TestSelectMachineModelFallback(t *testing.T) {
	// Test input "1" -> ModelMSX1
	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	inBuf.WriteString("1\n")

	m, err := SelectMachineModel(ModelPickerOptions{
		CurrentModel: ModelMSX2,
		In:           &inBuf,
		Out:          &outBuf,
	})
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if m != ModelMSX1 {
		t.Fatalf("Expected ModelMSX1 (0), got %d", m)
	}
	if !strings.Contains(outBuf.String(), "MSX 1") {
		t.Fatalf("Expected output to contain MSX 1, got:\n%s", outBuf.String())
	}

	// Test input "3" -> ModelMSX2P
	inBuf.Reset()
	outBuf.Reset()
	inBuf.WriteString("3\n")

	m2p, err := SelectMachineModel(ModelPickerOptions{
		CurrentModel: ModelMSX1,
		In:           &inBuf,
		Out:          &outBuf,
	})
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if m2p != ModelMSX2P {
		t.Fatalf("Expected ModelMSX2P (2), got %d", m2p)
	}

	// Test default on empty enter
	inBuf.Reset()
	outBuf.Reset()
	inBuf.WriteString("\n")

	mDef, err := SelectMachineModel(ModelPickerOptions{
		CurrentModel: ModelMSX2,
		In:           &inBuf,
		Out:          &outBuf,
	})
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if mDef != ModelMSX2 {
		t.Fatalf("Expected default ModelMSX2 (1), got %d", mDef)
	}
}
