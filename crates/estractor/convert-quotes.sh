#!/usr/bin/env bash

set -euo pipefail

INPUT_DIR="${1:-./csv}"
OUTPUT_DIR="${2:-./json}"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" -type f -name "*.csv" | while read -r csv_file; do

    echo "Processing: $csv_file"

    # ----------------------------------------
    # Extract issuer from parent directory
    #
    # Example:
    # ./csv/bnp/2026-03-05-08-23-19.csv
    # -> issuer=bnp
    # ----------------------------------------

    issuer=$(basename "$(dirname "$csv_file")")

    # ----------------------------------------
    # Extract datetime from filename
    #
    # Example:
    # 2026-03-05-08-23-19.csv
    # ->
    # 2026-03-05T08-23-19
    # ----------------------------------------

    base_name=$(basename "$csv_file" .csv)

    yyyy=$(echo "$base_name" | cut -d'-' -f1)
    mm=$(echo "$base_name" | cut -d'-' -f2)
    dd=$(echo "$base_name" | cut -d'-' -f3)
    hh=$(echo "$base_name" | cut -d'-' -f4)
    mi=$(echo "$base_name" | cut -d'-' -f5)
    ss=$(echo "$base_name" | cut -d'-' -f6)

    iso_dt="${yyyy}-${mm}-${dd}T${hh}-${mi}-${ss}"

    # ----------------------------------------
    # Output filename
    # ----------------------------------------

    output_file="${OUTPUT_DIR}/${issuer}-${iso_dt}-quotes.json"

    rm -f "$output_file"

    # ----------------------------------------
    # Process CSV rows
    # ----------------------------------------

    tail -n +2 "$csv_file" | while IFS=',' read -r isin name ask bid currency dt; do

        # skip invalid rows
        [ -z "$isin" ] && continue

        # synthetic bid = ask + 1.00
        if [[ -n "$ask" && "$ask" != "0.00" ]]; then
            synthetic_bid=$(awk "BEGIN { printf \"%.2f\", $ask + 1.00 }")
        else
            synthetic_bid=""
        fi

        # JSON line
        printf '{"ask":"%s","dt":"%s","issuer":"%s","isin":"%s","bid":"%s"}\n' \
            "$ask" \
            "$iso_dt" \
            "$issuer" \
            "$isin" \
            "$synthetic_bid" \
            >> "$output_file"

    done

    echo "Created: $output_file"

done

echo "Done."