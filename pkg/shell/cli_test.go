package shell

import (
	"bytes"
	"strings"
	"testing"

	"fmsxgo/pkg/msx"
)

func TestShellCommands(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer

	sh := New(machine, &inBuf, &outBuf)

	// Test single-line assemble
	sh.ExecuteCommand("a C000 LD A, 2Ah")
	sh.ExecuteCommand("a C002 HALT")

	// Set PC to C000h
	sh.ExecuteCommand("r pc C000")
	if machine.CPU.PC != 0xC000 {
		t.Fatalf("Expected PC = 0xC000, got %04X", machine.CPU.PC)
	}

	// Step instruction
	sh.ExecuteCommand("t 1")
	if machine.CPU.A != 0x2A {
		t.Fatalf("Expected A = 0x2A, got %02X", machine.CPU.A)
	}

	// Test slots command
	outBuf.Reset()
	sh.ExecuteCommand("slots")
	slotsOutput := outBuf.String()
	if !strings.Contains(slotsOutput, "Primary Slot Reg") {
		t.Fatalf("Expected slots output to contain 'Primary Slot Reg', got:\n%s", slotsOutput)
	}

	// Test mapper command
	outBuf.Reset()
	sh.ExecuteCommand("mapper")
	mapperOutput := outBuf.String()
	if !strings.Contains(mapperOutput, "RAM Mapper Total Pages") {
		t.Fatalf("Expected mapper output to contain 'RAM Mapper Total Pages', got:\n%s", mapperOutput)
	}

	// Test IO Out and In
	sh.ExecuteCommand("out 90 42")
	outBuf.Reset()
	sh.ExecuteCommand("in 90")
	inOutput := outBuf.String()
	if !strings.Contains(inOutput, "IN(90h)") {
		t.Fatalf("Expected in output, got:\n%s", inOutput)
	}

	// Test Language command
	outBuf.Reset()
	sh.ExecuteCommand("lang")
	if !strings.Contains(outBuf.String(), "Current UI language") {
		t.Fatalf("Expected language info, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("lang pt")
	if !strings.Contains(outBuf.String(), "Português") {
		t.Fatalf("Expected Portuguese language change confirmation, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("help")
	if !strings.Contains(outBuf.String(), "Controles Principais") {
		t.Fatalf("Expected Portuguese help output, got:\n%s", outBuf.String())
	}

	// Switch back to English
	sh.ExecuteCommand("lang en")

	// Test Theme command
	outBuf.Reset()
	sh.ExecuteCommand("theme")
	if !strings.Contains(outBuf.String(), "Available themes") {
		t.Fatalf("Expected available themes, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("theme dracula")
	if !strings.Contains(outBuf.String(), "dracula") {
		t.Fatalf("Expected dracula theme change, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("theme github-dark")
	if !strings.Contains(outBuf.String(), "github-dark") {
		t.Fatalf("Expected github-dark theme change, got:\n%s", outBuf.String())
	}

	// Reset theme to system
	sh.ExecuteCommand("theme system")
}
