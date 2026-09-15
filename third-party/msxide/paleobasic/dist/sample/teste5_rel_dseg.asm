	cseg
	public start
start:
	ld hl,buffer
	ld de,msgtable
	call clear
	ret
clear:
	ld (hl),0
	ret
msgtable:
	dw buffer
	dw buffer+1
	dw start

	dseg
buffer:
	ds 16
	end
