; sample/teste_opcodes.asm - suite de regressao do assembler Z80 nativo (modulo 2,
; ver docs/resumo-asm.md), papel equivalente ao sample/teste.dmx do
; pre-processador Dignified: rodar apos qualquer mudanca em Z80Asm.pbi e
; comparar byte a byte contra o oraculo N80.exe (ver docs/resumo-asm.md,
; "Material de referencia"):
;   editor\tools\Z80AsmTestCli.exe --assemble sample\teste_opcodes.asm saida_minha.bin
;   nestor80\N80\bin\Release\net6.0\N80.exe sample\teste_opcodes.asm saida_oracle.bin
;   fc /b saida_minha.bin saida_oracle.bin   (ou cmp no Git Bash)
; Cobre so o que a Fase A ja suporta: ORG/EQU/rotulos + instrucoes de CPU
; (sem DB/DW/DS/macros/condicionais ainda - isso fica em sample/teste2_macros.asm).
; Renomeado de teste.asm pra teste_opcodes.asm em 2026-07-24 porque o usuario
; usa sample/teste.asm pro proprio programa real (SCREEN2 demo) que esta
; testando/depurando - nao sobrescrever esse arquivo.
	org 100h
CONST	equ 42

start:
	nop
	ld a,b
	ld a,c
	ld a,(hl)
	ld (hl),a
	ld b,c
	ld a,CONST
	ld b,10
	ld (hl),20
	ld a,(bc)
	ld a,(de)
	ld (bc),a
	ld (de),a
	ld a,(1234h)
	ld (1234h),a
	ld hl,(1234h)
	ld (1234h),hl
	ld bc,(1234h)
	ld (1234h),bc
	ld de,(1234h)
	ld sp,(1234h)
	ld bc,4660
	ld de,5000
	ld hl,6000
	ld sp,7000
	ld sp,hl
	ex de,hl
	ex af,af'
	exx
	ex (sp),hl
	push bc
	push de
	push hl
	push af
	pop bc
	pop de
	pop hl
	pop af
	inc a
	inc b
	inc (hl)
	inc bc
	inc de
	inc hl
	inc sp
	dec a
	dec (hl)
	dec bc
	add hl,bc
	add hl,de
	add hl,hl
	add hl,sp
	add a,b
	add a,(hl)
	add a,5
	adc a,c
	adc a,7
	sub b
	sub 3
	sbc a,d
	sbc a,9
	and c
	and 15
	xor d
	xor 1
	or e
	or 2
	cp h
	cp 100
	daa
	cpl
	neg
	ccf
	scf
	halt
	di
	ei
	rlca
	rla
	rrca
	rra
	rlc b
	rrc c
	rl d
	rr e
	sla h
	sra l
	srl (hl)
	bit 0,a
	bit 7,(hl)
	set 3,b
	res 5,c
	jp start
	jp nz,start
	jp z,start
	jp nc,start
	jp c,start
	jp po,start
	jp pe,start
	jp p,start
	jp m,start
	jp (hl)
near:
	jr near
	jr nz,near
	jr z,near
	jr nc,near
	jr c,near
	djnz near
	call start
	call nz,start
	call z,start
	ret
	ret nz
	ret z
	reti
	retn
	rst 0
	rst 8h
	rst 38h
	in a,(10h)
	out (20h),a
	im 0
	im 1
	im 2
	ld i,a
	ld r,a
	ld a,i
	ld a,r
	ldi
	ldir
	ldd
	lddr
	cpi
	cpir
	cpd
	cpdr
	ini
	inir
	ind
	indr
	outi
	otir
	outd
	otdr
	rld
	rrd
	ld ix,8000h
	ld iy,9000h
	ld sp,ix
	ld sp,iy
	push ix
	push iy
	pop ix
	pop iy
	inc ix
	inc iy
	dec ix
	dec iy
	add ix,bc
	add ix,de
	add ix,ix
	add ix,sp
	add iy,bc
	add iy,sp
	ex (sp),ix
	ex (sp),iy
	jp (ix)
	jp (iy)
	ld a,(ix+5)
	ld (ix+5),a
	ld b,(ix-3)
	ld (ix-3),c
	ld (ix+2),42
	add a,(ix+1)
	sub (ix+1)
	and (ix+1)
	cp (ix+1)
	inc (ix+4)
	dec (ix+4)
	rlc (ix+1)
	bit 2,(ix+1)
	set 4,(ix+1)
	res 6,(ix+1)
	ld a,(iy+5)
	ld (iy+5),a
	add iy,iy
	ld ixh,10
	ld ixl,20
	ld a,ixh
	ld a,ixl
	ld ixh,b
	ld ixl,c
	inc ixh
	dec ixl
	add a,ixh
	sub ixl
	ld iyh,30
	ld iyl,40
	inc iyh
	dec iyl

; --- diretivas de dados (DB/DEFB/DEFM, DW/DEFW, DS/DEFS, DC, DZ/DEFZ) ---
data1:
	db 1,2,3,255
	db "AB"
	db "A;B",0
	defb CONST,CONST+1
	defm 'texto simples'
	dw 1234h,5678h
	defw "AB"
	dw data1
	ds 5
	ds 4,0AAh
	dc "OK"
	dz "Hi"

; --- operando "(expr) OP expr2" (parenteses de abertura sem fechar o
; operando inteiro) precisa ser tratado como LD A,(nn), nao LD A,n - achado
; real depurando sample/teste.asm do usuario (2026-07-24) ---
	ld a,(CONST SHL 4) OR 5

	end
