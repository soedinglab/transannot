#!/bin/sh -e

CLUDB="${RESULTS}/clu"
"${MMSEQS}" createdb "${DATADIR}/clu.fasta" "${CLUDB}" --shuffle 0

"${MMSEQS}" cluster "${CLUDB}" "$RESULTS/results_clu" "$RESULTS/tmp" --min-seq-id 0.3 -s 2 --cluster-steps 3
"${MMSEQS}" createtsv "${CLUDB}" "${CLUDB}" "$RESULTS/results_clu" "$RESULTS/results_cluster.tsv"

awk 'BEGIN { l = "" } l != $1 { l = $1; cnt++; } { t++; } END { print cnt"\t"t"\t"(t/cnt) }' "$RESULTS/results_cluster.tsv" > "$RESULTS/results_summary.tsv"
ACTUAL="$(cut -f1 "$RESULTS/results_summary.tsv")"
TARGET="15722"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
