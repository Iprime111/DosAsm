.model tiny
.286
.code
org 100h
locals @@

Start:
	mov bx, 0b800h
	mov es, bx

    mov ax, 0h

    mov si, 82h
    call FnStrToUnsigned            ; get frame width

    call FnSkipSpaces
    
    mov ax, bx
    call FnStrToUnsigned            ; get frame height

    mov bh, bl
    mov bl, al                      ; move width to bl and height to bh

    call FnSetFirstLine             ; set FirstLine variable

    call FnSkipSpaces
    xchg ax, bx
    call FnStrToHex                 ; get frame color
    xchg ax, bx
    xchg al, ah

    call FnSkipSpaces

	call FnDrawFrameByPrototype     ; draw frame
    call FnStrlenToColon    

	mov bh, FirstLine               ; get first line
	call FnDrawTitleText            ; draw title

    inc si
    mov cl, ds:[80h]
    mov ch, 0                       ; get args string length

    mov dx, si
    sub dx, 81h                     ; get si offset

    sub cx, dx                      ; get inner string length

    call FnDrawInnerText

ret

include NUMBER_P.asm

; -----------------------------------------------------------------------------
; | FnDrawInnerText
; | Args:   si - text address
; |         cx - text length
; |         ah - text attribytes
; |         bl - frame length
; |         bh - frame first line No
; | Assumes:    es register contains VMem address
; | Returns:    Nothing
; | Destroys:   al, bh, si, dx registers data
; -----------------------------------------------------------------------------
ret
FnDrawInnerText proc
    inc bh
    sub bl, 2

    call FnGetMaximalAddress    ; get first inner symbol address

@@Next:
    lodsb
    
    cmp di, dx
    jb @@LoopAddress            ; check if frame borders are reached
    
    inc bh
    call FnGetMaximalAddress    ; get new line address

@@LoopAddress:
    stosw
    loop @@Next                 ; draw text chunk

    ret
endp

; -----------------------------------------------------------------------------
; | FnGetMaximalAddress
; | Args    cx - text length
; |         bl - text field
; |         bh - line No
; | Assumes:    text length can be stored in the cl register
; | Returns:    di - new line address, dx - maximal address (for current line)
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
FnGetMaximalAddress proc

    cmp cl, bl
    ja @@GetLineEndAddress  ; check if whole text fits on a single line

    push bx                 ; save register value

    mov bl, cl
    call FnGetLineAddress   ; get address for text

    mov dh, 0
    mov dl, bl
    shl dl, 1

    add dx, di              ; set max address for text

    pop bx                  ; restore register value
    ret

@@GetLineEndAddress:
    call FnGetLineAddress   ; get address for frame line (without borders)

    mov dh, 0
    mov dl, bl
    shl dl, 1               

    add dx, di              ; set line end address
    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawTitleText
; | Args: 	si - text pointer
; |		    cl - text length
; |	  	    bh - frame first line No
; | Assumes:	text length < table line length
; |		        line No < screen height
; |             si register contains data address
; |		        es register contains VMem address
; |             df is set to 0
; | Returns: 	Nothing
; | Destroys:	Data in text cells
; |		        ax, cx registers data
; -----------------------------------------------------------------------------
ret
FnDrawTitleText	proc
    push bx                 ; save bx
	
    mov bl, cl
    call FnGetLineAddress   ; get title line address
	
@@Next:	
    lodsb            
	stosw
    loop @@Next             ; draw title

    pop bx                  ; restore bx
	ret
endp

; -----------------------------------------------------------------------------
; | FnStrlenToColon
; | Args:   si - text begin
; | Assumes:    gonna write it later
; | Returns:    cx - text length
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
FnStrlenToColon proc
    push di
    push ax
    push es             ; save registers

    mov ax, ds
    mov es, ax
    mov al, ':'
    mov di, si          ; set registers for counting

    mov cx, 0ffffh
    repne scasb
    neg cx
    sub cx, 2           ; count strlen

    pop es
    pop ax
    pop di              ; restore registers

    ret
endp

; -----------------------------------------------------------------------------
; | FnDrawFrameByPrototype
; | Args:   si - arguments line
; | Assumes:    All args (except si) are set for FnDrawFrame call
; | Returns:    Nothing
; | Destroys:   cx, dx, bx registers data
; -----------------------------------------------------------------------------
ret
FnDrawFrameByPrototype proc

    cmp byte ptr ds:[si], '*'
    jne @@NoCustomPrototype         ; check if argument is either a frame style or a preset No
    inc si
    
    call FnDrawFrame                ; draw frame by custom prototype
    inc si

    ret

@@NoCustomPrototype:
    push bx                         ; save register

    call FnStrToUnsigned            ; get preset No
    inc si

    sub bx, 1
    mov cx, bx
    shl bx, 3
    add bx, cx                      ; compute offset = (bx - 1) * 9, where 9 is style string length, bx is style No
    mov dx, bx

    pop bx                          ; restore register

    push si

    mov si, offset FrameStyles
    add si, dx                      ; calculate style string address

    call FnDrawFrame                ; draw frame
    pop si

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
; | Destroys: 	bx, cx registers data
; |		        Data in cells corresponding to frame
; -----------------------------------------------------------------------------
ret
FnDrawFrame	proc
    push dx

    sub bh, 2
    mov dh, bh
    mov bh, FirstLine       ; set first line

    call FnGetLineAddress   ; get first line address
    
    mov cl, bl
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

    pop dx
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
    push ax
    push cx     ; save registers

    sub cx, 2

	lodsb
    stosw       ; draw left symbol

	lodsb
    rep stosw   ; draw middle symbols

	lodsb
    stosw       ; draw right symbol

    pop cx
    pop ax      ; restore registers

	ret
endp


; -----------------------------------------------------------------------------
; | FnDrawSequence
; | Args:	di - sequence begin address
; |		    ax - symbol and attribytes
; |		    cx - sequence length
; | Assume:	    es contains VMem address
; |		        length is in suitable range (0 < len < screen size)
; | Returns:	di - next free memory cell
; | Destroys: 	Data in cells corresponding to sequence
; |		        cx register data
; -----------------------------------------------------------------------------
ret
FnDrawSequence	proc
    rep stosw   ; no comments xD
	ret
endp

; -----------------------------------------------------------------------------
; | FnSetPixel
; | Args:	di - cell address
; | 		ax - symbol and attributes
; | Assumes:	es contains VMem address
; | Returns: 	Nothing
; | Destroys: 	Data in cell corresponding to es:[di] address
; -----------------------------------------------------------------------------
ret
FnSetPixel	proc
	mov es:[di], ax
	ret
endp

; -----------------------------------------------------------------------------
; | FnGetLineAddress
; | Args: 	bl - line length
; | 	  	bh - line number
; | Assumes: 	2 < length < screen width
; |		        0 < line number <= screen height
; | Returns:	di - line address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnGetLineAddress proc
    push dx
    push ax         ; save registers

    mov dx, 80d
    sub dl, bl      ; shift on line

    mov al, 80*2
    mul bh          ; line address

    add ax, dx
    mov di, ax      ; full address (may be odd)

    and ax, 1
    add di, ax      ; move value to match alignment

    pop ax
    pop dx          ; restore registers

	ret
endp

; -----------------------------------------------------------------------------
; | FnSkipSpaces
; | Args: 	    si - input string
; | Assumes: 	current character ds:[si] is a space
; | Returns:	si - next valuable character address
; | Destroys:	Nothing
; -----------------------------------------------------------------------------
ret
FnSkipSpaces proc
    push ax
    push cx         
    push di         
    push es         ; save registers
    
    mov ax, ds
    mov es, ax      ; set es = ds

    mov di, si

    mov al, ' '
    mov cx, 0ffffh  ; max spaces count

    repe scasb      ; skip spaces
    dec di
    mov si, di      ; get new si

    pop es
    pop di
    pop cx
    pop ax          ; restore registers

    ret
endp

; -----------------------------------------------------------------------------
; | FnSetFirstLine
; | Args: 	    bh - table height
; | Assumes: 	screen is 25 rows tall
; | Returns:	Nothing
; | Destroys:	current FirstLine value
; ----------------------------------------------------------------------------
ret
FnSetFirstLine proc
    push ax             ; save register value
    
    mov al, 24d
    sub al, bh          ; free lines count
    
    shr al, 1           ; get first frame line No

    mov FirstLine, al

    pop ax              ; restore register value
    ret
endp

FirstLine   db 0d

FrameStyles db '+-+| |+-+'
            db 00c9h, 00cdh, 00bbh, 00bah, ' ', 00bah, 00c8h, 00cdh, 00bch
            db 03h, 03h, 03h, 03h, ' ', 03h, 03h, 03h, 03h

end	Start
