; -----------------------------------------------------------------------------
; | FnStrToUnsigned
; | Args:   si - text pointer
; | Assumes:	1 <= number length <= 2
; | Returns: 	bx - number made from string
; |             si - next symbol position
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnStrToUnsigned     proc
    push dx
    push ax
    
    mov ah, 0
    
    lodsb
    sub al, '0'
    mov bx, ax      ; convert first digit to dec
    
    lodsb
    cmp al, '0'
    jb @@NotNumber
    cmp al, '9'
    ja @@NotNumber  ; check if second symbol is digit
    
    sub al, '0'     ; convert second digit to dec
    
    push ax
    
    mov ax, 10d
    mul bx          ; multiply first digit by 10d
    
    pop bx
    add bx, ax      ; add up two digits
    
    pop ax
    pop dx
    
    ret

@@NotNumber:
    dec si
    pop ax
    pop dx
    ret
endp

; -----------------------------------------------------------------------------
; | FnStrToHex
; | Args:   si - text pointer
; | Assumes:	1 <= number length <= 2
; |             df = 0
; | Returns: 	bx - number made from string
; |             si - next symbol position
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnStrToHex  proc
    push ax
    
    mov ah, 0
    
    lodsb
    call FnHexDigitToNumber
    mov bx, ax                  ; convert first digit to number
    
    lodsb
    call FnHexDigitToNumber     ; convert second digit to number
    
    shl bx, 4                   ; multiply first digit by 10d

    add bx, ax                  ; add up two digits
    
    pop ax

    ret
endp

; -----------------------------------------------------------------------------
; | FnHexDigitToNumber
; | Args:   al - hex digit (symbol)
; | Assumes:    Nothing
; | Returns:    al - number made from digit
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
FnHexDigitToNumber  proc
    
    cmp al, '0'
    jb @@NotDecDigit
    cmp al, '9'
    ja @@NotDecDigit

    sub al, '0'
    ret

@@NotDecDigit:
    cmp al, 'A'
    jb @@NotCapitalLetter
    cmp al, 'F'
    ja @@NotCapitalLetter

    sub al, 55d
    ret

@@NotCapitalLetter:
    cmp al, 'a'
    jb @@NotSmallLetter
    cmp al, 'f'
    ja @@NotSmallLetter

    sub al, 87d
    ret

@@NotSmallLetter:
    dec si
    mov al, 0
    ret
endp


