// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "random.h"
#include <xs1.h>

static const unsigned XS1_L_RING_OSCILLATOR_CONTROL_REG    = 0x060B;
static const unsigned XS1_L_RING_OSCILLATOR_CONTROL_START  = 0x3;

__attribute__((constructor))
void random_simple_init_seed()
{
/* This constructor starts of the ring oscillator when the program loads.
   This will run on an asynchronous time base to the main xCORE. By starting it
   off now the later call to random_create_generator_from_hw_seed will pick up
   a value later which has drifted to a random state */
  setps(XS1_L_RING_OSCILLATOR_CONTROL_REG,
        XS1_L_RING_OSCILLATOR_CONTROL_START);
}
