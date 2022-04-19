#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

notExists() {
		[ ! -f "$1" ]
}

#setting plass and mmseqs
LIB="/mariia-zelenskaia/annotation_tool/lib";
PLASS="$LIB/plass";
MMSEQS="$LIB/mmseqs";
HTTP="$LIB/httpie"

#pre-processing
[ -z "$PLASS" ] && echo "Please set the environment variable \$PLASS to your current binary." && exit 1;
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
#how many input variables?
[ "$#" -ne 2 ] && echo "Please provide <queryDB> <tmp>" && exit 1;
#checking whether files exist
#[ ! -f "$("${MMSEQS}" dbtype "$1")" ] && echo "$1.dbtype not found!" && exit 1; 
#[   -f "$3.dbtype"] && echo "$3.dbtype exists already!" && exit 1; ##results - not defined yet
[ ! -d "$2" ] && echo "tmp directory $2 not found!" && mkdir -p "$2"; #change to 4 later $2 -> $4

INPUT="$1"
#TARGET="$2"  #user should give a target at the beginning of annotation? or we simply download UniProt??
#RESULTS="$3"
TMP_PATH="$2" #change to $4 later!!!
 
#implementing plass
mkdir -p "${TMP_PATH}/plass_tmp"
if notExists "${TMP_PATH}/*.fasta"; then 
	#shellcheck disable=SC
	"$PLASS" assemble "${INPUT}" "${TMP_PATH}/assembly.fasta" "${TMP_PATH}/plass_tmp" ${ASSEMBLY_PAR} \
        || fail "PLASS assembly died"
fi

#MMSEQS2 download UniProt database to search against
cd "${TMP_PATH}" #check whether db exists already + whether user-given one -> createdb !!! don't nec. need
if notExists "${TMP_PATH}/UniProt"; then
	mkdir -p "${TMP_PATH}/download_tmp" #do we need to create?
	"$MMSEQS" databases ${UniProtKB} "${TMP_PATH}/UniProt" "${TMP_PATH}/download_tmp" 
fi

#MMSEQS2 create database
if notExists "${TMP_PATH}/assembly.fasta"; then #which plass file do we give here
	#shellcheck disable=SC
	"$MMSEQS" createdb "${TMP_PATH}/assembly.fasta" "${TMP_PATH}/query"  ${CREATEDB_QUERY_PAR} \
		|| fail "query createdb died"
	QUERY="${TMP_PATH}/query"
fi	

#if notExists "${TARGET}.dbtype"; then
#	if notExists "${TMP_PATH}/target"; then
#		shellcheck disable=SC2086
#		"$MMSEQS" createdb "${TARGET}" "${TMP_PATH}/target" ${CREATEDB_PAR} \
#		|| fail "target createdb died"
#	fi
#	TARGET="${TMP_PATH}/target"
#fi

#MMSEQS2 RBH
#if we assemble with plass we get "${RESULTS}/plass_assembly.fas" as input
#otherwise we have .fas file which must be translated into protein sequence
if notExists.......; then
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
	echo "Remove temporary files"
	rm -rf "${TMP_PATH}/annotate_tmp"  #current name of tmp pathway DO we really have annotate_tmp? or rbh_tmp? or smth else? -> we can create one tmp file for all steps and remove them at one go.
	#rm -f "${TMP_PATH}/annotate.sh"   #current name of this file	
fi