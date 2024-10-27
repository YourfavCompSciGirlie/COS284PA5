; ==========================
; Group member 01: Yohali_Malaika_Kamangu_u23618583
; Group member 02: Mpho_Martha_Siminya_u21824241
; Group member 03: Thabiso_Mncube_u22617362
; Group member 04: Amantle_Temo_u23539764
; Group member 05: David_Kalu_u23534975
; ==========================

section .text
    global applyHistogramEqualisation

applyHistogramEqualisation:
    push rbp                     ; Save base pointer for stack frame
    mov rbp, rsp                 ; Establish new stack frame
    push rbx                     ; Save rbx to preserve column traversal state
    push r12                     ; Save r12 to preserve row traversal state

    test rdi, rdi                ; Check if the head pointer is NULL
    jz .cleanup                  ; If NULL, jump to cleanup section

    mov r12, rdi                 ; Set the row pointer to the start of the linked list

.row_iterate:
    test r12, r12                ; Check if we've reached the end of rows
    jz .cleanup                  ; If no more rows, proceed to cleanup

    mov rbx, r12                 ; Set the column pointer to the current row

.col_iterate:
    test rbx, rbx                ; Check if we've reached the end of the current row
    jz .next_row                 ; If current node is NULL, move to the next row

    movzx eax, byte [rbx + 3]    ; Load CdfValue from the pixel node
    cvtsi2sd xmm0, eax           ; Convert CdfValue to double for precise rounding
    addsd xmm0, qword [rel .const_0_5] ; Add 0.5 for rounding adjustment
    cvttsd2si eax, xmm0          ; Convert back to integer for clamping

    cmp eax, 0                   ; Check if the value is less than 0
    jge .check_high_clamp        ; If non-negative, skip low clamping
    xor eax, eax                 ; Set value to 0 if negative (clamp)

.check_high_clamp:
    cmp eax, 255                 ; Check if the value exceeds 255
    jle .apply_grayscale         ; If within bounds, proceed to apply grayscale
    mov eax, 255                 ; Cap the value at 255 if it's too high

.apply_grayscale:
    mov byte [rbx], al           ; Update Red channel with grayscale value
    mov byte [rbx + 1], al       ; Update Green channel with grayscale value
    mov byte [rbx + 2], al       ; Update Blue channel with grayscale value

    mov rbx, [rbx + 16]          ; Move to the next pixel in the row
    jmp .col_iterate             ; Repeat for each pixel in the current row

.next_row:
    mov r12, [r12 + 32]          ; Move down to the next row in the image
    jmp .row_iterate             ; Continue processing with the next row

.cleanup:
    pop r12                      ; Restore row pointer
    pop rbx                      ; Restore column pointer
    pop rbp                      ; Restore base pointer and exit function
    ret

section .rodata
    align 8
.const_0_5: dq 0.5              ; Constant value used for rounding adjustment
