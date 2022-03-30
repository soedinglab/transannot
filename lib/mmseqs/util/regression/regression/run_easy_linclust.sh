#!/bin/sh -e
"${MMSEQS}" easy-linclust "${DATADIR}/clu.fasta" "$RESULTS/results" "$RESULTS/tmp" --cov-mode 1 --cluster-mode 0 -c 0.90 --min-seq-id 0.50

awk 'BEGIN { l = "" } l != $1 { l = $1; cnt++; } { t++; } END { print cnt"\t"t"\t"(t/cnt) }' "$RESULTS/results_cluster.tsv" > "$RESULTS/results_summary.tsv"
ACTUAL="$(cut -f1 "$RESULTS/results_summary.tsv")"
TARGET="26493"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
