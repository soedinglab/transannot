#!/bin/bash
fail() {
	echo "Error: $1"
	exit 1
}

notExists() {
	[ ! -f "$1" ]
}

#preprocessing
[ -z "${LIB}/PLASS" ] && echo "Please set the environment variable \$PLASS to your current binary." && exit 1;
[ -z "${LIB}/MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found!" && exit 1; 
[   -f "$3.dbtype"] && echo "$3.dbtype exists already!" && exit 1;
[ ! -d "$4" ] && echo "tmp directory $4 not found!" && mkdir -p "$4";

#defining
INPUT="$1"
#TARGET="$2"  #user should give a target at the beginning of annotation? or we simply download UniProt??
RESULTS="$3"
TMP_PATH="$4"
 
#implementing plass
if notExists "${TMP_PATH}/*.fasta"; then 
	shellcheck disable=SC2086
	"$PLASS" assemble "${INPUT}" "${TMP_PATH}/assembly.fasta" "${TMP_PATH}/plass_tmp" ${ASSEMBLY_PAR} \ #or nuclassemble???
		|| fail "PLASS assembly died"
fi

#MMSEQS2 download UniProt database to search against
cd "${TMP_PATH}" #check whether db exists already + whether user-given one -> createdb
if notExists "${TMP_PATH}/UniProt"; then
	"$MMSEQS" databases ${UniProtKB} "${TMP_PATH}/UniProt" "${TMP_PATH}/download_tmp" 
fi

#MMSEQS2 create database
if notExists "${TMP_PATH}/assembly.fasta"; then #which plass file do we give here
	shellcheck disable=SC2086
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
if notExists.......; then
	shellcheck disable=SC2086
	"$MMSEQS" rbh "${QUERY}" "${TARGET}" "${TMP_PATH}/result" "${TMP_PATH}/rbh_tmp" ${SEARCH_PAR} \ #should we use rbh or easy-rbh??? -> rbh is relatively an elaborate procedure and hence we can try rbh directly.
		|| fail "rbh search died"
fi

#get GO-IDs
if notExists......; then
	shellcheck disable=SC2086

fi

#remove everything unnecessary for user
if [ -n "${REMOVE_TMP}" ]; then
	shellcheck disable=SC2086
	rm -rf "${TMP_PATH}/annotate_tmp"  #current name of tmp pathway DO we really have annotate_tmp? or rbh_tmp? or smth else? -> we can create one tmp file for all steps and remove them at one go.
	#rm -f "${TMP_PATH}/annotate.sh"   #current name of this file	
fi
