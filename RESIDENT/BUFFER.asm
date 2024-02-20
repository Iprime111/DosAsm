; -----------------------------------------------------------------------------
; | FnDrawBufferContent
; | Args:   No args
; | Assumes: 	Nothing
; | Returns:	Nothing
; | Destroys:	cx, bx, si, di registers
; -----------------------------------------------------------------------------
ret
FnDrawBufferContent proc
    mov cx, FrameHeight
    mov si, offset SavedScreenBuffer
    mov bh, FirstLine                   ; set frame height, source buffer address and first line

    push 0b800h
    pop es                              ; set es to VMem address

    push cs
    pop ds                              ; set ds to cs

@@DrawLoop:
    call FnDrawLineFromBuffer
    inc bh                              ; draw line and increment line No

    loop @@DrawLoop
    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawLineFromBuffer
; | Args:   bh - line number
; |         si - buffer address
; | Assumes: 	0 < line < screen height
; | Returns:	Nothing
; | Destroys:	di register
; -----------------------------------------------------------------------------
ret
FnDrawLineFromBuffer proc
    push cx                             ; save cx

    call FnGetLineAddress
    mov cx, FrameWidth                  ; get address and set symbols count

    rep movsw                           ; draw line

    pop cx                              ; restore cx
    ret
endp

; -----------------------------------------------------------------------------
; | FnSaveScreenToBuffer
; | Args:   No args
; | Assumes: 	Nothing
; | Returns:	Nothing
; | Destroys:	si, di, es, ds, bx, cx registers
; -----------------------------------------------------------------------------
ret
FnSaveScreenToBuffer proc
    push cs
    pop es                              ; mov es, cs (fuck you, DOS)

    push 0b800h
    pop ds                              ; mov ds, VMem address

    mov cx, FrameHeight
    mov di, offset SavedScreenBuffer
    mov bh, FirstLine                   ; save height, screen buffer address and first line

@@SaveLoop:   
    call FnSaveScreenLineToBuffer
    inc bh                              ; save line and increment its number

    loop @@SaveLoop
    ret
endp

; -----------------------------------------------------------------------------
; | FnSaveScreenLineToBuffer
; | Args:   bh - line number
; |         di - buffer address
; | Assumes: 	0 < line < screen height
; | Returns:	Nothing
; | Destroys:	si registers
; -----------------------------------------------------------------------------
ret
FnSaveScreenLineToBuffer proc
    push ax cx                  ; save ax and cx

    push di
    call FnGetLineAddress
    mov si, di                  ; move line address to si
    pop di

    mov cx, FrameWidth          ; set symbols count
    rep movsw                   ; save line

    pop cx ax                   ; restore registers
    ret
endp

SavedScreenBuffer db FrameWidth * FrameHeight * 2 dup(0)
FrameBuffer       db FrameWidth * FrameHeight * 2 dup(0)
