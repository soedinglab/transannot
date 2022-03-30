#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" translateaa "${TARGETDB}" "${TARGETDB}_nucl" --threads 1
ln -sf "${TARGETDB}_h" "${TARGETDB}_nucl_h"
ln -sf "${TARGETDB}_h.index" "${TARGETDB}_nucl_h.index"
ln -sf "${TARGETDB}_h.dbtype" "${TARGETDB}_nucl_h.dbtype"

"${MMSEQS}" createindex "${TARGETDB}_nucl" "$RESULTS/tmp" --search-type 2
"${MMSEQS}" search "${QUERYDB}" "${TARGETDB}_nucl" "$RESULTS/results_aln" "$RESULTS/tmp" -e 10000 -s 4 --max-seqs 4000
"${MMSEQS}" convertalis "${QUERYDB}" "${TARGETDB}_nucl" "$RESULTS/results_aln" "$RESULTS/results_aln.m8"

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.237504"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
