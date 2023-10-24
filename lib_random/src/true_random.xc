#include <platform.h>
#include <stdio.h>
#include <xs1.h>
#include <xclib.h>
#include "random.h"

#define MIN_RANDOM_BITS 8

static void inline ro_on() {
    setps(0x60B, 2);
}

static void inline ro_off() {
    setps(0x60B, 0);
}



#define TIME_FOR_ONE_BIT 20000
static int last_time = 0;

void random_true_init() {
    asm("gettime %0" : "=r" (last_time));
    ro_on();
}

{uint32_t,int32_t} random_true_get_bits() {
    int time, ro;

    ro_off();
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    ro = getps(0x70B);
    asm("gettime %0" : "=r" (time));
    ro_on();
    
    if (((unsigned)(time - last_time)) > TIME_FOR_ONE_BIT) {
        last_time = time;
        return {1, ro & 1};
    }
    return {0, last_time + TIME_FOR_ONE_BIT};
}

void random_true_uninit() {
    ro_off();
}
