#!/bin/sh -e
"${MMSEQS}" multihitdb "${DATADIR}/qset_01.fas.gz" "${DATADIR}/qset_02.fas.gz" "$RESULTS/qsetsdb" "$RESULTS/tmp"
"${MMSEQS}" multihitdb "${DATADIR}/tset_01.fas.gz" "${DATADIR}/tset_02.fas.gz" "$RESULTS/tsetsdb" "$RESULTS/tmp"
"${MMSEQS}" multihitsearch "$RESULTS/qsetsdb" "$RESULTS/tsetsdb" "$RESULTS/result" "$RESULTS/tmp" -s 4
"${MMSEQS}" combinepvalperset "$RESULTS/qsetsdb" "$RESULTS/tsetsdb" "$RESULTS/result" "$RESULTS/pval" "$RESULTS/tmp"

ACTUAL1="$(tr -d '\000' < "$RESULTS/pval" | head -n1 | cut -f2)"
TARGET1="0"
ACTUAL2="$(tr -d '\000' < "$RESULTS/pval" | tail -n1 | cut -f2)"
TARGET2="0"
awk -v actual1="$ACTUAL1" -v target1="$TARGET1" -v actual2="$ACTUAL2" -v target2="$TARGET2"  \
    'BEGIN { print (actual1 == target1 && actual2 == target2) ? "GOOD" : "BAD"; print "Expected: ", target1; print "Actual: ", actual1; ; print "Expected: ", target2; print "Actual: ", actual2; }' \
    > "${RESULTS}.report"
