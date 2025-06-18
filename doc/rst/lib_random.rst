
####################################
lib_random: Random number generation
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

An example demonstrating how to generate random values using the ``lib_random`` library is provided
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

*************
API reference
*************

There are two random-number APIs available, one API that creates fast pseudo-random
numbers using a linear-feedback-shift register, one that slowly creates
random bits. A third API enables you to switch the ring oscillator off.

=============
Pseudo random
=============

The Pseudo random number generator uses a 32-bit LFSR to generate a pseudo
random string of random bits. This has known weaknesses but is exceedingly
fast. It comprises the following functions:

.. doxygenfunction:: random_create_generator_from_seed
.. doxygenfunction:: random_create_generator_from_hw_seed
.. doxygenfunction:: random_get_random_number
.. doxygenfunction:: random_get_random_bytes

======================
Ring oscillator random
======================

This interface uses the on-chip ring oscillators to create a random bit
after some time has elapsed. These bits are notionally true random. The bit
rate is limited by a constant ``RANDOM_RO_MIN_TIME_FOR_ONE_BIT``. The
default value is a safe value that should produce random bits in most
circumstances. You can lower it in order to generate more random bits per
second at a risk of introducing correlation.

.. doxygenfunction:: random_ro_init
.. doxygenfunction:: random_ro_get_bit

============================
Switching random numbers off
============================

The random library switches on a ring oscillator on startup. If it is no
longer required it can be switched off to save some power.

.. doxygenfunction:: random_ro_uninit

   
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

