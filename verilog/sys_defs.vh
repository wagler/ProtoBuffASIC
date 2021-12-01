`timescale 10ns/1ns

typedef struct packed {
    logic [28:0]    field_id;           // 29 bits
    logic [4:0]     field_type;         // 5 bits
    logic [13:0]    offset;             // 14 bits
    logic [14:0]    size;               // 15 bits
    logic           nested;             // 1 bit
    logic [63:0]    nested_type_table;  // 64 bits
} TABLE_ENTRY;

typedef struct packed {
    logic           valid;
    TABLE_ENTRY     entry;
} BUFFER_ENTRY;

