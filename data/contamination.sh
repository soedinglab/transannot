#!/bin/sh -e

fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
    [ ! -f "$1" ]
}

#pre-processing
[-z "$MMSEQS"] && echo "Please set the environment variable \$MMSEQS to your current binary" && exit 1;
#["$#" -ne 2] && echo "Please provide <queryDB> <tmp>" && exit 1;

if notExists "${TMP_PATH}/queryDB"; then
    #shellcheck disable=SC
    "$MMSEQS" createdb "${RESULTS}/plass_assembly.fas" "${TMP_PATH}/queryDB" "${CREATEDB_PAR}" \
        || fail "Create database died"
fi


"$MMSEQS" taxonomy 

if [ -n "$REMOVE_TMP" ]; then
    #shellcheck disable=SC
    echo "Remove temporary files and directories"
    rm -f "${TMP_PATH}/contamination.sh"
fi