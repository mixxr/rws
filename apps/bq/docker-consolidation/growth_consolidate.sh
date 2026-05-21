#!/usr/bin/env bash

OUTPUT_FILE=${1:-certs_growth-temp1.csv}

# remove old output if exists
rm -f "$OUTPUT_FILE"

FIRST_FILE=true

for file in growths/*.csv; do

    echo "Processing $file"

    if $FIRST_FILE; then
        # keep header from first file
        cat "$file" > "$OUTPUT_FILE"
        FIRST_FILE=false
    else
        # skip header from remaining files
        tail -n +2 "$file" >> "$OUTPUT_FILE"
    fi

done

echo "Merged CSV created: $OUTPUT_FILE"