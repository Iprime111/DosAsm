; -----------------------------------------------------------------------------
; | FnDrawFrameWithTitle
; | Args:   No args
; | Assumes:    All args (except si) are set for FnDrawFrame call
; | Returns:    Nothing
; | Destroys:   cx, ax registers data
; -----------------------------------------------------------------------------
ret
FnDrawFrameWithTitle proc
    push si

    mov si, offset FrameStyle
    mov ah, StyleAttribytes
    call FnDrawFrame                ; draw frame

    call FnDrawTitleText            ; draw title

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
    mov bl, FrameWidth
    mov bh, cl
    call FnGetTitleLineAddress      ; get title line address

@@Next:	
    lodsb            
	stosw
    loop @@Next                     ; draw title

    pop si                          ; restore si
	ret
endp

; -----------------------------------------------------------------------------
; | FnDrawFrame
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
FnDrawFrame	proc
    push bx dx

    mov dh, FrameHeight     ; set text field height
    sub dh, 2

    mov bh, 0               ; set first line

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
; -----------------------------------------------------------------------------
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
; | Args: 	bl - line length
; | 	  	bh - line number
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
; | Args: 	bl - line length
; | 	  	bh - title length
; | Assumes:    title length < line length
; | Returns:	di - line address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnGetTitleLineAddress proc
    
    push bx         ; save register

    sub bl, bh
    mov bh, 0

    mov di, bx      ; full address (may be odd)

    and bx, 1
    add di, bx      ; move value to match alignment

    pop bx          ; restore register

	ret
endp

FrameStyle      db 00c9h, 00cdh, 00bbh, 00bah, ' ', 00bah, 00c8h, 00cdh, 00bch  ; symbols hex codes for frame style 2 (double lines)
TitleLength     db 3d
FrameTitle      db "HUI"
StyleAttribytes db 70h
FrameWidth      db 15d
FrameHeight     db 15d
