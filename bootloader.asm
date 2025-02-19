BITS 16
ORG 0x7C00

; Data section
boot_drive db 0

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Store the boot drive number that BIOS provides in DL
    mov [boot_drive], dl
    
    ; Enable interrupts now that setup is done
    sti

    ; Bootloader start debug message
    mov si, msg1
    call print_string

    ; Reset disk system
    mov ah, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; Message before loading kernel
    mov si, msg_prepare_kernel
    call print_string

    ; Read kernel (2 sectors)
    mov ax, 0           ; we want to read into segment 0
    mov es, ax
    mov bx, 0x1000     ; load kernel to 0x1000

    mov ah, 0x02       ; BIOS read sector function
    mov al, 3          ; number of sectors to read (increased to 2)
    mov ch, 0          ; cylinder 0
    mov cl, 2          ; sector 2 (sectors start at 1)
    mov dh, 0          ; head 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; Kernel succesful load message
    mov si, msg_loaded_kernel
    call print_string

    ; Message before jumping to kernel
    mov si, msg_before_jump
    call print_string

    ; Jump to kernel
    jmp 0x0000:0x1000

disk_error:
    mov si, msg_disk_error
    call print_string
    jmp error

error:
    mov si, msg_error
    call print_string
.halt:
    hlt
    jmp .halt

print_string:
    mov ah, 0x0E
.repeat:
    lodsb               ; Get character from string
    test al, al
    jz .done           ; If char is zero, end of string
    int 0x10           ; else, print it
    jmp .repeat
.done:
    ret

; Messages
msg1 db "Bootloader started.", 13, 10, 0
msg_prepare_kernel db "Preparing to load kernel...", 13, 10, 0
msg_loaded_kernel db "Kernel loaded to 0x1000.", 13, 10, 0
msg_before_jump db "Jumping to kernel at 0x1000.", 13, 10, 0
msg_disk_error db "Disk read error!", 13, 10, 0
msg_error db "Error loading kernel!", 13, 10, 0

; Boot sector magic
times 510-($-$$) db 0
dw 0xAA55
