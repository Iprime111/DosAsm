.model tiny
.286
.code
org 100h
locals @@

Start:
    mov ax, cs
    mov bx, 0020h
    mov cx, 0300h
    mov dx, 4000h

    push 0005h
    pop ds

    push 0060h
    pop es
    
    jmp Start

end Start
