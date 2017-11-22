#!/usr/bin/env python
import xmostest

def runtest():
    resources = xmostest.request_resource("xsim")

    tester = xmostest.ComparisonTester(open('random_pool/expected.output'),
                                       'lib_random',
                                       'lib_random_tests',
                                       'random_pool', {})

    xmostest.run_on_simulator(resources['xsim'],
                              'random_pool/bin/random_pool.xe',
                              tester=tester)

