[bits 32]

; 内核入口点
global kernel_main

; 外部函数声明
extern main

kernel_main:
    ; 初始化保护模式环境
    call init_protected_mode
    
    ; 调用C主函数
    call main
    
    ; 挂起系统
    jmp $

init_protected_mode:
    ; 初始化保护模式所需组件
    call init_video
    call init_memory_manager
    call init_interrupts
    ret

init_video:
    ; 初始化VGA文本模式
    mov edi, 0xB8000    ; VGA文本缓冲区
    mov ecx, 80*25      ; 80x25字符
    mov ah, 0x0F        ; 白字黑底
    mov al, ' '
    rep stosw
    ret

init_memory_manager:
    ; 初始化内存管理器
    ; 这里会设置分页和内存映射
    ret

init_interrupts:
    ; 初始化中断描述符表
    ret

; 简单的保护模式打印函数
print_string_pm:
    pusha
    mov edx, 0xB8000    ; VGA文本缓冲区
.loop:
    mov al, [ebx]
    mov ah, 0x0F
    cmp al, 0
    je .done
    mov [edx], ax
    add ebx, 1
    add edx, 2
    jmp .loop
.done:
    popa
    ret

; 数据区
section .data
welcome_msg db 'Protected Mode Kernel Loaded!', 0

section .bss
; 内核堆栈
resb 8192
kernel_stack: