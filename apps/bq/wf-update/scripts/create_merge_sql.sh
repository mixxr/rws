#!/bin/bash

TABLE_NAME="$1"
INPUT_FILE="$2"
OUTPUT_FILE="$3"

if [[ -z "$TABLE_NAME" || -z "$INPUT_FILE" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <TABLE_NAME> <input.csv> <output.sql>"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: input file '$INPUT_FILE' not found"
    exit 1
fi

# Open output file once
exec > "$OUTPUT_FILE"

printf "MERGE \`%s\` T\n" "$TABLE_NAME"
printf "USING (\n"
printf "  SELECT * FROM UNNEST([\n"

# Read all rows into an array
mapfile -t rows < <(tail -n +2 "$INPUT_FILE")

last_index=$(( ${#rows[@]} - 1 ))

for i in "${!rows[@]}"; do
    IFS=";" read -r isin phase <<< "${rows[$i]}"
    [[ -z "$isin" ]] && continue

    if [[ "$i" -eq "$last_index" ]]; then
        printf "    STRUCT('%s' AS isin, '%s' AS phase)\n" "$isin" "$phase"
    else
        printf "    STRUCT('%s' AS isin, '%s' AS phase),\n" "$isin" "$phase"
    fi
done

printf "  ])\n"
printf ") S\n"
printf "ON T.isin = S.isin\n"
printf "WHEN MATCHED THEN\n"
printf "  UPDATE SET T.phase = S.phase;\n"
