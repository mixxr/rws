#!/usr/bin/env bash

STOCK_INDEX="$1"
EXCHANGE_FILE="$2"
OUTPUT="${3:-STOCK_INDEX_adjusted.csv}"

if [[ -z "$STOCK_INDEX" || -z "$EXCHANGE_FILE" ]]; then
    echo "Usage: $0 STOCK_INDEX EXCHANGE_FILE [OUTPUT_FILE]"
    exit 1
fi

# Load exchange → suffix mapping
declare -A EXMAP
while IFS=';' read -r exch suffix || [[ -n "$exch" ]]; do
    [[ -z "$exch" ]] && continue
    EXMAP["$exch"]="$suffix"
done < "$EXCHANGE_FILE"

# Process STOCK_INDEX
{
    # Read and write header
    read -r header
    echo "$header" > "$OUTPUT"

    while IFS=';' read -r ticker name exch isin industry sector; do

        # Extract exchange:symbol if present
        t_ex=""
        t_sym="$ticker"

        if [[ "$ticker" == *:* ]]; then
            t_ex="${ticker%%:*}"
            t_sym="${ticker#*:}"
        fi

        # Clean whitespace
        t_ex="${t_ex//[[:space:]]/}"
        exch="${exch%% *}"
        exch="${exch//[[:space:]]/}"

        # echo "exc in symbol: $t_ex,${EXMAP[$t_ex]} | exc in col: $exch,${EXMAP[$exch]}" 

        # Apply suffix if ticker exchange OR stock_exchange matches
        if [[ "$t_sym" != *.* ]]; then
            if [[ -n "$t_ex" && -n "${EXMAP[$t_ex]}" ]]; then
                ticker="${t_sym}${EXMAP[$t_ex]}"
            elif [[ -n "$exch" && -n "${EXMAP[$exch]}" ]]; then
                ticker="${t_sym}${EXMAP[$exch]}"
            else
                ticker="$t_sym"
            fi
        else
            # symbol already has a suffix → leave unchanged
            ticker="$t_sym"
        fi

        # Detect index: stock_name or stock_industry contains "index"
        if [[ "$name" =~ [Ii][Nn][Dd][Ee] ]] || [[ "$industry" =~ [Ii][Nn][Dd][Ee] ]]; then
            ticker="^${ticker}"
        fi
        
        echo "${ticker};${name};${exch};${isin};${industry};${sector}" >> "$OUTPUT"

    done

} < "$STOCK_INDEX"

echo "Adjusted file written to: $OUTPUT"
