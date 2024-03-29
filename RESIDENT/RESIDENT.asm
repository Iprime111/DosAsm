.model tiny
.286
.code
org 100h
locals @@

Start:
    mov ax, 3509h
    int 21h
    mov OldKeyboardIntOffset,  bx
    mov OldKeyboardIntSegment, es               ; get old keyboard interrupt vector

    mov ax, 3508h
    int 21h
    mov OldTimerIntOffset,  bx
    mov OldTimerIntSegment, es                  ; get old timer interrupt vector

    mov ax, 2509h
    push cs
    pop ds
    mov dx, offset KeyboardInt
    int 21h                                     ; set new keyboard interrupt vector

    mov ax, 2508h
    push cs
    pop ds
    mov dx, offset TimerInt
    int 21h                                     ; set new timer interrupt vector

    mov ax, 3100h
    mov dx, offset ProgramEnd
    shr dx, 4
    inc dx
    int 21h                                     ; terminate program and stay resident

include VARIABLE.asm
include MACRO.asm
include FRAME.asm
include BUFFER.asm

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
; | TimerInt
; | Args: No args
; | Assumes:    Nothing
; | Returns:    Nothing
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
TimerInt proc
    .PushAllRegisters

    cld                                             ; clear direction flag

    push cs
    pop  ds                                         ; change ds

    cmp FrameState, 0h
    je @@DefaultInterrupt                           ; check if frame is on

    call FnUpdateScreenBuffer
    call FnDrawRegisterFrame                        ; if frame is turned on - update screen buffer, draw frame in frame buffer...

    mov si, offset FrameBuffer
    call FnDrawBufferContent                        ; ... and show frame

@@DefaultInterrupt:
    .PopAllRegisters
endp

db 0eah                                             ; jmp instruction
OldTimerIntOffset  dw 0
OldTimerIntSegment dw 0                             ; some self-modifying code for chain interrupts

; -----------------------------------------------------------------------------
; | KeyboardInt
; | Args: No args
; | Assumes:    Nothing
; | Returns:    Nothing
; | Destroys:   Nothing
; -----------------------------------------------------------------------------
ret
KeyboardInt proc
    .PushAllRegisters

    cld                                             ; clear direction flag

    in al, 60h                                      ; read scan code

    cmp al, 36h                                     ; cmp with rshift press scan code
    jne @@NotHotkeyPress

    call FnSwitchFrameState                         ; if hotkey is pressed - switch frame state
    cmp al, 0h
    je @@RestoreScreen                              ; if frame is being turned off - restore screen content

    call FnSaveScreenToBuffer                       
    call FnDrawRegisterFrame                        ; if frame is being turned on - save screen, draw frame in buffer...

    mov si, offset FrameBuffer
    call FnDrawBufferContent                        ; ... and show frame

    jmp @@ResetPPI

@@RestoreScreen:
    push 0b800h
    pop  es                                         ; set es to VMem address

    mov si, offset SavedScreenBuffer
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
    out 20h, al                                     ; send EOI signal

    .PopAllRegisters
    iret

@@DefaultInterrupt:
    .PopAllRegisters
endp

db 0eah                                             ; jmp instruction
OldKeyboardIntOffset  dw 0
OldKeyboardIntSegment dw 0                          ; some self-modifying code for chain interrupts

FrameState db 0

ProgramEnd:
end Start


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#%%##############%%%@@@@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@%@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#####******#****************#%@@@@@@@@@@@@@%%%%@@@@@@@@@@@%%%%@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%######**+++++++++++++++***+++*+****#%@@@@@@@@@@%%%@@@@@@@@@@@@%%@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##**+++++++++==++=============++++++++*+*#%@@@@@@@%%%@@@@@@@@@@*++*+*#@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%###*++++=++++========================++=+++***%@@@@@%%%@@@@@@@@#++*****+*%@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%***++++====-=------===-----===------=========+**++%@@@@%%@@@@@@@%++#%###**++*@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%**+++=++==-----------------------------========++++++*@@@%%@@@@@@@#+*%%##***+++*@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*++++======---------------------:--------===-======+++*+#@@@@@@@@@@*+*@%##***++++*@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%***+=+==------==-------------:::::::-::---------=======++++*%@@@@@@@%*+*%%##**++++=+@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*+++===--------------:::::::::::::::::::----------======++++++#@@@@@@*+++%@%##*++===+%@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+++====-=-----------::::::::::---------------------========++++++#@@@****+++****++==+#@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*++========-----------::::------:::::::::::-----------======++++=+++#*+**#*##***++++*#@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+++====--------------:----::::--::::::::::-------------=======++++++++++*#%%@@@@@@%%%@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*++====----------------:-:-----======--------------------=----==+**++++***%@@@@@@@@@@@@@@@@@@@
@@@@%#%@@@@@@@@@@@@@@@@@@@@@@@*+++=======--------------:---==+*++++**=-----------------------==+++++++**%@@@@@@@@@@@@@@@@@@@@
@@@@%#++**@@@@@@@@@@@@@@@@@@@%*++=========--------------==+**%@%@@@@@@%*+==-------------------===+++**#%*%@@@@@@@@@@@@@@@@@@@
@@@%@@%*+++*#@@@@@@@@@@@@@@@@*+===========---------=---==+#%@@@@@@@@@@@@%#*=--------:--------===++***#%%##%@@@@@@@@@@@@@@@@@@
@@@#%@@@++==++*@@@@@@@@@@@@@#++===========---======--==+#%@@@@@@@%#%%@@@@@%#*=---------------====++*#%@%%%%%@@@@@@@@@@@@@@@@@
@@@##@@@@*===++++#@@@@@@@@@%+==============-===----==+#@@@@@@%*========+**#*+=----=------------====++*#####%%@@@@@@@@@@@@@@@@
@@@%#%@@@%++=+++++++#%@@@@@*==============-===---=+#%@@@@%#*++================-=-------------------=====+++*%@@@@@@@@@@@@@@@@
@@@@##%@@@**+++++++++***##+===-=========-==-==-==#@@@@@%*+=======================---------------------=====++#%@@@@@@@@@@@@@@
@@@@%#%%%%#######********+====--========-==-====+#@@@#++===========================-------------------=======+#%%@@@@@@@@@@@@
@@@@@@@%@@@@@@@@@@@@%###*+=================-====****++++=+++++++++++++++++++++========------::::-------=======+###%%@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%#*+++======+========+++***++++++*******######*****+++++++=====-----::::-------========**####%@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#****##%#*++=++==++*******#####%%##*++========++++++++===----::::::--------======++**+***###%@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#****++++++****###%%####*++#%@@@@@@@@#**++++===----::::::::-------======++++++++++**#%@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%####*++++++****#######*#@@*@@@@@%*@*+@@#*+==---:::::::::::-------======+++++=======+*#
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#**++++++++*****##%@*=:+@%%%#@%--*#*=-=----:::::::::::-------======+++++======-==+
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@#*+++++++++++++*%@%+=-::*%%#*+***===----::::::::::-----------======++++===-----=+
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@#+++=========++*##%##*****##**+======--::::::----------------======++++===-----==
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+=+@@@@@@@#@#%@*+===---=========+*####****+++++++=--::::::------------------======+++++==-----==
@@@@@@@@@@@@@@@@@@@@@@@%%@@@%*==-#@@%%**#*##*+===----======-====+*#####****+=---::::::--------------------======++++==-----==
@@@@@@@@@@@@@@@@@@@@@@#*+#@@@%%#####**++++++=====-----==------==---======------:::::::--------------------=======+++==------=
@@@@@@@@@@@@@@@@@@@@@*====*%%##******++++======-------------------------------:::::::--------------------=--=====+++==------=
@@@@@@@@@@@@@@@@@@@@@+=----=**#***++++=+=====---------------------------------::::-----------------------=--=====+++==------=
@@@@@@@@@@@@@@@@@@@@@*==------=====+++*==========--------=----------------------------------------------------====++==-----==
@@@@@@@@@@@@@@@@@@@@@*+===---=====++**+=====-------:-------------===+===------------------------==------------====++==-----=+
@@@@@@@@@@@@@@@@@@@@@*++=========++++++======--------------------====**+====-----------=----==--====----------====+++=-----=+
@@@@@@@@@@@@@@@@@@@@@%#*++=====++***++++++=========---------------==+*##**++==========================--------====+++=----=+#
@@@@@@@@@@@@@@@@@@@@@@%#**+++++**#%#*++++++=======================+*##++*#%###*******+++++++==========---------==++++=---==*@
@@@@@@@@@@@@@@@@@@@@@@@%%###***##%@%***++++++++++++=======++++*#%%%%#+----=**#%%%%%%%#**+++++++=======---------==+*++=---=*%@
@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@%#**++++++++++++++++++*%@@@@@@#+=--------==++**#%%%#***+++=====------------==+*++=--=*%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@%%%@@@@#***+++++++++++++*#@@@@@@%*+=-----==--=========++***+++===-------------===+**++=#%@%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@%%%@@@@@%##*********###%@@@@@%#+=-------------================---------:------===+**++=+@@%@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@@@@@%%%%%%@@@@@@@@@%*+=---------------========-----------------------===+***+=++*=--=#
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@%#+==---------------====+++==----------------------==++****+++*=---==
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@@@@%*+=---------------==+*###+===-------------:-----====++***#*++++-----=
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@%#+=--------------=+*#%%#+===---------------------====++****#****=------
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@@%%%#####*++=----------==+*#%%%*+======-------------:------=====+*****##****-------
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@@@%##*++====------=+*#%%%%%#+==---------------------------======+*****#%###@=-------
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@%%%@@@@%%#****###%%%%%#*+===----==-------------==----------====+******#%%%%@*------==
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@%%%%%%%%%##*****#*#*****++++==========-----------------====-------==+++*****#%%%%@@*-=-==-===
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@%%%%%%##***++++++++++++++==============----==------=====----=====++****##%%@@@%+==---====+
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@%%%%%%##******++++++++++======================--==============++**#*###%%@@@@*+*-=*-=*==%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@%%@%%%###***********+++++++++++++++==+=++==================++**#####%%@@@@@#+=+@*-+#+%@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%####*********++++++++++++++++++++++=++++++=======++*####%%%%@@@@@%##+%@++%++%@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%#####*********+*+++++++++++++++++++++++=====++*###%%%%%%@@@@@####*%@+=%-=@@
@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@%%%%%%%%%%#########*************+*+++++++++++======++*##%%%%%@@@@@@@@@@@@@@@*=%=#@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#%%#%%%%%%%%#######*********+++++++++=======++++*###%%%%%%@@@@@%#%@%@%%@%%*%##@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%#######*****++++++==============++*###%%%%%@@@@@@@@@@@%%%%%%%%%@@@@@
@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%######*******++++==========-=======++**#%%%%%%@@@@@@@@@@@@@@@@@@%%%%@@@@@
@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%##******+++++++==================+++**#%%%%%@%@@@@@@@%%%@@@@@@@@@@%@@@@@@@
@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#**++++====================++++++*##%%%%@@@@@@@@@@@@@@@%%#%%@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%##**+++++++++++++++++++++***######%%%%%%%@@@@@@@@@@@@%%%%@@@@@@@@@@@@@%*
@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#####***#**###########%%%%#%%%%%%%%%@@@@@@@@@@@@@@@@%@@%@@%@@@@@@@%*=
@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%################%%%%#%#%%%%%%%@@%@@@@@@@@@@@@@@@%%%@@%%@@@@@@@@@%*==
@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%#%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@%@@%%@%@@@@@@@#*+==
@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%@@@@@@@@@@@@@@@@%#%%%@@@@@@@@@@#*+===


