// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include "random.h"
#include "random_internal.h"

#define crc32(a,b,c)  asm("crc32 %0, %1, %2" : "+r" (a) : "r" (c), "r" (b))

static const unsigned random_poly = 0xEDB88320;

unsigned random_get_random_number(random_generator_t *g)
{
  crc32(*g, -1, random_poly);
  return (unsigned) *g;
}

void random_get_random_bytes(random_generator_t *g, uint8_t in_buffer[], size_t byte_count)
{
  for (unsigned i=0; i < byte_count; i++)
  {
    in_buffer[i] = (uint8_t)random_get_random_number(g);
  }
}

random_generator_t random_create_generator_from_seed(unsigned seed)
{
  random_generator_t gen = (random_generator_t) seed;
  (void) random_get_random_number(&gen);
  return gen;
}

random_generator_t random_create_generator_from_hw_seed(void)
{
  random_ro_off();
  unsigned init_seed = random_ro_read();
  random_ro_on();
  return random_create_generator_from_seed(init_seed);
}

