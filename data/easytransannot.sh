#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

# pre-processing
# if ! command -v plass; then
#     echo "Please make sure that PLASS is installed"
#     exit 1;
# fi

[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
[ -f "${RESULTS}.dbtype" ] && echo "${RESULTS}.dbtype exists already!" && exit 1;
# [ ! -d "${TMP_PATH}" ] && echo "tmp directory ${TMP_PATH} not found! tmp will be created." && mkdir -p "${TMP_PATH}";

if notExists "${INPUT}.dbtype"; then
    #shellcheck disable=SC2086
    "${MMSEQS}" assemblereads "$@" "${TMP_PATH}/assembly" "${TMP_PATH}/inputDB" "${TMP_PATH}" ${ASSEMBLEREADS_PAR} \
        || fail "plass assembly died"
fi

if notExists "${SEQ_TARGET}.dbtype"; then
    echo "sequence target DB not found and will be downloaded."
    #shellcheck disable=SC2086
    "${MMSEQS}" downloaddb "${SEQ_TARGET}" "${SEQ_TARGET}DB" "${TMP_PATH}/downloaddb_tmp" ${DOWNLOADDB_PAR} \
        || fail "download sequence targetDB died"
fi

if notExists "${PROF1_TARGET}.dbtype"; then
    echo "first profile target DB not found and will be downloaded."
    #shellcheck disable=SC2086
    "${MMSEQS}" downloaddb "${PROF1_TARGET}" "${PROF1_TARGET}DB" "${TMP_PATH}/downloaddb_tmp" ${DOWNLOADDB_PAR} \
        || fail "download first profile targetDB died"
fi

if notExists "${PROF2_TARGET}.dbtype"; then
    echo "second profile targte DB not found and will be downloaded."
    #shellcheck disable=SC2086
    "${MMSEQS}" downloaddb "${PROF2_TARGET}" "${PROF2_TARGET}DB" "${TMP_PATH}/downloaddb_tmp" ${DOWNLOADDB_PAR} \
        || fail "download second profile targetDB died"
fi

if notExists "${RESULTS}.dbtype"; then
    #shellcheck disable=SC2086
    "${MMSEQS}" annotate "${TMP_PATH}/inputDB" "${PROF1_TARGET}DB" "${PROF2_TARGET}DB" "${SEQ_TARGET}DB" "${RESULTS}" "${TMP_PATH}/annotate_tmp" ${ANNOTATE_PAR} \
        || fail "annotate died"
fi

#remove temporary files
if [ -n "$REMOVE_TMP" ]; then
    echo "Remove temporary files and directories"
    #shellcheck disable=SC2086
    "${MMSEQS}" rmdb "${PROF1_TARGET}DB" ${VERBOSITY}
    #shellcheck disable=SC2086
    "${MMSEQS}" rmdb "${PROF2_TARGET}DB" ${VERBOSITY}
    #shellcheck disable=SC2086
    "${MMSEQS}" rmdb "${SEQ_TARGET}DB" ${VERBOSITY}
    rm -f "${TMP_PATH}/easytransannot.sh" 
fi