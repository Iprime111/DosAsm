.model tiny
.286
.code
org 100h
locals @@

Start:

    cld

    push offset TestString
    call FnStrlenCustom
    add sp, 2

    inc ax
    push ax
    push 'a'
    push offset TestString
    call FnMemchrCustom
    add sp, 6
    
    push 2d
    push 'x'
    push offset TestString
    call FnMemsetCustom
    add sp, 6

    push offset DestString
    push offset TestString
    push 6d
    call FnMemcpyCustom
    add sp, 6

    push offset DestString
    push offset TestString
    push 7d
    call FnMemcmpCustom
    add sp, 6

    push offset TestString + 2
    push offset TestString
    push 3d
    call FnMovmemCustom
    add sp, 6

ret

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

TestString db "abcdef3", 00h
DestString db "11111122"

end     Start
