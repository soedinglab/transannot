#!/bin/sh -e
TARGET="${DATADIR}/genes.fasta"

"${MMSEQS}" easy-cluster "${TARGET}" "$RESULTS/results" "$RESULTS/tmp" -k 13 --min-seq-id 0.8 -c 0.5 --cov-mode 1

awk 'BEGIN { l = "" } l != $1 { l = $1; cnt++; } { t++; } END { print cnt"\t"t"\t"(t/cnt) }' "$RESULTS/results_cluster.tsv" > "$RESULTS/results_summary.tsv"
ACTUAL="$(cut -f1 "$RESULTS/results_summary.tsv")"
TARGET="106"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
