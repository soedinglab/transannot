#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"
"${MMSEQS}" translateaa "${QUERYDB}" "${QUERYDB}_nucl" --threads 1
ln -sf "${QUERYDB}_h" "${QUERYDB}_nucl_h"
ln -sf "${QUERYDB}_h.index" "${QUERYDB}_nucl_h.index"
ln -sf "${QUERYDB}_h.dbtype" "${QUERYDB}_nucl_h.dbtype"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
TARGETDB_MAPPING="${DATADIR}/targetannotation.mapping"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" createtaxdb "${TARGETDB}" "$RESULTS/tmp" --tax-mapping-file "${TARGETDB_MAPPING}" --ncbi-tax-dump "${DATADIR}/ncbitax" 
"${MMSEQS}" taxonomy "${QUERYDB}_nucl" "$TARGETDB" "$RESULTS/results_aln" "$RESULTS/tmp" -e 0.1 -s 4
"${MMSEQS}" filtertaxdb "${TARGETDB}" "$RESULTS/results_aln" "$RESULTS/results_aln_bacteria" --taxon-list 2 
"${MMSEQS}" filtertaxdb "${TARGETDB}" "$RESULTS/results_aln" "$RESULTS/results_aln_virus" --taxon-list 10239
"${MMSEQS}" filtertaxdb "${TARGETDB}" "$RESULTS/results_aln" "$RESULTS/results_aln_eukaryota" --taxon-list 2759 

BACTERIA=$(awk '$3 != 1 {print}' "$RESULTS/results_aln_bacteria.index" | wc -l| awk '{print $1}')
VIRUS=$(awk '$3 != 1 {print}' "$RESULTS/results_aln_virus.index" | wc -l| awk '{print $1}')
EUKARYOTA=$(awk '$3 != 1 {print}' "$RESULTS/results_aln_eukaryota.index" | wc -l| awk '{print $1}')

# Create taxreport
"${MMSEQS}" taxonomyreport -v 3 "${TARGETDB}" "$RESULTS/results_aln" "$RESULTS/results_aln_taxreport"

# Check numbers in taxreport
R_BACTERIA=$(grep 'superkingdom.*Bacteria' "$RESULTS/results_aln_taxreport" | cut -f 2)
R_VIRUS=$(grep 'superkingdom.*Virus' "$RESULTS/results_aln_taxreport" | cut -f 2)
R_EUKARYOTA=$(grep 'superkingdom.*Eukaryota' "$RESULTS/results_aln_taxreport" | cut -f 2)

TARGET="from filtertaxdb: 1023 181 1265; from taxonomyreport: 1023 181 1265"
ACTUAL="from filtertaxdb: $BACTERIA $VIRUS $EUKARYOTA; from taxonomyreport: $R_BACTERIA $R_VIRUS $R_EUKARYOTA"
awk -v actual="$ACTUAL" -v target="$TARGET" 'BEGIN { print (actual == target) ? "GOOD" : "BAD"; \
    print "Expected: ", target; \
    print "Actual:   ", actual; }' > "${RESULTS}.report"
