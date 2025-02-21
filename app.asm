BITS 16
ORG 0x5000

; Import kernel functions
extern print_string
extern read_string
extern strcmp
extern clear_screen
extern print_decimal
extern new_line

start:
    ; Print welcome message
    mov si, welcome_msg
    call print_string

    ; Enter text editor mode
    call text_editor

    ; Exit the app
    ret

text_editor:
    ; Clear the screen
    call clear_screen

    ; Print editor instructions
    mov si, editor_instructions
    call print_string

    ; Initialize editor variables
    mov di, text_buffer  ; Pointer to text buffer
    mov cx, 0            ; Character counter

.edit_loop:
    ; Read a key
    mov ah, 0
    int 0x16

    ; Handle special keys
    cmp al, 8           ; Backspace
    je .backspace
    cmp al, 13          ; Enter
    je .newline
    cmp al, 27          ; ESC
    je .exit_editor

    ; Normal character
    mov ah, 0x0E        ; Print character
    int 0x10
    stosb               ; Store character in buffer
    inc cx              ; Increment character count
    jmp .edit_loop

.backspace:
    ; Handle backspace
    cmp cx, 0           ; If buffer is empty, ignore
    je .edit_loop
    dec di              ; Move pointer back
    dec cx              ; Decrement character count
    mov byte [di], 0    ; Clear the character

    ; Print backspace effect
    mov ah, 0x0E
    mov al, 8
    int 0x10            ; Backspace
    mov al, ' '
    int 0x10            ; Print space
    mov al, 8
    int 0x10            ; Backspace again
    jmp .edit_loop

.newline:
    ; Handle newline (Enter key)
    mov ah, 0x0E
    mov al, 13          ; Carriage return
    int 0x10
    mov al, 10          ; Line feed
    int 0x10
    mov byte [di], 13   ; Store carriage return
    inc di
    mov byte [di], 10   ; Store line feed
    inc di
    add cx, 2           ; Increment character count
    jmp .edit_loop

.exit_editor:
    ; Save the text buffer to a file (optional)
    ; For now, just exit
    mov si, exit_msg
    call print_string
    ret

welcome_msg db 'Welcome to ViText :3', 13, 10, 0
editor_instructions db 'Enter text (ESC to exit, Backspace to delete):', 13, 10, 0
exit_msg db 13, 10, 'Exiting text editor.', 13, 10, 0

; Text buffer (1 KB)
text_buffer times 1024 db 0