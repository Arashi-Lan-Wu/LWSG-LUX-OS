[org 0x5000]    ; 加载到 0x5000:0x0000
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

    ; 初始化文件列表
    call init_file_list
    
    ; 绘制界面
    call draw_filemgr_ui
    
    ; 主循环
    jmp filemgr_loop

init_file_list:
    ; 初始化模拟文件系统
    mov si, file_list
    mov di, file1
    call copy_string
    mov si, file_list + 16
    mov di, file2
    call copy_string
    mov si, file_list + 32
    mov di, file3
    call copy_string
    mov si, file_list + 48
    mov di, file4
    call copy_string
    
    mov word [selected_file], 0
    mov word [scroll_offset], 0
    ret

copy_string:
    pusha
.copy_loop:
    mov al, [di]
    mov [si], al
    inc si
    inc di
    test al, al
    jnz .copy_loop
    popa
    ret

draw_filemgr_ui:
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

    mov si, view_menu
    mov cx, 40
    mov dx, 18
    call print_string_graphic

    ; 绘制文件列表区域
    mov cx, 10
    mov dx, 35
    mov si, 300
    mov di, 140
    mov al, 15     ; 白色
    call draw_rectangle

    ; 绘制状态栏
    mov cx, 0
    mov dx, 180
    mov si, 320
    mov di, 20
    mov al, 8      ; 深灰色
    call draw_rectangle

    ; 状态信息
    mov si, status_msg
    mov cx, 5
    mov dx, 185
    mov bl, 15
    call print_string_graphic

    ; 显示文件列表
    call display_file_list
    
    ret

filemgr_loop:
    ; 检查输入
    mov ah, 0x01
    int 0x16
    jz filemgr_loop
    
    mov ah, 0x00
    int 0x16
    
    ; 处理按键
    cmp ah, 0x48    ; 上箭头
    je .up_arrow
    cmp ah, 0x50    ; 下箭头
    je .down_arrow
    cmp al, 0x0D    ; 回车
    je .open_file
    cmp al, 'n'     ; 新建文件
    je .new_file
    cmp al, 'd'     ; 删除文件
    je .delete_file
    cmp al, 27      ; ESC
    je .exit
    
    jmp filemgr_loop

.up_arrow:
    cmp word [selected_file], 0
    je filemgr_loop
    dec word [selected_file]
    call display_file_list
    jmp filemgr_loop

.down_arrow:
    cmp word [selected_file], 3    ; 总共4个文件
    jge filemgr_loop
    inc word [selected_file]
    call display_file_list
    jmp filemgr_loop

.open_file:
    ; 在这里可以添加打开文件的逻辑
    ; 现在只是显示消息
    mov si, open_msg
    mov cx, 100
    mov dx, 160
    mov bl, 2      ; 绿色
    call print_string_graphic
    jmp filemgr_loop

.new_file:
    ; 添加新文件（模拟）
    mov si, new_file_msg
    mov cx, 100
    mov dx, 160
    mov bl, 2
    call print_string_graphic
    jmp filemgr_loop

.delete_file:
    ; 删除文件（模拟）
    mov si, delete_msg
    mov cx, 100
    mov dx, 160
    mov bl, 4      ; 红色
    call print_string_graphic
    jmp filemgr_loop

.exit:
    ; 返回内核
    jmp 0x2000:0x0000

display_file_list:
    ; 清除文件列表区域
    mov cx, 11
    mov dx, 36
    mov si, 298
    mov di, 138
    mov al, 15
    call draw_rectangle
    
    ; 显示文件列表
    mov cx, 15      ; X位置
    mov dx, 40      ; Y位置
    mov bx, 0       ; 文件索引
    
.display_loop:
    cmp bx, 4       ; 显示4个文件
    jge .done
    
    ; 计算文件项位置
    push bx
    mov ax, bx
    mov si, 20      ; 行高
    mul si
    add dx, ax
    pop bx
    
    ; 检查是否为选中文件
    cmp bx, [selected_file]
    jne .normal_file
    
    ; 绘制选中背景
    push cx
    push dx
    push bx
    sub cx, 2
    sub dx, 2
    mov si, 290
    mov di, 15
    mov al, 9       ; 浅蓝色背景
    call draw_rectangle
    pop bx
    pop dx
    pop cx
    
.normal_file:
    ; 显示文件图标和名称
    push bx
    push cx
    push dx
    
    ; 文件图标
    mov si, file_icon
    mov bl, 0       ; 黑色
    call print_string_graphic
    
    ; 文件名
    pop dx
    pop cx
    push cx
    push dx
    add cx, 20
    
    ; 计算文件名地址
    mov ax, bx
    mov si, 16      ; 每个文件名16字节
    mul si
    mov si, file_list
    add si, ax
    
    mov bl, 0
    call print_string_graphic
    
    pop dx
    pop cx
    pop bx
    
    inc bx
    mov dx, 40      ; 重置Y
    jmp .display_loop

.done:
    ; 更新状态栏
    call update_status
    ret

update_status:
    ; 显示选中文件信息
    mov cx, 150
    mov dx, 185
    mov si, 150
    mov di, 10
    mov al, 8
    call draw_rectangle
    
    mov si, selected_msg
    mov cx, 150
    mov dx, 185
    mov bl, 15
    call print_string_graphic
    
    ; 显示文件索引
    mov ax, [selected_file]
    inc ax
    mov di, file_index_str
    call byte_to_ascii
    
    mov si, file_index_str
    mov cx, 200
    mov dx, 185
    mov bl, 15
    call print_string_graphic
    
    ret

byte_to_ascii:
    pusha
    mov bl, 10
    div bl
    add al, '0'
    mov [di], al
    inc di
    add ah, '0'
    mov [di], ah
    inc di
    mov byte [di], 0
    popa
    ret

; 图形函数（与前面相同）
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
title db 'File Manager', 0
file_menu db 'File', 0
view_menu db 'View', 0
status_msg db 'Use arrows to navigate, Enter to open, ESC to exit', 0
selected_msg db 'Selected: ', 0
file_icon db '> ', 0
open_msg db 'Opening file...', 0
new_file_msg db 'Creating new file...', 0
delete_msg db 'Deleting file...', 0

; 模拟文件列表
file1 db 'system.os', 0
file2 db 'notes.txt', 0
file3 db 'boot_loader.asm', 0
file4 db 'kernel.asm', 0

file_list times 64 db 0    ; 4个文件 * 16字节
selected_file dw 0
scroll_offset dw 0
file_index_str times 3 db 0

times 4096-($-$$) db 0