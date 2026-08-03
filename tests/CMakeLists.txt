cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(lib_crypto_tests)

add_subdirectory(test_pr)
add_subdirectory(test_ro)

