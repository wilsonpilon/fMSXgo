	cseg
	public start
	extrn printmsg, tableext
start:
	call printmsg
	ld hl,tableext
	call printmsg
	ret
	end
