
####################################
lib_random: Random Number Generation
####################################

************
Introduction
************

This library provides both hardware and software random number generation.

Hardware based generation uses an asynchronous oscillator in the `xcore` device.

*****
Usage
*****

To use the module you need to use ``lib_random`` in your application `CMakeLists.txt`, for example::

    set(APP_DEPENDENT_MODULES "lib_random")

An application should then the ``random.h`` header file::

    #include "random.h"

*******
Example
*******

An example demonstrating how to generate random values using the ``lib_random`` library is provide
in `examples/app_random`

It shows the two different methods for initialising a random number generator (software or hardware
seed), and then also shows how to generate either a single random value or populate an array with
random values.

To build and run the example, run the following from an XTC tools terminal::

    cd examples/app_random
    cmake -G "Unix Makefiles" -B build

The application binaries can be built using ``xmake``::

    xmake -C build

To run the application using the simulator, run the following command::

    xsim bin/app_random.xe

The random data values will be printed in the terminal.

|newpage|

.. _sec_further_reading:

***************
Further Reading
***************

  * `XMOS` XTC Tools Installation Guide

    https://xmos.com/xtc-install-guide

  * `XMOS` XTC Tools User Guide

    https://www.xmos.com/view/Tools-15-Documentation

  * `XMOS` application build and dependency management system; `xcommon-cmake`

    https://www.xmos.com/file/xcommon-cmake-documentation/?version=latest

