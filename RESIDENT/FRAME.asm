; TODO: better comments

; -----------------------------------------------------------------------------
; | FnDrawFrameWithTitle
; | Args:   No args
; | Assumes:    Nothing
; | Returns:    Nothing
; | Destroys:   cx, bx, ax registers data
; -----------------------------------------------------------------------------
ret
FnDrawFrameWithTitle proc
    push si

    mov si, offset FrameStyle
    mov ah, StyleAttribytes
    call FnDrawBlankFrame           ; draw frame

    call FnDrawTitleText            ; draw title
    call FnPrintRegisterNames

    pop si
    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawTitleText
; | Args:   No args
; | Assumes:	text length < table line length
; |		        line No < screen height
; |             si register contains data address
; |		        es register contains VMem address
; |             df is set to 0
; | Returns: 	Nothing
; | Destroys:	Data in text cells
; |		        ax, cx, bx registers data
; -----------------------------------------------------------------------------
ret
FnDrawTitleText	proc
    push si
	
    mov si, offset FrameTitle
    mov ch, 0
    mov cl, TitleLength
    call FnGetTitleLineAddress      ; get title line address

@@Next:	
    lodsb            
	stosw
    loop @@Next                     ; draw title

    pop si                          ; restore si
	ret
endp

; -----------------------------------------------------------------------------
; | FnPrintRegisterNames
; | Args:   Nothing
; | Assumes:    df=0
; |             es set to VMem address
; |             ds set to code address
; | Returns:    Nothing
; | Destroys:   ax, bx, cx, dx, si registers data
; -----------------------------------------------------------------------------
ret
FnPrintRegisterNames proc
    mov bh, FirstLine + 1
    mov cx, RegistersCount
    mov ax, 0

@@PrintRegisterLoop:
    push cx
    push ax

    call FnGetLineAddress
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
; |             bl - frame width
; |             bh - frame height
; |             si - frame prototype array
; | Assumes:    es contains VMem address
; |             0 < width  <= screen width  - 2
; | 		    0 < height <= screen height - 2
; |             df is set to 0
; | Returns: 	Nothing
; | Destroys: 	cx register data
; |		        Data in cells corresponding to frame
; -----------------------------------------------------------------------------
ret
FnDrawBlankFrame proc
    push bx dx

    mov dh, FrameHeight     ; set text field height
    sub dh, 2

    mov bh, FirstLine       ; set first line
    call FnGetLineAddress   ; get first line address
    
    mov ch, 0
    mov cl, FrameWidth
    call FnDrawLine         ; draw first line

    add dh, bh

@@Next:
    inc bh
    call FnGetLineAddress   ; get line address

    call FnDrawLine
    sub si, 3d              ; draw inner line and do si -= 3

    cmp bh, dh
    jb @@Next

    add si, 3d              ; get last line symbols address

    inc bh
    call FnGetLineAddress   ; get last line address

    call FnDrawLine         ; draw last line

    pop dx bx
	ret
endp

; -----------------------------------------------------------------------------
; | FnDrawLine
; | Args: 	ah - color attributes
; |         di - line begin address
; |		    cx - line length
; |         si - frame prototype array address
; | Assumes:	es contains VMem address
; |		        length is in suitable range (2 < length < screen size)
; |             df is set to 0
; | Returns:	Nothing
; | Destroys:	Data in cells corresponding to line 
; ---------------------------------------------------------------6--------------
ret
FnDrawLine	proc
    push ax cx ; save registers

    sub cx, 2

	lodsb
    stosw       ; draw left symbol

	lodsb
    rep stosw   ; draw middle symbols

	lodsb
    stosw       ; draw right symbol

    pop cx ax   ; restore registers

	ret
endp

; -----------------------------------------------------------------------------
; | FnGetLineAddress
; | Args:   bh - line number
; | Assumes: 	0 < length < screen width
; |		        0 < line number <= screen height
; | Returns:	di - line address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnGetLineAddress proc
    push dx ax      ; save registers

    mov dx, 0       ; first symbol on line (this can be changed for horizontal positioning)

    mov ah, 0
    mov al, 80*2
    mul bh          ; line address

    add ax, dx
    mov di, ax      ; full address (may be odd)

    and ax, 1
    add di, ax      ; move value to match alignment

    pop ax dx       ; restore registers

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
    push ax bx          ; save register

    mov ax, 80*2
    mov di, FirstLine
    mul di
    mov di, ax          ; line offset

    mov bl, FrameWidth
    mov bh, TitleLength

    sub bl, bh
    mov bh, 0

    add di, bx          ; full address (may be odd)

    and bx, 1
    add di, bx          ; move value to match alignment

    pop bx ax           ; restore register

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
    call FnPrintHexByte     ; print higher byte
    xchg al, ah

    call FnPrintHexByte     ; print lower byte

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

HexNumbers      db "0123456789ABCDEF"
