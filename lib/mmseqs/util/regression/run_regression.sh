#!/bin/sh -e
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

if [ "$#" -lt 2 ]; then
  echo "Need at least 2 parameters!"
  exit 1
fi
export MMSEQS="$(abspath "$(command -v "$1")")"
SCRATCH="$(abspath "$2")"
RUN_ONLY="${3:-""}"

BASE="$(dirname "$(abspath "$0")")"
cd "${BASE}"

# build the benchmark tools
(mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j4)

export DATADIR="${BASE}/data"
export SCRIPTS="${BASE}/regression"
export EVALUATE="${BASE}/build/evaluate_results"
export SAMTOOLS="${BASE}/samtools/samtools.sh"

TESTS=""
run_test() {
  if [ "$#" -lt 2 ]; then
    echo "Test needs at least 2 parameters!"
    exit 1
  fi
  NAME="$1"
  FILE="$2"
  shift
  shift
  if [ ! -z "$RUN_ONLY" ] && [ X"$RUN_ONLY" != X"$NAME" ]; then
    return
  fi
  TESTS="${TESTS} ${NAME}"
  export RESULTS="${SCRATCH}/${NAME}"
  mkdir -p "${RESULTS}"
  START="$(date +%s)"
  "${SCRIPTS}/${FILE}" "$@"
  STATUS="$?"
  END="$(date +%s)"
  if [ "${STATUS}" = "0" ]; then
     if [ -f "${RESULTS}.report" ] && [ "$(echo $(head -n 1 "${RESULTS}.report"))" = "GOOD" ]; then
        rm -rf "${RESULTS}"
     fi
  fi
  eval "${NAME}_TIME"="$((END-START))"
}

# continue on if one test fail
set +e
run_test SEARCH "run_search.sh"
run_test EASY_SEARCH "run_easy_search.sh"
run_test EASY_SEARCH_INDEX_SPLIT "run_easy_search_index_split.sh"
run_test PROFILE "run_profile.sh"
run_test EASY_PROFILE "run_easy_profile.sh"
run_test SLICEPROFILE "run_sliceprofile.sh"
run_test DBPROFILE "run_dbprofile.sh"
run_test EXPAND "run_expand.sh"
run_test NUCLPROT_SEARCH "run_nuclprot.sh"
run_test NUCLNUCL_SEARCH "run_nuclnucl.sh"
run_test NUCLNUCL_TRANS_SEARCH "run_nuclnucl_translated.sh"
run_test CLUSTER "run_cluster.sh"
run_test EASY_CLUSTER "run_easy_cluster.sh"
run_test EASY_NUCL_CLUSTER "run_easy_nuclcluster.sh"
run_test CLUSTER_REASSIGN "run_easy_cluster_reassign.sh"
run_test LINCLUST "run_linclust.sh"
run_test LINCLUST_SPLIT "run_linclust_split.sh"
run_test EASY_LINCLUST "run_easy_linclust.sh"
run_test CLUSTHASH "run_clusthash.sh"
run_test PROTNUCL_SEARCH "run_protnucl.sh"
run_test NUCLPROTTAX_SEARCH "run_nuclprottax.sh"
run_test EASYNUCLPROTSEARCH_TAX "run_easy_search_taxoutput.sh"
run_test DBPROFILE_INDEX "run_dbprofile_index.sh"
run_test LINSEARCH_NUCLNUCL_TARNS_SEARCH "run_nuclnucl_linsearchtranslated.sh"
run_test LINSEARCH_NUCLNUCL_SEARCH "run_nuclnucl_linsearch.sh"
run_test EASY_LINSEARCH_NUCLNUCL_SEARCH_SPLIT "run_easy_nuclnucl_linsearch_split.sh"
run_test LINCLUST_UPDATE "run_cluster_update.sh"
run_test EASYNUCLNUCLTAX_SEARCH "run_easy_nuclnucltax.sh"
run_test EXTRACTORFS "run_extractorfs.sh"
run_test RBH "run_rbh.sh"
case "$(uname -s)" in
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        ;;
    *)
        run_test APPLY "run_apply.sh"
        ;;
esac
run_test INDEX_COMPATIBLE "run_index_compatible.sh"
# run_test MULTHIT "run_multihit.sh"
run_test FILTERDB "run_filterdb.sh"
run_test PREF_DB_LOAD_MODE "run_prefilter_db_load_mode.sh"
run_test FILTERTAXSEQDB "run_filtertaxseqdb.sh"
case "$("${MMSEQS}" version)" in
	*MPI)
		export RUNNER="mpirun -np 1"
		run_test MPI_TARGET_SPLIT_NP1 "run_split.sh" 0
		run_test MPI_QUERY_SPLIT_NP1 "run_split.sh" 1
		run_test MPI_SLICE_TECH_NP1 "run_slicetechnical.sh"
		
		export RUNNER="mpirun -np 3"
		run_test MPI_TARGET_SPLIT_NP3 "run_split.sh" 0
		run_test MPI_QUERY_SPLIT_NP3 "run_split.sh" 1
		run_test MPI_SLICE_TECH_NP3 "run_slicetechnical.sh"
		
		unset RUNNER
		;;
	*)
		run_test NOMPI_TARGET_SPLIT "run_split.sh" 0
		run_test NOMPI_SLICE_TECH "run_slicetechnical.sh"
esac

set -e
printf "\n"
ERR=0
for i in ${TESTS} ; do
    VAL="${i}_TIME"
    eval TIME="\$$VAL"
    printf "\033[1m$i (Time: %ss)\033[0m\n" "${TIME}"
    if [ ! -f "${SCRATCH}/${i}.report" ]; then
        printf "\033[33mTEST FAILED (NO REPORT)\033[0m\n\n"
        ERR=$((ERR+1))
        continue
    fi

    if [ ! -s "${SCRATCH}/${i}.report" ]; then
        printf "\033[33mTEST FAILED (EMPTY REPORT)\033[0m\n\n"
        ERR=$((ERR+1))
        continue
    fi
    STATUS="$(head -n 1 "${SCRATCH}/${i}.report")"
    if [ "$STATUS" != "GOOD" ]; then
        printf "\033[31mTEST FAILED\033[0m\n"
        ERR=$((ERR+1))
    else
        printf "\033[32mTEST SUCCESS\033[0m\n"
    fi
    cat "${SCRATCH}/${i}.report"
    printf "\n"
done

exit "$ERR"
