#!/bin/sh -e
"${MMSEQS}" createdb "${DATADIR}/query.fasta" "${RESULTS}/query"
"${MMSEQS}" apply "${RESULTS}/query" "$RESULTS/apply" -- wc -c

ACTUAL="$(tr -d '\000' < "$RESULTS/apply" | awk '{ l += $1; } END { print l }')"
TARGET="$(grep -v "^>" "${DATADIR}/query.fasta" | wc -c)"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"

