[org 0x0000]
[bits 16]

start:
    ; 设置段
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; 清屏
    mov ax, 0x0003
    int 0x10

    ; 显示加载信息
    mov si, loader_msg
    call print_string

    ; 加载GDT
    call load_gdt

    ; 启用A20线
    call enable_a20

    ; 切换到保护模式
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转到保护模式
    jmp CODE_SEG:protected_mode_start

[bits 32]
protected_mode_start:
    ; 设置段寄存器
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; 初始化内核
    call kernel_main

    ; 挂起
    jmp $

[bits 16]
enable_a20:
    ; 通过键盘控制器启用A20
    call .wait
    mov al, 0xad
    out 0x64, al
    
    call .wait
    mov al, 0xd0
    out 0x64, al
    
    call .wait2
    in al, 0x60
    push eax
    
    call .wait
    mov al, 0xd1
    out 0x64, al
    
    call .wait
    pop eax
    or al, 2
    out 0x60, al
    
    call .wait
    mov al, 0xae
    out 0x64, al
    ret

.wait:
    in al, 0x64
    test al, 2
    jnz .wait
    ret

.wait2:
    in al, 0x64
    test al, 1
    jz .wait2
    ret

load_gdt:
    lgdt [gdt_descriptor]
    ret

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

; GDT
gdt_start:
    dq 0

gdt_code:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

loader_msg db 'Loading Full PMOS Kernel...', 0x0d, 0x0a, 0

times 8192-($-$$) db 0