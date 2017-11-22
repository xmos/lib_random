// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef __RANDOM_PRNG_H__
#define __RANDOM_PRNG_H__

#include <stdint.h>
#include <stddef.h>
#include "random_impl.h"
#include "random_pool.h"


/** Interface for a client to request pseudo-random numbers. */
interface random_prng {

/** Method that returns a pseudo-random number.
 *
 *  ====== WARNING ====================================================
 *  The PRNG is a simple CRC and hence is not cryptographically secure.
 *  Exposing a value outside of the chip exposes the entire sequence.
 *  See random_csprng for how to hash the PRNG to make it secure.
 *
 *  If n > 1, the PRNG will be called mulitple times to retrived 32bit values.
 */
  void value(uint32_t values[n], size_t n);

/** The following methods perturbe the PRNG with bits from a random_pool of true random bits.
 *  Each returns the numbe of bits actually taken from the random_pool.
 */
  size_t perturbe_nonBlocking(size_t numBits); // Returns the numBits actually used (available).
  size_t perturbe_blocking(size_t numBits);    // Blocks until 'numBits' are available to use.
  size_t perturbe_halfAvailableBits();         // Uses half the available bits in the pool.

/** Method exits the random_prng server task.
 *
 *  This allows a combined-par to exit if/when the client owning task exits.
 *  N.B. The user owns the random_pool client (passed to the server) and
 *       they must call `rpi.release()` when they have finished with it.
 */
  void release();
};

/** A type that specifies the repeat range for the PRNG
 *
 * There are 3 choices offering 32bit sequences of ~2^57, ~2^88 and ~2^113 in length.
 * The processing time will increase with the PrngSize.
 * The enumerated value is the number of uint32_t required to 'seed' the generator.
 */
typedef enum {prng57=2, prng88=3, prng113=4} PrngSize;

/** Server task that generates the pseudo-random number.
 *
 * This is a 1:1 relationship.
 * The call to perturbe_blocking() will 'sleep' both the client and server.
 * Being distributable, the server-code will be inlined into the client task.
 *
 * N.B. Using the same client (PRNG stream) for muliple consumers will result in
 *      the consumers recieving correlated numbers (shared state).
 *      If correlation is an issue, consumers must instantiate their own
 *      server-client pair with a unique seed.
 *
 * \param prngi     Server end of an `interface random_PRNG`.
 * \param rpi       Client end of an `interface random_pool`.
 * \param prngSize  Either 'prng57', 'prng88' or 'prng113'.
 * \param seed      Optional seed for the PRNG (or null)
 *                  N.B. each seed[] entry must be > 127, the default value is 128.
 */
[[distributable]]
void random_prng_server(server interface random_prng prngi, client interface random_pool rpi,
                        static const PrngSize prngSize, uint32_t (&?seed)[prngSize]);

#endif // __RANDOM_PRNG_H__
