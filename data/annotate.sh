#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

notExists() {
		[ ! -f "$1" ]
}

hasCommand () {
    command -v "$1" >/dev/null 2>&1
}

#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
hasCommand wget

#checking how many input variables are provided
#[ "$#" -ne 4 ] && echo "Please provide <assembled transciptome> <targetDB> <outDB> <tmp>" && exit 1;
[ "$("${MMSEQS}" dbtype "$2")" != "Profile" ] && echo "The given target database is not profile! Please download profileDB or create from existing sequenceDB!" && exit 1;
#checking whether files already exist
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db is already created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[   -f "$3.dbtype" ] && echo "$3.dbtype exists already!" && exit 1; ##results - not defined yet
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4"; 

INPUT="$1" #assembled sequence
TARGET="$2"  #already downloaded database
RESULTS="$3"
TMP_PATH="$4" 

#MMSEQS2 LINCLUST for the redundancy reduction
if notExists "${TMP_PATH}/clu.dbtype"; then
	#shellcheck disable=SC2086
	"$MMSEQS" linclust "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_tmp" ${CLUSTER_PAR} \
		|| fail "linclust died"

	#shellcheck disable=SC2086
	"$MMSEQS" result2repseq "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_rep" ${RESULT2REPSEQ_PAR} \
		|| fail "extract representative sequences died"
fi

	#MMSEQS2 RBH
	#if we assemble with plass we get "${RESULTS}/plass_assembly.fas" in MMseqs db format as input
	#otherwise we have .fas file which must be translated into protein sequence and turned into MMseqs db
	#alignment DB is not a directory and may not be created
	if [ -n "${TAXONOMY_ID}" ]; then
	
		echo "Taxonomy ID is provided. rbh will be run against known organism's proteins"
		if notExists "${RESULTS}.dbtype"; then
			#shellcheck disable=SC2086
			"$MMSEQS" rbh "${INPUT}" "${TARGET}" "${TMP_PATH}/searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
				|| fail "rbh search died"
		fi
		

	elif [ -z "${TAXONOMY_ID}" ]; then
		if notExists "${RESULTS}.dbtype"; then
		echo "No taxonomy ID is provided. Sequence-profile search will be run"
			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${TARGET}" "${TMP_PATH}/searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
				|| fail "search died"
			
			#there may be multiple DBs created - depends on the amount of threads
			# if notExists "${TMP_PATH}/searchDB"; then
			# 	cat "${TMP_PATH}/searchDB."[0-9]* > "${TMP_PATH}/searchDB"
			# 	rm -f "${TMP_PATH}/searchDB."[0-9]*		
			# fi

			if notExists "${TMP_PATH}/searchDB.tab"; then
				#shellcheck disable=SC2086
				"$MMSEQS" convertalis "${TMP_PATH}/clu_rep" "${TARGET}" "${TMP_PATH}/searchDB" "${TMP_PATH}/searchDB.tab" \
				|| fail "converatalis died"
			fi
		fi
	fi

#TODO extract column with IDs & pre-process it for UniProt mapping from searchDB
if notExists "${TMP_PATH}/profDB_id"; then
	awk '{print $2}' "${TMP_PATH}/searchDB.tab" >> "${TMP_PATH}/profDB_id"
fi

cd "${TMP_PATH}"
wget https://github.com/mariia-zelenskaia/transannot/blob/main/data/access_uniprot.py
#shellcheck disable=SC2086
python3 ../../access_uniprot.py "${TMP_PATH}/searchDB" >> "${RESULTS}" \
	|| fail "get gene ontology ids died"


#create output in .tsv format
if notExists "${RESULTS}.tsv"; then
	#shellcheck disable=SC2086
	"$MMSEQS" createtsv "${INPUT}" "${RESULTS}" "${RESULTS}.tsv" ${CREATETSV_PAR} \
		|| fail "createtsv died"
fi

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	#shellcheck disable=SC2086
	echo "Remove temporary files and directories"
	rm -rf "${TMP_PATH}/annotate_tmp"
	rm -f "${TMP_PATH}/annotate.sh"
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/clu" ${VERBOSITY_PAR}
fi
