	cseg
	public libroutine
	extrn shareddata
libroutine:
	ld a,(shareddata)
	ret
	end
