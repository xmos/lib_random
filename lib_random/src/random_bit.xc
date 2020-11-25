// Copyright (c) 2017, XMOS Ltd, All rights reserved
#include "random_bit.h"
#include "hwlock.h"
#include "random_impl.h"

#if __XS2__
#  include "xs2a_registers.h"
#else
#  include "xs1b_registers.h"
#  define XS1_PS_RING_OSC_CTRL   XS1_L_PS_RING_OSC_CTRL
#  define XS1_PS_RING_OSC_DATA0  XS1_L_PS_RING_OSC_DATA0
#endif

// Optional thread protection...

#define LOAD32(dst, ptr)       asm("ldw %0, %1[0]"  : "=r"(dst) : "r"(ptr));
#define STORE32(src, ptr)      asm("stw %0, %1[0]"  :           : "r"(src), "r"(ptr));

extern unsigned __libc_hwlock;
static int per_tile_available = 1;

int random_bit_claim() {
  int available;
  hwlock_acquire(__libc_hwlock);
  LOAD32(available, &per_tile_available);
  if (available) {
    int newValue = 0;
    STORE32(newValue, &per_tile_available);
  }
  hwlock_release(__libc_hwlock);
  return available;
}

void random_bit_release() {
  int newValue = 1;
  STORE32(newValue, &per_tile_available);
}


// None thread safe code...

static int per_tile_last_time = 0;

void random_bit_start() {
  int last_time;
  timer tmr;
  tmr :> last_time;
  STORE32(last_time, &per_tile_last_time);
  setps(XS1_PS_RING_OSC_CTRL, 2);
}

void random_bit_stop() {
  setps(XS1_PS_RING_OSC_CTRL, 0);
}

uint32_t random_bit(uint32_t &bit_time) {
  int last_time;
  LOAD32(last_time, &per_tile_last_time);
  timer tmr;
  uint32_t time;
  tmr :> time;
  // If the timer wraps, we will miss the opportunity - tough!
  // N.B. unsigned wrapping has defined behaviour.
  if (time - last_time > TIME_FOR_ONE_BIT) {
    random_bit_stop();
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop"); // Allow the data to stabilise.
    bit_time = getps(XS1_PS_RING_OSC_DATA0);
    random_bit_start();
    bit_time &=1;
    return 1;
  }
  else {
    bit_time = last_time + TIME_FOR_ONE_BIT;
    return 0;
  }
}
