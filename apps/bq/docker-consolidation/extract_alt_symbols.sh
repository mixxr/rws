#!/usr/bin/env bash

# Usage:
#   ./extract_alt_symbols.sh input.csv output.csv col_name

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 input.csv output.csv col_name"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
COL_NAME="$3"

DELIM=';'

awk -F"$DELIM" -v OFS="$DELIM" -v col_name="$COL_NAME" '

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

function get_col_index(col_name,    i, field) {
    for (i = 1; i <= NF; i++) {
        field = trim($i)
        if (field == col_name) return i
    }
    printf("ERROR: column \"%s\" not found\n", col_name) > "/dev/stderr"
    exit 1
}

FNR == 1 {
    col_idx = get_col_index(col_name)
    next
}

{
    symbol = trim($col_idx)

    # store existence map (case-insensitive safe)
    exists[toupper(symbol)] = symbol

    rows[++n] = symbol
}

END {
    print "stock_symbol", "stock_alt_symbol"

    for (i = 1; i <= n; i++) {

        symbol = rows[i]

        if (symbol ~ /:/) {

            split(symbol, parts, ":")
            alt = trim(parts[2])

            if (toupper(alt) in exists) {

                pair = symbol DELIM alt

                # ✅ deduplication
                if (!seen[pair]++) {
                    print symbol, alt
                }
            }
        }
    }
}

' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Output written to: $OUTPUT_FILE"