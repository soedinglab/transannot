#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

TRANSANNOT="$1"
DATA="$2"
BASEDIR="$3"

mkdir -p "${BASEDIR}"

"${TRANSANNOT}" createquerydb ${DATA}/*.pep "${BASEDIR}/query" "${BASEDIR}/tmp_query"
"${TRANSANNOT}" annotate  "${BASEDIR}/query" "${DATA}/pfamA_small" "${DATA}/eggNOG_DB_small" "${DATA}/SwissProt_small" "${BASEDIR}/resDB" "${BASEDIR}/tmp_annotate" --min-seq-id 0.5 --no-run-clust --remove-tmp-files --threads 128

awk -F'\t' -v OFS='\t' 'END{ if (NR != 20) exit 1;}' "${BASEDIR}/resDB" \
	|| fail "Check 1 failed"; awk -F'\t' -v OFS='\t' 'END{print NR}' "${BASEDIR}/resDB"

awk -F'\t' -v OFS='\t' 'FNR==NR{a[$4]=$2;next}a[$4]{ if($0!=$0) exit 1;}' "${DATA}/resDB_regression" "${BASEDIR}/resDB" \
	|| fail "Check 2 failed"
