// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef __RANDOM_POOL_H__
#define __RANDOM_POOL_H__

#include <stdint.h>
#include <stddef.h>
#include "random_impl.h"

/** Interface for clients to request bits from a random pool.
 *
 * Multiple clients, situated on any tile, may receive bits from a server.
 * There may be only one server per tile.
 *
 * The server task calls random_bit_claim() for the tile.
 * If the claim fails, the task will exit immediately.
 */
interface random_pool {
/** Method that returns the maximum bits a pool can hold. */
  size_t capacity();

/** Method that returns the number of bits available in the pool. */
  size_t available();

/** Method that returns the approximate period until `bits` will be available.
 *
 * Clients may then callback or sleep whilst waiting for the pool to fill.
 * The client will need to do multiple `fetch()` followed by waits if
 * there are multiple clients calling `fetch() or if `bits` > `capacity()`.
 */
  uint32_t timeUntil(size_t bits);

/** Method that overwrites `value[ bitPos : bitPos+numBits ]` with random bits.
 *
 * The bit range will be truncated to fit within value[].
 *
 * \returns   The number of bits overwritten, starting at 'bitPos'.
 *            This will be the same as numBits if the bits are available.
 */
  size_t insert(uint32_t& value, size_t bitPos, size_t numBits);

/** Method exits the random_pool server task when all clients have released.
 *
 *  This allows a combined-par to exit if/when the client owning tasks exits.
 *  random_bit_release() will be called, allowing another task to claim it.
 */
  void release();
};

/** Type represents an opaque bit pool size. */
typedef size_t PoolSize_t;

/** Helper function for turning the minimum number of bits into a `PoolSize_t` opaque value.
 *
 *  N.B. As `PoolSize_t` values are opaque, they must be generated via this function!
 *  PoolSize_t bitsToPoolSize(size_t bits);
 */
#define bitsToPoolSize(bits) _bitsToPoolSize(bits)

/** Server task that collects random bits into a pool.
 *
 * The server task may be combined with other tasks in a combined-par statement.
 * There may be one server task per tile (as there is only one random_bit generator per tile).
 * Clients may then request random bits from the sever task's pool via the `interface random_pool`.
 * There may be multiple clients, situated on a mixture of tile.
 *
 * \param rpi        Server end of an `interface random_pool`.
 * \param n          Number of `client interface random_pool`s being served.
 * \param poolSize   Size of random bit pool to create - N.B. use bitsToPoolSize() to generate the value.
 */
[[combinable]]
void random_pool_server(server interface random_pool rpi[n], static const size_t n,
                        static const PoolSize_t poolSize);

#endif // __RANDOM_POOL_H__
