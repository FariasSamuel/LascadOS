BITS 16
ORG 0x1000

start:
    ; Set up data segments
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
    mov ah, 0x04   ; Get RTC time
    int 0x1A       ; BIOS call

    mov si, time_msg
    call print_string

    ; Convert and print hour
    mov al, ch
    call bcd_to_ascii
    mov al, ':'
    call print_char

    ; Convert and print minute
    mov al, cl
    call bcd_to_ascii
    mov al, ':'
    call print_char

    ; Convert and print second
    mov al, dh
    call bcd_to_ascii

    call new_line
    jmp command_loop

; Function to convert BCD to ASCII and print
bcd_to_ascii:
    push ax
    mov ah, al    ; Copy value
    shr al, 4     ; Get upper nibble (tens place)
    and ah, 0x0F  ; Get lower nibble (ones place)
    add al, '0'   ; Convert to ASCII
    add ah, '0'   ; Convert to ASCII

    mov si, hex_buf
    mov [si], al
    mov [si+1], ah
    call print_string
    pop ax
    ret


do_shutdown:
    cli  ; Disable interrupts
    hlt  ; Halt the CPU

; Get available memory in KB
do_mem:
    mov ah, 0x12
    int 0x12
    mov si, mem_msg
    call print_string
    call print_hex
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
    cmp al, 13
    je .done
    cmp al, 8
    je .backspace
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .loop
.backspace:
    test cx, cx
    jz .loop
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    dec di
    dec cx
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

; Function to print a hex value
print_hex:
    aam
    add ah, '0'
    add al, '0'
    mov si, hex_buf
    mov [si], ah
    mov [si+1], al
    call print_string
    ret

; Function to clear screen
clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
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
kb_msg db ' KB', 13, 10, 0
hex_buf db '00', 0

; Command strings
cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_reboot db 'reboot', 0
cmd_time db 'time', 0
cmd_shutdown db 'shutdown', 0
cmd_mem db 'mem', 0

; Buffer for user input
command_buffer times 64 db 0

; Pad to two full sectors
times 1024-($-$$) db 0

