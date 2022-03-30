#!/bin/sh -e
"${MMSEQS}" createdb "${DATADIR}/dna.fas" "${RESULTS}/dna"
"${MMSEQS}" extractorfs "${RESULTS}/dna" "${RESULTS}/coding_frags_mode_0" --min-length 1 --orf-start-mode 0 --contig-start-mode 2 --contig-end-mode 2 --forward-frames 1,2,3 --reverse-frames 1,2,3
"${MMSEQS}" extractorfs "${RESULTS}/dna" "${RESULTS}/coding_frags_mode_1" --min-length 1 --orf-start-mode 1 --contig-start-mode 2 --contig-end-mode 2 --forward-frames 1,2,3 --reverse-frames 1,2,3
"${MMSEQS}" extractorfs "${RESULTS}/dna" "${RESULTS}/coding_frags_mode_2" --min-length 1 --orf-start-mode 2 --contig-start-mode 2 --contig-end-mode 2 --forward-frames 1,2,3 --reverse-frames 1,2,3

perl "${SCRIPTS}/extractorfs.pl" "${DATADIR}/dna.fas" "${RESULTS}/perl_coding_frags"

perl "${SCRIPTS}/compare_frags.pl" "${RESULTS}/perl_coding_frags_mode_0.txt" "${RESULTS}/coding_frags_mode_0"
RES0="$?"
perl "${SCRIPTS}/compare_frags.pl" "${RESULTS}/perl_coding_frags_mode_1.txt" "${RESULTS}/coding_frags_mode_1"
RES1="$?"
perl "${SCRIPTS}/compare_frags.pl" "${RESULTS}/perl_coding_frags_mode_2.txt" "${RESULTS}/coding_frags_mode_2"
RES2="$?"

ACTUAL="$((RES0+RES1+RES2))"
TARGET="0"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
