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
filterDb_simple() {
	awk '{if (($5>=50) && ($4>=0.6)) print $0}' "$1" | awk '{$4=$5=""; print $0}' |sort -n -k3 | awk '!seen[$1]++' | sort -s -k1b,1 >> "$2"
}

filterDb() {
	awk '{if (($5>=50) && ($4>=0.6)) print $0}' "$1" | sort -n -k3 | awk '!seen[$1]++' | sort -s -k1b,1 >> "$2"
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
#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

#checking how many input variables are provided
[ "$#" -ne 6 ] && echo "Please provide <assembled transciptome> <profile target DB> <sequence target DB> <outDB> <tmp>" && exit 1;
[ "$("${MMSEQS}" dbtype "$2")" != "Profile" ] && echo "The given target database is not profile! Please download profileDB or create from existing sequenceDB!" && exit 1;
[ "$("${MMSEQS}" dbtype "$3")" != "Profile" ] && echo "The given target database is not profile! Please download profileDB or create from existing sequenceDB!" && exit 1;
[ "$("${MMSEQS}" dbtype "$4")" = "Profile" ] && echo "The given target database is profile! Please provide sequence DB!" && exit 1;

#checking whether files already exist
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db is already created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[ ! -f "$3.dbtype" ] && echo "$3.dbtype not found!" && exit 1;
[ ! -f "$4.dbtype" ] && echo "$4.dbtype not found!" && exit 1;
# [   -f "$5.dbtype" ] && echo "$5.dbtype exists already!" && exit 1; 
[ ! -d "$6" ] && echo "tmp directory $6 not found! tmp will be created." && mkdir -p "$6"; 

INPUT="$1" #assembled sequence
PROF_TARGET1="$2"  #already downloaded database
PROF_TARGET2="$3"
SEQ_TARGET="$4"
RESULTS="$5"
TMP_PATH="$6" 

#MMSEQS2 LINCLUST for the redundancy reduction
if notExists "${TMP_PATH}/clu.dbtype"; then
	#shellcheck disable=SC2086
	"$MMSEQS" linclust "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_tmp" --min-seq-id 0.6 ${CLUSTER_PAR} \
		|| fail "linclust died"

	#shellcheck disable=SC2086
	"$MMSEQS" result2repseq "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_rep" ${RESULT2REPSEQ_PAR} \
		|| fail "extract representative sequences died"
fi

if [ -n "${TAXONOMY_ID}" ]; then
	
	# echo "Taxonomy ID is provided. rbh will be run against known organism's proteins"
	if notExists "${RESULTS}.dbtype"; then
		#shellcheck disable=SC2086
		"$MMSEQS" rbh "${INPUT}" "${PROF_TARGET1}" "${TMP_PATH}/searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
			|| fail "rbh search died"
	fi
		

	elif [ -z "${TAXONOMY_ID}" ]; then
		if notExists "${RESULTS}.dbtype"; then
		# echo "No taxonomy ID is provided. Sequence-profile search will be run"
			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${PROF_TARGET1}" "${TMP_PATH}/prof1_searchDB" "${TMP_PATH}/search_tmp" --min-seq-id 0.6 ${SEARCH_PAR} \
				|| fail "first sequence-profile search died"

			preprocessDb "${TMP_PATH}/prof1_searchDB" "${TMP_PATH}/filtprof1DB"

			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${PROF_TARGET2}" "${TMP_PATH}/prof2_searchDB" "${TMP_PATH}/search_tmp" --min-seq-id 0.6 ${SEARCH_PAR} \
				|| fail "second sequence-profile search died"
			
			preprocessDb "${TMP_PATH}/prof2_searchDB" "${TMP_PATH}/filtprof2DB"
			
			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${SEQ_TARGET}" "${TMP_PATH}/seq_searchDB" "${TMP_PATH}/search_tmp" --min-seq-id 0.6 ${SEARCH_PAR} \
				|| fail "sequence-sequence search died"

			preprocessDb "${TMP_PATH}/seq_searchDB" "${TMP_PATH}/filtseqDB"

			if [ -n "${SIMPLE_OUTPUT}" ]; then
				echo "Simplified output will be provided"
				convertalis_simple "${PROF_TARGET1}" "${TMP_PATH}/filtprof1DB" "${TMP_PATH}/prof1_searchDB.tsv"
				convertalis_simple "${PROF_TARGET2}" "${TMP_PATH}/filtprof2DB" "${TMP_PATH}/prof2_searchDB.tsv"
				convertalis_simple "${SEQ_TARGET}" "${TMP_PATH}/filtseqDB" "${TMP_PATH}/seq_searchDB.tsv"

			else
				echo "Standard output will be provided"
				convertalis_standard "${PROF_TARGET1}" "${TMP_PATH}/filtprof1DB" "${TMP_PATH}/prof1_searchDB.tsv"
				convertalis_standard "${PROF_TARGET2}" "${TMP_PATH}/filtprof2DB" "${TMP_PATH}/prof2_searchDB.tsv"
				convertalis_standard "${SEQ_TARGET}" "${TMP_PATH}/filtseqDB" "${TMP_PATH}/seq_searchDB.tsv"
			fi

			rm -f "${TMP_PATH}/prof1_searchDB."[0-9]*
			rm -f "${TMP_PATH}/prof2_searchDB."[0-9]*
			rm -f "${TMP_PATH}/seq_searchDB."[0-9]*
		fi
	fi

if notExists "${TMP_PATH}/tmp_join.tsv"; then

	sort -s -k1b,1 "${TMP_PATH}/prof1_searchDB.tsv" | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "seq-prof search"; print}' >> "${TMP_PATH}/prof1_searchDB2join.tsv"
	rm -f "${TMP_PATH}/prof1_searchDB.tsv"

	sort -s -k1b,1 "${TMP_PATH}/prof2_searchDB.tsv" | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "seq-prof search"; print}' >> "${TMP_PATH}/prof2_searchDB2join.tsv"
	rm -f "${TMP_PATH}/prof2_searchDB.tsv"

	TRANSANNOT="$(abspath "$(command -v "${MMSEQS}")")"
	SCRIPT="${TRANSANNOT%/build*}"

	# gzip -d "${SCRIPT}/data/all_OG_annotations.tsv.gz" >> "${TMP_PATH}/all_OG_annotations.tsv"
	chmod +x "${SCRIPT}/data/search_eggnog.py"
	python3 "${SCRIPT}/data/search_eggnog.py" "${TMP_PATH}/prof2_searchDB2join.tsv" "${SCRIPT}/data/NOG.annotations.tsv" "${TMP_PATH}/namesprof2_searchDB2join.tsv"
	head -n -1 "${TMP_PATH}/namesprof2_searchDB2join.tsv" >> "${TMP_PATH}/namesprof2_searchDB2joinnotail.tsv"; mv -f "${TMP_PATH}/namesprof2_searchDB2joinnotail.tsv" "${TMP_PATH}/namesprof2_searchDB2join.tsv" 
	sort -s -k1b,1 "${TMP_PATH}/namesprof2_searchDB2join.tsv" >> "${TMP_PATH}/sortnamesprof2_searchDB.tsv"
	rm -f "${TMP_PATH}/namesprof2_searchDB2join.tsv"
	join -j 1 -a1 -a2 -t ' ' "${TMP_PATH}/sortnamesprof2_searchDB.tsv" "${TMP_PATH}/prof2_searchDB2join.tsv" >> "${TMP_PATH}/finalprof2_searchDB2join.tsv"
	rm -f "${TMP_PATH}/all_OG_annotations.tsv"

	chmod +x "${SCRIPT}/data/search_pfama.py"
	python3 "${SCRIPT}/data/search_pfama.py" "${TMP_PATH}/prof1_searchDB2join.tsv" "${SCRIPT}/data/Pfam-A.clans.tsv" "${TMP_PATH}/namesprof1_searchDB2join.tsv"
	head -n -1 "${TMP_PATH}/namesprof1_searchDB2join.tsv" >> "${TMP_PATH}/namesprof1_searchDB2joinnotail.tsv"; mv -f "${TMP_PATH}/namesprof1_searchDB2joinnotail.tsv" "${TMP_PATH}/namesprof1_searchDB2join.tsv" 
	sort -s -k1b,1 "${TMP_PATH}/namesprof1_searchDB2join.tsv" >> "${TMP_PATH}/sortnamesprof1_searchDB.tsv"
	rm -f "${TMP_PATH}/namesprof1_searchDB2join.tsv"
	join -j 1 -a1 -a2 -t ' ' "${TMP_PATH}/sortnamesprof1_searchDB.tsv" "${TMP_PATH}/prof1_searchDB2join.tsv" >> "${TMP_PATH}/finalprof1_searchDB2join.tsv"

	sort -s -k1b,1 "${TMP_PATH}/seq_searchDB.tsv" | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "seq-seq search"; print}' >> "${TMP_PATH}/seq_searchDB2join.tsv"
	rm -f "${TMP_PATH}/seq_searchDB.tsv"

	join -j 1 -a1 -a2 -t ' ' "${TMP_PATH}/finalprof1_searchDB2join.tsv" "${TMP_PATH}/finalprof2_searchDB2join.tsv" >> "${TMP_PATH}/tmp_join.tsv"
	join -j 1 -a1 -a2 -t ' ' "${TMP_PATH}/tmp_join.tsv" "${TMP_PATH}/seq_searchDB2join.tsv" >> "${RESULTS}"

	#alphanumerical sort?
	# rm -f "${TMP_PATH}/tmp_join.tsv"
fi

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	echo "Remove temporary files and directories"

	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/clu" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof1_searchDB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof2_searchDB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/seq_searchDB" ${VERBOSITY_PAR}

	rm -f "${TMP_PATH}/prof1_searchDB2join.tsv"
	rm -f "${TMP_PATH}/prof2_searchDB2join.tsv"
	rm -f "${TMP_PATH}/seq_searchDB2join.tsv"

	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/filtprof1DB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/filtprof2DB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/filtseqDB" ${VERBOSITY_PAR}

	rm -f "${TMP_PATH}/annotate.sh"
fi
