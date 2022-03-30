#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"
"${MMSEQS}" translateaa "${QUERYDB}" "${QUERYDB}_nucl" --threads 1
ln -sf "${QUERYDB}_h" "${QUERYDB}_nucl_h"
ln -sf "${QUERYDB}_h.index" "${QUERYDB}_nucl_h.index"
ln -sf "${QUERYDB}_h.dbtype" "${QUERYDB}_nucl_h.dbtype"
"${MMSEQS}" convert2fasta "${QUERYDB}_nucl" "${QUERYDB}_nucl.fas"
TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
TARGETDB_MAPPING="${DATADIR}/targetannotation.mapping"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" createindex "${TARGETDB}" "$RESULTS/idxtmp"
"${MMSEQS}" createtaxdb "${TARGETDB}" "$RESULTS/tmp" --tax-mapping-file "${TARGETDB_MAPPING}" --ncbi-tax-dump "${DATADIR}/ncbitax" 
"${MMSEQS}" easy-search "${QUERYDB}_nucl.fas" "$TARGETDB" "$RESULTS/results_aln" "$RESULTS/tmp"  --format-output taxid,taxlineage,query,target,qaln,taln
awk '{print $1}' "$RESULTS/results_aln" | sort | uniq -c | awk '{print NR"\t"$2}' > "$RESULTS/results_aln_tax.tsv"
"${MMSEQS}" tsv2db "$RESULTS/results_aln_tax.tsv" "$RESULTS/results_aln_taxdb" --output-dbtype 8
"${MMSEQS}" filtertaxdb "${TARGETDB}" "$RESULTS/results_aln_taxdb" "$RESULTS/results_aln_bacteria" --taxon-list 2 
"${MMSEQS}" filtertaxdb "${TARGETDB}" "$RESULTS/results_aln_taxdb" "$RESULTS/results_aln_virus" --taxon-list 10239
"${MMSEQS}" filtertaxdb "${TARGETDB}" "$RESULTS/results_aln_taxdb" "$RESULTS/results_aln_eukaryota" --taxon-list 2759 

BACTERIA=$(awk '$3 != 1 {print}' "$RESULTS/results_aln_bacteria.index" | wc -l| awk '{print $1}')
VIRUS=$(awk '$3 != 1 {print}' "$RESULTS/results_aln_virus.index" | wc -l| awk '{print $1}')
EUKARYOTA=$(awk '$3 != 1 {print}' "$RESULTS/results_aln_eukaryota.index" | wc -l| awk '{print $1}')

TARGET="from filtertaxdb: 3626 680 1425;"
ACTUAL="from filtertaxdb: $BACTERIA $VIRUS $EUKARYOTA;"
awk -v actual="$ACTUAL" -v target="$TARGET" 'BEGIN { print (actual == target) ? "GOOD" : "BAD"; \
    print "Expected: ", target; \
    print "Actual:   ", actual; }' > "${RESULTS}.report"
