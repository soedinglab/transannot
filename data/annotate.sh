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

#checking how many input variables are provided
[ "$#" -ne 4 ] && echo "Please provide <assembled transciptome> <targetDB> <outDB> <tmp>" && exit 1;
#checking whether files already exist
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db is already created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[   -f "$3.dbtype" ] && echo "$3.dbtype exists already!" && exit 1; ##results - not defined yet
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4"; 

INPUT="$1" #assembled sequence
TARGET="$2"  #already downloaded datbase
RESULTS="$3"
TMP_PATH="$4" 
 
#MMSEQS2 RBH
#if we assemble with plass we get "${RESULTS}/plass_assembly.fas" in MMseqs db format as input
#otherwise we have .fas file which must be translated into protein sequence and turned into MMseqs db
#alignment DB is not a directory and may not be created

#NEW: in each case we have to run RBH so i decided not to check for anything and simply run it
#if notExists "${RESULTS}*.dbtype"; then

#shellcheck disable=SC2086
"$MMSEQS" rbh "${INPUT}" "${TARGET}" "${TMP_PATH}/alignmentDB" "${TMP_PATH}/rbh_tmp" ${SEARCH_PAR} \
	|| fail "rbh search died"
#fi

#get GO-IDs
#TO-DO we can make programmatic access to UniProt
#TO-DO think about condition to retrieve goids
#getgoid function is written as cpp skript in src/util
if notExists "${RESULTS}.**"; then
	#shellcheck disable=SC2086
	"$MMSEQS" getgoid   ${GETGOID_PAR} \
		|| fail "get gene ontology ids died"
fi

#create output in .tsv format
if notExists "${RESULTS}*.tsv"; then
	#shellcheck disable=SC2086
	"$MMSEQS" createtsv "${}" "${}" "${RESULTS}results.tsv" ${CREATETSV_PAR} \
		|| fail "createtsv died"
fi

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	#shellcheck disable=SC2086
	echo "Remove temporary files and directories"
	rm -rf "${TMP_PATH}/annotate_tmp"  #current name of tmp pathway DO we really have annotate_tmp? or rbh_tmp? or smth else? -> we can create one tmp file for all steps and remove them at one go.
	rm -f "${TMP_PATH}/annotate.sh"   #current name of this file	
fi