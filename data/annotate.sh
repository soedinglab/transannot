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

#we obtain best hits from targetDB based on sequence identity
filterDb() {
	awk '{if (($12>=50) && ($3>=0.6)) print $1, $2, $3}' "$1" | sort -n -k3 | awk '!seen[$1]++' | awk '{print $1, $2}' |sort -s -k1b,1 >> "$2"
}

filterDb_standard() {
	awk '{if (($12>=50) && ($3>=0.6)) print $1, $2, $3, $12}' "$1" | sort -n -k3 | awk '!seen[$1]++' | sort -s -k1b,1 >> "$2"
}

#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

#checking how many input variables are provided
[ "$#" -ne 5 ] && echo "Please provide <assembled transciptome> <profile target DB> <sequence target DB> <outDB> <tmp>" && exit 1;
[ "$("${MMSEQS}" dbtype "$2")" != "Profile" ] && echo "The given target database is not profile! Please download profileDB or create from existing sequenceDB!" && exit 1;
[ "$("${MMSEQS}" dbtype "$3")" = "Profile" ] && echo "The given target database is profile! Please provide sequence DB!" && exit 1;

#checking whether files already exist
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db is already created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[ ! -f "$3.dbtype" ] && echo "$3.dbtype not found!" && exit 1;
[   -f "$4.dbtype" ] && echo "$4.dbtype exists already!" && exit 1; 
[ ! -d "$5" ] && echo "tmp directory $5 not found! tmp will be created." && mkdir -p "$5"; 

INPUT="$1" #assembled sequence
PROFILE_TARGET="$2"  #already downloaded database
TARGET="$3"
RESULTS="$4"
TMP_PATH="$5" 

#MMSEQS2 LINCLUST for the redundancy reduction
if notExists "${TMP_PATH}/clu.dbtype"; then
	#shellcheck disable=SC2086
	"$MMSEQS" linclust "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_tmp" ${CLUSTER_PAR} \
		|| fail "linclust died"

	#shellcheck disable=SC2086
	"$MMSEQS" result2repseq "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_rep" ${RESULT2REPSEQ_PAR} \
		|| fail "extract representative sequences died"
fi

if [ -n "${TAXONOMY_ID}" ]; then
	
	echo "Taxonomy ID is provided. rbh will be run against known organism's proteins"
	if notExists "${RESULTS}.dbtype"; then
		#shellcheck disable=SC2086
		"$MMSEQS" rbh "${INPUT}" "${PROFILE_TARGET}" "${TMP_PATH}/searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
			|| fail "rbh search died"
	fi
		

	elif [ -z "${TAXONOMY_ID}" ]; then
		if notExists "${RESULTS}.dbtype"; then
		echo "No taxonomy ID is provided. Sequence-profile search will be run"
			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${PROFILE_TARGET}" "${TMP_PATH}/prof_searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
				|| fail "sequence-profile search died"

			if notExists "${TMP_PATH}/prof_searchDB.csv"; then
				#shellcheck disable=SC2086
				"$MMSEQS" convertalis "${TMP_PATH}/clu_rep" "${PROFILE_TARGET}" "${TMP_PATH}/prof_searchDB" "${TMP_PATH}/prof_searchDB.csv" \
					|| fail "converatalis died"
			fi
			rm -f "${TMP_PATH}/prof_searchDB."[0-9]*

			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${TARGET}" "${TMP_PATH}/seq_searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
				|| fail "sequence-sequence search died"

			if notExists "${TMP_PATH}/seq_searchDB.csv"; then
				#shellcheck disable=SC2086
				"$MMSEQS" convertalis "${TMP_PATH}/clu_rep" "${TARGET}" "${TMP_PATH}/seq_searchDB" "${TMP_PATH}/seq_searchDB.csv" \
					|| fail "convertalis died"
			fi
			rm -f "${TMP_PATH}/seq_searchDB."[0-9]*
		fi
	fi

if notExists "${TMP_PATH}/searchDB"; then
	echo "Filter, sort and merge alignment DBs"

	# simplified or standard output
	if [ -n "${SIMPLE_OUTPUT}" ]; then
		echo "Simplified output will be provided"
		filterDb "${TMP_PATH}/prof_searchDB.csv" "${TMP_PATH}/prof_searchDB_filtered_IDs.csv"
		filterDb "${TMP_PATH}/seq_searchDB.csv" "${TMP_PATH}/seq_searchDB_filtered_IDs.csv"
	else 
		echo "Standard output will be provided"
		filterDb_standard "${TMP_PATH}/prof_searchDB.csv" "${TMP_PATH}/prof_searchDB_filtered_IDs.csv"
		filterDb_standard "${TMP_PATH}/seq_searchDB.csv" "${TMP_PATH}/seq_searchDB_filtered_IDs.csv"
	fi

	PROF_DB_SIZE=$(wc -l < "${TMP_PATH}/prof_searchDB_filtered_IDs.csv")
	SEQ_DB_SIZE=$(wc -l < "${TMP_PATH}/seq_searchDB_filtered_IDs.csv")

	if [ "${PROF_DB_SIZE}" -ge "${SEQ_DB_SIZE}" ]; then
		echo "Sequence-profile DB is larger"
		join -j 1 -a2 -t ' ' "${TMP_PATH}/seq_searchDB_filtered_IDs.csv" "${TMP_PATH}/prof_searchDB_filtered_IDs.csv" >> "${TMP_PATH}/searchDB"
	else 
		echo "Seqeunce-sequence DB is larger"
		join -j 1 -a1 -t ' ' "${TMP_PATH}/seq_searchDB_filtered_IDs.csv" "${TMP_PATH}/prof_searchDB_filtered_IDs.csv" >> "${TMP_PATH}/searchDB"	
	fi

fi

MMSEQS="$(abspath "$(command -v "${MMSEQS}")")"
SCRIPT="${MMSEQS%/build*}"
chmod +x "${SCRIPT}/data/access_uniprot.py"
#shellcheck disable=SC2086
python3 "${SCRIPT}/data/access_uniprot.py" "${TMP_PATH}/searchDB" "${RESULTS}" \
 	|| fail "get gene ontology ids died"

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	echo "Remove temporary files and directories"
	rm -rf "${TMP_PATH}/annotate_tmp"
	rm -f "${TMP_PATH}/annotate.sh"
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/clu" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	rm -f "${TMP_PATH}/prof_searchDB.csv"
	#shellcheck disable=SC2086
	rm -f "${TMP_PATH}/seq_searchDB.csv"
fi
