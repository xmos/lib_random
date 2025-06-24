// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include "random.h"
#include "random_internal.h"

static const unsigned XS1_RING_OSCILLATOR_CONTROL_REG    = 0x060B;
static const unsigned XS1_RING_OSCILLATOR_CONTROL_START  = 0x3;
static const unsigned XS1_RING_OSCILLATOR_CONTROL_STOP   = 0x0;
static const unsigned XS1_RING_OSCILLATOR_VALUE_REG      = 0x070B;

__attribute__((constructor))
void random_simple_init_seed()
{
/* This constructor starts of the ring oscillator when the program loads.
   This will run on an asynchronous time base to the main xCORE. By starting it
   off now the later call to random_create_generator_from_hw_seed will pick up
   a value later which has drifted to a random state */
  setps(XS1_RING_OSCILLATOR_CONTROL_REG,
        XS1_RING_OSCILLATOR_CONTROL_START);
}

void random_ro_on() {
  setps(XS1_RING_OSCILLATOR_CONTROL_REG,
        XS1_RING_OSCILLATOR_CONTROL_START);
}

void random_ro_off() {
  setps(XS1_RING_OSCILLATOR_CONTROL_REG,
        XS1_RING_OSCILLATOR_CONTROL_STOP);
  asm volatile ("nop");
  asm volatile ("nop");
}

unsigned random_ro_read() {
  return getps(XS1_RING_OSCILLATOR_VALUE_REG);
}
