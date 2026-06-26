#!/usr/bin/env bash
if [ -z "$1" ]; then
  echo "usage: $0 <input csv file>"
  exit 1
fi
INPUT=$1
OUTPUT="tickers-index.csv"

# Write header
echo "stock_name;stock_google_finance_ticker;stock_exchange;stock_isin;stock_industry;stock_sector" > "$OUTPUT"

# Extract columns:
#  stock_name (3)
#  stock_google_finance_ticker (4)
#  stock_exchange (5)
#  stock_isin (6) ;stock_industry (7) ;stock_sector (8)
# Then dedupe by column 2 (ticker)
awk -F';' '
NR>1 {
    name=$3
    ticker=$4
    exch=$5
    isin=$6
    ind=$7
    sec=$8

    # Replace N/A only if ticker contains ":" (e.g., BIT:ISP)
    if (exch == "N/A" && index(ticker, ":") > 0) {
        split(ticker, parts, ":")
        exch = parts[1]
    }

    key=ticker
    if (!seen[key]++) {
        print name";"ticker";"exch";"isin";"ind";"sec
    }
}
' "$INPUT" >> "$OUTPUT"

echo "Created $OUTPUT"