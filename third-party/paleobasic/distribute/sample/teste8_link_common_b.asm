	common /shared/
counter2:
	ds 2

	cseg
	public addcommon
addcommon:
	ld hl,(counter2)
	inc hl
	ld (counter2),hl
	ret
	end
