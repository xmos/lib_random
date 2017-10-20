#include <platform.h>
#include <stdio.h>
#include <xs1.h>
#include <xclib.h>
#include "random.h"

#define MIN_RANDOM_BITS 8

{int,int} static getro() {
    int time;
    asm("gettime %0" : "=r" (time));
    setps(0x60B, 0);
    short x = getps(0x70B);
    setps(0x60B, 3);
    return {time, x};
}

static int last_used_time, last_used_ro;
static unsigned current_ro_per_tick;

void random_true_init() {
    int time, ro, time2, ro2;
    timer tmr;
    {time, ro} = getro();
    tmr when timerafter(time+1000) :> void;
    {time2, ro2} = getro();
    last_used_time = time;
    last_used_ro = ro;
    current_ro_per_tick = (ro2 - last_used_ro) * 0x10000LL / (time2 - last_used_time);
//    printf("%9u %5u %08x\n", last_used_time, last_used_ro & 0xFFFFU, current_ro_per_tick);
}

static inline int cls(int x) {
    return x < 0 ? clz(-x) : clz(x);
}

{uint32_t,uint32_t} random_true_get_bits() {
    int time, ro;
    {time, ro} = getro();
    int dtime = time - last_used_time;
    short expectedro = last_used_ro + ((dtime * (long long) current_ro_per_tick) >> 16);
    short dro = ro - expectedro;
    int random_bits = dro >> MIN_RANDOM_BITS;
    int nbits = 31 - cls(random_bits);
    if (nbits > 0) {
        current_ro_per_tick = (expectedro + dro - last_used_ro) * 0x10000LL / (time - last_used_time);
        last_used_time = time;
        last_used_ro = ro;
        printf("%9u %5u %08x\n", last_used_time, last_used_ro & 0xFFFFU, current_ro_per_tick);
        return {nbits, dro & (1 << nbits) - 1};
    }
    return {0, 0};
}
