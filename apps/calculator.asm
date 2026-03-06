[org 0x3000]    ; 加载到 0x3000:0x0000
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

    ; 绘制计算器界面
    call draw_calculator_ui
    
    ; 主循环
    jmp calculator_loop

draw_calculator_ui:
    ; 绘制背景
    mov cx, 0
    mov dx, 0
    mov si, 320
    mov di, 200
    mov al, 8      ; 深灰色
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

    ; 绘制显示屏
    mov cx, 20
    mov dx, 25
    mov si, 280
    mov di, 30
    mov al, 7      ; 浅灰色
    call draw_rectangle

    ; 绘制按钮网格
    mov cx, 30
    mov dx, 70
    mov si, 260
    mov di, 120
    mov al, 15     ; 白色
    call draw_rectangle

    ; 绘制数字按钮
    mov bx, 0      ; 按钮计数器
.draw_buttons:
    ; 计算按钮位置
    mov ax, bx
    mov cl, 3
    div cl         ; al = 行, ah = 列
    
    mov cx, 40     ; 起始X
    mov dx, 80     ; 起始Y
    
    ; 计算X位置
    push ax
    mov al, ah
    mov ah, 0
    mov si, 50     ; 按钮宽度+间距
    mul si
    add cx, ax
    pop ax
    
    ; 计算Y位置
    push ax
    mov al, al
    mov ah, 0
    mov si, 25     ; 按钮高度+间距
    mul si
    add dx, ax
    pop ax
    
    ; 绘制按钮
    push cx
    push dx
    mov si, 40     ; 宽度
    mov di, 20     ; 高度
    mov al, 7      ; 浅灰色
    call draw_rectangle
    
    ; 按钮边框
    pop dx
    pop cx
    push cx
    push dx
    mov si, 40
    mov di, 20
    mov al, 8      ; 深灰色边框
    call draw_rectangle_border
    
    ; 按钮标签
    pop dx
    pop cx
    add cx, 15
    add dx, 5
    mov al, bl
    add al, '0'
    mov [button_char], al
    mov si, button_char
    mov bl, 0      ; 黑色
    call print_string_graphic
    
    inc bx
    cmp bx, 9
    jle .draw_buttons

    ; 绘制操作符按钮
    mov cx, 190
    mov dx, 80
    mov si, button_labels
.draw_operators:
    mov al, [si]
    test al, al
    jz .draw_done
    
    push si
    push cx
    push dx
    
    ; 绘制按钮
    mov si, 40
    mov di, 20
    mov al, 14     ; 黄色
    call draw_rectangle
    
    ; 边框
    pop dx
    pop cx
    push cx
    push dx
    mov si, 40
    mov di, 20
    mov al, 8
    call draw_rectangle_border
    
    ; 标签
    pop dx
    pop cx
    pop si
    push si
    push cx
    push dx
    
    add cx, 15
    add dx, 5
    mov bl, 0
    call print_string_graphic
    
    pop dx
    pop cx
    pop si
    
    add dx, 25     ; 下一个按钮位置
    inc si
    jmp .draw_operators

.draw_done:
    ; 显示初始值
    mov si, display_value
    mov cx, 25
    mov dx, 35
    mov bl, 0
    call print_string_graphic
    
    ret

calculator_loop:
    ; 更新显示
    call update_display
    
    ; 检查输入
    mov ah, 0x01
    int 0x16
    jz calculator_loop
    
    mov ah, 0x00
    int 0x16
    
    ; 处理数字
    cmp al, '0'
    jb .check_operator
    cmp al, '9'
    ja .check_operator
    
    ; 添加到当前输入
    call input_digit
    jmp calculator_loop

.check_operator:
    cmp al, '+'
    je .set_operator
    cmp al, '-'
    je .set_operator  
    cmp al, '*'
    je .set_operator
    cmp al, '/'
    je .set_operator
    cmp al, '='
    je .calculate
    cmp al, 'c'
    je .clear
    cmp al, 27     ; ESC
    je .exit
    
    jmp calculator_loop

.set_operator:
    mov [operator], al
    mov ax, [current_value]
    mov [stored_value], ax
    mov word [current_value], 0
    jmp calculator_loop

.calculate:
    call perform_calculation
    jmp calculator_loop

.clear:
    mov word [current_value], 0
    mov word [stored_value], 0
    mov byte [operator], 0
    jmp calculator_loop

.exit:
    ; 返回内核
    jmp 0x2000:0x0000

input_digit:
    ; al包含数字字符
    sub al, '0'
    mov bl, al
    mov ax, [current_value]
    mov cx, 10
    mul cx
    add ax, bx
    mov [current_value], ax
    ret

perform_calculation:
    mov ax, [stored_value]
    mov bx, [current_value]
    
    cmp byte [operator], '+'
    je .add
    cmp byte [operator], '-'
    je .sub
    cmp byte [operator], '*'
    je .mul
    cmp byte [operator], '/'
    je .div
    ret

.add:
    add ax, bx
    jmp .store_result

.sub:
    sub ax, bx
    jmp .store_result

.mul:
    mul bx
    jmp .store_result

.div:
    cmp bx, 0
    je .div_zero
    xor dx, dx
    div bx
    jmp .store_result

.div_zero:
    mov si, error_msg
    mov cx, 25
    mov dx, 35
    mov bl, 4      ; 红色
    call print_string_graphic
    ret

.store_result:
    mov [current_value], ax
    mov word [stored_value], 0
    mov byte [operator], 0
    ret

update_display:
    ; 清除显示区域
    mov cx, 25
    mov dx, 35
    mov si, 270
    mov di, 10
    mov al, 7
    call draw_rectangle
    
    ; 转换数字为字符串
    mov ax, [current_value]
    mov di, display_buffer
    call word_to_ascii
    
    ; 显示数字
    mov si, display_buffer
    mov cx, 25
    mov dx, 35
    mov bl, 0
    call print_string_graphic
    
    ret

; 将word转换为ASCII字符串
; ax = 数字, di = 目标缓冲区
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

; 绘制矩形边框
; cx,dx = 位置, si=宽度, di=高度, al=颜色
draw_rectangle_border:
    pusha
    ; 上边框
    push cx
    push dx
    push si
    mov di, 1
    call draw_rectangle
    pop si
    pop dx
    pop cx
    
    ; 下边框
    push cx
    push dx
    add dx, 19     ; 高度-1
    mov di, 1
    call draw_rectangle
    pop dx
    pop cx
    
    ; 左边框
    push cx
    push dx
    mov si, 1
    mov di, 20
    call draw_rectangle
    pop dx
    pop cx
    
    ; 右边框
    push cx
    push dx
    add cx, 39     ; 宽度-1
    mov si, 1
    mov di, 20
    call draw_rectangle
    pop dx
    pop cx
    popa
    ret

; 图形函数（需要从内核复制）
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

; 数据区
title db 'Calculator', 0
button_labels db '+', '-', '*', '/', '=', 0
display_value db '0', 0
error_msg db 'Error', 0

current_value dw 0
stored_value dw 0
operator db 0
button_char db 0, 0
display_buffer times 16 db 0

times 4096-($-$$) db 0