#!/bin/sh -e
fail() {
    echo "Error: $1"
    exit 1
}

notExists() {
    [ ! -f "$1" ]
}

#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary" && exit 1;
# [ "$#" -ne 4 ] && echo "Please provide <InputSeq> <targetDB> <outPath> <tmp>" && exit 1; #easytaxonomy takes fasta file as an input
[ ! -f "${TARGET}.dbtype" ] && echo "Please make sure proper target database is provided and mmseqs database is created!" && exit 1;
[ ! -d "${TMP_PATH}" ] && echo "tmp directory ${TMP_PATH} not found! tmp will be created." && mkdir -p "${TMP_PATH}";

# INPUT="$1"
# TARGET="$2"
# OUT_PATH="$3"
# TMP_PATH="$4"

#if notExists "${TARGET}.dbtype"; then
#    #shellcheck disable=SC2086
#    "$MMSEQS" createdb "${TARGET}" "${TMP_PATH}/target" ${CREATEDB_PAR} \
#        || fail "create targetDB died"
#fi

#only INPUT goes to this script, everything else will be automatically generated in easytaxonomy
#only one variable should be given
#--tax-lineage 2-> column with full lineage NCBI taxids

# mkdir -p "${TMP_PATH}/easy_taxonomy_tmp"
#shellcheck disable=SC2086
"$MMSEQS" taxonomy "$@" "${TARGET}" "${OUT_PATH}" "${TMP_PATH}" ${TAXONOMY_PAR} \
        || fail "taxonomy died"

"$MMSEQS" mergedbs "${OUT_PATH}."[0-9]* "${OUT_PATH}_merged"
rm -f "${OUT_PATH}."[0-9]*

#easy taxonomy returns output in .tsv format
#"${OUT_PATH}_tophit_report" -> .tsv

#NOTE: $2 is a second column of tophit_report6 $6 is an taxonomical information identifier
#we compare values of each line's $2 with (I would suggest) 0.8 (out of 1)
#NOTE: I decided to use break after each condition so that there will be not so many output lines created, especially in case of contamination
# "${OUT_PATH}_tophit_report"
# "${OUT_PATH}_tophit_report_sorted" 

sort -k2 -rn "${OUT_PATH}_merged" >> "${OUT_PATH}_sorted"
# rm -f "${OUT_PATH}_tophit_report"
awk 'NR == 1 {
    if($2 < 0.8) {
        print "Input sequence may be contaminated, for more information see", "${OUT_PATH}_tophit_report_sorted", "\n"
    }
    else {
        print "No contamination detected, possible taxonomical assignment is ", $6,"\n"
        print "For more information see", "${OUT_PATH}_tophit_report_sorted", "\n"
    }
}' "${OUT_PATH}_sorted" # or we can call a small separate shellscript to pass the file and report the result. You refer to transannot/util folder in which I added the separate small script to perform this function. Hence, we can write the step like this: 'transannot/util/report_contamination.sh ${OUT_PATH}_tophit_report_sorted'

if [ -n "$REMOVE_TMP" ]; then
    #shellcheck disable=SC2086
    echo "Remove temporary files and directories"
    # rm -rf "${TMP_PATH}/easy_taxonomy_tmp"
    rm -f "${TMP_PATH}/contamination.sh"
fi
