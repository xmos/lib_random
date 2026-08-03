cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)

project(test_pr)

set(XMOS_SANDBOX_DIR        ${CMAKE_CURRENT_LIST_DIR}/../../..)

set(APP_HW_TARGET           XK-EVK-XU316)

set(APP_DEPENDENT_MODULES   "lib_random")

set(APP_COMPILER_FLAGS      -Werror -O2 -fcmdline-buffer-bytes=1024)

set(APP_INCLUDES            src)


XMOS_REGISTER_APP()
