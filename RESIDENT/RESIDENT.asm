.model tiny
.286
.code
org 100h
locals @@

Start:
    mov ax, 3509h
    int 21h
    mov OldKeyboardIntOffset,  bx
    mov OldKeyboardIntSegment, es               ; get old keyboard interrupt address

    mov ax, 2509h
    push cs
    pop ds
    mov dx, offset KeyboardInt
    int 21h                                     ; set new interrupt vector

    mov ax, 3100h
    mov dx, offset ProgramEnd
    shr dx, 4
    inc dx
    int 21h                                     ; terminate program and stay resident

include FRAME.asm


; -----------------------------------------------------------------------------
; | FnShowFrame
; | Args: No args
; | Assumes:    Nothing
; | Destroys:   es register
; | Returns:    Nothing
; -----------------------------------------------------------------------------
ret
FnShowFrame proc
    push 0b800h
    pop es
    call FnDrawFrameWithTitle
endp

; -----------------------------------------------------------------------------
; | FnSwitchFrameState
; | Args: No args
; | Assumes:    FrameState variable contains 0 or f
; | Destroys:   Nothing
; | Returns:    al - current frame state
; -----------------------------------------------------------------------------
ret
FnSwitchFrameState proc
    mov al, FrameState
    xor al, 0ffh                ; invert state
    mov FrameState, al
    ret
endp

; -----------------------------------------------------------------------------
; | KeyboardInt
; | Args: No args
; | Assumes:    Nothing
; | Returns:    Nothing
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
KeyboardInt proc
    push ax bx es ds            ; save registers

    push cs
    pop ds

    in al, 60h                  ; read scan code

    cmp al, 36h                 ; cmp with rshift press scan code
    jne @@NotHotkeyPress

    call FnSwitchFrameState
    cmp al, 0h
    je @@ResetPPI               ; if frame is turned off - do nothing
    
    call FnShowFrame

    jmp @@ResetPPI

@@NotHotkeyPress:
    cmp al, 0b6h                ; cmp with rshift release scan code
    jne @@DefaultInterrupt

@@ResetPPI:
    in al,  61h
    or al,  80h
    out 61h, al                 ; set 61 port's higher bit to 1

    and al,  not 80h            
    out 61h, al                 ; set 61 port's higher bit to 0

    mov al, 20h
    out 20h, al                 ; reset interrupt controller

    pop ds es bx ax
    iret

@@DefaultInterrupt:
    pop ds es bx ax
endp

db 0eah
OldKeyboardIntOffset  dw 0
OldKeyboardIntSegment dw 0

FrameState db 0

ProgramEnd:
end Start

