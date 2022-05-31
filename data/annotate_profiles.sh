#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your binary." && exit 1;
[ "$#" -ne 4 ] && echo "Please provide <assembled transcriptome> <targetDB> <outDB> <tmp>." && exit 1;
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs DB is already created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[   -f "$3.dbtype" ] && echo "$3.dbtype exists already!" && exit 1;
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4";

INPUT="$1"
TARGET="$2" #profile database, for example EggNOG
RESULTS="$3"
TMP_PATH="$4"

#run rbh -> alignment
if notExists "${TMP_PATH}/alignmentDB.dbtype"; then
    #shellcheck disable=SC2086
    "$MMSEQS" rbh "${INPUT}" "${TARGET}" "${TMP_PATH}/alignmentDB" ${SEARCH_PAR} \
        || fail "rbh search died"
fi

#create profile
if notExists "${TMP_PATH}/profileDB.dbtype"; then
    #shellcheck disable=SC2086
    $RUNNER "$MMSEQS" result2profile "$INPUT" "$TARGET" "${TMP_PATH}/alignmentDB" "${TMP_PATH}/profileDB" ${TMP} \
        || fail "creating profile died"
fi

#profile/profile search
if notExists "${RESULTS}.dbtype"; then
    #shellcheck disable=SC2086
    "$MMSEQS" search "${TMP_PATH}/profileDB" "$TARGET" "${RESULTS}" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
        || fail "profile-profile search died"
fi

if [ -n "${REMOVE_TMP}" ]; then
    rm -f "${TMP_PATH}/annotate_profiles.sh"
fi