; -----------------------------------------------------------------------------
; | FnDrawRegisterFrame
; | Args: No args
; | Assumes:    Top <RegistersCount> register values in stack are needed values
; | Destroys:   es, ds, ax, bx, cx registers
; | Returns:    Nothing
; -----------------------------------------------------------------------------
ret
FnDrawRegisterFrame proc
    push bp
    mov bp, sp                          ; set up stack frame

    push cs
    pop es                              ; set es to VMem begin

    push cs
    pop ds                              ; set ds = cs

    call FnDrawFrameWithTitle           ; redraw frame

    mov bh, 1
    mov cx, RegistersCount
    add bp, 4                           ; set first line, lines count and increment bp

@@RegisterDrawingLoop:
    call FnGetFrameLineAddress
    add di, RegisterValueOffset * 2     ; calculate value address

    mov ax, [bp]                        ; mov next register value to ax
    call FnPrintHexWord                 ; print ax value

    inc bh
    add bp, 2                           ; increment bp ('cause GOD DAMN FUCKING SHITTY DOS don't allows me to fucking address to [bp+bx])
    loop @@RegisterDrawingLoop
    
    pop bp                              ; restore bp
    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawFrameWithTitle
; | Args:   No args
; | Assumes:    Nothing
; | Returns:    Nothing
; | Destroys:   cx, ax registers data
; -----------------------------------------------------------------------------
ret
FnDrawFrameWithTitle proc
    push si

    mov si, offset FrameStyle
    mov ah, StyleAttribytes
    call FnDrawBlankFrame               ; draw frame

    call FnDrawTitleText                ; draw title
    call FnPrintRegisterNames

    pop si
    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawTitleText
; | Args:   No args
; | Assumes:    si register contains data address
; |		        es, ds = cs
; |             df is set to 0
; | Returns: 	Nothing
; | Destroys:	Data in text cells
; |		        ax, cx registers data
; -----------------------------------------------------------------------------
ret
FnDrawTitleText	proc
    push si
	
    mov si, offset FrameTitle
    mov ch, 0
    mov cl, TitleLength
    call FnGetTitleLineAddress          ; get title line address

@@Next:	
    lodsb            
	stosw
    loop @@Next                         ; draw title

    pop si                              ; restore si
	ret
endp

; -----------------------------------------------------------------------------
; | FnPrintRegisterNames
; | Args:   Nothing
; | Assumes:    df=0
; |             ds, es = cs
; | Returns:    Nothing
; | Destroys:   ax, bx, cx, dx, si registers data
; -----------------------------------------------------------------------------
ret
FnPrintRegisterNames proc
    mov bh, 1
    mov cx, RegistersCount
    mov ax, 0

@@PrintRegisterLoop:
    push cx
    push ax

    call FnGetFrameLineAddress
    add di, 4

    mov cx, RegisterNameLength
    mul cx
    mov si, offset RegisterNames
    add si, ax

    mov ah, StyleAttribytes

@@PrintSymbolLoop:

    lodsb
    stosw

    loop @@PrintSymbolLoop
    
    inc bh

    pop ax
    inc ax

    pop cx
    loop @@PrintRegisterLoop

    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawBlankFrame
; | Args:	    ah - color attributes
; |             si - frame prototype array
; | Assumes:    df is set to 0
; | Returns: 	si - next symbol
; | Destroys: 	cx, di register data
; |		        Data in cells corresponding to frame
; -----------------------------------------------------------------------------
ret
FnDrawBlankFrame proc
    push dx

    mov dh, FrameHeight                 ; set text field height
    sub dh, 2

    mov di, offset FrameBuffer
    
    mov cx, FrameHeight - 2
    call FnDrawLine                     ; draw first line

@@Next:
   FnPrintHexByte proc
    push bx dx

    mov bh, 0

    mov bl, al
    and bl, 0f0h
    shr bl, 4
    mov dl, ds:[offset HexNumbers + bx] 
    mov es:[di], dl                         ; draw first digit
    add di, 2

    mov bl, al
    and bl, 0fh
    mov dl, ds:[offset HexNumbers + bx]
    mov es:[di], dl                         ; draw second digit
    add di, 2

    pop dx bx
    ret
endp call FnDrawLine
    sub si, 3d                          ; draw inner line and do si -= 3

    loop @@Next

    add si, 3d                          ; get last line symbols address

    call FnDrawLine                     ; draw last line

    pop dx
	ret
endp

; -----------------------------------------------------------------------------
; | FnDrawLine
; | Args: 	ah - color attributes
; |         di - line begin address
; |         si - frame prototype array address
; | Assumes:	df is set to 0
; | Returns:	si - next symbol
; |             di - next buffer cell
; | Destroys:	Data in cells corresponding to line 
; -----------------------------------------------------------------------------
ret
FnDrawLine	proc
    push ax cx                          ; save registers

    mov cx, FrameWidth - 2

	lodsb
    stosw                               ; draw left symbol

	lodsb
    rep stosw                           ; draw middle symbols

	lodsb
    stosw                               ; draw right symbol

    pop cx ax                           ; restore registers

	ret
endp

; -----------------------------------------------------------------------------
; | FnGetFrameLineAddress
; | Args:   bh - line number
; | Assumes: 	0 < length < screen width
; |		        0 < line number <= screen height
; | Returns:	di - line address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnGetFrameLineAddress proc
    push dx ax      ; save registers

    mov di, offset FrameBuffer

    mov ah, 0
    mov al, FrameWidth * 2
    mul bh                              ; line address

    add di, ax                          ; full address (may be odd)

    and ax, 1
    add di, ax                          ; move value to match alignment

    pop ax dx                           ; restore registers

	ret
endp

; -----------------------------------------------------------------------------
; | FnGetTitleLineAddress
; | Args: 	Nothing
; | Assumes:    title length < line length
; | Returns:	di - line address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnGetTitleLineAddress proc
    push ax bx                          ; save register

    mov di, offset FrameBuffer

    mov bl, FrameWidth - TitleLength
    mov bh, 0

    add di, bx                          ; full address (may be odd)

    and bx, 1
    add di, bx                          ; move value to match alignment

    pop bx ax                           ; restore register

	ret
endp

; -----------------------------------------------------------------------------
; | FnPrintHexWord
; | Args:   ax - hex value (word)
; |         di - destination
; | Assumes:    Nothing
; | Returns:    Nothing
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
FnPrintHexWord proc
    xchg al, ah
    call FnPrintHexByte                 ; print higher byte
    xchg al, ah

    call FnPrintHexByte                 ; print lower byte

    ret
endp

; -----------------------------------------------------------------------------
; | FnPrintHexWord
; | Args:   al - hex value (byte)
; |         di - destination
; | Assumes:    Nothing
; | Returns:    di - next number destination
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
FnPrintHexByte proc
    push bx dx

    mov bh, 0

    mov bl, al
    and bl, 0f0h
    shr bl, 4
    mov dl, ds:[offset HexNumbers + bx] 
    mov es:[di], dl                         ; draw first digit
    add di, 2

    mov bl, al
    and bl, 0fh
    mov dl, ds:[offset HexNumbers + bx]
    mov es:[di], dl                         ; draw second digit
    add di, 2

    pop dx bx
    ret
endp

HexNumbers db "0123456789ABCDEF"
