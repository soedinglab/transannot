#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" createindex "$TARGETDB" "$RESULTS/tmp" -s 1

"${MMSEQS}" prefilter "$QUERYDB" "${TARGETDB}.idx" "$RESULTS/pref" --exact-kmer-matching 1 --db-load-mode 1
"${MMSEQS}" createtsv "$QUERYDB" "$TARGETDB" "$RESULTS/pref" "$RESULTS/pref.tsv"
awk '{print $1"\t"$2"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"$3"\t"0}' "$RESULTS/pref.tsv" | LC_ALL=C sort -k1,1 -k11,11g > "$RESULTS/pref.m8"
ACTUAL1=$("${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/pref.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | grep "^ROC5 AUC:" | cut -d" " -f3)

"${MMSEQS}" prefilter "$QUERYDB" "${TARGETDB}.idx" "$RESULTS/pref" --exact-kmer-matching 1 --db-load-mode 2
"${MMSEQS}" createtsv "$QUERYDB" "$TARGETDB" "$RESULTS/pref" "$RESULTS/pref.tsv"
awk '{print $1"\t"$2"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"$3"\t"0}' "$RESULTS/pref.tsv" | LC_ALL=C sort -k1,1 -k11,11g > "$RESULTS/pref.m8"
ACTUAL2=$("${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/pref.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | grep "^ROC5 AUC:" | cut -d" " -f3)

"${MMSEQS}" prefilter "$QUERYDB" "${TARGETDB}.idx" "$RESULTS/pref" --exact-kmer-matching 1 --db-load-mode 3
"${MMSEQS}" createtsv "$QUERYDB" "$TARGETDB" "$RESULTS/pref" "$RESULTS/pref.tsv"
awk '{print $1"\t"$2"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"0"\t"$3"\t"0}' "$RESULTS/pref.tsv" | LC_ALL=C sort -k1,1 -k11,11g > "$RESULTS/pref.m8"
ACTUAL3=$("${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/pref.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | grep "^ROC5 AUC:" | cut -d" " -f3)

TARGET="0.0856974"
awk -v actual1="$ACTUAL1" -v actual2="$ACTUAL2" -v actual3="$ACTUAL3" -v target="$TARGET" \
    'BEGIN { print (actual1 >= target && actual1 == actual2 && actual1 == actual3) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual1; }' \
    > "${RESULTS}.report"
