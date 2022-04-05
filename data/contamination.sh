#!/bin/bash

fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
    [ ! -f "$1" ]
}

#pre-processing
[-z "$MMSEQS"] && echo "Please set the environment variable \$MMSEQS to your current binary" && exit 1;
["$#" -ne 2] && echo "Please provide <queryDB> <tmp>" && exit 1;

"$MMSEQS" createdb "${INPUT}" "${seqTaxDB}" "${CREATEDB_PAR}" \
    || fail "Create database died"

"$MMSEQS" taxonomy 