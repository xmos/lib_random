#!/usr/bin/env python
import xmostest

def runtest():
    resources = xmostest.request_resource("xsim")

    tester = xmostest.ComparisonTester(open('random_bit/expected.output'),
                                       'lib_random',
                                       'lib_random_tests',
                                       'random_bit', {})

    xmostest.run_on_simulator(resources['xsim'],
                              'random_bit/bin/random_bit.xe',
                              tester=tester)

