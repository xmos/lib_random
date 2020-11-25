
#include "random_prng.h"
#include <stdio.h>
#include <xs1.h>

#define PRINT(...) printf(__VA_ARGS__)
//#define PRINT(...)

void test(const char*unsafe name, client interface random_prng prngi) {
  uint32_t values[2];
  prngi.value(values, 2);
  PRINT("%s raw -     %X %X\n",name, values[0], values[1]);

  size_t done = prngi.perturbe_halfAvailableBits();
  prngi.value(values, 2);
  PRINT("%s half %d     %X %X\n", name, done, values[0], values[1]);

  done = prngi.perturbe_nonBlocking(2);
  prngi.value(values, 2);
  PRINT("%s nonblocking %d     %X %X\n", name, done, values[0], values[1]);

  done = prngi.perturbe_blocking(1);
  prngi.value(values, 2);
  PRINT("%s blocking %d     %X %X\n", name, done, values[0], values[1]);

  // Client prngi is no longer wanted.
  prngi.release(); // This will allow the random_prng_server() to exit too.
  PRINT("Exit %s\n", name);
}

int main() {
  interface random_pool rpi[2];
  par {
    // Task-pool-server
    random_pool_server(rpi, 2, bitsToPoolSize(11));

    // Task-pool-client0 with subtasks.
    {
      PRINT("Task-pool-client0 available=%d capacity=%d\n", rpi[0].available(), rpi[0].capacity());
      uint32_t seed[prng57] = {1234,5678};
      interface random_prng prngi;
      // subtask-A.
      par {
        [[distribute]]
        random_prng_server(prngi, rpi[0], prng57, seed);
        test("subtask-A", prngi);
      }
      // Follow with a sequential subtask-B.
      // We can reuse the prngi interface object to start a new server & client.
      // N.B. BUT ONLY IF THE INTERFACE IS THE SAME TYPE - both 'distribute' or not!!
      par {
        [[distribute]]
        random_prng_server(prngi, rpi[0], prng113, null); // Use the default seed
        test("subtask-B", prngi);
      }
      // Client rpi[0] is no longer wanted.
      rpi[0].release(); // This will allow the random_pool_server() to exit too.
      PRINT("Exit Task-pool-client0\n");
    }

    // Task-pool-client1
    {
      PRINT("Task-pool-client1 available=%d capacity=%d\n", rpi[1].available(), rpi[1].capacity());
      timer tmr;
      uint32_t time;
      tmr :> time;
      tmr when timerafter(time+20000) :> void;
      PRINT("Task-pool-client1 available=%d capacity=%d\n", rpi[1].available(), rpi[1].capacity());
      // Client rpi[1] is no longer wanted.
      rpi[1].release(); // This will allow the random_pool_server() to exit too.
      PRINT("Exit Task-pool-client1\n");
    }
  }
  PRINT("Exit Task-pool-server\n");
  return 0;
}

