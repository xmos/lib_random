#!/usr/bin/env python
import xmostest

def runtest():
    resources = xmostest.request_resource("xsim")

    tester = xmostest.ComparisonTester(open('random/expected.output'),
                                       'lib_random',
                                       'lib_random_tests',
                                       'random', {})

    xmostest.run_on_simulator(resources['xsim'],
                              'random/bin/random.xe',
                              tester=tester)

