// Copyright (c) 2017, XMOS Ltd, All rights reserved

// The expected usage is for validating against 'dieharder'
// axe --args bin/dieharder.xe -g prng57 -n -1 -o - -B | dieharder -g 200 -a

// We want raw stdio.h, not the safe version.
#define UNSAFE_LIBC
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <xs1.h>
#include "random_prng.h"

static const char*unsafe prngString(PrngSize prng) {
  unsafe {
    switch (prng) {
      case prng57: return "prng57";
      case prng88: return "prng88";
      case prng113: return "prng113";
      default: return "prngInvalid";
    }
  }
}

unsigned readArgs(unsigned argC, char*unsafe argV[],
             PrngSize& prng, unsigned& numValues, const char*unsafe& filename, unsigned& binary) {
  unsigned found_g = 0;
  unsigned found_n = 0;
  unsigned found_o = 0;
  binary = 0;

  if (argC == 7 || argC == 8) {
    for(unsigned i=1; i<argC; i+=2) {
      if (strcmp(argV[i], "-B") == 0) {
        binary = 1;
        --i; // Hack the incrementor.
      }
      if (strcmp(argV[i], "-n") == 0) {
        numValues = atoi(argV[i+1]);
        found_n = 1;
      }
      else if (strcmp(argV[i], "-o") == 0) {
        filename = argV[i+1];
        found_o = 1;
      }
      else if (strcmp(argV[i], "-g") == 0) {
        found_g = 1;
        if (strcmp(argV[i+1], "prng57") == 0)
          prng = prng57;
        else if (strcmp(argV[i+1], "prng88") == 0)
          prng = prng88;
        else if (strcmp(argV[i+1], "prng113") == 0)
          prng = prng113;
        else
          found_g = 0;
      }
    }
  }
  if (found_g && found_n && found_o && (argC == 7 || binary))
    return 1;
  if (!argC) {
    printf ("Usage: Rebuild .xe with `-fcmdline-buffer-bytes=<value>` set\n");
    printf ("       and make sure you pass commandline arg using `xsim --args ...` or `axe --args ...`\n");
  }
  else {
    printf ("Usage: `axe --args %s -g <prng57|prng88|prng113> -n <numValues|-1> -o <outfile|-> [-B]`\n", argV[0]);
    printf ("        -g <prng57|prng88|prng113> see random_prng.h and PrngSize for details;\n");
    printf ("        -n <numValues|-1>          the number of 32bit values to generate, or -1 (with -B) for continuous;\n");
    printf ("        -o <outfile|->             output file name, or '-' for stdout;\n");
    printf ("        -B                         to turn on binary output, otherwise output will be in ASCII dieharder format.\n");
  }
  return 0;
}

FILE*unsafe openOutFile(const char*unsafe filename, unsigned numValues, unsigned prng, unsigned binary) {
  FILE*unsafe fp = (strcmp(filename, "-") == 0) ? stdout :
                                                  fopen(filename, binary? "wb":"w");
  if (!fp)
    printf ("Unable to open output file %s\n", filename);
  else if (!binary) {
    fprintf(fp, "#==================================================================\n");
    fprintf(fp, "# generator random_prng.h %s seed=null\n", prngString(prng));
    fprintf(fp, "#==================================================================\n");
    fprintf(fp, "type: d\n");
    fprintf(fp, "count: %u\n", numValues);
    fprintf(fp, "numbit: 32\n");
  }
  return fp;
}

int main(unsigned argC, char*unsafe argV[argC]) {
  PrngSize prng = 0;
  unsigned numValues = 0;
  const char*unsafe filename;
  unsigned binary;
  unsafe {
    if (!readArgs(argC, argV, prng, numValues, filename, binary))
      return 1;
  }
  FILE*unsafe fp = openOutFile(filename, numValues, prng, binary);

  //interface random_pool rpi[1];
  par {
    //random_pool_server(rpi, 1, bitsToPoolSize(1)); // We wont be using it.
    {
      interface random_prng prngi;
      par {
        [[distribute]]
        random_prng_server(prngi, null, prng57, null);
        // random_prng_server(prngi, rpi[0], prng57, null);
        {
          // Client task.
          while (numValues) {
            enum{blkLen=1000};
            uint32_t values[blkLen];
            unsigned len = (blkLen < numValues)? blkLen : numValues;
            prngi.value(values, len);
            if (binary)
              fwrite(values, len, sizeof(uint32_t), fp);
            else
              for (unsigned i=0; i < len; ++i)
                fprintf(fp, "%10u\n", values[i]);
            if (!binary || numValues != (unsigned)(-1))
              numValues -= len;
          }
          fclose(fp);
          prngi.release();
        }
      }
      //rpi[0].release();
    }
  }
  return 0;
}
