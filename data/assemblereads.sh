#!/bin/sh -e
fail(){
    echo "Error: $1"
    exit 1
}

notExists(){
        [ ! -f "$1" ]
}

# pre-processing
# if ! command -v plass; then
#     echo "Please make sure that plass is installed." 
#     exit 1
# fi

[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

if notExists "${RESULTS}.fasta"; then
    #shellcheck disable=SC2086
    "$(pwd)"/plass/bin/plass assemble "$@" "${TMP_PATH}/assembly.fasta" "${TMP_PATH}" ${ASSEMBLY_PAR} \
        || fail "plass assembly died"
fi

if notExists "${RESULTS}.dbtype"; then
    echo "creating mmseqs db from assembled transcriptome"
    #shellcheck disable=SC2086
    "$MMSEQS" createdb "${TMP_PATH}/assembly.fasta" "${RESULTS}" --createdb-mode 1 ${CREATEDB_PAR} \
        || fail "createdb died"
fi

#remove temporary files
if [ -n "$REMOVE_TMP" ]; then
    echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}" 
fi