cmake_minimum_required(VERSION 3.15 FATAL_ERROR)
project(transannot CXX)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/lib/mmseqs/cmake")
#set(CFLAGS = -g -Wall -Wextra -pedantic -Werror -target x86_64-apple-darwin20.3.0)
#set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -march=native)
#set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -Wall -Wextra -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fsanitize=undefined -fsanitize=address")

set(FRAMEWORK_ONLY 1 CACHE INTERNAL "" FORCE)
include(MMseqsSetupDerivedTarget)
add_subdirectory(lib/mmseqs)
add_subdirectory(data)
include_directories(lib)
add_subdirectory(src)

