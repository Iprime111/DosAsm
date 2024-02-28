.model tiny
.286
.code
org 100h
locals @@

Start:
    mov ax, 1111h
    mov bx, 2222h
    mov cx, 3333h
    mov dx, 4444h
    mov si, 5555h
    mov di, 6666h


    push 7777h
    pop ds

    push 8888h
    pop es
    
    in al, 60h
    cmp al, 1
    jne Start

    ret

end Start
