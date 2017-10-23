#include <platform.h>
#include <stdio.h>
#include <xs1.h>
#include <xclib.h>
#include "random.h"

#define MIN_RANDOM_BITS 12

{int,int} static getro() {
    int time;
    setps(0x60B, 0);
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    short x = getps(0x70B);
    asm("gettime %0" : "=r" (time));
    setps(0x60B, 3);
    return {time, x};
}

static int last_used_time, last_used_ro;
static unsigned current_ro_per_tick;
static int scanning = 0;
static int final_time = 0;

void random_true_init() {
    int time, ro, time2, ro2;
    timer tmr;
    {time, ro} = getro();
    tmr when timerafter(time+5000) :> void;
    {time2, ro2} = getro();
    last_used_time = time;
    last_used_ro = ro;
    current_ro_per_tick = ((short)(ro2 - last_used_ro)) * 0x10000LL / (time2 - last_used_time);
    scanning = 1;
}

static inline int cls(int x) {
    return x < 0 ? clz(-x) : clz(x);
}

{uint32_t,uint32_t} random_true_get_bits() {
    int time, ro;
    {time, ro} = getro();
    
    int dtime = time - last_used_time;
    int expectedro = last_used_ro + ((dtime * (long long) current_ro_per_tick) >> 16);
    short dro = ro - expectedro;
    int nbits = 32 - cls(dro) - MIN_RANDOM_BITS;
    if (scanning) {    
        if (nbits <= 0) {
            return {0, 10000};    // called much too early
        }
        final_time = time + dtime;
        scanning = 0;
        return {0, dtime};    // call again in dtime;
    } else if ((time - final_time) > 0) {
        random_true_init();
        return {nbits, dro & (1 << nbits) - 1};
    }
    return {0,final_time - time};
}
