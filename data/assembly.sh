#!/bin/sh -e
fail(){
    echo "Error: $1"
    exit 1
}

notExists(){
        [ ! -f "$1" ]
}

#pre-processing
[ -z "$PLASS"] && echo "Please set the environment variable \$PLASS to your current binary." && exit 1;

INPUT="$1"
RESULTS="$2"
TMP_PATH="$3"

mkdir -p "${TMP_PATH}/plass_tmp"
if notExists "${RESULTS}/plass_assembly.fas"; then
    #shellcheck disable=SC2086
    "$PLASS" assemble "${INPUT}" "${RESULTS}/plass_assembly.fas" "${TMP_PATH}/plass_tmp" ${ASSEMBLY_PAR} \
        || fail "PLASS assembly died"
fi

#remove temporary files
if [ -n "$REMOVE_TMP" ]; then
    #shellcheck disable=SC2086
    echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}/plass_tmp"
    rm -f "${TMP_PATH}/assembly.sh" 
fi