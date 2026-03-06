[org 0x4000]    ; 加载到 0x4000:0x0000
[bits 16]

start:
    ; 设置段
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; 设置图形模式
    mov ax, 0x0013
    int 0x10

    ; 初始化文本缓冲区
    call init_text_buffer
    
    ; 绘制界面
    call draw_notepad_ui
    
    ; 主循环
    jmp notepad_loop

init_text_buffer:
    mov di, text_buffer
    mov cx, 1000        ; 1000字符容量
    mov al, ' '
    rep stosb
    mov byte [text_buffer], 0
    mov word [cursor_pos], 0
    mov word [scroll_offset], 0
    ret

draw_notepad_ui:
    ; 绘制背景
    mov cx, 0
    mov dx, 0
    mov si, 320
    mov di, 200
    mov al, 7      ; 浅灰色
    call draw_rectangle

    ; 绘制标题栏
    mov cx, 0
    mov dx, 0
    mov si, 320
    mov di, 15
    mov al, 1      ; 蓝色
    call draw_rectangle

    ; 标题
    mov si, title
    mov cx, 10
    mov dx, 3
    mov bl, 15     ; 白色
    call print_string_graphic

    ; 绘制菜单栏
    mov cx, 0
    mov dx, 15
    mov si, 320
    mov di, 15
    mov al, 8      ; 深灰色
    call draw_rectangle

    ; 菜单项
    mov si, file_menu
    mov cx, 5
    mov dx, 18
    mov bl, 15
    call print_string_graphic

    mov si, edit_menu
    mov cx, 40
    mov dx, 18
    call print_string_graphic

    ; 绘制文本区域
    mov cx, 5
    mov dx, 35
    mov si, 310
    mov di, 160
    mov al, 15     ; 白色
    call draw_rectangle

    ; 显示状态栏
    mov si, status_msg
    mov cx, 5
    mov dx, 185
    mov bl, 0
    call print_string_graphic

    ; 显示初始文本
    call display_text
    call update_cursor
    
    ret

notepad_loop:
    ; 检查输入
    mov ah, 0x01
    int 0x16
    jz notepad_loop
    
    mov ah, 0x00
    int 0x16
    
    ; 处理特殊键
    cmp ah, 0x0E    ; 退格键
    je .backspace
    cmp ah, 0x1C    ; 回车键
    je .newline
    cmp ah, 0x4B    ; 左箭头
    je .left_arrow
    cmp ah, 0x4D    ; 右箭头
    je .right_arrow
    cmp al, 27      ; ESC
    je .exit
    
    ; 处理可打印字符
    cmp al, 32      ; 空格
    jb notepad_loop
    cmp al, 126     ; ~
    ja notepad_loop
    
    call insert_char
    jmp notepad_loop

.backspace:
    call delete_char
    jmp notepad_loop

.newline:
    mov al, 0x0D
    call insert_char
    jmp notepad_loop

.left_arrow:
    cmp word [cursor_pos], 0
    je notepad_loop
    dec word [cursor_pos]
    call update_cursor
    jmp notepad_loop

.right_arrow:
    mov si, text_buffer
    add si, [cursor_pos]
    cmp byte [si], 0
    je notepad_loop
    inc word [cursor_pos]
    call update_cursor
    jmp notepad_loop

.exit:
    ; 返回内核
    jmp 0x2000:0x0000

insert_char:
    ; al包含要插入的字符
    mov si, text_buffer
    add si, [cursor_pos]
    
    ; 检查缓冲区是否已满
    mov bx, si
    sub bx, text_buffer
    cmp bx, 999
    jge .done
    
    ; 移动后续字符
    mov di, si
    inc di
    mov cx, 1000
    sub cx, bx
    std
    rep movsb
    cld
    
    ; 插入新字符
    mov [si], al
    inc word [cursor_pos]
    
    ; 重绘文本
    call display_text
    call update_cursor
.done:
    ret

delete_char:
    cmp word [cursor_pos], 0
    je .done
    
    dec word [cursor_pos]
    mov si, text_buffer
    add si, [cursor_pos]
    
    ; 移动后续字符覆盖当前位置
    mov di, si
    inc si
    mov cx, 1000
    sub cx, [cursor_pos]
    cld
    rep movsb
    
    ; 重绘文本
    call display_text
    call update_cursor
.done:
    ret

display_text:
    ; 清除文本区域
    mov cx, 6
    mov dx, 36
    mov si, 308
    mov di, 158
    mov al, 15
    call draw_rectangle
    
    ; 显示文本
    mov si, text_buffer
    mov cx, 10      ; X位置
    mov dx, 40      ; Y位置
    mov bl, 0       ; 黑色
    
.display_loop:
    cmp byte [si], 0
    je .done
    
    ; 处理换行
    cmp byte [si], 0x0D
    je .newline
    
    ; 显示字符
    push si
    push cx
    push dx
    push bx
    
    mov ah, 0x02    ; 设置光标
    mov bh, 0
    int 0x10
    
    mov ah, 0x0e    ; 输出字符
    mov al, [si]
    int 0x10
    
    pop bx
    pop dx
    pop cx
    pop si
    
    add cx, 8       ; 字符宽度
    
    ; 检查是否超出边界
    cmp cx, 300
    jb .next_char
    
.newline:
    mov cx, 10      ; 重置X
    add dx, 10      ; 下一行
    
    ; 检查是否超出底部
    cmp dx, 180
    jae .done
    
.next_char:
    inc si
    jmp .display_loop

.done:
    ret

update_cursor:
    ; 计算光标位置（简化版）
    ; 在实际实现中，需要根据光标位置计算屏幕坐标
    mov si, status_cursor
    mov ax, [cursor_pos]
    mov di, cursor_pos_str
    call word_to_ascii
    
    ; 更新状态栏
    mov cx, 150
    mov dx, 185
    mov si, 100
    mov di, 10
    mov al, 7
    call draw_rectangle
    
    mov si, status_cursor
    mov cx, 150
    mov dx, 185
    mov bl, 0
    call print_string_graphic
    
    ret

; 图形函数（与计算器相同）
draw_rectangle:
    pusha
    mov bx, cx
.vertical:
    mov cx, bx
    push di
    mov di, si
.horizontal:
    call draw_pixel
    inc cx
    dec di
    jnz .horizontal
    pop di
    inc dx
    dec di
    jnz .vertical
    popa
    ret

draw_pixel:
    pusha
    mov ah, 0x0c
    mov bh, 0
    int 0x10
    popa
    ret

print_string_graphic:
    pusha
    mov ah, 0x02
    mov bh, 0
    int 0x10
    
    mov ah, 0x0e
.print_loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    popa
    ret

word_to_ascii:
    pusha
    mov cx, 0
    mov bx, 10
.convert_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .convert_loop
    
.pop_loop:
    pop ax
    add al, '0'
    mov [di], al
    inc di
    loop .pop_loop
    mov byte [di], 0
    popa
    ret

; 数据区
title db 'Notepad', 0
file_menu db 'File', 0
edit_menu db 'Edit', 0
status_msg db 'Press ESC to exit', 0
status_cursor db 'Pos: '
cursor_pos_str times 6 db 0

text_buffer times 1001 db 0
cursor_pos dw 0
scroll_offset dw 0

times 4096-($-$$) db 0