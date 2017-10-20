// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <stdint.h>
#include <stdio.h>
#include <xs1.h>
#include "random.h"

#define N 32

int main(void) {
    int n[N], rand[N];
    timer tmr;
    int t0;
    printf("Hello\n");
    random_true_init();
    for(int i = 0; i < N; i++) {
        tmr :> t0;
        tmr when timerafter(t0 + 10000) :> void;
        {n[i], rand[i]} = random_true_get_bits();
    }
    for(int i = 0; i < N; i++) {
        printf("** %d %d\n", n[i], rand[i]);
    }
    return 0;
}
