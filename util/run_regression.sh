#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

TRANSANNOT="$1"
DATA="$2"
BASEDIR="$3"

mkdir -p "${BASEDIR}"

"${TRANSANNOT}" createquerydb ${DATA}/*.pep "${BASEDIR}/query" "${BASEDIR}/tmp/query"
"${TRANSANNOT}" annotate  "${BASEDIR}/query" "${DATA}/pfamA200" "${DATA}/eggNOG_DB200" "${DATA}/SwissProt_200" "${BASEDIR}/resDB" "${BASEDIR}/tmp/annotate" --min-seq-id 0.5 --no-run-clust --remove-tmp-files --threads 128

awk -F'\t' -v OFS='\t' 'BEGIN{ i=0 }{ i++; } END{ if (i != 20) exit 1;}' "${BASEDIR}/resDB" \
	|| fail "Check 1 failed"

awk -F'\t' -v OFS='\t' 'FNR==NR{a[$4]=$2;next}a[$4]{ if($0!=$0) exit 1;}' "${DATA}/resDB_regression" "${BASEDIR}/resDB" \
	|| fail "Check 2 failed"