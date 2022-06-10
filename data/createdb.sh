#!/bin/sh -e

fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

#get absolute pathway function
abspath(){
    if [ -d "$1" ]; then
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then #if file exists
        if [ -z "${1##*/*}" ]; then
            echo "$(cd "${1%/*}"; pwd)/${13##*/}"
        else
            echo "$(pwd)/$1"
        fi
    elif [ -d "$(dirname "$1")" ]; then #if directory to $1 exists
            echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}

#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
[ "$#" -ne 3 ] && echo "Please provide <assembled transcriptome> <outDB> <tmp>" && exit 1;
[ ! -d "$2" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4";

INPUT="$1" #assembled transcriptome
OUT_DB="$(abspath "$2")"
TMP_PATH="$(abspath "$3")"

if notExists "${OUT_DB}.dbtype"; then
    if notExists "${INPUT}.dbtype"; then
        #shellcheck disable=SC2086
        "${MMSEQS}" createdb "${INPUT}" "${OUT_DB}" ${CREATEDB_PAR} \
            || fail "createdb died"
    else #if db is already created
        cp -f "$1" "${OUT_DB}"
        cp -f "$1.dbtype" "${OUT_DB}.dbtype"
        cp -f "$1.index" "${OUT_DB}.index"
        cp -f "$1.lookup" "${OUT_DB}.lookup"
        cp -f "$1_h" "${OUT_DB}_h"
        cp -f "$1_h.index" "${OUT_DB}_h.index"
        cp -f "$1_h.dbtype" "${OUT_DB}_h.dbtype"
    fi
fi

if [ -n "${REMOVE_TMP}" ]; then
    echo "Remove temporary files"
    rm -f "${TMP_PATH}/createdb.sh"
fi