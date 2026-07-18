#!/usr/bin/env sh

# Compile every runnable example into example-bin/.
# Run from any directory with: sh /path/to/mathlib-fp/build-examples.sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

# Keep compiler arguments relative to the repository root. Besides making the
# output shorter, this works with both native Unix FPC and Windows FPC invoked
# from Git Bash, whose drive-path conversion does not apply inside -Fu/-FU/-FE.
EXAMPLE_DIR=examples
SOURCE_DIR=src
OUTPUT_DIR=example-bin
UNIT_DIR="$OUTPUT_DIR/units"
FPC_BIN=${FPC:-fpc}

mkdir -p "$UNIT_DIR"

count=0
for example in "$EXAMPLE_DIR"/*.lpr; do
  if [ ! -f "$example" ]; then
    echo "No .lpr examples found in $EXAMPLE_DIR" >&2
    exit 1
  fi

  echo "Compiling $(basename "$example")"
  "$FPC_BIN" -B -FcUTF8 \
    "-Fu$SOURCE_DIR" \
    "-FU$UNIT_DIR" \
    "-FE$OUTPUT_DIR" \
    "$example"
  count=$((count + 1))
done

echo "Compiled $count examples into $OUTPUT_DIR"
