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
ln -sf "${TARGETDB}.lookup" "${TARGETDB}_nucl.lookup" 

TARGETDB_MAPPING="${DATADIR}/targetannotation.mapping"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" createtaxdb "${TARGETDB}_nucl" "$RESULTS/tmp" --ncbi-tax-dump "${DATADIR}/ncbitax" --tax-mapping-file "${TARGETDB_MAPPING}" 
"${MMSEQS}" easy-taxonomy "${QUERYDB}_nucl.fasta" "${TARGETDB}_nucl" "$RESULTS/results_aln" "$RESULTS/tmp" --threads 1 --remove-tmp-files 0 -k 14 --blacklist "0" -e 10000 -s 4 --search-type 3 --max-seqs 100


# Check numbers in taxreport
R_BACTERIA=$(grep 'superkingdom.*Bacteria' "$RESULTS/results_aln_report" | cut -f 2)
R_VIRUS=$(grep 'superkingdom.*Virus' "$RESULTS/results_aln_report" | cut -f 2)
R_EUKARYOTA=$(grep 'superkingdom.*Eukaryota' "$RESULTS/results_aln_report" | cut -f 2)

TARGET="from taxonomyreport: 2608 242 2623"
ACTUAL="from taxonomyreport: $R_BACTERIA $R_VIRUS $R_EUKARYOTA"
awk -v actual="$ACTUAL" -v target="$TARGET" 'BEGIN { print (actual == target) ? "GOOD" : "BAD"; \
    print "Expected: ", target; \
    print "Actual:   ", actual; }' > "${RESULTS}.report"
