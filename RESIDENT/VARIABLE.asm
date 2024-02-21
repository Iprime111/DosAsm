TitleLength     equ 9d          ; title length
FrameTitle      db "REGISTERS"  ; frame title
FrameStyle      db 00c9h, 00cdh, 00bbh, 00bah, ' ', 00bah, 00c8h, 00cdh, 00bch  ; symbols hex codes for frame style (double lines)

StyleAttribytes equ 70h         ; attributes for frame symbol

FirstLine           equ 5d      ; first line on screen where frame is displayed
FrameWidth          equ 15d     ; width  of the frame
FrameHeight         equ 15d     ; height of the frame

RegistersCount      equ 13d     ; saved registers count
RegisterValueOffset equ 9d      ; distance (in symbols) between frame left side and register value
RegisterNameLength  equ 2d      ; length of the register name
RegisterNames       db "cs", "ip", "ax", "bx", "cx", "dx", "si", "di", "ds", "es", "ss", "bp", "sp"

