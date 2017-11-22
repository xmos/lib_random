// Copyright (c) 2017, XMOS Ltd, All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <platform.h>
#include "random_pool.h"

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
#define DELAY              500

static void delay() {
  timer tmr;
  uint32_t now;
  tmr :> now;
  tmr when timerafter(now+DELAY) :> void;
}

void testPool_timeuntil(client interface checker ci, int id,
                        client interface random_pool rpi, size_t numBits, size_t poolBits) {
  uint32_t time = rpi.timeUntil(numBits);

  // How many bit are we waiting for.
  size_t reportedBits = (numBits > rpi.capacity())? rpi.capacity() : numBits;
  reportedBits = (reportedBits<poolBits)? 0 : reportedBits - poolBits;
  uint32_t expected = TIME_FOR_ONE_BIT * reportedBits; // We know how it is caluclated!

  CHECK( expected == time,
         ci,"testPool-%d %d bits : expected time %d, acutal time %d\n", id, numBits, expected, time);
}

void testPool(client interface checker ci, int id,
              client interface random_pool rpi) {

  size_t expectedCapacity = (id<3)? 7 : 15; // See random_pool_server(..., bitsToPoolSize).
  CHECK( rpi.capacity() == expectedCapacity,
        ci, "testPool-%d capacity %d not %d", id, rpi.capacity(), expectedCapacity );

  CHECK( rpi.available() == 0,
        ci, "testPool-%d expected 0, actual %d bits", id, rpi.available() );

  timer tmr;
  uint32_t now;
  tmr :> now;
  testPool_timeuntil(ci, id, rpi, 0, 0);
  testPool_timeuntil(ci, id, rpi, 1, 0);
  testPool_timeuntil(ci, id, rpi, 2, 0);
  testPool_timeuntil(ci, id, rpi, 99, 0);

  tmr when timerafter(now + TIME_FOR_ONE_BIT) :> void;
  CHECK( rpi.available() == 1,
        ci, "testPool-%d expected 1, actual %d bits", id, rpi.available() );

  // Retest, but the periods will be reduced as we have a bit in the pool
  testPool_timeuntil(ci, id, rpi, 0, 1);
  testPool_timeuntil(ci, id, rpi, 1, 1);
  testPool_timeuntil(ci, id, rpi, 2, 1);
  testPool_timeuntil(ci, id, rpi, 99, 1);

  tmr when timerafter(now + TIME_FOR_ONE_BIT*2) :> void;
  CHECK( rpi.available() == 2,
        ci, "testPool-%d expected 2, actual %d bits", id, rpi.available() );

  delay(); // Allow all cores to check the pool before continuing.

  // Then allow one core to plunder the pool.
  if (id==0 || id==3) {
    // Retest, but the periods will be reduced as we have 2 bits in the pool
    testPool_timeuntil(ci, id, rpi, 0, 2);
    testPool_timeuntil(ci, id, rpi, 1, 2);
    testPool_timeuntil(ci, id, rpi, 2, 2);
    testPool_timeuntil(ci, id, rpi, 99, 2);

    uint32_t bits;
    CHECK( rpi.insert(bits, 32, 1) == 0, // Outside of range.
          ci, "testPool-%d incorrectly inserted bit32", id);
    CHECK( rpi.available() == 2,
          ci, "testPool-%d 2-0=2, actual %d bits", id, rpi.available() );

    CHECK( rpi.insert(bits, 31, 5) == 1, // Truncate to last bit.
          ci, "testPool-%d expected bit31 to be filled", id);
    // We don't currently CHECK the bit - need to feed this into the simulator's "getps(0x70B)".
    CHECK( rpi.available() == 1,
          ci, "testPool-%d 2-1=1, actual %d bits", id, rpi.available() );

    CHECK( rpi.insert(bits, 0, 999) == 1, // Request far too many bits!
          ci, "testPool-%d expected only bit0 to be filled", id);
    // We don't currently CHECK the bit - need to feed this into the simulator's "getps(0x70B)".
    CHECK( rpi.available() == 0,
          ci, "testPool-%d 1-1=0, actual %d bits", id, rpi.available() );

    CHECK( rpi.insert(bits, 0, 1) == 0, // None available.
          ci, "testPool-%d expected no bits to be filled", id);
    CHECK( rpi.available() == 0,
          ci, "testPool-%d 0-0=0, actual %d bits", id, rpi.available() );

    // Retest now the pool is empty.
    testPool_timeuntil(ci, id, rpi, 0, 0);
    testPool_timeuntil(ci, id, rpi, 1, 0);
    testPool_timeuntil(ci, id, rpi, 2, 0);
    testPool_timeuntil(ci, id, rpi, 99, 0);
  }
  else {
    // Wait for the pool to be plundered.
    delay();

    // The bit will have been taken by id 0.
    CHECK( rpi.available() == 0,
          ci, "testPool-%d pool contains %d bits", id, rpi.available() );
    uint32_t bits;
    CHECK( rpi.insert(bits, 32, 1) == 0, // Outside of range.
          ci, "testPool-%d bit32 expected no bits to be filled", id);

    CHECK( rpi.insert(bits, 31, 5) == 0, // Truncate to last bit.
          ci, "testPool-%d bit31 expected no bits to be filled", id);

    CHECK( rpi.insert(bits, 0, 999) == 0, // Request far too many bits!
          ci, "testPool-%d bit0 expected no bits to be filled", id);

    CHECK( rpi.insert(bits, 0, 1) == 0, // None available.
          ci, "testPool-%d expected no bits to be filled", id);
  }
  rpi.release();

  INFO(ci, "testPool-%d done.", id);
  ci.release();
}

int main() {
  interface checker i[6];
  interface random_pool rpi_0[3];
  interface random_pool rpi_1[3];

  par {
    on tile[0] : checkerServer(i, 6, TIME_FOR_ONE_BIT*3);

    on tile[0] : random_pool_server(rpi_0, 3, bitsToPoolSize(3)); // Rounded to 8.
    on tile[0] : testPool(i[0], 0, rpi_0[0]);
    on tile[0] : testPool(i[1], 1, rpi_0[1]);
    on tile[0] : testPool(i[2], 2, rpi_0[2]);

    on tile[1] : random_pool_server(rpi_1, 3, bitsToPoolSize(11)); // Rounded to 16.
    on tile[1] : testPool(i[3], 3, rpi_1[0]);
    on tile[1] : testPool(i[4], 4, rpi_1[1]);
    on tile[1] : testPool(i[5], 5, rpi_1[2]);
  }
  return 0; // failure;
}
