BITS 16
ORG 0x5000

extern print_string
extern read_string
extern strcmp
extern clear_screen
extern print_decimal
extern new_line

start:
    mov si, welcome_msg
    call print_string
    call text_editor
    ret

text_editor:
    call clear_screen

    mov si, editor_instructions
    call print_string

    mov di, text_buffer  ; Ponteiro para buffer de texto
    mov cx, 0            ; Contador de caracteres

.edit_loop:
    hlt                  ; Aguarda interrupção para reduzir uso da CPU

    mov ah, 0
    int 0x16             ; Espera tecla

    cmp al, 8
    je .backspace
    cmp al, 13
    je .newline
    cmp al, 27
    je .exit_editor

    cmp cx, 1024        ; Se buffer cheio, ignora entrada
    jae .edit_loop

    mov ah, 0x0E
    int 0x10
    stosb               ; Armazena caractere no buffer
    inc cx
    jmp .edit_loop

.backspace:
    cmp cx, 0
    je .edit_loop
    dec di
    dec cx
    mov byte [di], 0

    ; Efeito visual do backspace
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .edit_loop

.newline:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

    mov byte [di], 13
    inc di
    mov byte [di], 10
    inc di
    add cx, 2
    jmp .edit_loop

.exit_editor:
    mov si, exit_msg
    call print_string
    ret

welcome_msg db 'Welcome to ViText :3', 13, 10, 0
editor_instructions db 'Enter text (ESC to exit, Backspace to delete):', 13, 10, 0
exit_msg db 13, 10, 'Exiting text editor.', 13, 10, 0

text_buffer times 1024 db 0