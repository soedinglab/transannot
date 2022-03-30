#!/bin/sh -e

CLUDB="${RESULTS}/clu"
"${MMSEQS}" createdb "${DATADIR}/query_pow2.fasta" "${CLUDB}" --shuffle 0
"${MMSEQS}" clusthash "${CLUDB}" "$RESULTS/results_aln" 
"${MMSEQS}" clust "${CLUDB}" "$RESULTS/results_aln" "$RESULTS/results_clu"
"${MMSEQS}" createtsv "${CLUDB}" "${CLUDB}" "$RESULTS/results_clu" "$RESULTS/results_cluster.tsv"

"${MMSEQS}" translateaa "${CLUDB}" "${CLUDB}_nucl"
"${MMSEQS}" clusthash "${CLUDB}_nucl" "$RESULTS/results_aln_nucl"
"${MMSEQS}" clust "${CLUDB}_nucl" "$RESULTS/results_aln_nucl" "$RESULTS/results_clu_nucl"
"${MMSEQS}" createtsv "${CLUDB}_nucl" "${CLUDB}_nucl" "$RESULTS/results_clu_nucl" "$RESULTS/results_cluster_nucl.tsv"

awk 'BEGIN { l = "" } l != $1 { l = $1; cnt++; } { t++; } END { print cnt"\t"t"\t"(t/cnt) }' "$RESULTS/results_cluster.tsv" > "$RESULTS/results_summary.tsv"
awk 'BEGIN { l = "" } l != $1 { l = $1; cnt++; } { t++; } END { print cnt"\t"t"\t"(t/cnt) }' "$RESULTS/results_cluster_nucl.tsv" > "$RESULTS/results_summary_nucl.tsv"
ACTUAL1="$(cut -f1 "$RESULTS/results_summary.tsv")"
ACTUAL2="$(cut -f1 "$RESULTS/results_summary_nucl.tsv")"
TARGET="5"
awk -v actual1="$ACTUAL1" -v actual2="$ACTUAL2" -v target="$TARGET" \
    'BEGIN { print (actual1 == target) && (actual2 == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual Prot: ", actual1," Nucl:",actual2; }' \
    > "${RESULTS}.report"
