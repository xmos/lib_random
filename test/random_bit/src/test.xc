// Copyright (c) 2017, XMOS Ltd, All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <platform.h>
#include "random_bit.h"

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

// Use 'TIME_FOR_ONE_BIT' from random_impl.h
#include "../../lib_random/src/random_impl.h"
#define UNCERTAINTY        200

static void sleep(uint32_t n) {
  timer tmr;
  uint32_t now;
  tmr :> now;
  tmr when timerafter(now+n) :> void;
}

void testClaimSimple(client interface checker ci, int id) {
  CHECK( random_bit_claim() == 1, ci, "testClaimSimple-%d step 1", id );
  random_bit_release();
  CHECK( random_bit_claim() == 1, ci, "testClaimSimple-%d step 2", id );
  CHECK( random_bit_claim() == 0, ci, "testClaimSimple-%d step 3", id );
  random_bit_release();
  INFO(ci, "testClaimSimple-%d done.", id);
  ci.release();
}

static int canClaim(uint32_t n) {
  sleep(n);
  if (random_bit_claim()) {
    sleep(100); // keep hold for a while.
    random_bit_release();
    return 1;
  }
  return 0;
}

void testClaimingParallel(client interface checker ci, int id) {
  int ret[6];
  par {
    // Only one logical core on a tile can claim.
    ret[0] = canClaim(0);
    ret[1] = canClaim(0);
    ret[2] = canClaim(0);
    // Once released (after 100), another logical core can claim (after 200)
    ret[3] = canClaim(200);
    ret[4] = canClaim(200);
    ret[5] = canClaim(200);
  }
  CHECK( ret[0]+ret[1]+ret[2] == 1, // One of them succeeds.
         ci, "testClaimingParallel-%d now", id );
  CHECK( ret[3]+ret[4]+ret[5] == 1, // One of them succeeds.
         ci, "testClaimingParallel-%d delayed", id );
  INFO(ci, "testClaimingParallel-%d done.", id);
  ci.release();
}

void testBit_notReady(client interface checker ci, int id, int step, uint32_t expectedTime) {
  uint32_t time;
  CHECK( random_bit(time) == 0,
         ci, "testBit-%d step 1 should not be ready", id );
  CHECK( expectedTime-UNCERTAINTY < time &&
         expectedTime+UNCERTAINTY > time,
         ci,"testBit-%d step %d expected time %d +- %d, acutal time %d\n", id, step, expectedTime, UNCERTAINTY, time);
}

void testBit_ready(client interface checker ci, int id, int step) {
  uint32_t bit;
  CHECK( random_bit(bit) == 1,
         ci, "testBit-%d step %d should be ready", id ,step );
  // We don't currently CHECK the bit - need to feed this into the simulator's "getps(0x70B)".
}

void testBit(client interface checker ci, int id) {
  // We don't need to call random_bit_claim() ... even if it is bad style :0
  timer tmr;
  uint32_t t;

  random_bit_start();
  tmr :> t;
  // Check at start.
  t += TIME_FOR_ONE_BIT; // We expect it to be ready in 'TIME_FOR_ONE_BIT' ticks.
  testBit_notReady(ci, id, 1, t);

  sleep(TIME_FOR_ONE_BIT/2);

  // Check at half way point.
  testBit_notReady(ci, id, 2, t);

  sleep(TIME_FOR_ONE_BIT/2);

  // Check at ready time.
  testBit_ready(ci, id, 3);
  tmr :> t; // Time till next bit from when we read previous bit.
  t += TIME_FOR_ONE_BIT; // We expect next bit ready in 'TIME_FOR_ONE_BIT' ticks from now.

  // Check next bit is not ready.
  testBit_notReady(ci, id, 4, t);

  // Sleep extra long.
  sleep(TIME_FOR_ONE_BIT*2);

  // We expect only one bit ready.
  testBit_ready(ci, id, 5);
  tmr :> t; // Time till next bit from when we read previous bit.
  t += TIME_FOR_ONE_BIT; // We expect next bit ready in 'TIME_FOR_ONE_BIT' ticks from now.

  // Check next bit is not ready.
  testBit_notReady(ci, id, 6, t);

  // stopping and starting will reset the time until ready.
  sleep(TIME_FOR_ONE_BIT*2);
  random_bit_stop();
  random_bit_start();
  tmr :> t;
  t += TIME_FOR_ONE_BIT; // We expect it to be ready in 'TIME_FOR_ONE_BIT' ticks.
  testBit_notReady(ci, id, 7, t);

  random_bit_stop();
  INFO(ci, "testBit-%d done.", id);
  ci.release();
}

int main() {
  interface checker i[6];
  par {
    on tile[0] : checkerServer(i,6, TIME_FOR_ONE_BIT*6);

    on tile[0] : {
      testClaimSimple(i[0], 0);
      // Followed by.
      testClaimingParallel(i[1] ,0);
    }
    on tile[0] : testBit(i[2], 0);

    // The tests on each tile are independant.
    on tile[1] : {
      testClaimSimple(i[3], 1);
      // Followed by.
      testClaimingParallel(i[4], 1);
    }
    on tile[1] : testBit(i[5], 1);
  }
  return 0;
}