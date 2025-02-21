BITS 16
ORG 0x1000

start:
    ; Set up data segments
    mov byte [0x3000], 0      ; file count = 0 (max 20 files)
    mov word [0x3001], 0x3241 ; pointer to first available byte

    mov ax, 0
    mov ds, ax
    mov es, ax

    ; Print welcome message
    mov si, welcome_msg
    call print_string

command_loop:
    ; Print prompt
    mov si, prompt
    call print_string

    ; Get command input
    mov di, command_buffer
    call read_string

    ; Compare with known commands
    mov si, command_buffer
    mov di, cmd_help
    call strcmp
    je do_help

    mov si, command_buffer
    mov di, cmd_create
    call strcmp
    je create_file

    mov si, command_buffer
    mov di, cmd_edit
    call strcmp
    je edit_file

    mov si, command_buffer
    mov di, cmd_delete
    call strcmp
    je delete_file

    mov si, command_buffer
    mov di, cmd_show
    call strcmp
    je show_file

    mov si, command_buffer
    mov di, cmd_list
    call strcmp
    je do_list

    mov si, command_buffer
    mov di, cmd_clear
    call strcmp
    je do_clear

    mov si, command_buffer
    mov di, cmd_reboot
    call strcmp
    je do_reboot

    mov si, command_buffer
    mov di, cmd_shutdown
    call strcmp
    je do_shutdown

    mov si, command_buffer
    mov di, cmd_mem
    call strcmp
    je do_mem

    ; If no command matched, print error
    mov si, unknown_cmd
    call print_string
    jmp command_loop

; Command handlers
do_help:
    mov si, help_msg
    call print_string
    jmp command_loop

do_clear:
    call clear_screen
    jmp command_loop

do_reboot:
    mov si, reboot_msg
    call print_string
    mov ah, 0
    int 0x16
    jmp 0xFFFF:0x0000

do_shutdown:
    cli             ; Disable interrupts
    hlt             ; Halt the CPU
    jmp $

do_mem:
    int 0x12        ; BIOS memory size (KB)
    push ax         ; Save memory size
    
    mov si, mem_msg
    call print_string
    
    pop ax          ; Restore memory size
    call print_decimal
    
    mov si, kb_msg
    call print_string
    call new_line
    jmp command_loop


show_file:
    push ax
    push bx
    push cx
    push dx

    mov bx, 0x3005
    mov cl, [0x3000]

    mov si, filename_prompt
    call print_string
    mov di, command_buffer
    call read_string
    mov di, command_buffer
.search:  
    mov si,bx
    call strcmp
    je .achou
    call print_string
    mov ah,0x0E
    mov al,32
    int 0x10
    add bx,13
    dec cl
    jnz .search
    jmp .not_find
.achou:
    mov ax,[bx+11]
    mov dx,[bx+9]
    mov bx,ax
    mov cx,0
.escrever:
    mov ah,0x0E
    push bx
    add bx,cx
    mov al,[bx]
    pop bx
    int 0x10
    inc cx
    cmp cx,dx
    jne .escrever
    jmp .done

.done:
    pop dx
    pop cx
    pop bx
    mov si, success
    call print_string
    jmp command_loop
.not_find:
    pop dx
    pop cx
    pop bx
    mov si, no_matched_files_msg
    call print_string
    jmp command_loop



edit_file:
    push ax
    push bx
    push cx
    push dx

    mov bx, 0x3005
    mov cl, [0x3000]

    mov si, filename_prompt
    call print_string
    mov di, command_buffer
    call read_string
    mov di, command_buffer
.search:  
    mov si,bx
    call strcmp
    je .achou
    call print_string
    mov ah,0x0E
    mov al,32
    int 0x10
    add bx,13
    dec cl
    jnz .search
    jmp .not_find
.achou:
    mov ax,[bx+11]
    mov dx,[bx+9]
    mov bx,ax
    mov cx,0
    push bx
    push cx
    push dx
.write:
    mov ah,0x0E
    mov al,[bx]
    int 0x10
    inc cx
    inc bx
    cmp cx,dx
    jle .write

    push cx
    MOV AH, 0x03
    MOV BH, 0x00   
    INT 0x10 
    MOV AH, 0x02
    MOV BH, 0x00  ; Página de vídeo
    pop cx
    sub dl,cl
    INT 0x10

    pop dx
    pop cx
    pop bx

.escrever:
    mov ah,0
    int 0x16
    cmp al,8
    je .backspace
    cmp al,13
    je .done
    cmp al,0x00
    je .check_arrow
    mov ah,0x0E
    int 0x10
    push bx
    add bx,cx
    mov [bx],al
    pop bx
    inc cx
    cmp cx,dx
    jne .escrever
    jmp .done
.check_arrow:
    ; Lê o scan code da tecla (está em AH)
    push ax
    push bx
    push dx
    cmp ah, 0x48    ; Seta para cima?
    je .arrow_up
    cmp ah, 0x50    ; Seta para baixo?
    je .arrow_down
    cmp ah, 0x4B    ; Seta para a esquerda?
    je .arrow_left
    cmp ah, 0x4D    ; Seta para a direita?
    je .arrow_right
    .finished_arrow:
    pop dx
    pop bx
    pop ax
    jmp .escrever   ; Se não for uma seta, volta ao loop

.arrow_up:
    ; Exibe a mensagem para seta para cima
    ;mov si, msg_up
    call print_string
    jmp .finished_arrow

.arrow_down:
    
    call print_string
    jmp .finished_arrow

.arrow_left:
    ; Exibe a mensagem para seta para a esquerda
    push cx
    MOV AH, 0x03
    MOV BH, 0x00   
    INT 0x10 
    MOV AH, 0x02
    MOV BH, 0x00  ; Página de vídeo
    dec DL
    INT 0x10
    pop cx
    dec cx 
    jmp .finished_arrow

.arrow_right:
    push cx
    MOV AH, 0x03
    MOV BH, 0x00   
    INT 0x10 
    MOV AH, 0x02
    MOV BH, 0x00  ; Página de vídeo
    inc DL
    INT 0x10
    pop cx
    inc cx 
    jmp .finished_arrow
    
.backspace:
    cmp cx,0
    je .escrever
    dec cx
    push bx
    add bx,cx
    mov byte [bx],' '
    pop bx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .escrever

.done:
    pop dx
    pop cx
    pop bx
    mov si, success_edit
    call print_string
    jmp command_loop
.not_find:
    pop dx
    pop cx
    pop bx
    mov si, no_matched_files_msg
    call print_string
    jmp command_loop


delete_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bx, 0x3005          ; Start of file table
    mov cl, [0x3000]        ; Number of files

    mov si, filename_prompt
    call print_string
    mov di, command_buffer
    call read_string

.search:
    push cx                 ; Save file counter
    push bx                 ; Save table pointer
    
    mov di, command_buffer
    mov si, bx              ; Point SI to filename in table
    call strcmp
    je .found
    
    pop bx                 ; Restore table pointer
    pop cx                 ; Restore counter
    add bx, 13             ; Move to next entry
    dec cl
    jnz .search
    jmp .not_found

.found:
    pop bx                 ; Restore table pointer to found entry
    pop cx                 ; Restore counter
    
    ; Save important values
    mov dx, [bx + 9]       ; Get file size
    mov ax, [bx + 11]      ; Get file address
    
    ; Move file data (compact memory)
    mov si, ax             ; Source address
    add si, dx             ; Source + size = next data block
    mov di, ax             ; Destination = deleted file's address
    
    ; Calculate bytes to move
    mov cx, [0x3001]       ; End of data
    sub cx, si             ; Subtract start of next block
    
    ; Move the data
    cld                    ; Ensure direction flag is clear (forward)
    rep movsb              ; Move the data
    
    ; Update file addresses for all subsequent files
    push bx                ; Save pointer to deleted entry
    
    ; Get index of deleted file
    sub bx, 0x3005         ; Calculate offset from table start
    xor ah, ah
    mov al, 13
    div al                 ; AX = index of deleted file
    
    mov ch, al             ; Save index in CH
    inc ch                 ; Next file index
    
    ; Calculate address of next file entry
    mov al, ch
    mov ah, 0
    mov cl, 13
    mul cl                 ; AX = next file index * 13
    add ax, 0x3005         ; Base address
    mov bx, ax             ; BX = next file entry
    
    ; Get total number of files
    mov cl, [0x3000]
    sub cl, ch             ; Number of files after deleted file
    
.update_loop:
    test cl, cl
    jz .update_done        ; If no more files, done
    
    ; Update file address
    mov ax, [bx + 11]      ; Get current address
    sub ax, dx             ; Subtract deleted file size
    mov [bx + 11], ax      ; Store updated address
    
    add bx, 13             ; Move to next entry
    dec cl
    jmp .update_loop
    
.update_done:
    pop bx                 ; Restore pointer to deleted entry
    
    ; Move file table entries to compact the table
    push bx                ; Save pointer again
    
    mov si, bx
    add si, 13             ; Source = next entry
    mov di, bx             ; Destination = current entry
    
    ; Calculate how many entries to move
    mov cl, [0x3000]
    sub cl, ch
    inc cl                 ; Include the entry we're replacing
    
    ; Calculate bytes to move
    mov al, cl
    mov ah, 0
    mov cl, 13
    mul cl                 ; AX = bytes to move
    mov cx, ax
    
    rep movsb              ; Move entries
    
    pop bx                 ; Restore pointer
    
    ; Update data pointer
    mov ax, [0x3001]
    sub ax, dx             ; Subtract deleted file size
    mov [0x3001], ax       ; Update data pointer
    
    dec byte [0x3000]      ; Decrease file count
    
    mov si, success_delete
    call print_string
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    jmp command_loop

.not_found:
    mov si, no_matched_files_msg
    call print_string
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    jmp command_loop

create_file:
    push ax
    push bx
    push cx
    push dx

    ; Check if maximum files reached (20)
    mov al, [0x3000]
    cmp al, 20
    je .no_more_files

    ; Calculate entry address (13 bytes per entry)
    xor ah, ah         ; Clear high part of AX
    mov bl, 13          ; Entry size
    mul bl              ; AX = file_count * 13
    add ax, 0x3005      ; Base address of file table
    mov bx, ax          ; BX = entry address

    ; Get filename
    mov si, filename_prompt
    call print_string
    mov di, command_buffer
    call read_string

    ; Copy filename (max 10 chars, zero-padded)
    mov cx, 9          ; Maximum filename length
    mov si, command_buffer
    push bx             ; Save entry address
    mov di, bx          ; Destination for filename
.copy_name:
    lodsb
    test al, al         ; Check for end of string
    jz .pad_name
    mov [di], al
    inc di
    loop .copy_name
    jmp .name_done
.pad_name:
    mov al, 0           ; Pad with zeros
.pad_loop:
    mov [di], al
    inc di
    loop .pad_loop
.name_done:
    pop bx
    ; Get and validate file size
    mov si, size_prompt
    call print_string
    call read_decimal
    mov ax, bx                   
    push ax
    mov bx, [0x3001]               
    add ax, bx                      
    cmp ax, 0x3629                  
    jge .invalid_size             

    mov al, [0x3000]
    xor ah, ah         
    mov bl, 13         
    mul bl              
    add ax, 0x3005      
    mov bx, ax     
    pop ax  
    mov [bx + 9], ax   ; Store at offset 9

    mov ax,[bx+9]
    call print_decimal

    ; Calculate and store file address
    mov ax, [0x3001]    ; Current data pointer
    mov [bx + 11], ax   ; Store at offset 11

    add ax,[bx+9]
    mov [0x3001],ax

    ; Increment file count
    inc byte [0x3000]

    ; Success
    mov si, success
    call print_string
    
    pop dx
    pop cx
    pop bx
    pop ax
    jmp command_loop

.invalid_size:
    mov si, invalid_size_msg
    jmp .error

.too_large:
    mov si, too_large_msg
    jmp .error

.no_more_files:
    mov si, files_error
    jmp .error

.error:
    call print_string
    pop dx
    pop cx
    pop bx
    pop ax
    jmp command_loop

.temp_size: dw 0

do_list:
    push ax
    push bx
    push cx
    push dx

    ; Check for files
    mov al, [0x3000]
    test al, al
    jz .no_files

    ; Print header
    mov si, list_header
    call print_string

    ; List all files
    xor cx, cx          ; File counter
    mov bx, 0x3005      ; Start of file table
.list_loop:
    mov al, [0x3000]    ; Get total files
    cmp cl, al
    jae .done           ; If we've listed all files, done

    ; Print file number
    push cx             ; Save file counter
    inc cx              ; Start from 1
    mov ax, cx
    call print_decimal
    mov si, list_separator
    call print_string

    ; Print filename
    mov dx, cx          ; Save file number
    mov cx, 9          ; Maximum filename length
.name_loop:
    mov al, [bx]
    test al, al
    jz .name_done
    call print_char
    inc bx
    loop .name_loop
.name_done:
    add bx, cx          ; Skip any remaining filename bytes
    
    ; Print size
    mov si, list_size
    call print_string
    xor ax, ax
    mov ax, [bx]        ; Get file size
    call print_decimal
    inc bx

    ; Print address
    mov si, list_addr
    call print_string
    mov ax, [bx + 1]    ; Get file address (2 bytes)
    call print_decimal
    call new_line
    inc bx

    ; Move to next entry (reset BX to start + entry_size * file_number)
    pop cx              ; Restore file counter
    inc cx              ; Next file
    push cx             ; Save for next iteration
    
    mov ax, 13          ; Entry size
    mul cl              ; AX = entry_size * file_number
    add ax, 0x3005      ; Add base address
    mov bx, ax          ; BX points to next entry

    pop cx              ; Restore counter for loop
    jmp .list_loop

.done:
    mov si, total_files
    call print_string
    xor ax, ax
    mov al, [0x3000]
    call print_decimal
    mov si, files_suffix
    call print_string
    jmp .exit

.no_files:
    mov si, no_files_msg
    call print_string

.exit:
    pop dx
    pop cx
    pop bx
    pop ax
    jmp command_loop
; Function to read a string from keyboard
read_string:
    xor cx, cx
.loop:
    mov ah, 0
    int 0x16
    cmp al, 13      ; Enter key
    je .done
    cmp al, 8       ; Backspace
    je .backspace
    cmp cx, 62      ; Buffer limit
    jge .loop
    stosb
    inc cx
    mov ah, 0x0E    ; Echo character
    int 0x10
    jmp .loop
.backspace:
    test cx, cx
    jz .loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .loop
.done:
    mov al, 0
    stosb
    call new_line
    ret

read_decimal:
    mov di,command_buffer
    call read_string
    xor ax,ax
    mov si,command_buffer
    mov bx,0
    mov al,0
.convert:
    imul bx,10
    mov al,[si]
    sub al,'0'
    add bx,ax 
    inc si
    loop .convert
    ret

; Function to compare two strings (pointed by SI and DI)
strcmp:
    push ax
    push bx
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
   
    inc si
    inc di
    jmp .loop
.not_equal:
    pop bx
    pop ax
    clc
    ret
.equal:
    pop bx
    pop ax
    stc
    ret

; Function to print a string (pointed by SI)
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Function to print a single character (in AL)
print_char:
    mov ah, 0x0E
    int 0x10
    ret

; Function to print a new line
new_line:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret

; Function to print a decimal number (value in AX)
print_decimal:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10      ; Divisor
    xor cx, cx      ; Counter for digits
    
.divide_loop:
    xor dx, dx      ; Clear DX before division
    div bx          ; Divide AX by 10
    push dx         ; Save remainder (digit)
    inc cx          ; Count digits
    test ax, ax     ; If quotient is 0, finish
    jnz .divide_loop
    
.print_loop:
    pop ax          ; Get digit
    add al, '0'     ; Convert to ASCII
    call print_char
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to clear the screen
clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

; Data section
welcome_msg     db 'Interactive Kernel v0.2', 13, 10
                db 'Type "help" for commands', 13, 10, 0
prompt          db '> ', 0
help_msg        db 'Available commands:', 13, 10
                db '  help      - Show this help', 13, 10
                db '  create    - Create a file', 13, 10
                db '  delete    - Delete a file', 13, 10
                db '  list      - List all files', 13, 10
                db '  clear     - Clear screen', 13, 10
                db '  reboot    - Restart system', 13, 10
                db '  shutdown  - Halt the CPU', 13, 10
                db '  mem       - Show available memory', 13, 10, 0
unknown_cmd     db 'Unknown command. Type "help" for available commands.', 13, 10, 0
reboot_msg      db 'System will reboot. Press any key...', 13, 10, 0
mem_msg         db 'Available memory: ', 0
kb_msg          db ' KB', 0

; File system messages
filename_prompt db 'Enter file name: ', 0
size_prompt     db 'Enter file size (bytes): ', 0
invalid_size_msg db 'Invalid file size.', 13, 10, 0
too_large_msg   db 'File too large (max 1000 bytes).', 13, 10, 0
files_error     db "Maximum number of files reached.", 13, 10, 0
success         db 'File created successfully.', 13, 10, 0
success_delete  db 'File deleted successfully.', 13, 10, 0
success_edit    db 'File edited successfully.', 13, 10, 0
list_header     db 'Files:', 13, 10, 0
list_separator  db '. ', 0
list_size       db ' - ', 0
list_addr       db ' bytes at ', 0
total_files     db 'Total files: ', 0
files_suffix    db ' file(s)', 13, 10, 0
no_files_msg    db 'No files found.', 13, 10, 0
matched_file_msg    db 'file found.', 13, 10, 0
no_matched_files_msg    db 'No file found.', 13, 10, 0
; Command strings
cmd_help        db 'help', 0
cmd_clear       db 'clear', 0
cmd_reboot      db 'reboot', 0
cmd_create      db 'create', 0
cmd_delete      db 'delete', 0
cmd_edit        db 'edit', 0
cmd_show       db 'show', 0
cmd_list        db 'list', 0
cmd_shutdown    db 'shutdown', 0
cmd_mem         db 'mem', 0

; Buffer for user input
command_buffer  times 64 db 0