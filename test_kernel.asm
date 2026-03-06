; Minimal test kernel 
[BITS 16] 
[ORG 0x8000] 
start: 
    mov si, msg 
    call print_string 
    jmp $ 
print_string: 
    lodsb 
    or al, al 
    jz .done 
    mov ah, 0x0E 
    int 0x10 
    jmp print_string 
.done: 
    ret 
msg db 'Kernel loaded!',0 
