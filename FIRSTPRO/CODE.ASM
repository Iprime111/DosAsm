.model tiny
.code
.286
org 100h

Start:
	mov ah, 09h
	mov dx, offset Message
	int 21h

	mov ax, 4c00h
	int 21h

Message db 'Test message$'

end Start