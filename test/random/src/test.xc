// Copyright (c) 2017, XMOS Ltd, All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <platform.h>
#include "random.h"

/////////////////////////////////////////////////////////
// First some unit testing boiler plate
interface checker {
  void str(const char str[100]);
  void release();
};
static void checkerServer(server interface checker si[n], static const size_t n, uint32_t timeout) {
  // We will release when the last client has released us.
  // All clients have implicitly claimed us, set the 'n' lowest bits.
  if (n > 32) {
    fprintf(stderr, "Error checkerServer: The maximum number of clients is 32\n");
    return;
  }
  uint32_t activeClients = (1ULL<<n) - 1;

  // Attempt to spot hung tests.
  timer tmr;
  uint32_t start;
  tmr :> start;

  while(1){
    select{
      case si[unsigned id].str(const char str[100]) :
        char local[100];
        memcpy(local,str,100);
        fprintf(stderr, "%s\n", local);
        break;
      case si[unsigned id].release():
        activeClients &= ~(1UL << id);
        if (!activeClients)
          return;
        break;
      case  tmr when timerafter(start + timeout) :> void:
        fprintf(stderr, "Error checkerServer: timout after %d tick, activeClients mask=0x%X\n", timeout, activeClients);
        exit(1);
        break;
    }
  }
}

#define INFO(ci, ...) \
  do { \
    char _checker_buff[100]; \
    snprintf(_checker_buff, 100, __VA_ARGS__); \
    ci.str(_checker_buff); \
  } while(0)

#define CHECK(c, ci, ...) \
  if (!(c)) INFO(ci, __VA_ARGS__)

/////////////////////////////////////////////////////////

typedef union {
  uint32_t word[2];
  uint8_t byte[8];
} Bytes;


void test(client interface checker ci, int id) {

  // Check '0' is valid.
  random_generator_t gen1 = random_create_generator_from_seed(0);
  unsigned v1 = random_get_random_number(gen1);
  CHECK( v1, ci, "test-%d unexpexted zero returned", id );
  Bytes b1 = {{0,0}};
  random_get_random_bytes(gen1, b1.byte, 5);
  // simple checks of the values returned...
  CHECK( b1.word[0] && b1.word[1], ci, "test-%d unexpexted zero returned, %#08X%08x", id, b1.word[0], b1.word[1] );
  CHECK( (b1.word[1] & 0xffffff00) == 0, ci, "test-%d too many bytes read, %#08X%08x", id, b1.word[0], b1.word[1] );
  // We do not test for 'out of bounds array access'
  // random_get_random_bytes(gen1, b1.byte, 11);

  // Check we get a different set of values.
  random_generator_t gen2 = random_create_generator_from_seed(0x12345678);
  unsigned v2 = random_get_random_number(gen2);
  CHECK( v2 != v1, ci, "test-%d unexpexted same value", id );
  Bytes b2 = {{0,0}};
  random_get_random_bytes(gen2, b2.byte, 5);
  CHECK( b2.word[0] != b1.word[0] && b2.word[1] != b1.word[1], ci, "unexpexted same bytes", id );

  // We should get the same output as the first block.
  random_generator_t gen3 = random_create_generator_from_seed(0);
  unsigned v3 = random_get_random_number(gen3);
  CHECK( v3 == v1, ci, "test-%d unexpexted different value", id );
  Bytes b3 = {{0,0}};
  random_get_random_bytes(gen3, b3.byte, 5);
  CHECK( b3.word[0] == b1.word[0] && b3.word[1] == b1.word[1], ci, "unexpexted different bytes", id );

  // All gernators are independant.
  v1 = random_get_random_number(gen1);
  v2 = random_get_random_number(gen2);
  v3 = random_get_random_number(gen3);
  CHECK( v2 != v1, ci, "test-%d unexpexted same value", id );
  CHECK( v3 == v1, ci, "test-%d unexpexted different value", id );

  Bytes zero = {{0,0}};
  random_get_random_bytes(gen1, zero.byte, 0);
  CHECK( !zero.word[0] && !zero.word[1], ci, "unexpexted bytes read", id );

  // The following function is deprecated but still tested.
  // We have add 'RANDOM_ENABLE_HW_SEED=1' to the Makefile.
  // The build will generate a warning... which we ignore.
  random_generator_t gen4 = random_create_generator_from_hw_seed();
  // No delay needed.
  random_generator_t gen5 = random_create_generator_from_hw_seed();
  CHECK( gen4 != gen5, ci, "test-%d same hw seed generator", id );

  INFO(ci, "test-%d done.", id);
  ci.release();
}

int main() {
  interface checker i[4];
  par {
    on tile[0] : checkerServer(i, 4, 100000);
    on tile[0] : test(i[0], 0);
    on tile[0] : test(i[1], 1);
    on tile[1] : test(i[2], 2);
    on tile[1] : test(i[3], 3);
  }
  return 0; // failure;
}
