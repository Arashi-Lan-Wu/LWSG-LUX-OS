[org 0x7c00]
[bits 16]

start:
    ; 设置段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; 保存启动驱动器号
    mov [boot_drive], dl

    ; 清屏
    mov ax, 0x0003
    int 0x10

    ; 显示启动信息
    mov si, boot_msg
    call print_string

    ; 检测内存
    call detect_memory

    ; 加载第二阶段加载器
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, 64          ; 读取64个扇区（32KB）
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13

    jc disk_error

    ; 跳转到第二阶段
    jmp 0x1000:0x0000

detect_memory:
    ; 简单内存检测
    mov si, memory_msg
    call print_string
    
    mov ah, 0x88
    int 0x15
    jc .memory_error
    
    mov [extended_memory_kb], ax
    mov si, memory_found
    call print_string
    mov ax, [extended_memory_kb]
    call print_dec_word
    mov si, kb_msg
    call print_string
    ret

.memory_error:
    mov word [extended_memory_kb], 4096
    mov si, memory_default
    call print_string
    ret

disk_error:
    mov si, error_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

print_dec_word:
    ; 打印AX中的十进制数
    pusha
    mov bx, 10
    mov cx, 0
.div_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .div_loop
.print_loop:
    pop ax
    add al, '0'
    mov ah, 0x0e
    int 0x10
    loop .print_loop
    popa
    ret

; 数据区
boot_drive db 0
extended_memory_kb dw 0

boot_msg db 'LUX OS - Full Edition', 0x0d, 0x0a, 0
memory_msg db 'Memory: ', 0
memory_found db 'Found ', 0
memory_default db 'Default 4096', 0
error_msg db 'Disk Error!', 0
kb_msg db ' KB', 0x0d, 0x0a, 0

times 510-($-$$) db 0
dw 0xaa55