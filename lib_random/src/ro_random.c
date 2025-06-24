// Copyright 2018-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <xcore/hwtimer.h>
#include "random.h"
#include "random_internal.h"

static unsigned last_time = 0;

void random_ro_init() {
    last_time = get_reference_time();
    random_ro_on();
}

void random_ro_uninit() {
    random_ro_off();
}

int random_ro_get_bit() {
    unsigned ro, time;
    
    time = get_reference_time();
    unsigned diff = time - last_time;

    if (diff > RANDOM_RO_MIN_TIME_FOR_ONE_BIT) {
        random_ro_off();
        ro = random_ro_read();
        random_ro_on();
        last_time = time;
        return ro & 1;
    }
    return -diff-1;
}
