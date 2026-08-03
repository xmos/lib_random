// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// This is a smoke test - just tests that there is no repeats in the first 100000 numbers.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <xcore/parallel.h>
#include <xcore/hwtimer.h>
#include <xcore/chanend.h>
#include <xcore/channel_streaming.h>
#include "random.h"

int main(int argc, char *argv[]) {
    random_generator_t g = 0x12345678;

    unsigned first = random_get_random_number(&g);
    for(int i = 0; i < 100000; i++) {
        unsigned x = random_get_random_number(&g);
        if (x == first) {
            printf("FAIL %d %08x %08x\n", i, first, x);
            exit(1);
        }
    }
    printf("PASS\n");
    return 0;
}
