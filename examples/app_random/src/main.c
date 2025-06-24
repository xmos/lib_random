// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdint.h>
#include <print.h>
#include "random.h"

#define RAND_SEED (8369)
#define RAND_BUF_LEN (8)

int main() {
    // Create a generator with a software seed
    random_generator_t rg_sw = random_create_generator_from_seed(RAND_SEED);

    // Generate a single random value and print it
    unsigned rand_val = random_get_random_number(&rg_sw);
    printuintln(rand_val);

    // Create a generator with a hardware seed
    random_generator_t rg_hw = random_create_generator_from_hw_seed();

    // Generate a set of random bytes and print them
    uint8_t rand_buf[RAND_BUF_LEN];
    random_get_random_bytes(&rg_hw, rand_buf, RAND_BUF_LEN);

    for (int idx = 0; idx < RAND_BUF_LEN; ++idx) {
        printuintln(rand_buf[idx]);
    }

    random_ro_init();
    for (int i = 0; i < 10; ++i) {
        int bit;
        do {
            bit = random_ro_get_bit();
            // You could sleep here for -bit timer ticks.
        } while(bit < 0);
        printint(bit);
    }
    random_ro_uninit();
    printstr(" Done\n");

    return 0;
}
