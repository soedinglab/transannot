#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

notExists() {
		[ ! -f "$1" ]
}

hasCommand() {
    command -v "$1" >/dev/null 2>&1
}

abspath() {
    if [ -d "$1" ]; then
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        if [ -z "${1##*/*}" ]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    elif [ -d "$(dirname "$1")" ]; then
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}

preprocessDb(){
	#filter DB by start index (and extract non-overlapping hits)

	#column 2 contains alnScore (internal ali format)
	#shellcheck disable=SC2086
	"${MMSEQS}" filterdb "$1" "${TMP_PATH}/bitscorefiltDB" --comparison-operator ge --comparison-value 50 --filter-column 2 \
	 	|| fail "filterdb died" 

	"${MMSEQS}" filterdb "${TMP_PATH}/bitscorefiltDB" "$2" --extract-lines 1 \
		|| fail "extract best hit died"
	
	#shellcheck disable=SC2086
	"${MMSEQS}" rmdb "${TMP_PATH}/bitscorefiltDB" ${VERBOSITY_PAR}
	##shellcheck disable=SC2086
	#"${MMSEQS}" rmdb "${TMP_PATH}/indexfiltDB" ${VERBOSITY_PAR}
}

non_overlapping_hits(){

	sort -k 3,3 "$1" > "${TMP_PATH}/sorted_input"

	if [ -n "${SIMPLE_OUTPUT}" ]; then #simple output
		printf "queryID\ttargetID\tqstart\tqend\theader_or_description\te-value\tsearch_type\tdb_name\t" > "$2"
	else # standard output
		printf "queryID\ttargetID\tqstart\tqend\theader_or_description\te-value\tsequenceidentity\tbitscore\tsearch_type\tdb_name\t"
	fi

	PREV_END=0
	while IFS= read -r line; do
		# obtain start and end of each query
		START=$(echo "$line" | awk '{print $3}')
		END=$(echo "$line" | awk '{print $4}')
	
		if [ "$START" -gt "$PREV_END" ]; then
			# no overlap
			#shellcheck disable=SC2086
			echo "$line" >> "$2"
			PREV_END="$END"
		fi
	done < "${TMP_PATH}/sorted_input"

	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/sorted_input" ${VERBOSITY_PAR}
}

convertalis_standard(){
	#shellcheck disable=SC2086
	"${MMSEQS}" convertalis "${TMP_PATH}/clu_rep" $1 $2 $3 --format-output "query,target,qstart,qend,theader,evalue,pident,bits" --format-mode 4 \
		|| fail "convertalis died"
}

convertalis_simple(){
	#shellcheck disable=SC2086
	"${MMSEQS}" convertalis "${TMP_PATH}/clu_rep" $1 $2 $3 --format-output "query,target,qstart,qend,theader,evalue" --format-mode 4 \
		|| fail "convertalis died"
}
#pre-processing
[ -z "$MMSEQS" ] && echo "Please set the environment variable \$MMSEQS to your current binary." && exit 1;
hasCommand wget

#checking how many input variables are provided
[ "$#" -ne 6 ] && echo "Please provide <assembled transciptome> <profile target DB> <sequence target DB> <outDB> <tmp>" && exit 1;
[ "$("${MMSEQS}" dbtype "$2")" != "Profile" ] && echo "The given target database is not profile! Please download profileDB or create from existing sequenceDB!" && exit 1;
[ "$("${MMSEQS}" dbtype "$3")" != "Profile" ] && echo "The given target database is not profile! Please download profileDB or create from existing sequenceDB!" && exit 1;
[ "$("${MMSEQS}" dbtype "$4")" = "Profile" ] && echo "The given target database is profile! Please provide sequence DB!" && exit 1;

#checking whether files already exist
[ ! -f "$1.dbtype" ] && echo "$1.dbtype not found! please make sure that MMseqs db has already been created." && exit 1;
[ ! -f "$2.dbtype" ] && echo "$2.dbtype not found!" && exit 1;
[ ! -f "$3.dbtype" ] && echo "$3.dbtype not found!" && exit 1;
[ ! -f "$4.dbtype" ] && echo "$4.dbtype not found!" && exit 1;
[ ! -d "$6" ] && echo "tmp directory $6 not found! tmp will be created." && mkdir -p "$6"; 

INPUT="$1" #assembled sequence
PROF_TARGET1="$2"  #already downloaded database
PROF_TARGET2="$3"
SEQ_TARGET="$4"
RESULTS="$5"
TMP_PATH="$6" 

#MMSEQS2 LINCLUST for the redundancy reduction
if [ -z "${NO_LINCLUST}" ]; then

	echo "Perform linclust for redundancy reduction"

	if notExists "${TMP_PATH}/clu.dbtype"; then

		#shellcheck disable=SC2086
		"$MMSEQS" linclust "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_tmp" --min-seq-id 0.3 ${CLUSTER_PAR} \
			|| fail "linclust died"

		#shellcheck disable=SC2086
		"$MMSEQS" result2repseq "${INPUT}" "${TMP_PATH}/clu" "${TMP_PATH}/clu_rep" ${RESULT2REPSEQ_PAR} \
			|| fail "extract representative sequences died"
	fi

elif [ -n "${NO_LINCLUST}" ]; then
	echo "No linclust will be performed"
	if notExists "${TMP_PATH}/clu_rep"; then
		#shellcheck disable=SC2086
		"$MMSEQS" cpdb "${INPUT}" "${TMP_PATH}/clu_rep" ${VERBOSITY_PAR} \
			|| fail "copy db died"
		
		#shellcheck disable=SC2086
		"$MMSEQS" cpdb "${INPUT}_h" "${TMP_PATH}/clu_rep_h" ${VERBOSITY_PAR} \
			|| fail "copy header db died"
	fi
fi

if [ -n "${TAXONOMY_ID}" ]; then

	if notExists "${RESULTS}.dbtype"; then
		#shellcheck disable=SC2086
		"$MMSEQS" rbh "${INPUT}" "${PROF_TARGET1}" "${TMP_PATH}/searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
			|| fail "rbh search died"
	fi
		
	elif [ -z "${TAXONOMY_ID}" ]; then
		if notExists "${RESULTS}.dbtype"; then
			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${PROF_TARGET1}" "${TMP_PATH}/prof1_searchDB_no_summ" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} --alt-ali 3 \
				|| fail "first sequence-profile search died"

			#shellcheck disable=SC2086
			$RUNNER "$MMSEQS" summarizeresult "${TMP_PATH}/prof1_searchDB_no_summ" "${TMP_PATH}/prof1_searchDB" ${SUMMARIZE_PAR} \
				|| fail "first sequence-profile search died"

			# preprocessDb "${TMP_PATH}/prof1_searchDB" "${TMP_PATH}/prof1_searchDB_filt"

			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${PROF_TARGET2}" "${TMP_PATH}/prof2_searchDB_no_summ" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} --alt-ali 3 \
				|| fail "second sequence-profile search died"
			
			# preprocessDb "${TMP_PATH}/prof2_searchDB" "${TMP_PATH}/prof2_searchDB_filt"
			
			#shellcheck disable=SC2086
			"$MMSEQS" summarizeresult "${TMP_PATH}/prof2_searchDB_no_summ" "${TMP_PATH}/prof2_searchDB" ${SUMMARIZE_PAR} \
				|| fail "second sequence-profile search died"

			#shellcheck disable=SC2086
			"$MMSEQS" search "${TMP_PATH}/clu_rep" "${SEQ_TARGET}" "${TMP_PATH}/seq_searchDB" "${TMP_PATH}/search_tmp" ${SEARCH_PAR} \
				|| fail "sequence-sequence search died"

			preprocessDb "${TMP_PATH}/seq_searchDB" "${TMP_PATH}/seq_searchDB_filt"

			if [ -n "${SIMPLE_OUTPUT}" ]; then
				echo "Simplified output will be provided"
				convertalis_simple "${PROF_TARGET1}" "${TMP_PATH}/prof1_searchDB" "${TMP_PATH}/prof1_searchDB.tsv"
				# non_overlapping_hits "${TMP_PATH}/prof1_searchDB.tsv" "${TMP_PATH}/prof1_searchDB_nooverlap.tsv"
				convertalis_simple "${PROF_TARGET2}" "${TMP_PATH}/prof2_searchDB" "${TMP_PATH}/prof2_searchDB.tsv"
				# non_overlapping_hits "${TMP_PATH}/prof2_searchDB.tsv" "${TMP_PATH}/prof2_searchDB_nooverlap.tsv"
				convertalis_simple "${SEQ_TARGET}" "${TMP_PATH}/seq_searchDB_filt" "${TMP_PATH}/seq_searchDB.tsv"

			else
				echo "Standard output will be provided"
				convertalis_standard "${PROF_TARGET1}" "${TMP_PATH}/prof1_searchDB" "${TMP_PATH}/prof1_searchDB.tsv"
				# non_overlapping_hits "${TMP_PATH}/prof1_searchDB.tsv" "${TMP_PATH}/prof1_searchDB_nooverlap.tsv"
				convertalis_standard "${PROF_TARGET2}" "${TMP_PATH}/prof2_searchDB" "${TMP_PATH}/prof2_searchDB.tsv"
				# non_overlapping_hits "${TMP_PATH}/prof2_searchDB.tsv" "${TMP_PATH}/prof2_searchDB_nooverlap.tsv"
				convertalis_standard "${SEQ_TARGET}" "${TMP_PATH}/seq_searchDB_filt" "${TMP_PATH}/seq_searchDB.tsv"
			fi

			rm -f "${TMP_PATH}/prof1_searchDB."[0-9]*
			rm -f "${TMP_PATH}/prof2_searchDB."[0-9]*
			rm -f "${TMP_PATH}/seq_searchDB."[0-9]*
			# rm -f "${TMP_PATH}/prof1_searchDB.tsv"
			# rm -f "${TMP_PATH}/prof2_searchDB.tsv"
		fi
	fi

if notExists "${TMP_PATH}/tmp_join.tsv"; then

	TRANSANNOT="$(abspath "$(command -v "${MMSEQS}")")"
	SCRIPT="${TRANSANNOT%/build*}"
	# SCRIPT_NO_BUILD="${TRANSANNOT%/*/*}"
	SCRIPT_NO_BUILD=$(echo "$TRANSANNOT" | awk -F'/' '{if (NF > 2) {for (i=1; i<=NF-2; i++) {printf "%s/", $i}}}')

	echo "obtain names of the Pfam families"
	
	# wget -O "${TMP_PATH}/pfamA_desc.tsv" --mirror http://raw.githubusercontent.com/soedinglab/transannot/main/data/Pfam-A.clans.tsv
	awk -F '\t' -v OFS='\t' '{sub(/\.[^\.]+$/,"",$5)}1' "${TMP_PATH}/prof1_searchDB.tsv" >> "${TMP_PATH}/tmpfile"; mv -f "${TMP_PATH}/tmpfile" "${TMP_PATH}/prof1_searchDB_proc.tsv"

	if [ -e "${SCRIPT}/data/Pfam-A.clans.tsv" ]; then
		awk -F '\t' -v OFS='\t' '{print $1, $5}' "${SCRIPT}/data/Pfam-A.clans.tsv" >> "${TMP_PATH}/PfamMappingFile"
	else
		awk -F '\t' -v OFS='\t' '{print $1, $5}' "${SCRIPT_NO_BUILD}/bin/Pfam-A.clans.tsv" >> "${TMP_PATH}/PfamMappingFile"
	fi
	# awk -F '\t' -v OFS='\t' '{print $1, $5}' "${SCRIPT}/data/Pfam-A.clans.tsv" >> "${TMP_PATH}/PfamMappingFile" || awk -F '\t' -v OFS='\t' '{print $1, $5}' "${SCRIPT_NO_BUILD}/bin/Pfam-A.clans.tsv" >> "${TMP_PATH}/PfamMappingFile"
	awk -F '\t' -v OFS='\t' 'BEGIN{OFS=FS="\t"} NR==FNR{clr[$1]=$2; next} { if ($5 in clr) {$5=clr[$5]; print}}' "${TMP_PATH}/PfamMappingFile" "${TMP_PATH}/prof1_searchDB_proc.tsv" | \
	LC_ALL=C sort -s -k1b,1 | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "seq-prof search"; print}' | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "PfamA"; print}'  >> "${TMP_PATH}/prof1_search_annot.tsv"

	rm -f "${TMP_PATH}/prof1_searchDB.tsv"
	rm -f "${TMP_PATH}/PfamMappingFile"
	rm -f "${TMP_PATH}/pfamA_desc.tsv"

	echo "download eggNOG annotation file"
	wget -O "${TMP_PATH}/nog_annotations.tsv" http://eggnog5.embl.de/download/eggnog_5.0/e5.og_annotations.tsv

	echo "obtain descriptions of the eggNOG orthology groups"
	awk -F '\t' -v OFS='\t' 'BEGIN{OFS=FS="\t"} {print $2, $4}' "${TMP_PATH}/nog_annotations.tsv" >> "${TMP_PATH}/mappingFile" 
	rm -f "${TMP_PATH}/nog_annotations.tsv" 
	awk -F '\t' -v OFS='\t' 'BEGIN{OFS=FS="\t"} NR==FNR{clr[$1]=$2; next} { if ($5 in clr) {$5=clr[$2]; print}}' "${TMP_PATH}/mappingFile" "${TMP_PATH}/prof2_searchDB.tsv" | \
	 LC_ALL=C sort -s -k1b,1 | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "seq-prof search"; print}' | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "eggNOG"; print}' >> "${TMP_PATH}/prof2_search_annot.tsv"

	rm -f "${TMP_PATH}/prof2_searchDB.tsv"

	LC_ALL=C sort -s -k1b,1 "${TMP_PATH}/seq_searchDB.tsv" | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "seq-seq search"; print}' | awk -F '\t' -v OFS='\t' '{ $(NF+1) = "SwissProt"; print}'>> "${TMP_PATH}/seq_search_filt.tsv"
	rm -f "${TMP_PATH}/seq_searchDB.tsv"

	join -j 1 -a1 -a2 -t ' ' "${TMP_PATH}/prof1_search_annot.tsv" "${TMP_PATH}/prof2_search_annot.tsv" >> "${TMP_PATH}/tmp_join.tsv"
	join -j 1 -a1 -a2 -t ' ' "${TMP_PATH}/tmp_join.tsv" "${TMP_PATH}/seq_search_filt.tsv" >> "${TMP_PATH}/restmp"

	rm -f "${TMP_PATH}/tmp_join.tsv"
fi

# add headers
if [ -n "${SIMPLE_OUTPUT}" ]; then
		echo "Simple output"
		awk -F'\t' -v OFS='\t' 'BEGIN { print "queryID\ttargetID\tquery_start\tquery_end\theader_or_description\te-value\tsearch_type\tdb_name\t"}{print}' "${TMP_PATH}/restmp" >> "${RESULTS}"
	else
		echo "Standard output"
		awk -F'\t' -v OFS='\t' 'BEGIN { print "queryID\ttargetID\tquery_start\tquery_end\theader_or_description\te-value\tsequenceidentity\tbitscore\tsearch_type\tdb_name\t"}{print}' "${TMP_PATH}/restmp" >> "${RESULTS}"
fi
rm -f "${TMP_PATH}/restmp"

#remove temporary files and directories
if [ -n "${REMOVE_TMP}" ]; then
	echo "Remove temporary files and directories"

	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/clu" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof1_searchDB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof2_searchDB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/seq_searchDB" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof1_searchDB_filt" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof2_searchDB_filt" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/seq_searchDB_filt" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof1_searchDB_no_summ" ${VERBOSITY_PAR}
	#shellcheck disable=SC2086
	"$MMSEQS" rmdb "${TMP_PATH}/prof2_searchDB_no_summ" ${VERBOSITY_PAR}
	rm -f "${TMP_PATH}/annotate.sh"
fi
