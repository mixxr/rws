#!/usr/bin/env bash

STOCK_INDEX="$1"
EXCHANGE_FILE="$2"
INDEX_FILE="$3"
OUTPUT="${4:-stock_index_adjusted.csv}"
OUTPUT_FOLDER="${5:-./_work}"
DELIM=";"

if [[ -z "$STOCK_INDEX" || -z "$EXCHANGE_FILE" ]]; then
    echo "Usage: $0 STOCK_INDEX EXCHANGE_FILE INDEX_FILE [OUTPUT_FILE] [OUTPUT_FOLDER]"
    exit 1
fi

mkdir -p $OUTPUT_FOLDER
output_file="$OUTPUT_FOLDER/$OUTPUT"

# Load exchange → suffix mapping
declare -A EXMAP
while IFS=';' read -r exch suffix || [[ -n "$exch" ]]; do
    [[ -z "$exch" ]] && continue
    EXMAP["$exch"]="$suffix"
done < "$EXCHANGE_FILE"

# Load symbols for indexed -> goal: replace symbols
declare -A INDEXMAP
while IFS=';' read -r name symbol || [[ -n "$name" ]]; do
    [[ -z "$name" ]] && continue
    name="${name^^}"
    INDEXMAP["$name"]="$symbol"
done < "$INDEX_FILE"

# Process STOCK_INDEX
{
    # Read and write header
    read -r header
    header="${header//;/$DELIM}"
    echo "$header" > "$output_file"

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

        # Detect index: stock_name or stock_industry contains "index" or similar
        name="${name//®/}"      # remove ® anywhere in name
        name="${name//-/ }"     # replace - with space
        name="${name^^}"
        industry="${industry^^}"
        ticker="${ticker^^}"
        if [[ "$name" == *INDE* ]] || [[ "$industry" == IND* ]]; then
            # Replace Indexes (Eg. SP 500, KOSPI 200, ...)
            for key in "${!INDEXMAP[@]}"; do
                if [[ "$ticker" == "$key"* ]] || [[ "$name" == "$key"* ]]; then
                    ticker="${INDEXMAP[$key]}"
                    break
                fi
            done
        fi


        echo "${ticker}${DELIM}${name}${DELIM}${exch}${DELIM}${isin}${DELIM}${industry}${DELIM}${sector}" >> "$output_file"

    done

} < "$STOCK_INDEX"

echo "Adjusted file written to: $output_file"
