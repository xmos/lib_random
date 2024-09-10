Using lib_random
================

Overview
--------

This example demonstrates how to generate random values using the lib_random library.

It shows the two different methods for initialising a random number generator (software or hardware seed), and
then also shows how to generate either a single random value or populate an array with random values.

To build and run the example, run the following from an XTC tools terminal::

    cd examples/app_random
    cmake -G "Unix Makefiles" -B build

The application binaries can be built using ``xmake``::

    xmake -C build

To run the application using the simulator, run the following command::

    xsim bin/app_random.xe

The random data values will be printed in the terminal.

Required tools and libraries
............................

  * XMOS XTC Tools: 15.3.0

