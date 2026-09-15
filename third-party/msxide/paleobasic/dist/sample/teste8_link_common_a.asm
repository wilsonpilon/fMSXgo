	common /shared/
counter:
	ds 2

	cseg
	public starta
	extrn addcommon
starta:
	call addcommon
	ret
	end
