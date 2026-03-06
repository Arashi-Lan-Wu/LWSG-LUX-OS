[bits 32]

; 内核入口点
kernel_main:
    ; 初始化系统
    call init_system
    
    ; 显示欢迎信息
    mov ebx, welcome_msg
    call print_string_pm
    
    ; 显示系统信息
    mov ebx, system_info
    call print_string_pm
    
    ; 初始化文件系统
    call init_filesystem
    
    ; 进入主循环
    call main_loop
    
    ret

init_system:
    ; 清屏
    call clear_screen_32
    
    ; 初始化键盘缓冲区
    mov dword [keyboard_buffer_pos], 0
    mov byte [input_buffer], 0
    
    ; 初始化应用程序状态
    mov dword [current_app], 0
    mov dword [file_cursor], 0
    
    ret

init_filesystem:
    ; 初始化简单的文件系统结构
    ; 在实际实现中，这里会读取磁盘上的文件系统
    ; 现在使用内存中的模拟文件系统
    
    ; 创建示例文件
    mov esi, sample_file1_name
    mov edi, file1_name
    call copy_string_32
    
    mov esi, sample_file1_content
    mov edi, file1_content
    call copy_string_32
    
    mov esi, sample_file2_name
    mov edi, file2_name
    call copy_string_32
    
    mov esi, sample_file2_content
    mov edi, file2_content
    call copy_string_32
    
    mov dword [file_count], 2
    
    ret

main_loop:
    ; 显示主菜单
    call show_main_menu
    
.menu_loop:
    ; 等待用户输入
    call wait_for_key
    
    ; 处理按键
    cmp al, '1'
    je .launch_calc
    cmp al, '2'
    je .launch_editor
    cmp al, '3'
    je .launch_filemgr
    cmp al, '4'
    je .show_info
    cmp al, '0'
    je .reboot
    
    jmp .menu_loop

.launch_calc:
    call calculator_app
    jmp main_loop

.launch_editor:
    call text_editor_app
    jmp main_loop

.launch_filemgr:
    call file_manager_app
    jmp main_loop

.show_info:
    call show_system_info_app
    jmp main_loop

.reboot:
    ; 重启系统
    jmp 0xffff:0x0000

; === 主菜单显示 ===
show_main_menu:
    call clear_screen_32
    
    mov ebx, menu_title
    call print_string_pm
    
    mov ebx, menu_calc
    call print_string_pm
    
    mov ebx, menu_editor
    call print_string_pm
    
    mov ebx, menu_filemgr
    call print_string_pm
    
    mov ebx, menu_info
    call print_string_pm
    
    mov ebx, menu_reboot
    call print_string_pm
    
    mov ebx, menu_prompt
    call print_string_pm
    
    ret

; === 计算器应用 ===
calculator_app:
    call clear_screen_32
    mov ebx, calc_title
    call print_string_pm
    
.calc_loop:
    mov ebx, calc_prompt
    call print_string_pm
    
    ; 读取输入
    call read_input_32
    mov esi, input_buffer
    
    ; 检查退出命令
    cmp byte [esi], 'q'
    je .exit
    cmp byte [esi], 'Q'
    je .exit
    
    ; 简单的表达式计算（这里可以扩展）
    mov ebx, calc_result
    call print_string_pm
    mov ebx, input_buffer
    call print_string_pm
    mov ebx, newline
    call print_string_pm
    
    jmp .calc_loop

.exit:
    ret

; === 文本编辑器应用 ===
text_editor_app:
    call clear_screen_32
    mov ebx, editor_title
    call print_string_pm
    
    mov ebx, editor_help
    call print_string_pm
    
    ; 显示文件列表
    mov ebx, editor_file_list
    call print_string_pm
    
    mov dword [file_cursor], 0
    call list_files
    
    mov ebx, editor_prompt
    call print_string_pm
    
    ; 读取文件名
    call read_input_32
    
    ; 查找文件
    mov esi, input_buffer
    call find_file
    cmp eax, 0
    jne .file_found
    
    ; 文件不存在，创建新文件
    mov ebx, editor_new_file
    call print_string_pm
    mov esi, input_buffer
    call create_file
    jmp .edit_file

.file_found:
    ; 文件存在，加载内容
    mov ebx, editor_loading
    call print_string_pm
    
.edit_file:
    call clear_screen_32
    mov ebx, editor_editing
    call print_string_pm
    mov ebx, input_buffer
    call print_string_pm
    mov ebx, newline
    call print_string_pm
    
    ; 显示文件内容
    mov esi, input_buffer
    call find_file
    cmp eax, 0
    je .empty_file
    
    ; 显示现有内容
    mov ebx, eax
    call print_string_pm
    
.empty_file:
    mov ebx, editor_content
    call print_string_pm
    
    ; 读取编辑内容
    call read_input_32
    
    ; 保存文件
    mov esi, input_buffer
    mov edi, file_content_buffer
    call copy_string_32
    
    mov ebx, editor_saved
    call print_string_pm
    
    call wait_for_key
    ret

; === 文件管理器应用 ===
file_manager_app:
    call clear_screen_32
    mov ebx, filemgr_title
    call print_string_pm
    
.filemgr_loop:
    mov ebx, filemgr_help
    call print_string_pm
    
    ; 显示文件列表
    call list_files
    
    mov ebx, filemgr_prompt
    call print_string_pm
    
    ; 读取命令
    call read_input_32
    mov esi, input_buffer
    
    ; 处理命令
    cmp byte [esi], 'q'
    je .exit
    cmp byte [esi], 'Q'
    je .exit
    cmp byte [esi], 'c'
    je .create_file
    cmp byte [esi], 'd'
    je .delete_file
    cmp byte [esi], 'v'
    je .view_file
    
    mov ebx, filemgr_unknown
    call print_string_pm
    jmp .filemgr_loop

.create_file:
    mov ebx, filemgr_create_prompt
    call print_string_pm
    call read_input_32
    mov esi, input_buffer
    call create_file
    mov ebx, filemgr_created
    call print_string_pm
    jmp .filemgr_loop

.delete_file:
    mov ebx, filemgr_delete_prompt
    call print_string_pm
    call read_input_32
    mov esi, input_buffer
    call delete_file
    mov ebx, filemgr_deleted
    call print_string_pm
    jmp .filemgr_loop

.view_file:
    mov ebx, filemgr_view_prompt
    call print_string_pm
    call read_input_32
    mov esi, input_buffer
    call find_file
    cmp eax, 0
    je .file_not_found
    
    mov ebx, filemgr_viewing
    call print_string_pm
    mov ebx, eax
    call print_string_pm
    mov ebx, newline
    call print_string_pm
    jmp .filemgr_loop

.file_not_found:
    mov ebx, filemgr_not_found
    call print_string_pm
    jmp .filemgr_loop

.exit:
    ret

; === 系统信息应用 ===
show_system_info_app:
    call clear_screen_32
    mov ebx, info_title
    call print_string_pm
    
    mov ebx, info_memory
    call print_string_pm
    
    mov ebx, info_features
    call print_string_pm
    
    mov ebx, info_apps
    call print_string_pm
    
    call wait_for_key
    ret

; === 文件系统操作 ===
list_files:
    ; 显示所有文件
    mov ecx, 0
.list_loop:
    cmp ecx, [file_count]
    jge .list_done
    
    ; 计算文件名地址
    mov eax, ecx
    mov edx, 64  ; 每个文件条目64字节
    mul edx
    add eax, file1_name
    
    ; 显示文件名
    mov ebx, file_list_prefix
    call print_string_pm
    mov ebx, eax
    call print_string_pm
    mov ebx, newline
    call print_string_pm
    
    inc ecx
    jmp .list_loop

.list_done:
    ret

find_file:
    ; esi = 文件名
    ; 返回: eax = 文件内容地址，0表示未找到
    mov ecx, 0
.find_loop:
    cmp ecx, [file_count]
    jge .not_found
    
    ; 计算文件名地址
    mov eax, ecx
    mov edx, 64
    mul edx
    mov edi, eax
    add edi, file1_name
    
    ; 比较文件名
    push esi
    push edi
    call compare_string_32
    pop edi
    pop esi
    jc .found
    
    inc ecx
    jmp .find_loop

.found:
    ; 计算内容地址
    mov eax, ecx
    mov edx, 64
    mul edx
    add eax, file1_content
    ret

.not_found:
    mov eax, 0
    ret

create_file:
    ; esi = 文件名
    ; 创建新文件
    mov ecx, [file_count]
    cmp ecx, MAX_FILES
    jge .full
    
    ; 计算存储位置
    mov eax, ecx
    mov edx, 64
    mul edx
    mov edi, eax
    add edi, file1_name
    
    ; 复制文件名
    call copy_string_32
    
    ; 清空文件内容
    mov eax, ecx
    mov edx, 64
    mul edx
    add eax, file1_content
    mov byte [eax], 0
    
    ; 增加文件计数
    inc dword [file_count]
    
.full:
    ret

delete_file:
    ; esi = 文件名
    ; 删除文件（简化版，只是清空文件名）
    call find_file
    cmp eax, 0
    je .not_found
    
    ; 计算文件名地址
    sub eax, file1_content
    add eax, file1_name
    mov byte [eax], 0
    
    ; 减少文件计数
    dec dword [file_count]
    
.not_found:
    ret

; === 工具函数 ===
clear_screen_32:
    mov edi, 0xb8000
    mov ecx, 80*25
    mov ax, 0x0f20  ; 白字黑底空格
    rep stosw
    mov dword [cursor_pos], 0
    ret

print_string_pm:
    pusha
    mov edx, 0xb8000
    mov eax, [cursor_pos]
    shl eax, 1      ; 每个字符2字节
    add edx, eax
.loop:
    mov al, [ebx]
    mov ah, 0x0f
    cmp al, 0
    je .done
    cmp al, 10      ; 换行
    je .newline
    mov [edx], ax
    add ebx, 1
    add edx, 2
    inc dword [cursor_pos]
    jmp .loop

.newline:
    ; 移动到下一行
    mov eax, [cursor_pos]
    mov ebx, 80
    xor edx, edx
    div ebx
    inc eax
    mul ebx
    mov [cursor_pos], eax
    add ebx, 1
    jmp .loop

.done:
    popa
    ret

wait_for_key:
    ; 等待按键
    in al, 0x64
    test al, 1
    jz wait_for_key
    in al, 0x60
    ret

read_input_32:
    ; 读取输入到input_buffer
    mov edi, input_buffer
    mov byte [edi], 0
    mov dword [keyboard_buffer_pos], 0
    
.input_loop:
    call wait_for_key
    
    cmp al, 0x1c    ; 回车
    je .input_done
    cmp al, 0x0e    ; 退格
    je .backspace
    
    ; 转换为ASCII（简化版）
    cmp al, 0x39    ; 空格
    jb .input_loop
    cmp al, 0x7f
    ja .input_loop
    
    ; 存储字符
    mov [edi], al
    inc edi
    inc dword [keyboard_buffer_pos]
    mov byte [edi], 0
    
    ; 显示字符
    mov ebx, input_buffer
    call print_string_pm
    
    jmp .input_loop

.backspace:
    cmp dword [keyboard_buffer_pos], 0
    je .input_loop
    
    dec edi
    dec dword [keyboard_buffer_pos]
    mov byte [edi], 0
    
    ; 显示退格（简化版）
    call clear_screen_32
    mov ebx, input_buffer
    call print_string_pm
    
    jmp .input_loop

.input_done:
    ret

copy_string_32:
    ; esi = 源, edi = 目标
    pusha
.copy_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    test al, al
    jnz .copy_loop
    popa
    ret

compare_string_32:
    ; esi = 字符串1, edi = 字符串2
    ; 如果相等则设置CF
    pusha
.compare_loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc esi
    inc edi
    jmp .compare_loop
.equal:
    stc
    jmp .done
.not_equal:
    clc
.done:
    popa
    ret

; === 数据区 ===
section .data

; 系统消息
welcome_msg db 'Protected Mode OS - Full Edition', 10, 0
system_info db '4GB Memory, File System, Applications', 10, 10, 0

; 主菜单
menu_title db '=== PMOS Main Menu ===', 10, 10, 0
menu_calc db '1. Calculator', 10, 0
menu_editor db '2. Text Editor', 10, 0
menu_filemgr db '3. File Manager', 10, 0
menu_info db '4. System Info', 10, 0
menu_reboot db '0. Reboot', 10, 10, 0
menu_prompt db 'Select option: ', 0

; 计算器
calc_title db '=== Calculator ===', 10, 10, 0
calc_prompt db 'Enter expression (q to quit): ', 0
calc_result db 'Result: ', 0

; 文本编辑器
editor_title db '=== Text Editor ===', 10, 10, 0
editor_help db 'Enter filename to edit:', 10, 0
editor_file_list db 'Files:', 10, 0
editor_prompt db 'Filename: ', 0
editor_new_file db 'Creating new file...', 10, 0
editor_loading db 'Loading file...', 10, 0
editor_editing db 'Editing: ', 0
editor_content db 10, 'Content:', 10, 0
editor_saved db 10, 'File saved. Press any key...', 0

; 文件管理器
filemgr_title db '=== File Manager ===', 10, 10, 0
filemgr_help db 'Commands: c=create, d=delete, v=view, q=quit', 10, 10, 0
filemgr_prompt db 'Command: ', 0
filemgr_unknown db 'Unknown command', 10, 0
filemgr_create_prompt db 'Enter filename: ', 0
filemgr_created db 'File created', 10, 0
filemgr_delete_prompt db 'Enter filename to delete: ', 0
filemgr_deleted db 'File deleted', 10, 0
filemgr_view_prompt db 'Enter filename to view: ', 0
filemgr_viewing db 'Content: ', 0
filemgr_not_found db 'File not found', 10, 0

; 系统信息
info_title db '=== System Information ===', 10, 10, 0
info_memory db 'Memory: 4GB Supported', 10, 0
info_features db 'Features: Protected Mode, File System', 10, 0
info_apps db 'Applications: Calculator, Editor, File Manager', 10, 0

; 文件系统
file_list_prefix db '- ', 0
newline db 10, 0

; 示例文件
sample_file1_name db 'readme.txt', 0
sample_file1_content db 'Welcome to LUX OS!', 0
sample_file2_name db 'notes.txt', 0
sample_file2_content db 'Important notes...', 0

; 常量
MAX_FILES equ 16

section .bss

; 键盘缓冲区
input_buffer resb 256
keyboard_buffer_pos resd 1

; 文件系统
file_count resd 1
file1_name resb 32
file1_content resb 32
file2_name resb 32
file2_content resb 32
; 可以继续添加更多文件...

; 应用程序状态
current_app resd 1
file_cursor resd 1
cursor_pos resd 1
file_content_buffer resb 1024

; 填充内核到64KB
times 65536-($-$$) db 0