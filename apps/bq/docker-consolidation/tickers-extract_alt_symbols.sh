#!/usr/bin/env bash

# Usage:
#   ./extract_alt_symbols.sh tickers.csv output.csv

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 tickers.csv output.csv"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

########################################
# CONFIGURATION
########################################

DELIM=';'

SYMBOL_COL="stock_google_finance_ticker"
EXCHANGE_COL="stock_exchange"

########################################

awk -F"$DELIM" \
-v OFS="$DELIM" \
-v symbol_col_name="$SYMBOL_COL" \
-v exchange_col_name="$EXCHANGE_COL" '

function get_col_index(col_name,    i) {
    for (i = 1; i <= NF; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i)

        if ($i == col_name) {
            return i
        }
    }

    printf("ERROR: column \"%s\" not found\n", col_name) > "/dev/stderr"
    exit 1
}

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

# =========================
# HEADER
# =========================
FNR == 1 {

    symbol_idx = get_col_index(symbol_col_name)
    exchange_idx = get_col_index(exchange_col_name)

    next
}

# =========================
# STORE DATA
# =========================
{

    symbol = trim($symbol_idx)
    exchange = trim($exchange_idx)

    symbols[symbol] = exchange

    # Detect prefixed ticker like BIT:BMPS
    if (symbol ~ /:/) {

        split(symbol, parts, ":")

        alt_symbol = trim(parts[2])

        # Match only if alt symbol exists
        # AND exchange is the same
        if (alt_symbol in symbols &&
            symbols[alt_symbol] == exchange) {

            print symbol, alt_symbol
        }
    }
}

END {

}
' "$INPUT_FILE" > "$OUTPUT_FILE"

# Add header
sed -i '1istock_symbol;stock_alt_symbol' "$OUTPUT_FILE"

echo "Output written to: $OUTPUT_FILE"