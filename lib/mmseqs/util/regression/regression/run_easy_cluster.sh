#!/bin/sh -e
"${MMSEQS}" easy-cluster "${DATADIR}/clu.fasta" "$RESULTS/results" "$RESULTS/tmp" --min-seq-id 0.3 -s 2 --cluster-steps 3

awk 'BEGIN { l = "" } l != $1 { l = $1; cnt++; } { t++; } END { print cnt"\t"t"\t"(t/cnt) }' "$RESULTS/results_cluster.tsv" > "$RESULTS/results_summary.tsv"
ACTUAL="$(cut -f1 "$RESULTS/results_summary.tsv")"
TARGET="15722"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
