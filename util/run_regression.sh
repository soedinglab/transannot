#!/bin/sh -e
fail() {
	echo "Error: $1"
	exit 1
}

TRANSANNOT="$1"
DATA="$2"
BASEDIR="$3"

mkdir -p "${BASEDIR}"