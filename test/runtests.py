#!/usr/bin/env python
import xmostest, sys, subprocess

if __name__ == "__main__":
    xmostest.init()
    xmostest.register_group("lib_random", "lib_random_tests", "lib_random library tests", "Tests random_bit.h, random_pool.h and random_prng.h")
    xmostest.runtests()
    xmostest.finish()

