TARGET = SLICEKIT-L16
APP_NAME =
USED_MODULES = lib_random

XCC_FLAGS = -Os -g
#XCC_FLAGS += -save-temps -v

# RANDOM_ENABLE_HW_SEED must either:
#    not be declared at all
#    or if it is, take the value '0'.
# We chose the second option here as an example, other tests do not declare it at all.
# N.B. We expect random_deprecated.c not to be built.
RANDOM_ENABLE_HW_SEED=0

VERBOSE = 0

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
