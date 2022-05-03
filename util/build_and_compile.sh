#!/bin/sh -e

[ -d build ] && rm -rf build;
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..
make
make install
#shellcheck disable=SC2086
PATH=$(pwd)/bin/:$PATH
export PATH