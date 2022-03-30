#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"
"${MMSEQS}" translateaa "${QUERYDB}" "${QUERYDB}_nucl" --threads 1
ln -sf "${QUERYDB}_h" "${QUERYDB}_nucl_h"
ln -sf "${QUERYDB}_h.index" "${QUERYDB}_nucl_h.index"
ln -sf "${QUERYDB}_h.dbtype" "${QUERYDB}_nucl_h.dbtype"
"${MMSEQS}" convert2fasta "${QUERYDB}_nucl" "${QUERYDB}_nucl.fasta"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" translateaa "${TARGETDB}" "${TARGETDB}_nucl" --threads 1
ln -sf "${TARGETDB}_h" "${TARGETDB}_nucl_h"
ln -sf "${TARGETDB}_h.index" "${TARGETDB}_nucl_h.index"
ln -sf "${TARGETDB}_h.dbtype" "${TARGETDB}_nucl_h.dbtype"

"${MMSEQS}" createlinindex "${TARGETDB}_nucl" "$RESULTS/tmp"  --search-type 3 
"${MMSEQS}" easy-linsearch "${QUERYDB}_nucl.fasta" "${TARGETDB}_nucl" "$RESULTS/results_aln.m8" "$RESULTS/tmp" -e 10000 --kmer-per-seq 200  --split-memory-limit 4M --search-type 3 -a 

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.108903"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
