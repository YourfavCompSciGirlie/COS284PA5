; ==========================
; Group member 01: Yohali_Malaika_Kamangu_u23618583
; Group member 02: Mpho_Martha_Siminya_u21824241
; Group member 03: Thabiso_Mncube_u22617362
; Group member 04: Amantle_Temo_u23539764
; Group member 05: David_Kalu_u23534975
; ==========================

section .data
    msg_before_display db "rb", 0          ; Message to print before displaying the ciphertext
    getinput db "%2s", 0  ; Prompt for user input
    ppm_magic_number db "P6", 0              ; 32-bit XOR constant
    fmt_read_dimensions db "%d %d %d", 0                      ; Format for reading 4-character input
    

extern fgetc, __isoc99_fscanf,strcmp , malloc,fopen,fclose ,ungetc,fread,free

section .text
    global readPPM

readPPM:                                  ; Function to read a PPM file
        push    rbp                       ; Save base pointer
        mov     rbp, rsp                  ; Set new base pointer
        push    rbx                       ; Save rbx register
        sub     rsp, 104                  ; Allocate 104 bytes on the stack for local variables
        mov     qword  [rbp-104], rdi     ; Store the filename (first argument) in local variable

        mov     rax, qword  [rbp-104]     ; Load filename into rax
        lea     esi, [msg_before_display]  ; Load message to display (for debugging)
        mov     rdi, rax                   ; Set up the filename as the first argument for fopen
        call    fopen                      ; Open the file
        mov     qword  [rbp-48], rax      ; Store the file pointer

        cmp     qword  [rbp-48], 0         ; Check if the file was opened successfully
        jne     .open_file_read            ; If successful, proceed to read file content

        mov     eax, 0                      ; Return 0 for failure (file not opened)
        jmp     .open_file_read5            ; Jump to file closing section

.open_file_read:                           ; Label for successfully opening file
        lea     rdx, [rbp-75]               ; Prepare space to read PPM identifier
        mov     rax, qword  [rbp-48]        ; Load file pointer
        lea     esi, [getinput]             ; Load format string for fscanf
        mov     rdi, rax                     ; Set up file pointer as the first argument for fscanf
        mov     eax, 0                       ; Clear eax before calling fscanf
        call    __isoc99_fscanf              ; Read the PPM identifier

        cmp     eax, 1                       ; Check if one item was successfully read
        jne     .close_file_on_error         ; If not, close the file and return

        lea     rax, [rbp-75]                ; Load the read identifier
        lea     esi, [ppm_magic_number]      ; Load the expected PPM identifier
        mov     rdi, rax                     ; Set up the identifier as the first argument for strcmp
        call    strcmp                       ; Compare read identifier with expected

        test    eax, eax                     ; Check the result of the comparison
        je      .handle_invalid_format       ; If equal, continue; otherwise handle invalid format

.close_file_on_error:                      ; Label to handle file closing on error
        mov     rax, qword  [rbp-48]        ; Load file pointer
        mov     rdi, rax                     ; Set up file pointer as argument for fclose
        call    fclose                       ; Close the file
        mov     eax, 0                       ; Return 0 for failure
        jmp     .open_file_read5            ; Jump to file closing section
        
.skip_to_next_line:                       ; Label to skip to the next line
        nop                                  ; No operation (placeholder)

.loop_untiline_end:                        ; Label for reading until end of line
        mov     rax, qword  [rbp-48]        ; Load file pointer
        mov     rdi, rax                     ; Set up file pointer for fgetc
        call    fgetc                       ; Read a character from the file
        cmp     eax, 10                     ; Compare the character with newline (ASCII 10)
        jne     .loop_untiline_end          ; If not newline, continue reading

.handle_invalid_format:                   ; Label to handle invalid PPM format
        mov     rax, qword  [rbp-48]        ; Load file pointer
        mov     rdi, rax                     ; Set up file pointer for fgetc
        call    fgetc                       ; Read the next character
        mov     dword  [rbp-52], eax         ; Store the character in local variable

        cmp     dword  [rbp-52], 35         ; Check if the character is '#'
        je      .skip_to_next_line          ; If it is, skip to the next line

        mov     rdx, qword  [rbp-48]        ; Load file pointer
        mov     eax, dword  [rbp-52]        ; Load the character value
        mov     rsi, rdx                     ; Set file pointer as second argument for ungetc
        mov     edi, eax                     ; Set character value as first argument for ungetc
        call    ungetc                       ; Unget the character to reprocess it

        lea     rsi, [rbp-88]               ; Load address for storing dimensions
        lea     rcx, [rbp-84]               ; Load address for storing width and height
        lea     rdx, [rbp-80]               ; Load address for storing color max value
        mov     rax, qword  [rbp-48]        ; Load file pointer
        mov     r8, rsi                      ; Set r8 for storing format string
        lea     esi, [fmt_read_dimensions]   ; Load format string for reading dimensions
        mov     rdi, rax                     ; Set up file pointer as first argument for fscanf
        mov     eax, 0                       ; Clear eax before calling fscanf
        call    __isoc99_fscanf              ; Read dimensions (width, height, max color value)

        cmp     eax, 3                       ; Check if three items were successfully read
        jne     .error_reading_dimensions     ; If not, handle error in reading dimensions

        mov     eax, dword  [rbp-88]         ; Load the max color value
        cmp     eax, 255                     ; Check if max color value is 255
        je      .check_max_color_value       ; If it is, proceed to check color values

.error_reading_dimensions:                 ; Label to handle errors in reading dimensions
        mov     rax, qword  [rbp-48]        ; Load file pointer
        mov     rdi, rax                     ; Set up file pointer for fclose
        call    fclose                       ; Close the file
        mov     eax, 0                       ; Return 0 for failure
        jmp     .open_file_read5            ; Jump to file closing section

.check_max_color_value:                   ; Label to check the max color value
        mov     rax, qword  [rbp-48]        ; Load file pointer
        mov     rdi, rax                     ; Set up file pointer for fgetc
        call    fgetc                       ; Read a character (the max color value)
        
        mov     qword  [rbp-24], 0          ; Initialize pixel data allocation size
        mov     eax, dword  [rbp-84]        ; Load width from local variable
        cdqe                                 ; Sign-extend to 64 bits
        sal     rax, 3                       ; Multiply width by 8 (for RGB)
        mov     rdi, rax                     ; Set up size for malloc
        call    malloc                       ; Allocate memory for pixel data
        mov     qword  [rbp-64], rax        ; Store allocated memory pointer
        mov     dword  [rbp-28], 0          ; Initialize pixel counter
        jmp     .check_pixeallocation_condition  ; Jump to check pixel allocation condition

.allocate_pixememory_loop:
        mov     eax, dword  [rbp-80]       ; Load the maximum color value into EAX
        cdqe                              ; Sign-extend EAX to RAX
        sal     rax, 3                    ; Multiply RAX by 8 (shifting left by 3)
        mov     edx, dword  [rbp-28]      ; Load the current pixel index into EDX
        mov   rdx, rdx                    ; No operation (might be a placeholder for clarity)
        lea     rcx, [0+rdx*8]            ; Calculate the memory offset for the current pixel
        mov     rdx, qword  [rbp-64]      ; Load the base address for pixel memory allocation
        lea     rbx, [rcx+rdx]            ; Calculate the address for the current pixel
        mov     rdi, rax                   ; Set RDI to the size of memory to allocate
        call    malloc                     ; Call malloc to allocate memory for the pixel
        mov     qword  [rbx], rax         ; Store the allocated pointer in the pixel array
        add     dword  [rbp-28], 1         ; Increment the pixel index

.check_pixeallocation_condition:
        mov     eax, dword  [rbp-84]      ; Load the number of pixels into EAX
        cmp     dword  [rbp-28], eax       ; Compare the current pixel index with the total pixels
        jl      .allocate_pixememory_loop  ; If less, repeat the allocation loop
        mov     dword  [rbp-32], 0         ; Initialize the pixel processing index to 0
        jmp     .process_pixels            ; Jump to process the allocated pixels

.open_file_read2:
        mov     dword  [rbp-36], 0         ; Initialize pixel reading index to 0
        jmp     .check_next_pixel          ; Jump to check for the next pixel

.open_file_read1:
        mov     edi, 40                    ; Set the size for malloc (potentially for pixel data)
        call    malloc                     ; Call malloc to allocate memory
        mov     qword  [rbp-72], rax       ; Store the allocated pointer for pixel data
        cmp     qword  [rbp-72], 0          ; Check if malloc failed
        jne     .skip_comment_line         ; If allocation succeeded, skip comment line processing
        mov     rax, qword  [rbp-48]       ; Load file pointer for closing
        mov     rdi, rax                   ; Move file pointer into RDI
        call    fclose                     ; Close the file
        mov     eax, 0                     ; Set return value to 0 (indicating error)
        jmp     .open_file_read5          ; Jump to end of file reading

.skip_comment_line:
        mov     rax, qword  [rbp-72]       ; Load pixel data pointer
        mov     rdx, qword  [rbp-48]       ; Load file pointer
        mov     rcx, rdx                   ; Move file pointer into RCX
        mov     edx, 1                     ; Set read size to 1 byte
        mov     esi, 1                     ; Set number of elements to read to 1
        mov     rdi, rax                   ; Move pixel data pointer into RDI
        call    fread                      ; Read a single byte into pixel data
        mov     rax, qword  [rbp-72]       ; Load pixel data pointer again
        lea     rdi, [rax+1]               ; Prepare to read into the next byte
        mov     rax, qword  [rbp-48]       ; Load file pointer
        mov     rcx, rax                   ; Move file pointer into RCX
        mov     edx, 1                     ; Set read size to 1 byte
        mov     esi, 1                     ; Set number of elements to read to 1
        call    fread                      ; Read a single byte into pixel data
        mov     rax, qword  [rbp-72]       ; Load pixel data pointer again
        lea     rdi, [rax+2]               ; Prepare to read into the next byte
        mov     rax, qword  [rbp-48]       ; Load file pointer
        mov     rcx, rax                   ; Move file pointer into RCX
        mov     edx, 1                     ; Set read size to 1 byte
        mov     esi, 1                     ; Set number of elements to read to 1
        call    fread                      ; Read a single byte into pixel data
        mov     rax, qword  [rbp-72]       ; Load pixel data pointer again
        mov     BYTE  [rax+3], 0           ; Null-terminate the pixel data

        mov     eax, dword  [rbp-32]       ; Load the current pixel processing index
        cdqe                              ; Sign-extend to RAX
        lea     rdx, [0+rax*8]            ; Calculate the offset for pixel data
        mov     rax, qword  [rbp-64]      ; Load the base address of the pixel memory
        add     rax, rdx                  ; Add the offset to the base address
        mov     rax, qword  [rax]         ; Load the current pixel pointer
        mov     edx, dword  [rbp-36]      ; Load the pixel reading index
        mov  rdx, rdx                     ; No operation (might be a placeholder for clarity)
        sal     rdx, 3                    ; Multiply EDX by 8 (shifting left by 3)
        add     rdx, rax                  ; Add to the pixel pointer
        mov     rax, qword  [rbp-72]       ; Load pixel data pointer
        mov     qword  [rdx], rax         ; Store pixel data pointer at calculated offset

        cmp     dword  [rbp-36], 0        ; Check if pixel reading index is non-positive
        jle     .initialize_pixedata       ; If so, jump to initialize pixel data
        mov     eax, dword  [rbp-32]       ; Load the current pixel processing index
        cdqe                              ; Sign-extend to RAX
        lea     rdx, [0+rax*8]            ; Calculate the offset for pixel data
        mov     rax, qword  [rbp-64]      ; Load the base address of the pixel memory
        add     rax, rdx                  ; Add the offset to the base address
        mov     rax, qword  [rax]         ; Load the current pixel pointer
        mov     edx, dword  [rbp-36]      ; Load the pixel reading index
        mov   rdx, rdx                     ; No operation (might be a placeholder for clarity)
        sal     rdx, 3                    ; Multiply EDX by 8 (shifting left by 3)
        sub     rdx, 8                    ; Adjust the index for pixel data
        add     rax, rdx                  ; Update RAX to point to the adjusted pixel
        mov     rdx, qword  [rax]         ; Load the pixel value at the adjusted address
        mov     rax, qword  [rbp-72]       ; Load pixel data pointer
        mov     qword  [rax+24], rdx      ; Store the pixel value in the pixel data
        mov     eax, dword  [rbp-32]       ; Load the current pixel processing index
        cdqe                              ; Sign-extend to RAX
        lea     rdx, [0+rax*8]            ; Calculate the offset for pixel data
        mov     rax, qword  [rbp-64]      ; Load the base address of the pixel memory
        add     rax, rdx                  ; Add the offset to the base address
        mov     rax, qword  [rax]         ; Load the current pixel pointer
        mov     edx, dword  [rbp-36]      ; Load the pixel reading index
        mov   rdx, rdx                     ; No operation (might be a placeholder for clarity)
        sal     rdx, 3                    ; Multiply EDX by 8 (shifting left by 3)
        sub     rdx, 8                    ; Adjust the index for pixel data
        add     rax, rdx                  ; Update RAX to point to the adjusted pixel
        mov     rax, qword  [rax]         ; Load the pixel value at the adjusted address
        mov     rdx, qword  [rbp-72]       ; Load pixel data pointer
        mov     qword  [rax+32], rdx      ; Store the pixel data pointer in the pixel value
        jmp     .handle_pixedata          ; Jump to handle further pixel data processing
        
.initialize_pixedata:
        mov     rax, qword  [rbp-72]      ; Load the pointer to the pixel data structure into RAX
        mov     qword  [rax+24], 0         ; Initialize field at offset 24 to 0 (possibly a counter or flag)

.handle_pixedata:
        mov     rax, qword  [rbp-72]      ; Load the pixel data pointer again into RAX
        mov     qword  [rax+32], 0         ; Initialize field at offset 32 to 0 (possibly another counter or flag)
        cmp     dword  [rbp-32], 0         ; Check if the pixel index (rbp-32) is less than or equal to 0
        jle     .set_default_pixevalues     ; If so, jump to set default pixel values
        mov     eax, dword  [rbp-32]       ; Load the current pixel index into EAX
        cdqe                                ; Sign extend EAX to RAX
        sal     rax, 3                      ; Multiply the index by 8 (size of a pointer) to get the byte offset
        lea     rdx, [rax-8]                ; Calculate the effective address offset by subtracting 8
        mov     rax, qword  [rbp-64]       ; Load the base address of the pixel data into RAX
        add     rax, rdx                    ; Add the calculated offset to the base address
        mov     rax, qword  [rax]           ; Dereference the pointer at the computed address
        mov     edx, dword  [rbp-36]        ; Load the pixel data from rbp-36 into EDX
        mov   rdx, rdx                       ; Redundant instruction; can be removed
        sal     rdx, 3                      ; Multiply EDX by 8 to get the byte offset
        add     rax, rdx                    ; Add the offset to the pixel pointer
        mov     rdx, qword  [rax]           ; Load the pixel data at the computed address
        mov     rax, qword  [rbp-72]       ; Load the pixel data structure pointer again into RAX
        mov     qword  [rax+8], rdx         ; Store the loaded pixel data at offset 8 in the structure
        mov     eax, dword  [rbp-32]       ; Load the pixel index again into EAX
        cdqe                                ; Sign extend EAX to RAX
        sal     rax, 3                      ; Multiply the index by 8 to get the byte offset
        lea     rdx, [rax-8]                ; Calculate the effective address offset by subtracting 8
        mov     rax, qword  [rbp-64]       ; Load the base address of the pixel data into RAX
        add     rax, rdx                    ; Add the calculated offset to the base address
        mov     rax, qword  [rax]           ; Dereference the pointer at the computed address
        mov     rdx, qword  [rbp-72]       ; Load the pixel data structure pointer again into RDX
        mov     qword  [rax+16], rdx        ; Store the pixel data pointer at offset 16 in the structure
        jmp     .set_zero_pixevalues        ; Jump to set pixel values to zero

.set_default_pixevalues:
        mov     rax, qword  [rbp-72]       ; Load the pixel data structure pointer into RAX
        mov     qword  [rax+8], 0           ; Initialize field at offset 8 to 0 (set default pixel value)

.set_zero_pixevalues:
        mov     rax, qword  [rbp-72]       ; Load the pixel data structure pointer into RAX
        mov     qword  [rax+16], 0          ; Initialize field at offset 16 to 0 (set another default pixel value)
        cmp     dword  [rbp-32], 0          ; Check if the pixel index is still less than or equal to 0
        jne     .open_file_read0            ; If not, jump to read the next pixel
        cmp     dword  [rbp-36], 0          ; Check if the pixel data field is not equal to 0
        jne     .open_file_read0            ; If not, jump to read the next pixel
        mov     rax, qword  [rbp-72]       ; Load the pixel data structure pointer into RAX
        mov     qword  [rbp-24], rax        ; Store the pointer to the pixel data structure into rbp-24

.open_file_read0:
        add     dword  [rbp-36], 1          ; Increment the pixel data counter

.check_next_pixel:
        mov     eax, dword  [rbp-80]       ; Load the total pixel count into EAX
        cmp     dword  [rbp-36], eax        ; Compare the current pixel index with the total pixel count
        jl      .open_file_read1            ; If the current index is less, jump to read the next pixel
        add     dword  [rbp-32], 1          ; Increment the pixel index

.process_pixels:
        mov     eax, dword  [rbp-84]       ; Load the maximum pixel count into EAX
        cmp     dword  [rbp-32], eax        ; Compare the current pixel index with the maximum pixel count
        jl      .open_file_read2            ; If the current index is less, jump to read more pixels
        mov     dword  [rbp-40], 0          ; Initialize pixel free counter at rbp-40 to 0
        jmp     .open_file_read3            ; Jump to the free pixel allocation routine

.open_file_read4:
        mov     eax, dword  [rbp-40]       ; Load the pixel free counter into EAX
        cdqe                                ; Sign extend EAX to RAX
        lea     rdx, [0+rax*8]              ; Calculate the address offset for the pixel
        mov     rax, qword  [rbp-64]       ; Load the base address of the pixel data into RAX
        add     rax, rdx                    ; Add the offset to the pixel base address
        mov     rax, qword  [rax]           ; Dereference the pointer at the computed address
        mov     rdi, rax                    ; Prepare RDI for the free call
        call    free                        ; Free the memory allocated for the pixel
        add     dword  [rbp-40], 1          ; Increment the pixel free counter

.open_file_read3:
        mov     eax, dword  [rbp-84]       ; Load the maximum pixel count into EAX
        cmp     dword  [rbp-40], eax        ; Compare the pixel free counter with the maximum pixel count
        jl      .open_file_read4            ; If free pixels are less than maximum, continue freeing

        ; Free the allocated pixel data structure
        mov     rax, qword  [rbp-64]       ; Load the pixel data pointer
        mov     rdi, rax                    ; Prepare RDI for the free call
        call    free                        ; Free the pixel data structure

        ; Close the file after reading pixels
        mov     rax, qword  [rbp-48]       ; Load the file pointer
        mov     rdi, rax                    ; Prepare RDI for the fclose call
        call    fclose                      ; Close the opened file

        ; Return the allocated pixel data pointer
        mov     rax, qword  [rbp-24]       ; Load the pixel data pointer into RAX
.open_file_read5:
        mov     rbx, qword  [rbp-8]        ; Restore the base pointer from stack
        leave                              ; Clean up the stack frame
        ret                                 ; Return from the function