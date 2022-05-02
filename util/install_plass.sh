#!/bin/bash -e
if ! command -v plass; then
    if ! command -v cmake; then
        echo "Please make sure cmake is installed." && exit 1;
    fi
    git clone https://github.com/soedinglab/plass.git
    cd plass
    git submodule update --init
    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..
    make -j 4 && make install
    export PATH="$(pwd)/bin/:$PATH"
fi