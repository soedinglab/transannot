#!/bin/sh -e

fail(){
    echo "Error: $1"
    exit 1
}

notExists(){
        [ ! -f "$1" ]
}

#pre-processing
[ -z "$PLASS"] && echo "Please set the environment variable \$PLASS to your current binary." && exit 1;