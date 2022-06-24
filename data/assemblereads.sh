#!/bin/sh -e
fail(){
    echo "Error: $1"
    exit 1
}

notExists(){
        [ ! -f "$1" ]
}

#pre-processing
if ! command -v plass; then
    echo "Please make sure that plass is installed." 
    exit 1
fi
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

INPUT="$1"
RESULTS="$2"
TMP_PATH="$3"

#mkdir -p "${TMP_PATH}/plass_tmp"
if notExists "${RESULTS}/assembly.fasta"; then
    #shellcheck disable=SC2086
    plass assemble "${INPUT}" "${TMP_PATH}/assembly.fasta" "${TMP_PATH}/plass_tmp" ${ASSEMBLY_PAR} \
        || fail "plass assembly died"
fi

if notExists "${RESULTS}.dbtype"; then
    echo "creating mmseqs db from assembled transcriptome"
    #shellcheck disable=SC2086
    "$MMSEQS" createdb "${TMP_PATH}/plass_assembly" "${RESULTS}" --createdb-mode 1 ${CREATEDB_PAR} \
        || fail "createdb died"
fi

#remove temporary files
if [ -n "$REMOVE_TMP" ]; then
    #shellcheck disable=SC2086
    echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}/plass_tmp"
    rm -f "${TMP_PATH}/assemble.sh" 
fi