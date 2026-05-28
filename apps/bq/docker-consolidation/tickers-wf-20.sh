#!/usr/bin/env bash

# Usage:
#   ./update_tickers.sh certs_tickers.csv tickers_alt_names.csv output.csv
#
# Example:
#   ./update_tickers.sh certs_tickers.csv tickers_alt_names.csv certs_updated.csv

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 certs_tickers.csv tickers_alt_names.csv output.csv"
    exit 1
fi

CERTS_FILE="$1"
ALT_FILE="$2"
OUTPUT_FILE="$3"

########################################
# CONFIGURATION
########################################

DELIM=';'

# certs_tickers.csv columns
CERTS_MATCH_COL="ticker_symbol"

# tickers_alt_names.csv columns
ALT_MATCH_COL="ticker_alt_symbol"
ALT_REPLACE_COL="ticker_correct_symbol"

########################################

awk -F"$DELIM" \
-v OFS="$DELIM" \
-v certs_match_col="$CERTS_MATCH_COL" \
-v alt_match_col="$ALT_MATCH_COL" \
-v alt_replace_col="$ALT_REPLACE_COL" '

function get_col_index(header_line, col_name,    i) {
    for (i = 1; i <= NF; i++) {
        if ($i == col_name) {
            return i
        }
    }

    printf("ERROR: Column \"%s\" not found\n", col_name) > "/dev/stderr"
    exit 1
}

# =========================
# Read ALT FILE
# =========================
FNR == NR {

    # Header
    if (FNR == 1) {

        alt_match_idx = get_col_index($0, alt_match_col)
        alt_replace_idx = get_col_index($0, alt_replace_col)

        next
    }

    alt_value = $alt_match_idx
    correct_value = $alt_replace_idx

    mapping[alt_value] = correct_value

    next
}

# =========================
# Process CERTS FILE
# =========================
{

    # Header
    if (FNR == 1) {

        certs_match_idx = get_col_index($0, certs_match_col)

        print
        next
    }

    current_value = $certs_match_idx

    if (current_value in mapping) {
        $certs_match_idx = mapping[current_value]
    }

    print
}

' "$ALT_FILE" "$CERTS_FILE" > "$OUTPUT_FILE"

echo "Updated file written to: $OUTPUT_FILE"