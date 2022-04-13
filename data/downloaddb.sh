#!/bin/sh -e

fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

[ -z "$1"] && echo "Default UniProtKB database will be downloaded." && INPUT="UniProtKB";

INPUT="$1" #database to download, default UniProtKB, see L14
OUT_PATH="$2"
TMP_PATH="$3"


