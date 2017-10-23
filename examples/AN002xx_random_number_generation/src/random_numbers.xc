// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <xs1.h>
#include "random.h"

#define MAXX 256
#define MAXY 256
#define MAXBITS (MAXX * MAXY)

unsigned char thebits[MAXBITS/8];

unsigned int getbit(int i) {
    return (thebits[i>>3] >> (i&7)) & 1;
}

unsigned int setbit(int i) {
    return thebits[i>>3] |= 1 << (i&7);
}

void blocktest(int n) {
    int hist[256];
    for(int i = 0; i < 256; i++) {
        hist[i] = 0;
    }
    for(int i = 0; i < MAXBITS - n; i++) {
        int val = 0;
        for(int j = 0; j < n; j++) {
            val = val << 1 | getbit(i+j);
        }
        hist[val]++;
    }
    printf("Blocktest %d\n", n);
    for(int i = 0; i < (1<<n); i++) {
        printf("  Bin %d: %d %s\n", i, hist[i], abs(hist[i]-(MAXBITS >> n)) < MAXX ? "Ok" : "Hmm");
    }
    printf("\n");
}

void runtest() {
    int hist[200];
    int old = 0;
    int run = 0;
    for(int i = 0; i < 200; i++) {
        hist[i] = 0;
    }
    for(int i = 0; i < MAXBITS; i++) {
        if(getbit(i) == old) {
            run++;
        } else {
            hist[run]++;
            run = 1;
        }
    }
    printf("Runtest:\n");
    for(int i = 1; i < 10; i++) {
        printf("  Bin %d: %d %s\n", i, hist[i], abs(hist[i] - (MAXBITS >> (i+1))) < (MAXX >> (i/2)) ? "Ok" : "Hmm" );
    }
    printf("\n");
}

void xmain(void) {
    int n, rand;
    timer tmr;
    int t0;
    int sum = 0;
    int ns = 0;
    int ticks = 1500;
    random_true_init();
    while(sum < MAXBITS) {
//        tmr when timerafter(t0 + ticks) :> void;
        {n, rand} = random_true_get_bits();
        if (n == 0) {
            tmr :> t0;
            tmr when timerafter(t0 + 10 + 0 * rand) :> void;
        } else {
            for(int i = 0; i < n && sum < MAXBITS; i++) {
                setbit(sum, rand & 1);
                rand >>= 1;
                sum++;
            }
            ns++;
        }
    }
    printf("Average bits per call %f at %d ticks\n", sum/(float)ns, ticks);
    blocktest(1);
    blocktest(2);
    blocktest(3);
    runtest();
//    printf("P2\n%d %d\n1\n", MAXX, MAXY);
    for(int i = 0; i < MAXX; i++) {
        for(int j = 0; j < MAXY; j++) {
//            printf("%d ", bits[i*MAXY+j]);
        }
//        printf("\n");
    }
}

int busy(int x) {
    return 0;
    for(int j = 0; j < 100; j++) {
        for(int i = 0; i < 100000000; i++) {
            x = x * 1234567 + 1;
        }
    }
    printf("%d\n", x);
    return x;
}

int main(void) {
    par {
        busy(0x3);
        busy(0x4);
        busy(0x5);
        busy(0x6);
        busy(0x7);
        busy(0x8);
        busy(0x9);
        xmain();
    }
    return 0;
}
