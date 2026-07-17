#!/usr/bin/env bash

# Default values
INPUT="./_work/stock_index_adjusted.csv"
BATCH_SIZE=5
OUTPUT_FOLDER="./_quotes"

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --input=*)
            INPUT="${arg#*=}"
            ;;
        --batch-size=*)
            BATCH_SIZE="${arg#*=}"
            ;;
        --output-folder=*)
            OUTPUT_FOLDER="${arg#*=}"
            ;;
        *)
            echo "Unknown parameter: $arg"
            echo "Usage: $0 --input=stock_index_adjusted.csv --batch-size=5 --output-folder=quotes/"
            exit 1
            ;;
    esac
done

echo "Usage: $0 --input=stock_index_adjusted.csv --batch-size=5 --output-folder=quotes/"
echo "Reading stock symbols from $INPUT..."
ERRLOG="${OUTPUT_FOLDER}/quotes.err"

# Counters
REQUESTS_COUNT=0
ERROR_COUNT=0
mkdir -p "$OUTPUT_FOLDER"

# Clean error log
> "$ERRLOG"

# Extract tickers (skip header)
mapfile -t TICKERS < <(tail -n +2 "$INPUT" | awk -F';' '{print $1}')
TOTAL_SYMBOLS=${#TICKERS[@]}

batch=()

process_batch() {
    local symbols_csv
    symbols_csv=$(printf "%s," "${batch[@]}" | sed 's/,$//')

    ((REQUESTS_COUNT++))

    json=$(curl -s \
      -X GET --compressed \
      "https://query1.finance.yahoo.com/v7/finance/quote?&symbols=${symbols_csv}&fields=currency,regularMarketChange,regularMarketChangePercent,regularMarketPrice,regularMarketTime,preMarketChange,preMarketChangePercent,preMarketPrice,preMarketTime,priceHint,postMarketChange,postMarketChangePercent,postMarketPrice,postMarketTime,extendedMarketChange,extendedMarketChangePercent,extendedMarketPrice,extendedMarketTime&crumb=BBNBOdpC2sE&formatted=false&region=US&lang=en-US" \
      -H "Accept-Language: en-US,en;q=0.9" \
      -H "Cache-Control: no-cache" \
      -H "Accept-Encoding: gzip, deflate, br, zstd" \
      -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36" \
      -H "Cookie: EuConsent=CQnSakAQnSakAAOACKITCnFgAAAAAAAAACiQAAAAAAAA.IMHtB9G7eTXFneTJ2YLskOYwX0VBJ4MAwBgCAAEABzBIUIBwGVmATJEyIICACGAIAIGBBIABtGBhAQEAAIIAVAABIAEkAIBAAIGAAACAIQABACAABAAAAMAAQgEAXIAQgmAYEBFoIQUhAkgAgAQAAAAAEAIgBCASAEAAAQAAACAAAgCgAggAAAAAAAAAEAFAIEQAAIAECAovgdgAQAAAAAAgIAAYACEABAAAABIAAAgCAAAAAAAAAAAAAAAAAAABCAIAACA; GUC=AQABCAFqVptqfUIj3ATu&s=AQAAAA7YSrgT&g=alVQKg; A1S=d=AQABBCBQVWoCEPvLKkvMn_wmVUCXHxlS5GcFEgABCAGbVmp9aue4Jm0AAiAAAAcIGlBVaqRaQdw&S=AQAAAkQu-BJwCaAkkFERAi7kcdQ; A1=d=AQABBCBQVWoCEPvLKkvMn_wmVUCXHxlS5GcFEgABCAGbVmp9aue4Jm0AAiAAAAcIGlBVaqRaQdw&S=AQAAAkQu-BJwCaAkkFERAi7kcdQ; A3=d=AQABBCBQVWoCEPvLKkvMn_wmVUCXHxlS5GcFEgABCAGbVmp9aue4Jm0AAiAAAAcIGlBVaqRaQdw&S=AQAAAkQu-BJwCaAkkFERAi7kcdQ; PRF=t%3DIBM%252BORCL%26dock-collapsed%3Dtrue; cmp=t=1784024221&j=1&u=1---&v=14")
  
    # Check Error
    if echo "$json" | jq -e '.finance.error' >/dev/null 2>&1; then
        for sym in "${batch[@]}"; do
            echo "$sym" >> "$ERRLOG"
            ((ERROR_COUNT++))
        done
        batch=()
        return
    fi

    # Save each JSON result
    echo "$json" | jq -c '.quoteResponse.result[]' | while read -r item; do
        symbol=$(echo "$item" | jq -r '.symbol')
        clean_symbol="${symbol/^/}"
        echo "$item" > "${OUTPUT_FOLDER}/${clean_symbol}.json"
    done

    # Detect missing symbols
    for sym in "${batch[@]}"; do
        clean="${sym/^/}"
        if [[ ! -f "${OUTPUT_FOLDER}/${clean}.json" ]]; then
            echo "$sym" >> "$ERRLOG"
            ((ERROR_COUNT++))
        fi
    done

    batch=()
}

# Build batches
for ticker in "${TICKERS[@]}"; do
    batch+=("$ticker")

    if (( ${#batch[@]} == BATCH_SIZE )); then
        process_batch
    fi
done

# Process remaining tickers
if (( ${#batch[@]} > 0 )); then
    process_batch
fi

echo "Requests made: $REQUESTS_COUNT for $TOTAL_SYMBOLS symbols" >> "$ERRLOG"
echo "Errors found:  $ERROR_COUNT" >> "$ERRLOG"
echo "Requests made: $REQUESTS_COUNT for $TOTAL_SYMBOLS symbols" 
echo "Errors found:  $ERROR_COUNT"
echo "Errors logged in $ERRLOG" 
