// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdint.h>
#include <print.h>
#include "random.h"

#define RAND_SEED (8369)
#define RAND_BUF_LEN (4)

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

    return 0;
}
