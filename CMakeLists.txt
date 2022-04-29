cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
project(transannot CXX)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/lib/mmseqs/cmake")

set(FRAMEWORK_ONLY 1 CACHE INTERNAL "" FORCE)
include(MMSeqsSetupDerivedTarget)

include_directories(lib/mmseqs)
include_directories(lib/plass)

add_subdirectory(lib/mmseqs)
add_subdirectory(lib/plass)
# we don't add httpie because it is python library
add_subdirectory(src)
add_subdirectory(data)