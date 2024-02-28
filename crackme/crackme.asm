.model tiny
.286
.code
org 100h
locals @@

Start:
    call FnCheckFileHash

    mov dx, offset EnterPasswordMessage
    call FnShowMessage

    mov di, offset PasswordBuffer
    push cs
    pop  es                                                     ; set args for FnReadPassword

    mov VerificationJumpSegment, cs                             ; it's here for invisibility (setting segment for verification jump)
    call FnReadPassword

    db 0eah                                                     ; jmp instruction
    VerificationJumpOffset  dw offset FnDestroyVideoBuffers
    VerificationJumpSegment dw 0                                ; some self-modifying code for checksum verification
VerificationJumpEnd:

    mov di, offset PasswordBuffer
    call FnCheckPassword
    call FnPrintPasswordCheckMessage

    ret

include vars.asm
include checker.asm

; -----------------------------------------------------------------------------
; | FnReadPassword (No buffer overflow check)
; | Args:       di - password array address
; | Assumes:    es = cs
; | Destroys:   ax, cx, di registers
; | Returns:    Nothing
; -----------------------------------------------------------------------------
FnReadPassword proc
    mov cx, 0ffffh           ; set ffff (65535 dec) as max password length

@@ReadingLoop:
    mov ah, 07h
    int 21h                 ; read character

@@PasswordNotEnded:
    stosb                   ; store character

    cmp al, 0dh             ; '\r' code
    je @@Return

    loop @@ReadingLoop

@@Return:
    ret
endp

; -----------------------------------------------------------------------------
; | FnCheckPassword
; | Args: di - password array address 
; | Assumes:    password string ends with '\r'
; | Destroys:   si, di, ax, cx registers
; | Returns:    
; -----------------------------------------------------------------------------
FnCheckPassword proc
    mov si, di                                                  ; save password address

    mov al, 0dh                                                 ; '\r' ascii code
    mov cx, 0ffffh                                              ; set registers

    repne scasb
    neg cx
    sub cx, 2                                                   ; get password length

    mov ax, TargetPasswordHash                                  ; set target hash
    call FnCheckHash

    cmp ax, 00h
    jne @@CorrectHash
    ret

@@CorrectHash:
    mov CheckResult, 01h
    ret
endp

; -----------------------------------------------------------------------------
; | FnPrintPasswordCheckMessage
; | Args: di - password array address 
; | Assumes: password string ends with '\r'
; | Destroys:
; | Returns:    
; -----------------------------------------------------------------------------
FnPrintPasswordCheckMessage proc
    cmp CheckResult, 00h
    je @@AccessDenied

    mov dx, offset AccessGrantedMessage
    jmp @@PrintMessage
@@AccessDenied:
    mov dx, offset AccessDeniedMessage

@@PrintMessage:
    call FnShowMessage
    ret
endp

; -----------------------------------------------------------------------------
; | FnCheckFileHash
; | Args: No args
; | Assumes:    Nothing
; | Destroys:   ax, bx, cx, es, si registers
; | Returns:    sets VerificationJumpOffset and VerificationJumpSegment
; -----------------------------------------------------------------------------
FnCheckFileHash proc
    mov si, offset Start
    mov cx, offset FileEnd
    sub cx, si
    mov ax, TargetFileHash
    call FnCheckHash                    ; check hash

    cmp ax, 00h                         ; doing check second time to make it harder to understand what is going on
    je @@WrongHash
    ret

@@WrongHash:
    mov dx, offset FileModifiedMessage
    call FnShowMessage                  ; show rejection message

    mov ah, 00h
    int 21h                             ; terminate program
endp

; -----------------------------------------------------------------------------
; | FnShowMessage
; | Args: dx - message address
; | Assumes:    Message ends with '$' byte, ds = cs
; | Destroys:   ax register
; | Returns:    Nothing
; -----------------------------------------------------------------------------
FnShowMessage proc
    mov ah, 09h 
    int 21h

    ret
endp

; -----------------------------------------------------------------------------
; | FnDestroyVideoBuffers
; | Args: No args
; | Assumes:    Nothing
; | Destroys:   Everything)
; | Returns:    Nothing
; -----------------------------------------------------------------------------
FnDestroyVideoBuffers proc
    push 0b800h
    pop  es

    push cs
    pop  ds                                             ; set es and ds

@@SetRegisters:
    mov cx, 80 * 2 * 25                                 ; video buffer legth
    
    mov si, offset Start
    mov di, 0                                           ; set di and si

@@DestructionLoop:
    movsw
    loop @@DestructionLoop
    
    jmp @@SetRegisters
endp

PasswordBuffer      db 10 dup(0)
CheckResult         db 0

EnterPasswordMessage db 0dh, 0ah, "Enter password: ", "$"
AccessGrantedMessage db 0dh, 0ah, "Password correct", 02h, "$"
AccessDeniedMessage  db 0dh, 0ah, "Password is incorrect. Try harder ;D", "$"
FileModifiedMessage  db "File has been modified, f*ck you :)", "$"

TargetPasswordHash dw 0f7c5h
FileEnd:
TargetFileHash     dw 0c1d9h

end Start
