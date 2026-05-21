#!/bin/bash
echo "Remove duplicates based on ISIN and ticker, and filter invalid rows"

input="$1"
output="${2:-deduplicated.csv}"

awk -F';' '
NR==1 {
    print
    next
}

{
    isin = toupper($1)
    ticker = toupper($4)

    # filter invalid rows
    if (isin == "N/A" ||
        ticker == "N/A" ||
        length(isin) != 12 ||
        length(ticker) > 12 ||
        length(ticker) < 2) {
        next
    }

    key = isin "|" ticker

    if (!seen[key]++) {
        print
    }
}
' "$input" > "$output"

echo "Saved to: $output"