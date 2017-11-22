// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef __RANDOM_BIT_H__
#define __RANDOM_BIT_H__

#include <stdint.h>
#include <stddef.h>

#ifndef REFERENCE_PARAM
#ifdef __XC__
#define REFERENCE_PARAM(type, name) type &name
#else
#define REFERENCE_PARAM(type, name) type *name
#endif
#endif


/** The random_bit.h library is NOT thread safe.
 *
 * There is one oscillator per tile, hence there may be one user of the library per tile.
 * However, on a multi-tile device, each tile may have one thread calling the library.
 */


/** Functions used to claim and release the random_bit library.
 *
 * As is only one oscillator per tile, there may only be one user of the
 * library per tile.
 *
 * random_bit_claim() returns 0 if the library has already been claimed on
 * this tile.
 *
 * N.B. Ownership of the library does not prevent others from calling it!
 */
int random_bit_claim();
void random_bit_release();

/** Functions that start & stop the random number generator.
 *
 * Calling this function will start/stop the free running oscillator.
 * A running oscillator will increase power consumption by a few mW.
 *
 * N.B. There is no checking that the caller has previously claimed the library.
 */
void random_bit_start();
void random_bit_stop();

/** Function that produces a random bit.
 *
 * If random bits are available, then it returns '1' and the random bit.
 *
 * If no random bits are available, then it returns 0 and the absolute
 * time in ticks at which a bit will be available.
 * The calling code may then wait until this time (for example in a select statement),
 * recalling the function when the bit will be available.
 *
 * N.B. There is no checking that the caller has previously claimed the library.
 */
uint32_t random_bit(REFERENCE_PARAM(uint32_t, bit_time));

#endif // __RANDOM_BIT_H__
