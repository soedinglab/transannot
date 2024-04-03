#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
        [ ! -f "$1" ]
}

hasCommand() {
    command -v "$1" >/dev/null 2>&1
}

abspath() {
    if [ -d "$1" ]; then
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        if [ -z "${1##*/*}" ]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    elif [ -d "$(dirname "$1")" ]; then
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}

convertalis_standard(){
	#shellcheck disable=SC2086
	"${MMSEQS}" convertalis "${TMP_PATH}/clu_rep" $1 $2 $3 --format-output "query,target,theader,evalue,pident,bits" --format-mode 4 \
		|| fail "convertalis died"
}

convertalis_simple(){
	#shellcheck disable=SC2086
	"${MMSEQS}" convertalis "${TMP_PATH}/clu_rep" $1 $2 $3 --format-output "query,target,theader,evalue" --format-mode 4 \
		|| fail "convertalis died"
}

preprocessDb(){
	#filter decreasing DBs by bit score and extract one best hit for each query

	#shellcheck disable=SC2086
	"${MMSEQS}" filterdb "$1" "${TMP_PATH}/bitscorefiltDB" --comparison-operator ge --comparison-value 50 --filter-column 2 \
		|| fail "filterdb died" 

	#shellcheck disable=SC2086
	"${MMSEQS}" filterdb "${TMP_PATH}/bitscorefiltDB" "${TMP_PATH}/bitscoresortedDB" --sort-entries 2 --filter-column 2 \
		|| fail "sort DB decreasing died"

	#shellcheck disable=SC2086
	"${MMSEQS}" filterdb "${TMP_PATH}/bitscoresortedDB" "$2" --extract-lines 1 \
		|| fail "extract best hit died"
	
	#shellcheck disable=SC2086
	"${MMSEQS}" rmdb "${TMP_PATH}/bitscorefiltDB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"${MMSEQS}" rmdb "${TMP_PATH}/bitscoresortedDB" ${VERBOSITY_PAR}
}

#check requierments
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

#there should be 4 inputs
[ "$#" -ne 4 ] && echo "Please provide <assembled transcriptome> <1-3 target DBs> <outDB> <>tmp" && exit 1;
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4";

[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db has already been created." && exit 1;

QUERY="$1"
RESULTS="$3"
TMP_PATH="$4"

#convert user-provided DBs into MMseqs DBs
if notExists "$2.dbtype"; then
	if notExists "$2"_db.dbtype; then
		echo "converting user-defined DB into MMseqs2 format."
		#shellcheck disable=SC2086
		"$MMSEQS" createdb "$2" "$2"_db ${CREATEDB_PAR} \
			|| fail "createdb died"
	fi
	TARGET="$2"_db
else
	TARGET="$2"
fi

#MMSEQS2 LINCLUST for the input DB redundancy reduction
if [ -z "${NO_LINCLUST}" ]; then

	echo "Perform linclust for redundancy reduction"

	if notExists "${TMP_PATH}/clu.dbtype"; then

		#shellcheck disable=SC2086
		"$MMSEQS" linclust "${QUERY}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_tmp" --min-seq-id 0.3 ${CLUSTER_PAR} \
			|| fail "linclust died"

		#shellcheck disable=SC2086
		"$MMSEQS" result2repseq "${QUERY}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_rep" ${RESULT2REPSEQ_PAR} \
			|| fail "extract representative sequences died"
	fi

elif [ -n "${NO_LINCLUST}" ]; then
	echo "No linclust will be performed"
	if notExists "${TMP_PATH}/clu_rep"; then
		#shellcheck disable=SC2086
		"$MMSEQS" cpdb "${QUERY}" "${TMP_PATH}/clu_rep" ${VERBOSITY} \
			|| fail "copy db died"
		
		#shellcheck disable=SC2086
		"$MMSEQS" cpdb "${QUERY}_h" "${TMP_PATH}/clu_rep_h" ${VERBOSITY} \
			|| fail "copy header db died"
	fi
fi

#search against the target db
if notExists "${TMP_PATH}/search_not_proc.dbtype"; then
    echo "Running MMseqs2 search"
    #shellcheck disable=SC2086
    "$MMSEQS" search "${TMP_PATH}/clu_rep" "${TARGET}" "${TMP_PATH}/search_not_proc" "${TMP_PATH}/tmp_search" ${SEARCH_PAR} \
        || fail "MMseqs2 search died"
fi

if notExists "${TMP_PATH}/search_not_proc_filt.dbtype"; then
	#TODO pre-process DB here -> "${TMP_PATH}/search_not_proc_filt"
	#filter output
	preprocessDb "${TMP_PATH}/search_not_proc" "${TMP_PATH}/search_not_proc_filt"
fi

#add headers
if [ -n "${SIMPLE_OUTPUT}" ]; then
	convertalis_simple "${TARGET}" "${TMP_PATH}/search_not_proc_filt" "${RESULTS}.tsv"
else
	echo "Standard output will be provided"
	convertalis_standard "${TARGET}" "${TMP_PATH}/search_not_proc_filt" "${RESULTS}.tsv"
fi

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	echo "Remove temporary files and directories"

	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/clu" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/search_not_proc" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/search_not_proc_filt" ${VERBOSITY_PAR}

	rm -f "${TMP_PATH}/annotate.sh"
fi
