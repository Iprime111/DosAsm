TitleLength     equ 9d
FrameTitle      db "REGISTERS"
FrameStyle      db 00c9h, 00cdh, 00bbh, 00bah, ' ', 00bah, 00c8h, 00cdh, 00bch  ; symbols hex codes for frame style 2 (double lines)

StyleAttribytes equ 70h

FirstLine           equ 5d
FrameWidth          equ 15d
FrameHeight         equ 15d

RegistersCount      equ 13d
RegisterValueOffset equ 9d
RegisterNameLength  equ 2d
RegisterNames       db "cs", "ip", "ax", "bx", "cx", "dx", "si", "di", "ds", "es", "ss", "bp", "sp"

