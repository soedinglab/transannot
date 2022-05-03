#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
    [ ! -f "$1" ]
}

#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary" && exit 1;
[ "$#" -ne 4 ] && echo "Please provide <InputSeq> <targetDB> <outPath> <tmp>" && exit 1; #easytaxonomy takes fasta file as an input
[ ! -f "$2.dbtype" ] && echo "Please make sure proper target database is provided and mmseqs database is created!" && exit 1;
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4";

INPUT="$1"
TARGET="$2"
OUT_PATH="$3"
TMP_PATH="$4"

#if notExists "${TARGET}.dbtype"; then
#    #shellcheck disable=SC2086
#    "$MMSEQS" createdb "${TARGET}" "${TMP_PATH}/target" ${CREATEDB_PAR} \
#        || fail "create targetDB died"
#fi

#only INPUT goes to this script, everything else will be automatically generated in easytaxonomy
#only one variable should be given

mkdir -p "${TMP_PATH}/easy_taxonomy_tmp"
#shellcheck disable=SC2086
"$MMSEQS" easy-taxonomy "${INPUT}" "${TARGET}" "${OUT_PATH}/taxonomyReport" "${TMP_PATH}/easy_taxonomy_tmp" ${EASYTAXONOMY_PAR} \
        || fail "easytaxonomy died"

#easy taxonomy returns output in .tsv format

if [ -n "$REMOVE_TMP" ]; then
    #shellcheck disable=SC2086
    echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}/easy_taxonomy_tmp"
    rm -f "${TMP_PATH}/contamination.sh"
fi