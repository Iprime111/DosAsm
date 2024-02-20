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

include VARIABLE.asm
include FRAME.asm
include BUFFER.asm

; -----------------------------------------------------------------------------
; | FnShowFrame
; | Args: No args
; | Assumes:    Top <RegistersCount> register values in stack are needed values
; | Destroys:   es, ds, ax, bx, cx registers
; | Returns:    Nothing
; -----------------------------------------------------------------------------
ret
FnShowFrame proc
    push bp
    mov bp, sp                          ; set up stack frame

    push 0b800h
    pop es                              ; set es to VMem begin

    push cs
    pop ds                              ; set needed ds

    call FnDrawFrameWithTitle           ; redraw frame

    mov bh, FirstLine + 1
    mov cx, RegistersCount
    add bp, 4                           ; set first line, lines count and increment bp

@@RegisterDrawingLoop:
    call FnGetLineAddress
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
; | FnSwitchFrameState
; | Args: No args
; | Assumes:    FrameState variable contains 0 or f
; | Destroys:   Nothing
; | Returns:    al - current frame state
; -----------------------------------------------------------------------------
ret
FnSwitchFrameState proc
    mov al, FrameState          ; get state from RAM
    xor al, 0ffh                ; invert state
    mov FrameState, al          ; save state
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
    push sp bp ss es ds di si dx cx bx ax           ; save registers

    push cs
    pop ds                                          ; mov cs, ds (shiTASM notation)
    
    ; SoMe GiPsY mAgIc HeRe (DO NOT TOUCH OR IT WILL BE PIZDEZ)
    ; Just getting cs and ip values from interrupt call
    mov bp, sp                                      ; create pseudo stack frame to save info 'bout adresses
    mov ax, [bp + (RegistersCount - 2) * 2 + 0]     ; get ip
    push ax                                         ; push ip
    mov ax, [bp + (RegistersCount - 2) * 2 + 2]     ; get code segment
    push ax                                         ; push code segment

    in al, 60h                                      ; read scan code

    cmp al, 36h                                     ; cmp with rshift press scan code
    jne @@NotHotkeyPress

    call FnSwitchFrameState                         ; if hotkey is pressed - switch frame state
    cmp al, 0h
    je @@RestoreScreen                              ; if frame is being turned off - restore screen content


    call FnSaveScreenToBuffer                       
    call FnShowFrame                                ; if frame is being turned on - save screen and draw

    jmp @@ResetPPI

@@RestoreScreen:
    push 0b800h
    pop es                                          ; set es to VMem address

    call FnDrawBufferContent                        ; move buffer content to VMem
    jmp @@ResetPPI

@@NotHotkeyPress:
    cmp al, 0b6h                                    ; cmp with rshift release scan code
    jne @@DefaultInterrupt

@@ResetPPI:
    in al,  61h
    or al,  80h
    out 61h, al                                     ; set 61 port's higher bit to 1

    and al,  not 80h            
    out 61h, al                                     ; set 61 port's higher bit to 0

    mov al, 20h
    out 20h, al                                     ; reset interrupt controller

    pop ax ax ax bx cx dx si di ds es ss bp sp      ; ax is being popped 3 times to balance stack that contains info 'bout cs and ip
    iret

@@DefaultInterrupt:
    pop ax ax ax bx cx dx si di ds es ss bp sp      ; ax is being popped 3 times to balance stack that contains info 'bout cs and ip
endp

db 0eah                                             ; jmp instruction
OldKeyboardIntOffset  dw 0
OldKeyboardIntSegment dw 0                          ; some self-modifying code for chain interrupts

FrameState db 0

ProgramEnd:
end Start

