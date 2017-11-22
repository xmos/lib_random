// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#include "random.h"
#include <xs1.h>

#if RANDOM_ENABLE_HW_SEED

#warning "Building deprecated random_create_generator_from_hw_seed()"
#warning "N.B. random_create_generator_from_hw_seed() is incompatible with the rest of the lib_random library."
#warning "Did you mean to define `RANDOM_ENABLE_HW_SEED`?"

__attribute__((constructor))
void random_simple_init_seed() {
  setps(0x060B, 0x3);
}

random_generator_t random_create_generator_from_hw_seed(void) {
  unsigned init_seed = getps(0x070B);
  return random_create_generator_from_seed(init_seed);
}

#endif
