.model tiny
.286
.code
org 100h
locals @@

Start:

    cld

    call FnDisplayStrings       ; display test strings

    push offset TestString
    call FnStrlenCustom
    add sp, 2                   ; get strlen of first string

    inc ax
    push ax
    push 'c'
    push offset TestString
    call FnMemchrCustom
    add sp, 6                   ; find 'c' symbol in first string
    
    push 2d
    push 'x'
    push offset TestString
    call FnMemsetCustom
    add sp, 6                   ; set first 2 symbols of first string to 'x'

    mov ah, 9h
    mov dx, offset AfterMemset
    int 21h
    call FnDisplayStrings       ; display result

    push offset DestString
    push offset TestString
    push 6d
    call FnMemcpyCustom
    add sp, 6                   ; copy 6 symbols of first string to second

    mov ah, 9h
    mov dx, offset AfterMemcpy
    int 21h
    call FnDisplayStrings       ; display result

    push offset DestString
    push offset TestString
    push 7d
    call FnMemcmpCustom         ; compare 2 strings
    add sp, 6

    push offset TestString + 2
    push offset TestString
    push 3d
    call FnMovmemCustom         ; move first 3 symbols of first string to it's second symbol
    add sp, 6

    mov ah, 9h
    mov dx, offset AfterMovmem
    int 21h
    call FnDisplayStrings       ; display result


ret

; -----------------------------------------------------------------------------
; | FnDisplayStrings
; | Args:   No args
; | Assumes:    Variables are exist
; | Returns:    Nothing
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
FnDisplayStrings proc
    push dx
    push ax

    mov ah, 09h
    mov dx, offset SourceStringMessage
    int 21h

    mov dx, offset TestString
    int 21h

    mov dx, offset NewLine
    int 21h

    mov dx, offset DestStringMessage
    int 21h

    mov dx, offset DestString
    int 21h

    mov dx, offset NewLine
    int 21h

    mov dx, offset NewLine
    int 21h

    pop ax
    pop dx

    ret
endp

; -----------------------------------------------------------------------------
; | FnMemcmpCustom (pascal)
; | Args:   bp + 8 - array 1
; |         bp + 6 - array 2
; |         bp + 4 - compared part size
; | Assumes:    es is set properly
; |             df = 0
; | Returns:    ax = 0 if arrays parts are equal
; |             ax > 0 if there was such an i that arr1[i] > arr2[i]
; |             ax < 0 otherwise
; | Destroys:   cx, si, di registers data
; -----------------------------------------------------------------------------
ret
FnMemcmpCustom proc
    push bp
    mov bp, sp          ; create stack frame

    mov si, [bp+8]
    mov di, [bp+6]
    mov cx, [bp+4]      ; get arguments

@@CompareSymbol:
    
    cmpsb
    jne @@NotEqual

    loop @@CompareSymbol

    mov ax, 0
    jmp @@Return        ; return 0

@@NotEqual:
    mov ax, ds:[si-1]
    sub ax, es:[di-1]   ; return arr1[i] - arr2[i]

@@Return:
    pop bp              ; restore bp and exit
    ret
endp

; -----------------------------------------------------------------------------
; | FnMemcpyCustom (pascal)
; | Args:   bp + 8 - destination
; |         bp + 6 - source
; |         bp + 4 - size
; | Assumes:    es is set properly
; |             df = 0
; | Returns:    ax - destination address
; | Destroys:   cx, si, di registers data
; -----------------------------------------------------------------------------
ret
FnMemcpyCustom proc
    push bp
    mov bp, sp      ; create stack frame

    mov di, [bp+8]
    mov si, [bp+6]
    mov cx, [bp+4]  ; get arguments


    mov ax, cx
    and ax, 1       ; get length oddity bit

    shr cx, 1       ; cx /= 2

    rep movsw       ; copy data by words

    mov cx, ax
    rep movsb       ; write left byte

    mov ax, [bp+8]  ; return destination address

    pop bp          ; restore bp and exit
    ret

endp



; -----------------------------------------------------------------------------
; | FnMovmemCustom (pascal)
; | Args:   bp + 8 - destination
; |         bp + 6 - source
; |         bp + 4 - size
; | Assumes:    es is set properly
; |             df = 0
; | Returns:    ax - destination address
; | Destroys:   cx, si, di registers data
; -----------------------------------------------------------------------------
ret
FnMovmemCustom proc
    push bp
    mov bp, sp      ; create stack frame

    mov di, [bp+8]
    mov si, [bp+6]
    mov cx, [bp+4]  ; get arguments

    cmp di, si
    ja @@DestIsBigger

@@Continue:
    rep movsb       ; write data

    mov ax, [bp+8]  ; return destination address
    cld             ; df = 0

    pop bp          ; restore bp and exit
    ret

@@DestIsBigger:
    mov ax, si
    add ax, cx
        
    cmp ax, di
    jbe @@Continue  ; if source + size > destination

    mov si, ax
    dec si          ; si += cx - 1
    add di, cx
    dec di          ; di += cx - 1
    std             ; df = 1

    jmp @@Continue

endp

; -----------------------------------------------------------------------------
; | FnMemsetCustom (cdecl)
; | Args:   bp + 4 - destination
; |         bp + 6 - symbol
; |         bp + 8 - symbol count
; | Assumes:    es is set properly
; |             df = 0
; | Returns:    ax - array address
; | Destroys:   bx, cx, di registers data
; -----------------------------------------------------------------------------
ret
FnMemsetCustom proc
    push bp
    mov bp, sp          ; create stack frame

    mov di, [bp + 4]
    mov al, [bp + 6]
    mov ah, al
    mov cx, [bp + 8]    ; get arguments

    mov bx, cx
    and bx, 1           ; get cx oddity bit

    shr cx, 1           ; cx /= 2
    
    rep stosw           ; write data to memory (by words)

    mov cx, bx
    rep stosb           ; write one byte (if it left)

    mov ax, [bp + 4]    ; return array address

    pop bp              ; restore bp and exit
    ret
endp


; -----------------------------------------------------------------------------
; | FnMemchrCustom (cdecl)
; | Args:   bp + 4 - memory address
; |         bp + 6 - symbol
; |         bp + 8 - array length
; | Assumes:    es is set properly
; |             df = 0
; | Returns:    ax - symbol address
; | Destroys:   cx, di registers data
; -----------------------------------------------------------------------------
ret
FnMemchrCustom proc
    push bp
    mov bp, sp          ; create stack frame

    mov di, [bp+4]
    mov ax, [bp+6]
    mov cx, [bp+8]      ; get arguments

    repne scasb
    
    cmp cx, 00h
    je @@CounterIsNull  ; if cx == 0

@@SymbolFound:
    mov ax, [bp+4]
    add ax, [bp+8]  
    dec ax              ; compute array end address
    
    sub ax, cx          ; compute found symbol address

@@Return:
    pop bp
    ret                 ; restore bp and return

@@CounterIsNull:
    mov ax, es:[di-1]
    cmp ax, [bp+6]
    je @@SymbolFound    ; if last symbol fits

    mov ax, 00h
    jmp @@Return        ; no symbol has been found
endp

; -----------------------------------------------------------------------------
; | FnStrlenCustom (cdecl)
; | Args:   bp + 4 - address
; | Assumes:    df = 0
; | Returns:    ax - string length
; | Destroys:   cx, di registers data
; -----------------------------------------------------------------------------
ret
FnStrlenCustom proc
    push bp
    mov bp, sp      ; create stack frame

    mov al, 00h
    mov di, [bp+4]
    mov cx, 0ffffh  ; set registers

    repne scasb
    neg cx
    mov ax, cx
    sub ax, 2       ; get length

    pop bp
    ret             ; restore bp and exit
endp

SourceStringMessage db "Source string: $"
DestStringMessage   db "Destination string: $"
NewLine             db 0ah, 0dh, '$'

AfterMemcpy db "After memcpy 6 symbols from source to dest: ", 0ah, 0dh, '$'
AfterMovmem db "After movmem 3 symbols from source to source + 2: ", 0ah, 0dh, '$'
AfterMemset db "After memset 2 symbols of source with x: ", 0ah, 0dh, '$'

TestString db "abcdef3$", 00h
DestString db "11111122$"

end     Start
