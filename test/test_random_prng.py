#!/usr/bin/env python
import xmostest

def runtest():
    resources = xmostest.request_resource("xsim")

    tester = xmostest.ComparisonTester(open('random_prng/expected.output'),
                                       'lib_random',
                                       'lib_random_tests',
                                       'random_prng', {})

    xmostest.run_on_simulator(resources['xsim'],
                              'random_prng/bin/random_prng.xe',
                              tester=tester)

