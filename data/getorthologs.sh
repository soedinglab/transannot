#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db is already created." && exit 1;
[   -f "$2.dbtype" ] && echo "$2.dbtype exists already!" && exit 1; 
[ ! -d "$3" ] && echo "tmp directory $3 not found! tmp will be created." && mkdir -p "$3";

INPUT="$1"
OUTDB="$2"
TMP_PATH="$3"

if notExists "eggNOG.dbtype"; then
    #shellcheck disable=SC2086
    "$MMSEQS" databases "eggNOG" "eggNOG" "${TMP_PATH}/downloaddb_tmp" \
        || fail "download eggNOG died"
fi

if notExists "${TMP_PATH}/clu.dbtype"; then
    #shellcheck disable=SC2086
    "$MMSEQS" linclust "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_tmp" \
        || fail "linclust died"

    #shellcheck disable=SC2086
	"$MMSEQS" result2repseq "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_rep" ${RESULT2REPSEQ_PAR} \
		|| fail "extract representative sequences died"
fi

if notExists "${OUTDB}.dbtype"; then
    #shellcheck disable=SC2086
	"$MMSEQS" search "${TMP_PATH}/clu_rep" "eggNOG" "${OUTDB}" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
		|| fail "search died"
fi

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	echo "Remove temporary files and directories"
    rm -rf "${TMP_PATH}/clu_tmp"
	rm -rf "${TMP_PATH}/search_tmp"
	rm -f "${TMP_PATH}/getorthologs.sh"
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/clu" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	rm -f "${TMP_PATH}/searchDB.csv" ${VERBOSITY_PAR}
fi