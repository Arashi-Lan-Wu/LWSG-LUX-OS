#ifndef NTFS_H
#define NTFS_H

#include <stdint.h>

// NTFS常量
#define NTFS_SIGNATURE "NTFS    "
#define NTFS_BLOCK_SIZE 512
#define NTFS_MFT_RECORD_SIZE 1024

// NTFS属性类型
typedef enum {
    NTFS_ATTR_STANDARD_INFORMATION = 0x10,
    NTFS_ATTR_ATTRIBUTE_LIST = 0x20,
    NTFS_ATTR_FILE_NAME = 0x30,
    NTFS_ATTR_OBJECT_ID = 0x40,
    NTFS_ATTR_SECURITY_DESCRIPTOR = 0x50,
    NTFS_ATTR_VOLUME_NAME = 0x60,
    NTFS_ATTR_VOLUME_INFORMATION = 0x70,
    NTFS_ATTR_DATA = 0x80,
    NTFS_ATTR_INDEX_ROOT = 0x90,
    NTFS_ATTR_INDEX_ALLOCATION = 0xA0,
    NTFS_ATTR_BITMAP = 0xB0,
    NTFS_ATTR_REPARSE_POINT = 0xC0,
    NTFS_ATTR_EA_INFORMATION = 0xD0,
    NTFS_ATTR_EA = 0xE0,
    NTFS_ATTR_PROPERTY_SET = 0xF0,
    NTFS_ATTR_LOGGED_UTILITY_STREAM = 0x100
} ntfs_attr_type;

// NTFS数据结构
typedef struct {
    uint64_t mft_reference;
    uint16_t sequence_number;
    uint16_t link_count;
    uint16_t attributes_offset;
    uint16_t flags;
    uint32_t bytes_in_use;
    uint32_t bytes_allocated;
} __attribute__((packed)) ntfs_file_record_header;

typedef struct {
    uint32_t type;
    uint32_t length;
    uint8_t non_resident;
    uint8_t name_length;
    uint16_t name_offset;
    uint16_t flags;
    uint16_t instance;
    union {
        struct {
            uint32_t value_length;
            uint16_t value_offset;
            uint8_t reserved[2];
        } __attribute__((packed)) resident;
        struct {
            uint64_t lowest_vcn;
            uint64_t highest_vcn;
            uint16_t mapping_pairs_offset;
            uint8_t compression_unit;
            uint8_t reserved[5];
            uint64_t allocated_size;
            uint64_t data_size;
            uint64_t initialized_size;
            uint64_t compressed_size;
        } __attribute__((packed)) non_resident;
    };
} __attribute__((packed)) ntfs_attribute_header;

// NTFS函数声明
int ntfs_mount(uint32_t disk_number);
int ntfs_read_file(const char* filename, void* buffer, uint32_t size);
int ntfs_list_directory(const char* path);
int ntfs_get_file_info(const char* filename);
uint64_t ntfs_get_free_space();

#endif