#!/bin/sh -e
SPLIT_MODE="${1}"

NUM_RES_LINES_BASELINE=500
head -n $((NUM_RES_LINES_BASELINE*2)) "${DATADIR}/query.fasta" > "${RESULTS}/500prots.fasta"
"${MMSEQS}" createdb "${RESULTS}/500prots.fasta" "${RESULTS}/prots" --dbtype 0

NUM_LINES_ALL_TESTS="${NUM_RES_LINES_BASELINE}"
for NUM_SPLITS in 1 5; do
	# target split
	SPLIT_OUTPUT="${RESULTS}/NS_${NUM_SPLITS}"
	mkdir -p "${SPLIT_OUTPUT}"
	"${MMSEQS}" search "${RESULTS}/prots" "${RESULTS}/prots" "${SPLIT_OUTPUT}/res" "${SPLIT_OUTPUT}/tmpFolder" -s 1 --split-mode "${SPLIT_MODE}" --split "${NUM_SPLITS}"
	"${MMSEQS}" convertalis "${RESULTS}/prots" "${RESULTS}/prots" "${SPLIT_OUTPUT}/res" "${SPLIT_OUTPUT}/res.m8"
	NUM_LINES_CURR_TEST="$(wc -l < "${SPLIT_OUTPUT}/res.m8")"
	if [ "${NUM_LINES_CURR_TEST}" -ne "${NUM_RES_LINES_BASELINE}" ]; then
		NUM_LINES_ALL_TESTS="${NUM_LINES_CURR_TEST}"
	fi
done

# if ALL tests passed - GOOD, otherwise - BAD
awk -v actual="$NUM_LINES_ALL_TESTS" -v target="$NUM_RES_LINES_BASELINE" \
	'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
	> "${RESULTS}.report"
