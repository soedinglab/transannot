#!/bin/sh -e

fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

[-z "$MMSEQS"] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;