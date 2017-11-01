// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved
#ifndef __RANDOM_H__
#define __RANDOM_H__

#include <stdint.h>
#include <stddef.h>

#ifndef REFERENCE_PARAM
#ifdef __XC__
#define REFERENCE_PARAM(type, name) type &name
#else
#define REFERENCE_PARAM(type, name) type *name
#endif
#endif

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
 *  a true random value into the seed, using
 *  an asynchronous timer. To use this function you must enable the
 *  ``RANDOM_ENABLE_HW_SEED`` define in your application's ``random_conf.h``.
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
unsigned
random_get_random_number(REFERENCE_PARAM(random_generator_t, g));

void random_get_random_bytes(REFERENCE_PARAM(random_generator_t, g), uint8_t in_buffer[], size_t byte_count);

#ifdef __XC__
/** Function that produces a number of random bits. It returns two
 * integers.
 *
 * If random bits are available, then it returns the number of random bits,
 * and the actual random bits.
 *
 * If no random bits are available, then it returns 0 (for no random bits)
 * and the time in ticks at which new bits are available. The code can wait
 * for this time (for example in a select statement), and then collect the
 * random bits.
 * 
 * At most 16 random bits are returned. To get a large number of random
 * bits this function should be called regularly. Calling it too quickly
 * since a previous call will return 0.
 *
 * \returns Number of bits, and random bits, or 0 and timestamp in the future.
 */
{uint32_t,int32_t} random_true_get_bits();

/** Function that initialises the true random number generator. Calling
 * this function will start the free running oscillator. This will take a
 * bit of extra power.
 */
void random_true_init();

/** Function that uninitialises the true random number generator. This will
 * stop the ring oscillator, and reduce the power foot print a little.
 */
void random_true_uninit();
#endif

#endif // __RANDOM_H__
