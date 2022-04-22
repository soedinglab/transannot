#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

notExists() {
		[ ! -f "$1" ]
}

#pre-processing
[ -z "$PLASS" ] && echo "Please set the environment variable \$PLASS to your current binary." && exit 1;
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;

#checking how many input variables are provided
[ "$#" -ne 4 ] && echo "Please provide <assembled transciptome> <targetDB> <outDB> <tmp>" && exit 1;
#checking whether files already exist
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db is already created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[   -f "$3.dbtype"] && echo "$3.dbtype exists already!" && exit 1; ##results - not defined yet
[ ! -d "$4" ] && echo "tmp directory $4 not found! tmp will be created." && mkdir -p "$4"; 

INPUT="$1" #assembled sequence
TARGET="$2"  #already downloaded datbase - after dowload it will be turned into MMSeqs database type as well
RESULTS="$3"
TMP_PATH="$4" 
 
#MMSEQS2 create database
#if notExists "${TMP_PATH}/assembly.fasta"; then 
#	#shellcheck disable=SC
#	"$MMSEQS" createdb "${TMP_PATH}/plass_assembly.fas" "${TMP_PATH}/query"  ${CREATEDB_QUERY_PAR} \
#		|| fail "query createdb died"
#	QUERY="${TMP_PATH}/query"
#fi	

#MMSEQS2 RBH
#if we assemble with plass we get "${RESULTS}/plass_assembly.fas" in MMseqs db format as input
#otherwise we have .fas file which must be translated into protein sequence and turned into MMseqs db
if notExists "${RESULTS}.dbtype"; then
	#shellcheck disable=SC2086
	"$MMSEQS" rbh "${QUERY}" "${TARGET}" "${TMP_PATH}/result" "${TMP_PATH}/rbh_tmp" ${SEARCH_PAR} \ #should we use rbh or easy-rbh??? -> rbh is relatively an elaborate procedure and hence we can try rbh directly.
		|| fail "rbh search died"
fi

#get GO-IDs
#read more whether we need GET module
if notExists "${RESULTS}/go_ids"; then
	#shellcheck disable=SC
	"$HTTP" GET https://www.uniprot.org/uniprot/?query=....&sort=score&columns=id,entry name,reviewed,protein names,genese,organism,length&format=tab > "${RESULTS}/go_ids"
		|| fail "get GO-IDs died"
fi

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	#shellcheck disable=SC
	echo "Remove temporary files and directories"
	rm -rf "${TMP_PATH}/annotate_tmp"  #current name of tmp pathway DO we really have annotate_tmp? or rbh_tmp? or smth else? -> we can create one tmp file for all steps and remove them at one go.
	rm -f "${TMP_PATH}/annotate.sh"   #current name of this file	
fi