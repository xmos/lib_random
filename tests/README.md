# lib_random Tests

This directory contains xCore tests for the lib_random library.

## Test Coverage

The test suite covers all public API functions:

### Pseudo-Random Number Generation
- `random_create_generator_from_seed()` - Tests deterministic seed behavior
- `random_get_random_number()` - Tests number generation and state changes
- `random_get_random_bytes()` - Tests byte array generation

### Hardware-Based Random Generation
- `random_create_generator_from_hw_seed()` - Tests hardware seed initialization
- `random_ro_init()` - Tests ring oscillator initialization
- `random_ro_get_bit()` - Tests individual bit generation
- `random_ro_uninit()` - Tests ring oscillator cleanup

### Statistical Properties
- Basic distribution tests for generated values
- Uniqueness tests for generated sequences
- Edge case testing

## Building and Running

To build the tests (requires XMOS XTC Tools):

```bash
cd tests
cmake -G "Unix Makefiles" -B build
xmake -C build
```

To run the tests:

```bash
xsim build/bin/test_lib_random.xe
```

## Test Results

The test suite outputs PASS/FAIL for each individual test and provides a summary at the end. A return code of 0 indicates all tests passed.