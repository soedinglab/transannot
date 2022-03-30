#!/bin/sh -e
# rbh test
# RBHproteinsA.fas has 6 sequences
# RBHproteinsB.fas has 6 sequences
# in each file - one sequence has no match at all
# in each file all other sequences match all other sequences in the other file
# the best matching is:
# seqA1 with seqB1
# seqA2 with seqB2
# seqA2 with seqB2_also_best
# seqA3 with seqB3
# seqA4 with seqB4

APROTEINS="${DATADIR}/RBHproteinsA.fas"
BPROTEINS="${DATADIR}/RBHproteinsB.fas"

"${MMSEQS}" createdb "${APROTEINS}" "${RESULTS}/proteinsA"
"${MMSEQS}" createdb "${BPROTEINS}" "${RESULTS}/proteinsB"
"${MMSEQS}" rbh "${RESULTS}/proteinsA" "${RESULTS}/proteinsB" "${RESULTS}/rbhAB" "${RESULTS}/tmp"
"${MMSEQS}" convertalis "${RESULTS}/proteinsA" "${RESULTS}/proteinsB" "${RESULTS}/rbhAB" "${RESULTS}/rbhAB.m8"

# both of these should be 5
TOTAL_NUM_LINES="$(wc -l < "${RESULTS}/rbhAB.m8")"
NUM_GOOD_MATCHES="$(perl -nle'print if m{seqA(\d)(_also_best)?\tseqB\1(_also_best)?\t}' "${RESULTS}/rbhAB.m8" | wc -l)"
ACTUAL="$((TOTAL_NUM_LINES+NUM_GOOD_MATCHES))"
TARGET="10"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
