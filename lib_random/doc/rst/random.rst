.. include:: ../../../README.rst

API
---

To use the module you need to use ``lib_random`` in your application and
include only one of the ``api`` header files.
The three APIs are nested, hence you should choose the one that gives you
the required level of functionality.
In most cases, you will want to be using the top level, ``random_prng.h``.
The top level is built upon the lower level, hence access to entropy.

For alternative PRNG see stdlib.h which includes:
   rand, srand, rand_r, drand48, erand48, jrand48, lcong48, lrand48,
   mrand48, nrand48, seed48, srand48.

|appendix|

Known Issues
------------

.. include:: ../../../CHANGELOG.rst
