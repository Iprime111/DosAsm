.PushAllRegisters   macro 
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

                    endm

.PopAllRegisters equ pop ax ax ax bx cx dx si di ds es ss bp sp      ; ax is being popped 3 times to balance stack that contains info 'bout cs and ip
