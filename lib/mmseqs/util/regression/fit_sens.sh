#!/bin/bash -e
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
MMSEQS_OLD="$(abspath "$(command -v "$1")")"
MMSEQS_NEW="$(abspath "$(command -v "$2")")"
SCRATCH="$(abspath "$3")"
mkdir -p "${SCRATCH}"
RUN_ONLY="${4:-""}"

BASE="$(dirname "$(abspath "$0")")"
cd "${BASE}"

# build the benchmark tools
(mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j4) > /dev/null 2>&1

export DATADIR="${BASE}/data"
export SCRIPTS="${BASE}/regression"
export EVALUATE="${BASE}/build/evaluate_results"

CURR_ROC=""
TESTS=""
: > "${SCRATCH}/fit.log"
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
  "${SCRIPTS}/${FILE}" "$@" &>> "${SCRATCH}/fit.log"
  CURR_ROC=$(awk '/^Actual:/ { print $2 }' "${RESULTS}.report")
  rm -rf "${RESULTS}" ${RESULTS}.report
}

TEST="DBPROFILE"
TEST_SCRIPT="run_dbprofile.sh"
KMER_SIZE=(5 6 7)
for K in ${KMER_SIZE[@]}; do
TARGET_SENS=(1 3 5 7)
COUNT=${#TARGET_SENS[@]}
declare -a TARGET_ROC=()
export MMSEQS=${MMSEQS_OLD}
: > "${SCRATCH}/fit.start"
for i in $(seq 0 $((COUNT - 1))); do
    CURR_SENS=${TARGET_SENS[i]}
    run_test "${TEST}" "${TEST_SCRIPT}" "-s ${CURR_SENS} -k ${K}"
    TARGET_ROC+=($CURR_ROC)
    echo -e "${CURR_SENS}\t${CURR_ROC}" | tee -a "${SCRATCH}/fit.start"
done

START_KMER_THR_HIGH=180
START_KMER_THR_LOW=60

export MMSEQS=${MMSEQS_NEW}
: > "${SCRATCH}/fit.opt"
for i in $(seq 0 $((COUNT - 1))); do
    CURR_SENS=${TARGET_SENS[i]}
    CURR_TARGET=${TARGET_ROC[i]}
    KMER_THR_HIGH=$START_KMER_THR_HIGH
    KMER_THR_LOW=$START_KMER_THR_LOW
    LAST_KMER_THR=0
    LAST_ACCEPTED_THR=0
    LAST_ACCEPTED_ROC=0
    LAST_REJECTED_THR=0
    LAST_REJECTED_ROC=0
    while true; do
        KMER_THR=$(echo "(($KMER_THR_LOW + ($KMER_THR_HIGH - $KMER_THR_LOW) / 2)+0.5)/1" | bc -l)
        KMER_THR=${KMER_THR%%.*}
        if [ ${LAST_KMER_THR} = $KMER_THR ]; then
            break
        fi
        LAST_KMER_THR=$KMER_THR
        run_test "${TEST}" "${TEST_SCRIPT}" "--k-score ${KMER_THR} -k ${K}"
        if (( $(echo "$CURR_ROC < $CURR_TARGET" | bc -l) )); then
            KMER_THR_HIGH=$(echo "$KMER_THR" | bc -l)
            LAST_REJECTED_THR=$KMER_THR
            LAST_REJECTED_ROC=$CURR_ROC
        else
            KMER_THR_LOW=$(echo "$KMER_THR" | bc -l)
            LAST_ACCEPTED_THR=$KMER_THR
            LAST_ACCEPTED_ROC=$CURR_ROC
        fi
    done
    echo -e "${CURR_SENS}\t${LAST_ACCEPTED_THR}\t${LAST_ACCEPTED_ROC}" | tee -a "${SCRATCH}/fit.opt"
    #echo -e "${CURR_SENS}\t${LAST_REJECTED_THR}\t${LAST_REJECTED_ROC}"
done
done
