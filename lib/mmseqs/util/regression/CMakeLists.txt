cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
project(MMseqs_benchmark)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")

include_directories(lib)
include_directories(lib/kseq)
add_executable(evaluate_results src/EvaluateResults.cpp src/EvaluateResults.h)

install(TARGETS evaluate_results DESTINATION bin)

