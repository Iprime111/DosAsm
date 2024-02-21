; -----------------------------------------------------------------------------
; | FnUpdateScreenBuffer
; | Args:   No args
; | Assumes: 	Nothing
; | Returns:	Nothing
; | Destroys:	cx, bx, si, di, es, ds registers
; -----------------------------------------------------------------------------
ret
FnUpdateScreenBuffer proc
    push cs
    pop  ds                         ; ds = cs

    push 0b800h
    pop  es                         ; es = b800

    mov cx, FrameHeight
    mov si, offset FrameBuffer
    mov bh, FirstLine               ; set registers

@@CheckRow:

    call FnGetLineAddress
    call FnUpdateRow                ; update each row
    
    inc bh
    loop @@CheckRow

    ret
endp

; -----------------------------------------------------------------------------
; | FnUpdateRow
; | Args:   si - buffer address
; | Assumes: 	Nothing
; | Returns:	si - next buffer symbol
; | Destroys:	di register
; -----------------------------------------------------------------------------
ret
FnUpdateRow proc
    push ax cx                                              ; save ax and cs
    
    mov cx, FrameWidth
@@CheckSymbol:

    cmpsw
    je @@SymbolMatched                                      ; compare symbols in screen buffer and video memory
    
    mov ax, es:[di - 2]
    mov ds:[si - FrameWidth * FrameHeight * 2 - 2], ax      ; if no match then update screen buffer

@@SymbolMatched:
    loop @@CheckSymbol 

    pop cx ax                                               ; restore registers
    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawBufferContent
; | Args:   si - buffer address
; | Assumes: 	Nothing
; | Returns:	Nothing
; | Destroys:	cx, bx, si, di registers
; -----------------------------------------------------------------------------
ret
FnDrawBufferContent proc
    mov cx, FrameHeight
    mov bh, FirstLine                   ; set frame height and first line

    push 0b800h
    pop  es                             ; set es to VMem address

    push cs
    pop  ds                             ; set ds to cs

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
    pop  es                             ; mov es, cs (fuck you, DOS)

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
    push ax cx                          ; save ax and cx
                                        
    push di                             
    call FnGetLineAddress               
    mov si, di                          ; move line address to si
    pop di                              
                                        
    mov cx, FrameWidth                  ; set symbols count
    rep movsw                           ; save line
                                        
    pop cx ax                           ; restore registers
    ret
endp

; -----------------------------------------------------------------------------
; | FnGetLineAddress
; | Args:   bh - line number
; | Assumes: 	0 < line number <= screen height
; | Returns:	di - line address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnGetLineAddress proc
    push ax                             ; save registers
                                        
    mov ah, 0                           
    mov al, 80 * 2                      
    mul bh                              ; line address
                                        
    mov di, ax                          ; full address (may be odd)
                                        
    and ax, 1                           
    add di, ax                          ; move value to match alignment
                                        
    pop ax                              ; restore registers

	ret
endp

SavedScreenBuffer db FrameWidth * FrameHeight * 2 dup(0)
FrameBuffer       db FrameWidth * FrameHeight * 2 dup(0)    ; these 2 arrays must be stored sequentially for code to work (tasm, fuck you)
