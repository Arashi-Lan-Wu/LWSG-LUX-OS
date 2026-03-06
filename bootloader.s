; bootloader.s - 最小化OS的16位引导加载程序
; NASM语法版本

[BITS 16]          ; 指示汇编器生成16位模式的代码
[ORG 0x7C00]       ; 引导程序加载到0x7C00

_start:
    ; 初始化段寄存器
    xor     ax, ax          ; 清零AX寄存器
    mov     ds, ax          ; 数据段寄存器DS = 0
    mov     es, ax          ; 附加段寄存器ES = 0
    mov     ss, ax          ; 栈段寄存器SS = 0
    mov     sp, 0x7C00      ; 栈指针SP设置为0x7c00

    ; 打印引导信息
    mov     si, msg_boot    ; 将消息字符串的偏移地址加载到SI
    call    print_string    ; 调用打印字符串子程序

    ; 从磁盘加载内核
    mov     ah, 0x02        ; INT 0x13, AH=0x02 表示"读扇区"功能
    mov     al, 0x01        ; AL=1 表示要读取1个扇区
    mov     ch, 0x00        ; CH=0x00 表示柱面号（Cylinder）为0
    mov     cl, 0x02        ; CL=0x02 表示扇区号（Sector）为2
    mov     dh, 0x00        ; DH=0x00 表示磁头号（Head）为0
    mov     dl, 0x80        ; DL=0x80 表示驱动器号（Drive）
    mov     bx, 0x8000      ; ES:BX 是目标内存地址
    mov     es, bx          ; 将ES设置为0x8000
    xor     bx, bx          ; BX清零，使ES:BX = 0x8000:0x0000
    int     0x13            ; 调用BIOS中断，执行磁盘读取

    jc      disk_error      ; 如果CF置位，表示读取错误

    ; 跳转到内核
    push    0x8000          ; 推送段地址到栈
    push    0x0000          ; 推送偏移地址到栈
    retf                    ; 远返回，实现跳转到8000h:0000h

; --- 辅助子程序 ---

; print_string: 打印SI指向的字符串到屏幕
print_string:
    push    ax
.print_loop:
    lodsb                   ; 从DS:SI加载一个字节到AL，并递增SI
    or      al, al          ; 如果AL为0，则为字符串结束符
    jz      .done           ; 跳转到.done
    mov     ah, 0x0E        ; AH=0x0e 是BIOS中断 0x10 的TTY输出功能
    int     0x10            ; 调用BIOS中断，在屏幕上显示字符
    jmp     .print_loop     ; 继续打印下一个字符
.done:
    pop     ax
    ret

; disk_error: 磁盘读取错误处理
disk_error:
    mov     si, msg_error   ; 加载错误消息
    call    print_string    ; 打印错误消息
    jmp     $               ; 死循环，停止系统

; --- 数据段 ---
msg_boot:
    db  "Bootloader loaded! Loading kernel...", 0x0D, 0x0A, 0x00
msg_error:
    db  "Disk read error!", 0x0D, 0x0A, 0x00

; --- 填充与魔术数字 ---
; 引导扇区必须是512字节，并且最后两个字节必须是 0x55AA
times 510-($-$$) db 0       ; 填充剩余空间为0
dw 0xAA55                   ; 写入魔术数字