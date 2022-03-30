#!/bin/sh -e
# create profiles db from fasta
"${MMSEQS}" createdb "${DATADIR}/five_profiles.fasta" "${RESULTS}/prof_5"
"${MMSEQS}" mergedbs "${RESULTS}/prof_5" "${RESULTS}/prof_5_fasta" "${RESULTS}/prof_5_h" "${RESULTS}/prof_5" --prefixes ">"
awk 'BEGIN { printf("%c%c%c%c",11,0,0,0); exit; }' > "${RESULTS}/prof_5_fasta.dbtype"
"${MMSEQS}" msa2profile "${RESULTS}/prof_5_fasta" "${RESULTS}/five_profiles" --filter-msa 0

# create db from duplicated query #
"${MMSEQS}" createdb "${DATADIR}/query_pow2.fasta" "${RESULTS}/query_pow2"

PROFILES_DB="five_profiles"
PROTEINS_DB="query_pow2"

FINAL_COUNTS_AS_SHOULD="512,256,128,64,32"
COUNTS_ALL_TESTS="${FINAL_COUNTS_AS_SHOULD}"

for SPLIT_MODE in 0 1; do
	DISK_SPACE_LIMIT_KB=17
	SPLIT_OUTPUT="${RESULTS}/DSL_${DISK_SPACE_LIMIT_KB}K_SPLIT_MODE_${SPLIT_MODE}"
	mkdir -p "${SPLIT_OUTPUT}"
	# run exhaustive search #
	"${MMSEQS}" search "${RESULTS}/query_pow2" "${RESULTS}/five_profiles" "${SPLIT_OUTPUT}/res" "${SPLIT_OUTPUT}/tmpFolder" --exhaustive-search -s 1 --disk-space-limit "${DISK_SPACE_LIMIT_KB}K" --split-mode "${SPLIT_MODE}"
	"${MMSEQS}" convertalis "${RESULTS}/query_pow2" "${RESULTS}/five_profiles" "${SPLIT_OUTPUT}/res" "${SPLIT_OUTPUT}/alis"
	awk '{print $1}' "${SPLIT_OUTPUT}/alis" | sort | uniq -c | sort -nr | awk '{ print $1 }' | paste -d, -s - > "${SPLIT_OUTPUT}/final_counts.txt"
	COUNTS_CURR_TEST="$(cat < "${SPLIT_OUTPUT}/final_counts.txt")"
	echo "$COUNTS_CURR_TEST"
	if [ "$COUNTS_CURR_TEST" != "$FINAL_COUNTS_AS_SHOULD" ]; then
		COUNTS_ALL_TESTS="$COUNTS_CURR_TEST"
	fi
done

# if ALL tests passed - GOOD, otherwise - BAD
awk -v actual="$COUNTS_ALL_TESTS" -v target="$FINAL_COUNTS_AS_SHOULD" \
	'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
	> "${RESULTS}.report"
