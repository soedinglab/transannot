#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"

"${MMSEQS}" search "${TARGETDB}" "${TARGETDB}" "${RESULTS}/aln_target_profile" "${RESULTS}/tmp" -s 2 --e-profile 0.1 -e 0.1 -a --realign
"${MMSEQS}" result2profile "${TARGETDB}" "${TARGETDB}" "${RESULTS}/aln_target_profile" "${RESULTS}/target_profile"
"${MMSEQS}" profile2cs "${RESULTS}/target_profile" "${RESULTS}/target_profile_states"

"${MMSEQS}" search "${QUERYDB}" "${TARGETDB}" "${RESULTS}/aln_query_target" "${RESULTS}/tmp"
"${MMSEQS}" result2profile "${QUERYDB}" "${TARGETDB}" "${RESULTS}/aln_query_target" "${RESULTS}/query_profile"

"${MMSEQS}" search "${RESULTS}/query_profile" "${RESULTS}/target_profile_states" "${RESULTS}/results_aln" "${RESULTS}/tmp" --max-seqs 4000 -e 100000 -s 2 -k 10
"${MMSEQS}" convertalis "${RESULTS}/query_profile" "${RESULTS}/target_profile_states" "${RESULTS}/results_aln" "${RESULTS}/results_aln.m8"

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.245"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
