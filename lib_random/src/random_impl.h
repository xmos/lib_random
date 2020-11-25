// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef __RANDOM_IMPL_H__
#define __RANDOM_IMPL_H__

#include <stdint.h>

// Used by random_bit() & random_pool_server()
#define TIME_FOR_ONE_BIT 20000

// N.B. _rp_impl_type is NOT part of the interface.
//      as part of the implementation it may change at any time.
typedef uint8_t _rp_impl_type;
// random_pool_server() : assert(sizeof(uint32_t) >= sizeof(_rp_impl_type) && "memcpy needs fixing");


// N.B. The implementation requires an extra bit for indexing efficiency,
//      hence we do NOT use `(b+(N-1))/N` rounding.
#define _bitsToPoolSize(bits) (((bits) / (sizeof(_rp_impl_type)*8)) + 1)

#endif // __RANDOM_IMPL_H__
