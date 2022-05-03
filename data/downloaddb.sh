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
[ "$#" -ne 3 ] && echo "Please provide <selection> <outDBpath> <tmp>." && exit 1;
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

SELECTION="$1"
OUTDB="$(abspath "$2")"
TMP_PATH="$(abspath "$3")"

mkdir -p "${TMP_PATH}/download_db.tmp"
if notExists "${OUTDB}/${SELECTION}/.dbtype"; then
    #shellcheck disable=SC2086
    "$MMSEQS" databases "${SELECTION}" "${OUTDB}/${SELECTION}DB" "${TMP_PATH}/download_db.tmp" ${DOWNLOADDB_PAR} \
        || fail "download database died"
fi

# downloaddb creates db as well

if [ -n "$REMOVE_TMP" ]; then
    #shellcheck disable=SC2086
    echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}/download_db.tmp"
    rm -f "${TMP_PATH}/downloaddb.sh"
fi