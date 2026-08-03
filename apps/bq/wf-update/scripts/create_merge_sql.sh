#!/usr/bin/env bash

TABLE_NAME="$1"
INPUT_FILE="$2"

if [[ -z "$TABLE_NAME" || -z "$INPUT_FILE" ]]; then
    echo "Usage: $0 <TABLE_NAME> <input.csv>"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: input file '$INPUT_FILE' not found"
    exit 1
fi

echo "MERGE \`$TABLE_NAME\` T"
echo "USING ("
echo "  SELECT * FROM UNNEST(["

# Read all rows into an array first
mapfile -t rows < <(tail -n +2 "$INPUT_FILE")

last_index=$(( ${#rows[@]} - 1 ))

for i in "${!rows[@]}"; do
    IFS=";" read -r isin phase <<< "${rows[$i]}"
    [[ -z "$isin" ]] && continue

    if [[ "$i" -eq "$last_index" ]]; then
        # Last row → NO comma
        echo "    STRUCT('$isin' AS isin, '$phase' AS phase)"
    else
        # Other rows → comma
        echo "    STRUCT('$isin' AS isin, '$phase' AS phase),"
    fi
done

echo "  ])"
echo ") S"
echo "ON T.isin = S.isin"
echo "WHEN MATCHED THEN"
echo "  UPDATE SET T.phase = S.phase;"
