// Copyright (c) 2017, XMOS Ltd, All rights reserved

#include "random_prng.h"
#include <xs1.h>
#include <string.h>
#include "xassert.h"
#include "random_pool.h"

// We always want xassert(e) to trap.
#if !(XASSERT_ENABLE_ASSERTIONS0)
# undef xassert
# define xassert(e) do { if (!(e)) __builtin_trap();} while(0)
#endif

// From: P. L'Ecuyer, "Maximally Equidistributed Combined Tausworthe Generators"
// Mathematics of Computation, 65, 213 (1996), 203--213:
// www.iro.umontreal.ca/~lecuyer/myftp/papers/tausme.ps
static uint32_t quickTaus(uint32_t state, uint32_t c,
                          uint32_t q, uint32_t s, uint32_t k_s) {
  return (((state << q) ^ state) >> k_s) ^ ((state & c) << s);
}
#define QT_PARAMS(k,q,s)  (uint32_t)(-(1UL<<(32-k))),q,s,(k-s)
// state[] seeds must be >= 2^(32-k)
#define QT_DEFAULT_SEED 128

// period ~ 2^57
// N.B. seed with: state[0] > 7, state[1] > 15
static uint32_t lfsr57(uint32_t state[2]) {
  state[0] = quickTaus(state[0], QT_PARAMS(29, 2,18) );
  state[1] = quickTaus(state[1], QT_PARAMS(28, 9,14) );
  return state[0] ^ state[1];
}

// period ~ 2^88
// N.B. seed with: state[0] > 1, state[1] > 7, state[2] > 15
static uint32_t lfsr88(uint32_t state[3]) {
  state[0] = quickTaus(state[0], QT_PARAMS(31,13,12) );
  state[1] = quickTaus(state[1], QT_PARAMS(29, 2, 4) );
  state[2] = quickTaus(state[2], QT_PARAMS(28, 3,17) );
  return state[0] ^ state[1] ^ state[2];
}

// period ~2^113
// N.B. seed with: state[0] > 1, state[1] > 7, state[2] > 15, state[3] > 127
static uint32_t lfsr113(uint32_t state[4]) {
  // Alternative values of the QT_PARAMS 's' are listed in table 1 of:
  // Tables Of Maximally Equidistributed Combined LFSR Generators: Pierre L'ecuyer
  // www.ams.org/mcom/1999-68-225/S0025-5718-99-01039-X/S0025-5718-99-01039-X.pdf
  state[0] = quickTaus(state[0], QT_PARAMS(31, 6,18) );
  state[1] = quickTaus(state[1], QT_PARAMS(29, 2, 2) );
  state[2] = quickTaus(state[2], QT_PARAMS(28,13, 7) );
  state[3] = quickTaus(state[3], QT_PARAMS(25, 3,13) );
  return state[0] ^ state[1] ^ state[2] ^ state[3];
}

static inline void sleepUntil(size_t numBits, client interface random_pool rpi) {
  timer tmr;
  uint32_t time;
  tmr :> time;
  time += rpi.timeUntil(numBits);
  tmr when timerafter(time) :> void;
}

static size_t perturbe(uint32_t state[prngSize], static const size_t prngSize,
                       size_t numBits, size_t& perturbeIndex, client interface random_pool rpi) {

  // Truncate large numbers.
  const size_t maxBits =  prngSize * (sizeof(uint32_t)*8);
  if (numBits > maxBits)
    numBits = maxBits;

  // Initialise state access variables, we will update them in the loop.
  size_t bitsInserted = 0; // What the caller wants to know.
  // These three variables track where 'perturbeIndex' needs to be set to.
  size_t index = perturbeIndex / (sizeof(uint32_t)*8);
  size_t bitPos = perturbeIndex % (sizeof(uint32_t)*8);
  size_t inserted = 0;

  while (numBits) {
    size_t tailBits = (sizeof(uint32_t)*8) - bitPos;
    if (tailBits > numBits)
      tailBits = numBits;

    inserted = rpi.insert(state[index], bitPos, tailBits);
    if (state[index] < QT_DEFAULT_SEED) {
      // N.B. The value of the state must be >= 2^(32-k) viz 'QT_DEFAULT_SEED'
      //      But the rpi pool may be empty.
      state[index] ^= 0xffffffff; // Will this break our PRNG?
    }
    bitsInserted += inserted;
    numBits -= inserted;

    if (numBits &&               // More to do.
        inserted == tailBits) {  // The pool is not empty.
      // We need to move onto the next state[] value.
      ++index;
      if (index == prngSize)
        index = 0;
      bitPos = 0;
    }
    // else index, bitPos, inserted give where we got up to.
  }

  perturbeIndex = (index * (sizeof(uint32_t)*8)) + bitPos + inserted;
  return bitsInserted;
}

[[distributable]]
void random_prng_server(server interface random_prng prngi, client interface random_pool ?rpi,
                        static const PrngSize prngSize, uint32_t (&?seed)[prngSize]) {

  xassert(prngSize >= prng57 && prngSize <= prng113); // "Invalid prngSize".

  size_t perturbeIndex = 0; // Track the next bit to be peturbed.
  uint32_t state[prngSize]; // Can't initialise distributable variables. Why not?
  if (!isnull(seed)) {
    for (int i=0; i<prngSize; ++i)
      xassert(seed[i] >= QT_DEFAULT_SEED); // "Invalid seed".
    memcpy(state, seed, prngSize * sizeof(uint32_t));
  }
  else {
    memset(state, QT_DEFAULT_SEED, prngSize * sizeof(uint32_t));
  }

  while(1) {
    select {
      case prngi.value(uint32_t values[n], size_t n) :
        switch (prngSize) {
          case prng57:
            for (size_t i = 0; i < n; ++i)
              values[i] = lfsr57(state);
            break;
          case prng88:
            for (size_t i = 0; i < n; ++i)
              values[i] = lfsr88(state);
            break;
          case prng113:
            for (size_t i = 0; i < n; ++i)
              values[i] = lfsr113(state);
            break;
        }
        break;

      case prngi.perturbe_nonBlocking(size_t numBits) -> size_t bitsUsed:
        bitsUsed = perturbe(state, prngSize, numBits, perturbeIndex, rpi);
        break;

      case prngi.perturbe_blocking(size_t numBits) -> size_t bitsUsed:
        bitsUsed = numBits;
        while (numBits) {
          numBits -= perturbe(state, prngSize, numBits, perturbeIndex, rpi);
          if (numBits)
            sleepUntil(numBits, rpi); // N.B. Only one clients wanting to block.
        }
        break;

      case prngi.perturbe_halfAvailableBits() -> size_t bitsUsed:
        bitsUsed = rpi.available() / 2; // We round down, so we can never use all bits.
        (void) perturbe(state, prngSize, bitsUsed, perturbeIndex, rpi);
        break;

      case prngi.release():
        return;
    }
  }
}
