; sample/teste2_macros.asm - suite de regressao de condicionais (IF/IFT/IFE/
; IFF/IFDEF/IFNDEF/IF1/IF2/ELSE/ENDIF) e macros basicas (MACRO/ENDM/LOCAL) do
; assembler Z80 nativo (modulo 2, ver docs/resumo-asm.md) - complementa
; sample/teste.asm (que so cobre instrucoes de CPU + diretivas de dados).
; Mesmo fluxo de validacao (comparar contra N80.exe):
;   editor\tools\Z80AsmTestCli.exe --assemble sample\teste2_macros.asm saida_minha.bin
;   nestor80\N80\bin\Release\net6.0\N80.exe sample\teste2_macros.asm saida_oracle.bin
;   fc /b saida_minha.bin saida_oracle.bin
; Cobre em particular o caso mais delicado de LOCAL: a mesma macro (DELAY)
; invocada duas vezes precisa gerar rotulos internos distintos em cada
; expansao, senao o segundo "loop:" sobrescreve o primeiro na tabela de
; simbolos e o JR da primeira expansao salta pro lugar errado. Ultima
; validacao: identico byte a byte (21 bytes) em 2026-07-24.
	org 100h

DEBUG	equ 0

	if DEBUG
	ld a,1
	else
	ld a,2
	endif

	ifdef DEBUG
	ld b,1
	endif

	ifndef DEBUG
	ld b,2
	endif

	if1
	nop
	endif

	if2
	nop
	endif

PUSHBOTH macro reg1,reg2
	push reg1
	push reg2
	endm

	pushboth bc,de
	pushboth hl,af

DELAY	macro count
	local loop
	ld b,count
loop:	dec b
	jr nz,loop
	nop
	endm

	delay 5
	delay 10

	end
