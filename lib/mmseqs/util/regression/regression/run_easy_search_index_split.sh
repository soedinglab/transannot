#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" createindex "$TARGETDB" "$RESULTS/tmp" --split 3 

"${MMSEQS}" easy-search "$QUERY" "$TARGETDB" "$RESULTS/results_aln.m8" "$RESULTS/tmp" --alignment-mode 4 --exact-kmer-matching 1 --sort-results 1

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.118265"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
