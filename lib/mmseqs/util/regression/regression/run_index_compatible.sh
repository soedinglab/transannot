#!/bin/sh
"${MMSEQS}" createdb "${DATADIR}/query.fasta" "${RESULTS}/query"
"${MMSEQS}" createdb "${DATADIR}/dna.fas" "${RESULTS}/dna"

FAIL=0
# search
for tool in createindex createlinindex; do
"${MMSEQS}" "${tool}" "${RESULTS}/query" "${RESULTS}/tmp" -k 5 --mask 1 --check-compatible 0
"${MMSEQS}" "${tool}" "${RESULTS}/query" "${RESULTS}/tmp" -k 5 --mask 1 --check-compatible 2
if [ $? != 0 ]; then 
    FAIL=$((FAIL+1))
fi
"${MMSEQS}" "${tool}" "${RESULTS}/query" "${RESULTS}/tmp" -k 5 --mask 0 --check-compatible 2
if [ $? = 0 ]; then 
    FAIL=$((FAIL+1))
fi

"${MMSEQS}" "${tool}" "${RESULTS}/dna" "${RESULTS}/tmp" -k 5 --mask 1 --search-type 2 --check-compatible 0
"${MMSEQS}" "${tool}" "${RESULTS}/dna" "${RESULTS}/tmp" -k 5 --mask 1 --search-type 2 --check-compatible 2
if [ $? != 0 ]; then 
    FAIL=$((FAIL+1))
fi
"${MMSEQS}" "${tool}" "${RESULTS}/dna" "${RESULTS}/tmp" -k 5 --mask 0 --search-type 2 --check-compatible 2
if [ $? = 0 ]; then 
    FAIL=$((FAIL+1))
fi

"${MMSEQS}" "${tool}" "${RESULTS}/dna" "${RESULTS}/tmp" -k 10 --mask 1 --search-type 3 --check-compatible 0
"${MMSEQS}" "${tool}" "${RESULTS}/dna" "${RESULTS}/tmp" -k 10 --mask 1 --search-type 3 --check-compatible 2
if [ $? != 0 ]; then 
    FAIL=$((FAIL+1))
fi
"${MMSEQS}" "${tool}" "${RESULTS}/dna" "${RESULTS}/tmp" -k 10 --mask 0 --search-type 3 --check-compatible 2
if [ $? = 0 ]; then 
    FAIL=$((FAIL+1))
fi
done

awk -v actual="$FAIL" -v target="0" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"

