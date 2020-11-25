// Copyright (c) 2017, XMOS Ltd, All rights reserved

#include "random_pool.h"
#include <xs1.h>
#include <string.h>
#include "xassert.h"
#include "random_bit.h"

// We always want xassert(e) to trap.
#if !(XASSERT_ENABLE_ASSERTIONS0)
# undef xassert
# define xassert(e) do { if (!(e)) __builtin_trap();} while(0)
#endif

// Internally, we use bit indexes into the pool (head, tail etc).
// To make head/tail handling easier and more efficient:
//   head==tail means empty;
//   we will always have at least one bit 'empty'.
// See _bitsToPoolSize() macro for extra bit calculation.

static inline size_t poolSizeInBits(static const PoolSize_t poolSize) {
  return poolSize * (sizeof(_rp_impl_type)*8);
}

static inline size_t poolSizeCapacity(static const PoolSize_t poolSize) {
  return poolSizeInBits(poolSize) - 1; // see comment above.
}

static inline size_t available(size_t head, size_t tail, static const PoolSize_t poolSize) {
  if (tail > head)
    head += poolSizeInBits(poolSize);
  return head - tail;
}

// incrementor for bit position
static inline void incrementPos(size_t& pos, static const PoolSize_t poolSize) {
  ++pos;
  if (pos == poolSizeInBits(poolSize))
    pos = 0;
}

// Convert the `head` and `tail` bit positions into `_rp_impl_type[]` accessors.
static inline size_t indexOffset(size_t pos) {
  return pos / (sizeof(_rp_impl_type)*8);
}
static inline size_t bitOffset(size_t pos) {
  return pos % (sizeof(_rp_impl_type)*8);
}

static inline _rp_impl_type bitMask(size_t numBits) {
  return (1ULL << numBits) - 1;
}

static inline uint32_t poolFill(size_t& head, size_t& tail,
                                _rp_impl_type pool[poolSize], static const PoolSize_t poolSize) {
  uint32_t bit_time;
  while (random_bit(bit_time)) {
    // xor the bit at 'head'.
    pool[indexOffset(head)] ^= (bit_time << bitOffset(head));
    incrementPos(head, poolSize);
    if (head == tail) { // We have a full pool.
      // Throw away old bits and keep the newest (always one bit empty).
      incrementPos(tail, poolSize);
    }
  }
  return bit_time; // Time when next bit available.
}

static inline void xorInsert(uint32_t& value, size_t bitPos, size_t numBits,
                          size_t& tail, _rp_impl_type pool[poolSize], static const PoolSize_t poolSize ) {
  // asserted (bitPos+numBits <= 32), bits will map onto a single uint32_t 'value'.

  // Initialise the pool access variables, we will update them in the loop.
  size_t tailIndex = indexOffset(tail);
  size_t tailBit = bitOffset(tail); // zero on subsequent passes.

  // Update 'tail' assuming we will remove 'numBits'.
  // asserted (numBits<=available() && numBits < poolSizeInBits), so we wont need to worry about head.
  tail += numBits;
  if (tail >= poolSizeInBits(poolSize))
    tail -= poolSizeInBits(poolSize);

  while (numBits) {
    size_t allotted = (sizeof(_rp_impl_type)*8) - tailBit; // Initially grab all top bits...
    size_t invalidTop = 0;                                 // so we don't discard any top bits.
    if (allotted > numBits) {
      // We don't need them all (or they are not available).
      allotted = numBits;
      invalidTop = (sizeof(_rp_impl_type)*8) - (tailBit + allotted);
    }
    _rp_impl_type v = pool[tailIndex];
    v <<= invalidTop;               // Mask top bits.
    v >>= (tailBit + invalidTop);   // Mask bottom bits.
    v <<= bitPos;                   // Position bits ready for insertion.
    value ^= v;                     // xor-ing does not affect the randomness quality.

    numBits -= allotted;
    if (numBits) {
      // Update loop variables.
      bitPos += allotted;
      ++tailIndex;
      if (tailIndex == poolSize)
        tailIndex = 0;
      tailBit = 0;
    }
  }
}

[[combinable]]
void random_pool_server(server interface random_pool rpi[numClients], static const size_t numClients,
                        static const PoolSize_t poolSize) {
  if (!random_bit_claim()) {
    xassert(0); // "You can have only one random_pool_server task per tile."
  }

  // We will release when the last client has released us.
  // All clients have implicitly claimed us, set the 'numClients' lowest bits.
  xassert(numClients <= 32); // "The maximum number of clients is 32".
  uint32_t activeClients = (1ULL<<numClients) - 1;

  _rp_impl_type pool[poolSize];
  size_t head = 0; // The fill point.
  size_t tail = 0; // The removal point.

  uint32_t time = poolFill(head, tail, pool, poolSize);
  timer tmr;

  while(1) {
    select {
      case rpi[unsigned id].capacity() -> size_t numBits:
        numBits = poolSizeCapacity(poolSize);
        break;

      case rpi[unsigned id].available() -> size_t numBits:
        numBits = available(head, tail, poolSize);
       break;

      case rpi[unsigned id].timeUntil(size_t numBits) -> uint32_t period:
        if (numBits > poolSizeCapacity(poolSize))
          numBits = poolSizeCapacity(poolSize);
        size_t bits = available(head, tail, poolSize);
        period = (numBits < bits)? 0 : (numBits - bits) * TIME_FOR_ONE_BIT;
        break;

      case rpi[unsigned id].insert(uint32_t& value, size_t bitPos, size_t numBits) -> size_t bits:
        if (bitPos > 31)
          numBits = 0;
        if (numBits > sizeof(uint32_t)*8 - bitPos)
          numBits = sizeof(uint32_t)*8 - bitPos;
        size_t avail = available(head, tail, poolSize);
        bits = (numBits > avail)? avail : numBits;
        if (bits) {
          uint32_t local = value;  // Can't use remote-references as argument :-(
          xorInsert(local, bitPos, bits, tail, pool, poolSize);
          value = local;
        }
        break;

      case rpi[unsigned id].release():
        activeClients &= ~(1UL << id);
        if (!activeClients) {
          random_bit_release();
          return;
        }
        break;

      case  tmr when timerafter(time) :> void:
        time = poolFill(head, tail, pool, poolSize);
        break;
    }
  }
}
