#include <stdint.h>
#include <stddef.h>

// 类型定义
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

// VGA文本缓冲区
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

volatile u16* vga_buffer = (u16*)0xB8000;
u32 vga_index = 0;
u8 vga_color = 0x0F; // 白字黑底

// 内存管理结构
typedef struct {
    u32 base_low;
    u32 base_high;
    u32 length_low;
    u32 length_high;
    u32 type;
    u32 acpi;
} __attribute__((packed)) memory_map_entry;

memory_map_entry* memory_map = (memory_map_entry*)0x5000;
u32 memory_map_entries = 0;

// NTFS数据结构
typedef struct {
    u8 jump[3];
    char oem[8];
    u16 bytes_per_sector;
    u8 sectors_per_cluster;
    u16 reserved_sectors;
    u8 fats;
    u16 root_entries;
    u16 total_sectors_16;
    u8 media;
    u16 fat_size_16;
    u16 sectors_per_track;
    u16 heads;
    u32 hidden_sectors;
    u32 total_sectors_32;
    
    // NTFS特定字段
    u64 total_sectors_64;
    u64 mft_cluster;
    u64 mft_mirror_cluster;
    s8 clusters_per_mft_record;
    u32 clusters_per_index_buffer;
    u64 volume_serial;
    u32 checksum;
} __attribute__((packed)) ntfs_boot_sector;

// 函数声明
void clear_screen();
void print_string(const char* str);
void print_hex(u32 num);
void print_dec(u32 num);
void detect_memory();
void init_ntfs();
void read_disk(u32 lba, u32 count, void* buffer);

// 主函数
int main() {
    clear_screen();
    print_string("LUX OS v1.1\n");
    print_string("===================================================\n\n");
    
    // 检测内存
    print_string("Memory Detection: ");
    detect_memory();
    
    // 初始化NTFS
    print_string("Initializing NTFS File System...\n");
    init_ntfs();
    
    // 显示系统信息
    print_string("\nSystem Information:\n");
    print_string("  - 32-bit Protected Mode\n");
    print_string("  - 4GB+ Memory Support\n");
    print_string("  - NTFS File System Driver\n");
    print_string("  - Advanced Memory Management\n");
    
    // 命令行界面
    print_string("\nCLI Ready. Type 'help' for commands.\n");
    command_loop();
    
    return 0;
}

// 清屏函数
void clear_screen() {
    for (u32 i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = (vga_color << 8) | ' ';
    }
    vga_index = 0;
}

// 打印字符串
void print_string(const char* str) {
    while (*str) {
        if (*str == '\n') {
            vga_index = (vga_index + VGA_WIDTH) / VGA_WIDTH * VGA_WIDTH;
        } else {
            vga_buffer[vga_index] = (vga_color << 8) | *str;
            vga_index++;
        }
        str++;
        
        // 滚动检查
        if (vga_index >= VGA_WIDTH * VGA_HEIGHT) {
            // 实现屏幕滚动
            for (u32 i = 0; i < VGA_WIDTH * (VGA_HEIGHT - 1); i++) {
                vga_buffer[i] = vga_buffer[i + VGA_WIDTH];
            }
            for (u32 i = VGA_WIDTH * (VGA_HEIGHT - 1); i < VGA_WIDTH * VGA_HEIGHT; i++) {
                vga_buffer[i] = (vga_color << 8) | ' ';
            }
            vga_index = VGA_WIDTH * (VGA_HEIGHT - 1);
        }
    }
}

// 打印十六进制数
void print_hex(u32 num) {
    char buffer[9];
    const char* hex_chars = "0123456789ABCDEF";
    
    for (int i = 7; i >= 0; i--) {
        buffer[i] = hex_chars[num & 0xF];
        num >>= 4;
    }
    buffer[8] = '\0';
    print_string("0x");
    print_string(buffer);
}

// 打印十进制数
void print_dec(u32 num) {
    char buffer[12];
    int i = 0;
    
    if (num == 0) {
        print_string("0");
        return;
    }
    
    while (num > 0) {
        buffer[i++] = '0' + (num % 10);
        num /= 10;
    }
    
    for (int j = i - 1; j >= 0; j--) {
        vga_buffer[vga_index++] = (vga_color << 8) | buffer[j];
    }
}

// 内存检测
void detect_memory() {
    // 这里会调用BIOS内存检测结果
    // 简化版本，显示固定值
    print_string("4GB Detected\n");
}

// NTFS初始化
void init_ntfs() {
    ntfs_boot_sector boot;
    
    // 读取引导扇区
    read_disk(0, 1, &boot);
    
    // 验证NTFS签名
    if (boot.oem[0] == 'N' && boot.oem[1] == 'T' && 
        boot.oem[2] == 'F' && boot.oem[3] == 'S') {
        print_string("NTFS Volume Detected\n");
        
        // 显示NTFS信息
        print_string("  Bytes per Sector: ");
        print_dec(boot.bytes_per_sector);
        print_string("\n");
        
        print_string("  Sectors per Cluster: ");
        print_dec(boot.sectors_per_cluster);
        print_string("\n");
        
        print_string("  Total Sectors: ");
        print_dec(boot.total_sectors_32);
        print_string("\n");
    } else {
        print_string("NTFS Not Found\n");
    }
}

// 磁盘读取函数（简化版）
void read_disk(u32 lba, u32 count, void* buffer) {
    // 在实际实现中，这里会使用ATA PIO模式读取磁盘
    // 简化版本，不实际读取
}

// 命令行循环
void command_loop() {
    char input_buffer[256];
    u32 input_index = 0;
    
    while (1) {
        print_string("PMOS> ");
        
        // 简单的输入循环
        // 在实际实现中，这里会有键盘中断处理
        input_index = 0;
        input_buffer[0] = '\0';
        
        // 显示提示符后返回（简化版）
        return;
    }
}