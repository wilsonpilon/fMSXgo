	cseg
	public start, shareddata
	extrn libroutine
start:
	call libroutine
	ret
shareddata:
	db 42
	end
