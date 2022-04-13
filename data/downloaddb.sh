#!/bin/sh -e

fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

[ -z "$1"] && echo "Default UniProtKB database will be downloaded." && SELECTION="UniProtKB";

SELECTION="$1" #database to download, default UniProtKB, see L14
OUTDB_PATH="$2"
TMP_PATH="$3"

if notExists "${OUTDB_PATH}/${SELECTION}.fasta.gz" # check $SELECTION is a valid term for MMSEQS databases. If not show error message and provide the list or is it already done by MMSEQS
    #shellcheck disable=SC
    "$MMSEQS" databases "${SELECTION}" "${OUTDB_PATH}/${SELECTION}.fasta.gz" "${TMP_PATH}/download_db.tmp"
        || fail "download database died"
fi
