#!/usr/bin/env bash

# Usage:
#   ./normalize-cols.sh input.csv alt_names.csv output.csv \
#       input_col_name normalized_col_name alt_col_name
#
# Logic:
#   Replace:
#       input.csv::input_col_name
#   with:
#       alt_names.csv::normalized_col_name
#
#   IF:
#       input.csv::input_col_name
#       ==
#       alt_names.csv::alt_col_name

set -euo pipefail

if [ "$#" -ne 6 ]; then
    echo "Usage:"
    echo "  $0 input.csv alt_names.csv output.csv input_col_name normalized_col_name alt_col_name"
    exit 1
fi

INPUT_FILE="$1"
ALT_FILE="$2"
OUTPUT_FILE="$3"

INPUT_COL_NAME="$4"
NORMALIZED_COL_NAME="$5"
ALT_COL_NAME="$6"

########################################
# CONFIG
########################################

DELIM=';'

########################################

awk -F"$DELIM" \
-v OFS="$DELIM" \
-v input_col_name="$INPUT_COL_NAME" \
-v normalized_col_name="$NORMALIZED_COL_NAME" \
-v alt_col_name="$ALT_COL_NAME" '

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

function get_col_index(col_name,    i, field) {

    for (i = 1; i <= NF; i++) {

        field = trim($i)

        if (field == col_name) {
            return i
        }
    }

    printf("ERROR: column \"%s\" not found\n", col_name) > "/dev/stderr"
    exit 1
}

# ======================================
# READ ALT FILE
# ======================================
FNR == NR {

    # HEADER
    if (FNR == 1) {

        alt_col_idx = get_col_index(alt_col_name)
        normalized_col_idx = get_col_index(normalized_col_name)

        next
    }

    alt_value = toupper(trim($alt_col_idx))
    normalized_value = trim($normalized_col_idx)

    if (alt_value != "") {
        mapping[alt_value] = normalized_value
    }

    next
}

# ======================================
# PROCESS INPUT FILE
# ======================================
{

    # HEADER
    if (FNR == 1) {

        input_col_idx = get_col_index(input_col_name)

        print
        next
    }

    current_value = toupper(trim($input_col_idx))

    if (current_value in mapping) {
        $input_col_idx = mapping[current_value]
    }

    print
}

' "$ALT_FILE" "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Normalized file written to: $OUTPUT_FILE"