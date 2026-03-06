// kernel.c
// 引导加载程序加载后执行

// 自己定义如何输出字符
// 显存地址 0xB8000
// 0xB8000 文本模式下显存起始地址
// 每字符占两个字节 第一个字节是字符的ASC2码 第二个字节是属性字节（颜色）
volatile char* vga_buffer = (volatile char*)0xB8000;

// 用于将字符串写入到屏幕
void print_string(const char* str) {
    int i = 0;
    int j = 0; // 屏幕缓冲区偏移量
    while (str[i] != '\0') {
        vga_buffer[j] = str[i]; // 字符
        vga_buffer[j + 1] = 0x0F; // 白色字符黑色背景
        i++;
        j += 2; // 移动到下一个字符的位置
    }
}
void _start_kernel() {
    // 测试消息
    print_string("LWSG Lux System");

    // 无限循环，防止程序结束
    while (1) {

    }
}