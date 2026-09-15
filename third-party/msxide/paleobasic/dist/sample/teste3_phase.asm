; sample/teste3_phase.asm - suite de regressao de .PHASE/.DEPHASE do
; assembler Z80 nativo (modulo 2, ver docs/resumo-asm.md). Exemplo tirado
; direto de nestor80/docs/LanguageReference.md (secao ".PHASE") - codigo de
; checksum de banco de ROM copiado por LDIR pra RAM e executado la, mesmo
; padrao usado pra gerar o cabecalho MSX BLOAD (ver docs/MANUAL.md,
; "Assembler Z80" e docs/resumo-asm.md pra detalhe tecnico). Validar com:
;   editor\tools\Z80AsmTestCli.exe --assemble sample\teste3_phase.asm saida_minha.bin
;   nestor80\N80\bin\Release\net6.0\N80.exe sample\teste3_phase.asm saida_oracle.bin
;   fc /b saida_minha.bin saida_oracle.bin
; Ultima validacao: identico byte a byte (47 bytes) em 2026-07-24.
RAM_BUFFER equ 8000h

	org 4000h

	ld hl,CALCULATE_CHECKSUM
	ld de,8000h
	ld bc,CALCULATE_CHECKSUM_END - CALCULATE_CHECKSUM
	ldir

	ld a,1
	call RAM_BUFFER
	jp MORE_CODE

CALCULATE_CHECKSUM:
	.phase RAM_BUFFER

	out (10h),a
	ld d,0
	ld hl,4000h
	ld bc,4000h

LOOP:
	ld a,(hl)
	add a,d
	ld d,a
	inc hl
	dec bc
	ld a,b
	or c
	jp nz,LOOP

	ld a,0
	out (10h),a

	ld a,d
	ret

	.dephase
CALCULATE_CHECKSUM_END:

MORE_CODE:
	ld a,34
	end
