#ifndef TX64_H
#define TX64_H

#include <stdint.h>

#define TX64_MAX_INSTR_LEN 15
#define TX64_ITXT_SZ 16

typedef unsigned char byte;

typedef struct tx64_instr_info {
	uint64_t ip;
	byte itxt_mem[TX64_ITXT_SZ];
} tx64_instr_info;

#define TX64_HDR_SZ 64

#endif
