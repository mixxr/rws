#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: $0 [details|tickers|issuers]"
  exit 1
fi
ITEM=$1

OUTPUT_FILE=$ITEM-consolidated.csv

# remove old output if exists
rm -f "$OUTPUT_FILE"

FIRST_FILE=true

for file in $ITEM/*.csv; do

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
echo "Removing downloaded data ./$ITEM/*.csv..."
rm -rf ./$ITEM