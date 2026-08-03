// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// This program collects 1,000,000 random bits
// These are stored compressed, and then written to a file as single bits in a byte file
// These can then be analysed off-line for randomness.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <xcore/hwtimer.h>
#include "random.h"

#define N 1000000/32

unsigned int data[N];

int main(int argc, char *argv[]) {
    int t0 = get_reference_time();
    random_ro_init();
    for(int i = 0; i < N; i++) {
        int j = 0;
        unsigned int bits = 0;
        do {
            int bit = random_ro_get_bit();
            if (bit >= 0) {
                bits |= bit << j;
                j++;
            }
        } while (j != 32);
        data[i] = bits;
    }
    int t1 = get_reference_time();
    printf("%d %d\n", t1 - t0, (t1-t0)/(N*32));
    FILE *fd = fopen(argv[1], "wb");
    for(int i = 0; i < N; i++) {
        unsigned char output_data[32];
        for(int j = 0; j < 32; j++) {
            output_data[j] = (data[i] >> j)&1;
        }
        fwrite(output_data, sizeof(output_data), 1, fd);
    }
    fclose(fd);
    return 0;
}
