#!/usr/bin/env bash
echo "Downloading CSV files from GCP and CF to prepare stats"

echo "Downloading from CF..."
rclone copy r2:rws/ws/* ./helpers/

ls -la ./helpers/

echo "Downloading from GCP..."
cd ./helpers
source ./utils.sh

INPUT_FILE="issuers.csv"

while IFS=";" read -r issuer all; do
    [[ -z "$issuer" ]] && continue

    issuer_idx=$(normalize_name "$issuer")
    echo "$issuer_idx from $issuer"
    ./cp.sh $issuer_idx quotes dw

done < <(tail -n +2 "$INPUT_FILE")

echo "Creating stats..."
ls -la
items=( "details" "issuers" "tickers" "tickers_index")
echo "type;count" > "stats.csv"
for item in "${items[@]}"; do
    filepath="$item.csv"
    rows=$(tail -n +2 "$filepath" | wc -l)
    echo "$item;$rows" >> "stats.csv"
done

echo "issuer;count" > "quotes.csv"
for filepath in *.urls.*; do
    rows=$(tail -n +2 "$filepath" | wc -l)
    echo "$filepath;$rows" >> "quotes.csv"
done

cat quotes.csv
cat stats.csv