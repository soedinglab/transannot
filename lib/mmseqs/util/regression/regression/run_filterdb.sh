#!/bin/sh -e
"${MMSEQS}" tsv2db "${DATADIR}/mock.tsv" "${RESULTS}/db" --output-dbtype 12

ERR=0
expected_index() {
    if [ "$(awk -v e1="$2" -v e2="$3" -v e3="$4" -v e4="$5" 'BEGIN {i=0} (NR==1 && $3==e1) || (NR==2 && $3==e2) || (NR==3 && $3==e3) || (NR==4 && $3==e4) {next} {i++} END {print i}' "$1")" -ne "0" ]; then
    ERR="$((ERR+1))"
    echo "Issue in $1"
  fi
}

"${MMSEQS}" filterdb "${RESULTS}/db" "${RESULTS}/filt" --sort-entries 2 --filter-column 1
"${MMSEQS}" filterdb "${RESULTS}/filt" "${RESULTS}/filt_2" --extract-lines 1
"${MMSEQS}" filterdb "${RESULTS}/filt_2" "${RESULTS}/filt_3" --comparison-operator ge --comparison-value 50 --filter-column 2
expected_index "${RESULTS}/filt_3.index" 6 7 6 1

"${MMSEQS}" filterdb "${RESULTS}/db"  "${RESULTS}/filt_4" --filter-file "${RESULTS}/db.index"
expected_index "${RESULTS}/filt_4.index" 12 13 6 6

"${MMSEQS}" filterdb "${RESULTS}/db"  "${RESULTS}/filt_5" --filter-file "${RESULTS}/db.index" --positive-filter false
expected_index "${RESULTS}/filt_5.index" 6 1 1 1

"${MMSEQS}" filterdb "${RESULTS}/db"  "${RESULTS}/filt_6" --mapping-file "${RESULTS}/db.index"
expected_index "${RESULTS}/filt_6.index" 14 14 6 7

"${MMSEQS}" filterdb "${RESULTS}/db" "${RESULTS}/filt_7" --filter-expression '$1 * $2 >= 200'
expected_index "${RESULTS}/filt_7.index" 12 13 1 1

"${MMSEQS}" filterdb "${RESULTS}/db" "${RESULTS}/filt_8" --filter-regex '^[1-9].$' --filter-column 2
expected_index "${RESULTS}/filt_8.index" 11 1 6 6

"${MMSEQS}" filterdb "${RESULTS}/db" "${RESULTS}/filt_9" --extract-lines 1 --trim-to-one-column
expected_index "${RESULTS}/filt_9.index" 3 3 3 3

"${MMSEQS}" filterdb "${RESULTS}/db"  "${RESULTS}/filt_10" --join-db "${RESULTS}/filt_9"
expected_index "${RESULTS}/filt_10.index" 16 17 8 8

"${MMSEQS}" filterdb "${RESULTS}/db"  "${RESULTS}/filt_11" --beats-first --comparison-operator ge
expected_index "${RESULTS}/filt_11.index" 12 13 6 6

"${MMSEQS}" filterdb "${RESULTS}/db"  "${RESULTS}/filt_12" --beats-first --filter-column 2 --comparison-operator ip --comparison-value 0.8
expected_index "${RESULTS}/filt_12.index" 12 7 6 6

awk -v actual="$ERR" -v target="0" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"

