#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

#pre-processing
if ! command -v plass; then
    echo "Please make sure that PLASS is installed"
    exit
fi
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
[ "$#" -ne 4 ] && echo "Please provide <inputSeq> <target> <outDB> <tmpPath>!" && exit 1;
[ -f "$3.dbtype" ] && echo "$3.dbtype exists already!" && exit 1;
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4";

#TODO: assign INPUT, TARGET and so on in cpp code
INPUT="$1"
TARGET="$2" #selection to downloaddb
RESULTS="$3"
TMP_PATH="$4"

if notExists "${INPUT}.dbtype"; then
    #shellcheck disable=SC2086
    "${MMSEQS}" assemblereads "${INPUT}" "${TMP_PATH}/assembly" "${TMP_PATH}/plass_tmp" ${ASSEMBLEREADS_PAR} \
        || fail "plass assembly died"
fi

if notExists "${TARGET}.dbtype"; then
    #shellcheck disable=SC2086
    "${MMSEQS}" downloaddb "${TARGET}" "${TARGET}DB" "${TMP_PATH}/downloaddb_tmp" ${DOWNLOADDB_PAR} \
        || fail "download targetDB died"
fi

if notExists "${RESULTS}.dbtype"; then
    #shellcheck disable=SC2086
    "${MMSEQS}" annotate "${TMP_PATH}/assembly" "${TARGET}DB" "${RESULTS}" "${TMP_PATH}/annotate_tmp" ${ANNOTATE_PAR} \
        || fail "annotate died"
fi

#remove temporary files
if [ -n "$REMOVE_TMP" ]; then
    echo "Remove temporary files and directories"
    #shellcheck disable=SC2086
    "${MMSEQS}" rmdb "${TARGET}DB" ${VERBOSITY}
    rm -f "${TMP_PATH}/easytransannot.sh" 
fi