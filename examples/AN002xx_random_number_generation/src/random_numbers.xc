// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <xs1.h>
#include "random_bit.h"

#define MAXX 1024
#define MAXY 1024
#define MAXBITS (MAXX * MAXY)

unsigned char thebits[MAXBITS/8];

unsigned int getbit(int i) {
  return (thebits[i>>3] >> (i&7)) & 1;
}

unsigned int setbit(int i, int val) {
  return thebits[i>>3] |= val << (i&7);
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

void fillmetrue(void) {
  timer tmr;
  int t0, t1;
  int sum = 0;
  tmr :> t0;
  random_bit_start();
  while(sum < MAXBITS) {
    uint32_t bit_time;
    if (random_bit(bit_time)) {
      //assert((bit_time & ~1UL)==0);
      setbit(sum, bit_time);
      sum++;
      if ((sum & 0xffff) == 0) {
        int time;
        asm volatile ("gettime %0" : "=r" (time));
        printf("%11d %d\n", time, sum);
      }
    }
    //else
    //  tmr when timerafter(bit_time) :> void;
  }
  random_bit_stop();
  tmr :> t1;
  printf("Ticks taken: %d, %d per bit\n", t1-t0, (t1-t0)/sum);
}

void xmain(chanend done[7]) {
  for(int i = 0; i < 7; i++) {
    done[i] <: 0;
  }
  fillmetrue();
  blocktest(1);
  blocktest(2);
  blocktest(3);
  runtest();
  return;
  printf("P2\n%d %d\n1\n", MAXX, MAXY);
  for(int i = 0; i < MAXX; i++) {
    for(int j = 0; j < MAXY; j++) {
      printf("%d ", getbit(i*MAXY+j));
    }
    printf("\n");
  }
}

int busy(int x, chanend y) {
  while(1) {
    for(int i = 0; i < 1000; i++) {
      x = x * 1234567 + 1;
    }
    select {
      case y :> int _: return x;
      default:  break;
    }
  }
  return x;
}


int main(void) {
  chan done[7];
  par {
    busy(0x3, done[0]);
    busy(0x4, done[1]);
    busy(0x5, done[2]);
    busy(0x6, done[3]);
    busy(0x7, done[4]);
    busy(0x8, done[5]);
    busy(0x9, done[6]);
    xmain(done);
  }
  return 0;
}
