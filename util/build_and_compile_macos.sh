#!/bin/sh -e
[ ! command -v gcc ] && echo "Please make sure gcc is installed!" && exit 1;
[ -d build ] && rm -rf build;
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. -DREQUIRE_OPENMP=0 ..
make
make install
#shellcheck disable=SC2086
PATH=$(pwd)/bin/:$PATH
export PATH