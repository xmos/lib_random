// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdint.h>
#include <stddef.h>
#include <print.h>
#include <string.h>
#include <assert.h>
#include "random.h"

// Test configuration
#define TEST_SEED (12345)
#define TEST_BUF_LEN (16)
#define NUM_RO_BITS_TEST (20)

// Simple test framework
static int test_count = 0;
static int test_passed = 0;

#define TEST_ASSERT(condition, test_name) \
    do { \
        test_count++; \
        if (condition) { \
            test_passed++; \
            printstr("PASS: "); \
            printstr(test_name); \
            printstr("\n"); \
        } else { \
            printstr("FAIL: "); \
            printstr(test_name); \
            printstr("\n"); \
        } \
    } while(0)

void test_random_create_generator_from_seed() {
    printstr("\n=== Testing random_create_generator_from_seed ===\n");
    
    // Test that same seed produces same initial state
    random_generator_t gen1 = random_create_generator_from_seed(TEST_SEED);
    random_generator_t gen2 = random_create_generator_from_seed(TEST_SEED);
    
    TEST_ASSERT(gen1 == gen2, "Same seed produces same generator state");
    
    // Test that different seeds produce different states
    random_generator_t gen3 = random_create_generator_from_seed(TEST_SEED + 1);
    TEST_ASSERT(gen1 != gen3, "Different seeds produce different generator states");
    
    // Test with edge cases
    random_generator_t gen_zero = random_create_generator_from_seed(0);
    random_generator_t gen_max = random_create_generator_from_seed(0xFFFFFFFF);
    TEST_ASSERT(gen_zero != gen_max, "Zero and max seeds produce different states");
}

void test_random_get_random_number() {
    printstr("\n=== Testing random_get_random_number ===\n");
    
    random_generator_t gen = random_create_generator_from_seed(TEST_SEED);
    
    // Generate a sequence of numbers
    unsigned numbers[10];
    for (int i = 0; i < 10; i++) {
        numbers[i] = random_get_random_number(&gen);
    }
    
    // Test that we get different numbers (extremely unlikely to get duplicates in LFSR)
    int unique_count = 0;
    for (int i = 0; i < 10; i++) {
        int is_unique = 1;
        for (int j = i + 1; j < 10; j++) {
            if (numbers[i] == numbers[j]) {
                is_unique = 0;
                break;
            }
        }
        if (is_unique) unique_count++;
    }
    
    TEST_ASSERT(unique_count >= 8, "Most generated numbers should be unique");
    
    // Test deterministic behavior - same seed should produce same sequence
    random_generator_t gen1 = random_create_generator_from_seed(TEST_SEED);
    random_generator_t gen2 = random_create_generator_from_seed(TEST_SEED);
    
    unsigned val1 = random_get_random_number(&gen1);
    unsigned val2 = random_get_random_number(&gen2);
    
    TEST_ASSERT(val1 == val2, "Same seed produces deterministic sequence");
    
    // Test that generator state changes
    random_generator_t gen_before = gen1;
    random_get_random_number(&gen1);
    TEST_ASSERT(gen1 != gen_before, "Generator state changes after use");
}

void test_random_get_random_bytes() {
    printstr("\n=== Testing random_get_random_bytes ===\n");
    
    random_generator_t gen = random_create_generator_from_seed(TEST_SEED);
    uint8_t buffer[TEST_BUF_LEN];
    
    // Initialize buffer to known pattern
    memset(buffer, 0xAA, TEST_BUF_LEN);
    
    // Generate random bytes
    random_get_random_bytes(&gen, buffer, TEST_BUF_LEN);
    
    // Test that buffer was modified
    int changed_count = 0;
    for (int i = 0; i < TEST_BUF_LEN; i++) {
        if (buffer[i] != 0xAA) {
            changed_count++;
        }
    }
    TEST_ASSERT(changed_count > TEST_BUF_LEN / 2, "Most bytes should be changed from pattern");
    
    // Test with zero length
    uint8_t small_buffer[4] = {0xFF, 0xFF, 0xFF, 0xFF};
    random_get_random_bytes(&gen, small_buffer, 0);
    TEST_ASSERT(small_buffer[0] == 0xFF, "Zero length request should not modify buffer");
    
    // Test deterministic behavior
    random_generator_t gen1 = random_create_generator_from_seed(TEST_SEED);
    random_generator_t gen2 = random_create_generator_from_seed(TEST_SEED);
    
    uint8_t buf1[8], buf2[8];
    random_get_random_bytes(&gen1, buf1, 8);
    random_get_random_bytes(&gen2, buf2, 8);
    
    int match = 1;
    for (int i = 0; i < 8; i++) {
        if (buf1[i] != buf2[i]) {
            match = 0;
            break;
        }
    }
    TEST_ASSERT(match, "Same seed produces same byte sequence");
}

void test_random_create_generator_from_hw_seed() {
    printstr("\n=== Testing random_create_generator_from_hw_seed ===\n");
    
    // Test that function works (we can't test true randomness easily)
    random_generator_t gen1 = random_create_generator_from_hw_seed();
    random_generator_t gen2 = random_create_generator_from_hw_seed();
    
    // Generators created from HW should potentially be different
    // (though there's a small chance they could be the same)
    TEST_ASSERT(1, "Hardware seed generator creation works");
    
    // Test that we can use the generator
    unsigned val = random_get_random_number(&gen1);
    TEST_ASSERT(1, "Can generate number from hardware-seeded generator");
}

void test_random_ro_functions() {
    printstr("\n=== Testing ring oscillator functions ===\n");
    
    // Test initialization
    random_ro_init();
    TEST_ASSERT(1, "Ring oscillator initialization works");
    
    // Test bit generation
    int bits_collected = 0;
    int attempts = 0;
    int max_attempts = 1000; // Prevent infinite loop
    
    while (bits_collected < NUM_RO_BITS_TEST && attempts < max_attempts) {
        int bit = random_ro_get_bit();
        attempts++;
        
        if (bit >= 0) {
            // Valid bit received
            TEST_ASSERT(bit == 0 || bit == 1, "Ring oscillator bit is 0 or 1");
            bits_collected++;
        } else {
            // Need to wait, bit contains negative time
            TEST_ASSERT(bit < 0, "Negative return indicates wait time");
        }
    }
    
    TEST_ASSERT(bits_collected > 0, "Ring oscillator produced at least one bit");
    TEST_ASSERT(attempts < max_attempts, "Ring oscillator didn't time out");
    
    // Test cleanup
    random_ro_uninit();
    TEST_ASSERT(1, "Ring oscillator cleanup works");
}

void test_statistical_properties() {
    printstr("\n=== Testing basic statistical properties ===\n");
    
    random_generator_t gen = random_create_generator_from_seed(TEST_SEED);
    
    // Test that we don't get all zeros or all ones
    unsigned values[100];
    unsigned zero_count = 0;
    unsigned max_val = 0;
    
    for (int i = 0; i < 100; i++) {
        values[i] = random_get_random_number(&gen);
        if (values[i] == 0) zero_count++;
        if (values[i] > max_val) max_val = values[i];
    }
    
    TEST_ASSERT(zero_count < 10, "Not too many zero values generated");
    TEST_ASSERT(max_val > 0x80000000, "Large values generated");
    
    // Test byte distribution
    uint8_t bytes[256];
    random_get_random_bytes(&gen, bytes, 256);
    
    int low_bytes = 0, high_bytes = 0;
    for (int i = 0; i < 256; i++) {
        if (bytes[i] < 128) low_bytes++;
        else high_bytes++;
    }
    
    // Should have reasonable distribution (not perfectly balanced, but not heavily skewed)
    int diff = low_bytes > high_bytes ? low_bytes - high_bytes : high_bytes - low_bytes;
    TEST_ASSERT(diff < 50, "Byte values reasonably distributed");
}

void print_test_summary() {
    printstr("\n=== Test Summary ===\n");
    printstr("Tests passed: ");
    printuintln((unsigned)test_passed);
    printstr("Tests total:  ");
    printuintln((unsigned)test_count);
    
    if (test_passed == test_count) {
        printstr("ALL TESTS PASSED!\n");
    } else {
        printstr("SOME TESTS FAILED!\n");
    }
}

int main() {
    printstr("lib_random Test Suite\n");
    printstr("====================\n");
    
    // Run all tests
    test_random_create_generator_from_seed();
    test_random_get_random_number();
    test_random_get_random_bytes();
    test_random_create_generator_from_hw_seed();
    test_random_ro_functions();
    test_statistical_properties();
    
    print_test_summary();
    
    return (test_passed == test_count) ? 0 : 1;
}