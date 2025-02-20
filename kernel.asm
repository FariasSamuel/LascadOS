BITS 16
ORG 0x1000

start:
    ; Set up data segments

    mov byte [0x3000],0; maximum number of files
    mov word [0x3001],0x3241; first available byte

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
    mov di, crt_file
    call strcmp
    je create_file

    mov si, command_buffer
    mov di, cmd_clear
    call strcmp
    je do_clear

    mov si, command_buffer
    mov di, cmd_reboot
    call strcmp
    je do_reboot

    mov si, command_buffer
    mov di, cmd_time
    call strcmp
    je do_time

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

do_time:
    mov ah, 0x02    ; Get RTC time
    int 0x1A        ; BIOS call

    mov si, time_msg
    call print_string

    ; Convert and print hour
    mov al, ch
    call print_bcd
    mov al, ':'
    call print_char

    ; Convert and print minute
    mov al, cl
    call print_bcd
    mov al, ':'
    call print_char

    ; Convert and print second
    mov al, dh
    call print_bcd
    
    call new_line
    jmp command_loop

do_shutdown:
    cli             ; Disable interrupts
    hlt             ; Halt the CPU

; Get available memory in KB - Fixed version
do_mem:
    int 0x12        ; Call BIOS memory size function
    push ax         ; Save the result (in KB)
    
    mov si, mem_msg
    call print_string
    
    pop ax          ; Restore the memory size
    call print_decimal
    
    mov si, kb_msg
    call print_string
    call new_line
    jmp command_loop

; Function to read a string from keyboard
read_string:
    xor cx, cx
.loop:
    mov ah, 0
    int 0x16
    cmp al, 13      ; Check for Enter key
    je .done
    cmp al, 8       ; Check for Backspace
    je .backspace
    cmp cx, 62      ; Check buffer limit
    jae .loop
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

; Function to compare two strings
strcmp:
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
    clc
    ret
.equal:
    stc
    ret

; Function to print a string
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

; Function to print a single character
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

; Function to print BCD number
print_bcd:
    push ax
    mov ah, al
    shr al, 4
    and ah, 0x0F
    add al, '0'
    add ah, '0'
    call print_char
    mov al, ah
    call print_char
    pop ax
    ret

; Function to print a decimal number
print_decimal:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10      ; Divisor
    xor cx, cx      ; Counter for digits
    
.divide_loop:
    xor dx, dx      ; Clear high word before division
    div bx          ; Divide by 10
    push dx         ; Save remainder
    inc cx          ; Increment digit counter
    test ax, ax     ; Check if quotient is zero
    jnz .divide_loop
    
.print_loop:
    pop ax          ; Get digit
    add al, '0'     ; Convert to ASCII
    mov ah, 0x0E    ; BIOS teletype output
    int 0x10
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to clear screen
clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

read_decimal:
    mov di,command_buffer
    call read_string
    xor ax,ax
    mov si,command_buffer
    mov ah,0x0E
    mov bx,0
    mov al,0
.convert:
    imul bx,10
    mov al,[si]
    sub al,'0'
    add bh,al 
    inc si
    loop .convert
    ret
create_file:
    push bx ;verifica se tem espaço na tabela
    mov bx,[0x3000]
    cmp bx, 20
    je .no_more_files
    
    mov di, command_buffer;pede o nome do arquivo
    call read_string

    mov si, command_buffer;salva o arquivo na tabela
    imul bx,13
    add bx,0x3005
.retry:
    mov al, [si]
    mov [bx], al
    inc si
    inc bx
    loop .retry

    call read_decimal;pede quantidade de bytes
    mov al,bh;salva a quantidade na tabela
    xor bx,bx
    mov bx,[0x3000]
    imul bx,13
    add bx,0x3005
    add bx, 10
    mov [bx],al
    mov cl, al

    inc bx;salva inicio do arquivo
    mov ax,[0x3001]
    mov [bx],ax

    mov cx,13
    mov bx,[0x3000]
    imul bx,13
    add bx,0x3005
    mov ah,0x0E
.repetir:
    mov al,[bx]
    int 0x10
    inc bx
    loop .repetir

    jmp .done
.no_more_files:
    mov si,files_error
    call print_string
    ret

.no_more_bytes:
    mov si,bytes_error
    call print_string
    ret

.done:
    mov si,sucess
    call print_string
    ret


; Data section
welcome_msg db 'Interactive Kernel v0.2', 13, 10
           db 'Type "help" for commands', 13, 10, 0
prompt db '> ', 0
help_msg db 'Available commands:', 13, 10
        db '  help      - Show this help', 13, 10
        db '  clear     - Clear screen', 13, 10
        db '  reboot    - Restart system', 13, 10
        db '  time      - Show current time', 13, 10
        db '  shutdown  - Halt the CPU', 13, 10
        db '  mem       - Show available memory', 13, 10, 0
unknown_cmd db 'Unknown command. Type "help" for available commands.', 13, 10, 0
reboot_msg db 'System will reboot. Press any key...', 13, 10, 0
time_msg db 'Current Time: ', 0
mem_msg db 'Available memory: ', 0
kb_msg db ' KB', 0
sucess db 'YAAAAAS, pisa prima.', 13, 10, 0
files_error db 'There isnt available space for files.', 13, 10, 0
bytes_error db 'There isnt available space for files.', 13, 10, 0

; Command strings
cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_reboot db 'reboot', 0
cmd_time db 'time', 0
crt_file db 'create', 0
cmd_mem db 'mem', 0
dlt_file db 'delete',0
read_file db 'delete',0
cmd_shutdown db 'shutdown', 0

; Buffer for user input
command_buffer times 64 db 0

; Pad to two full sectors
;times 1080-($-$$) db 0
