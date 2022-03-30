#!/bin/sh -e
SELF="$( cd "$(dirname "$0")" ; pwd -P )"
SUFFIX=""
case "$(uname -m)" in
  arm*|aarch*) SUFFIX="-aarch64" ;;
  ppc*) SUFFIX="-ppc64le" ;;
esac
case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
  linux*) exec "$SELF/samtools-linux$SUFFIX" "$@" ;;
  darwin*) exec "$SELF/samtools-darwin" "$@" ;;
  msys*|cygwin*|mingw*) exec "$SELF/samtools-windows" "$@" ;;
esac
echo "No precompiled samtools found, using system samtools" >&2
samtools "$@"
