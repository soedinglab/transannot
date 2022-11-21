#!/bin/sh -e
fail(){
    echo "Error: $1"
    exit 1
}

notExists(){
        [ ! -f "$1" ]
}

# pre-processing
echo "Please set PLASS to the current working directory!"
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
[ -f "${RESULTS}.dbtype" ] && "${RESULTS}.dbtype exists already! Assembly is already performed!" && echo 1;

if notExists "${ASSEMBLY}.fasta"; then
    #shellcheck disable=SC2086
    "$(pwd)"/plass/bin/plass assemble "$@" "${ASSEMBLY}" "${TMP_PATH}" ${ASSEMBLY_PAR} \
        || fail "plass assembly died"
fi

if notExists "${RESULTS}.dbtype"; then
    echo "creating mmseqs db from assembled transcriptome"
    #shellcheck disable=SC2086
    "$MMSEQS" createdb "${ASSEMBLY}" "${RESULTS}" ${CREATEDB_PAR} \
        || fail "createdb died"
fi

#remove temporary files
if [ -n "$REMOVE_TMP" ]; then
    echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}" 
fi