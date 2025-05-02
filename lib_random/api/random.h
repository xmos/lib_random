// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef _RANDOM_H_
#define _RANDOM_H_

#include <stdint.h>
#include <stddef.h>
#include <xccompat.h>

/** Type representing a random number generator.
 */
typedef unsigned random_generator_t;

/** Function that creates a random number generator from a seed.
 *
 * \param seed  seed for the generator.
 *
 * \returns     a random number generator.
 */
random_generator_t random_create_generator_from_seed(unsigned seed);

/** Function that attempts to create a random number generator from
 *  a ring-oscillator random value into the seed, using
 *  an asynchronous timer. This is based on a 16-bit start value.
 *  For better randomness, initialise the random number by calling
 *  random_ro_get_bits() 32 times.
 *
 *  \returns a random number generator.
 */
random_generator_t random_create_generator_from_hw_seed(void);

/** Function that produces a random number. The number has a cycle of 2^32
 *  and is produced using a LFSR.
 *
 *  \param g    the used generator to produce the seed.
 *
 *  \returns    a random 32 bit number.
 */
unsigned random_get_random_number(REFERENCE_PARAM(random_generator_t, g));

void random_get_random_bytes(REFERENCE_PARAM(random_generator_t, g), uint8_t in_buffer[], size_t byte_count);

/** Constant that defines at which tick-rate one can extract a random bit
 * This equates to 5,000 bits per second. Bench measurements show good random
 * properties down to 1000 (100,000 bits per second)
 */
#define RANDOM_RO_MIN_TIME_FOR_ONE_BIT 20000

/** Function that may produce a random bit using the ring-oscillator.
 * Before calling this function you must have called random_ro_init.
 *
 * If a random bit is available, then it returns 0 or 1 at random.
 *
 * If no random bits are available, then it returns a negative value which is
 * the time in ticks to wait before the next bit is available.
 *
 * \returns Random bit, or the negated time to wait in ticks.
 */
int random_ro_get_bit();

/** Function that initialises the ring-oscillator random number generator. Call this once
 * before
 * ``random_ro_get_bit()`` is called
 */
void random_ro_init();

/** Function that stops the ring oscillator, and reduce the power a little.
 */
void random_ro_uninit();

#endif // __RANDOM_H__
