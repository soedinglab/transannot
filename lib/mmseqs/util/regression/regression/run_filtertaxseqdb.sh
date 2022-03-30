#!/bin/sh -e
"${MMSEQS}" createdb "${DATADIR}/filterTax/bacs_w_tax.fas" "${RESULTS}/bacs_seqs" --shuffle 0
cp "${DATADIR}/filterTax/bacsToTaxid.tsv" "${RESULTS}/bacs_seqs_mapping"
ln -s "${DATADIR}/ncbitax/names.dmp"  "${RESULTS}/bacs_seqs_names.dmp"
ln -s "${DATADIR}/ncbitax/nodes.dmp"  "${RESULTS}/bacs_seqs_nodes.dmp"
ln -s "${DATADIR}/ncbitax/merged.dmp"  "${RESULTS}/bacs_seqs_merged.dmp"
ln -s "${DATADIR}/ncbitax/delnodes.dmp"  "${RESULTS}/bacs_seqs_delnodes.dmp"

"${MMSEQS}" filtertaxseqdb "${RESULTS}/bacs_seqs" "${RESULTS}/only_7" --taxon-list 7
"${MMSEQS}" filtertaxseqdb "${RESULTS}/bacs_seqs" "${RESULTS}/des_356" --taxon-list 356
"${MMSEQS}" filtertaxseqdb "${RESULTS}/bacs_seqs" "${RESULTS}/des_772" --taxon-list 772
"${MMSEQS}" filtertaxseqdb "${RESULTS}/bacs_seqs" "${RESULTS}/not_1224" --taxon-list '!1224'

AS_SHOULD_ONLY_7="0,1,2"
AS_SHOULD_DES_356="0,1,2,3,4,5"
AS_SHOULD_DES_772="3,4,5"
AS_SHOULD_NOT_1224=""

RES_ONLY_7="$(awk '{printf "%s%s",sep,$1; sep=","} END{print ""}' ${RESULTS}/only_7.index)"
RES_DES_356="$(awk '{printf "%s%s",sep,$1; sep=","} END{print ""}' ${RESULTS}/des_356.index)"
RES_DES_772="$(awk '{printf "%s%s",sep,$1; sep=","} END{print ""}' ${RESULTS}/des_772.index)"
RES_NOT_1224="$(awk '{printf "%s%s",sep,$1; sep=","} END{print ""}' ${RESULTS}/not_1224.index)"

TARGET="${AS_SHOULD_ONLY_7} ${AS_SHOULD_DES_356} ${AS_SHOULD_DES_772} ${AS_SHOULD_NOT_1224}"
ACTUAL="${RES_ONLY_7} ${RES_DES_356} ${RES_DES_772} ${RES_NOT_1224}"

awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual == target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
