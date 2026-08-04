#!/bin/bash
source ./helpers/utils.sh
echo "Setup Local running...NOTE: IT IS NEEDED **ONLY** WHEN it runs locally!!"
# TYPE="quotes"
# BUCKET_URI="gs://rws-data"
# BUCKET_URI_CFG="$BUCKET_URI/$TYPE/config"
# WORKDIR="./helpers"
# WORKDIR_CFG="$WORKDIR/$TYPE/config"

# echo "Downloading $BUCKET_URI_CFG/*.urls.* to $WORKDIR_CFG..."
# rm -rf $WORKDIR_CFG/*
# mkdir -p $WORKDIR_CFG
# gcloud storage cp $BUCKET_URI_CFG/*.urls.* $WORKDIR_CFG/

cd ./helpers

echo "Processing input file $1 to remove ISINs..."
INPUT_FILE="$1"

if [[ -z "$INPUT_FILE" ]]; then
    echo "Usage: $0 <input.csv>"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: input file '$INPUT_FILE' not found"
    exit 1
fi

# Phases to match
PHASE_FILTER=("rimborsato" "scaduto")

# Convert array to regex: rimborsato|scaduto
PHASE_REGEX="$(printf "%s|" "${PHASE_FILTER[@]}" | sed 's/|$//')"

declare -A issuer_map

# Skip header and read rows
while IFS=";" read -r isin issuer phase; do
    [[ -z "$isin" ]] && continue

    # Check if phase matches any in PHASE_FILTER
    if [[ "$phase" =~ ^($PHASE_REGEX)$ ]]; then
        issuer_idx=$(normalize_name "$issuer")
        # Append ISIN to issuer group
        if [[ -z "${issuer_map[$issuer_idx]}" ]]; then
            issuer_map[$issuer_idx]="$isin"
        else
            issuer_map[$issuer_idx]="${issuer_map[$issuer_idx]}|$isin"
        fi
    fi
done < <(tail -n +2 "$INPUT_FILE")

# Execute commands per issuer
for issuer in "${!issuer_map[@]}"; do
    echo "$issuer"
    ISIN_LIST="${issuer_map[$issuer]}"
    echo "Calling ISSUER=$issuer TYPE_LIST=quotes ISIN_LIST=$ISIN_LIST ./rm_isin.sh..."
    ISSUER="$issuer" TYPE_LIST="quotes" ISIN_LIST="$ISIN_LIST" ./rm_isin.sh
done


# echo "Uploading $WORKDIR_CFG/*.urls.* to $BUCKET_URI_CFG..."
# gcloud storage cp $WORKDIR_CFG/*.bak.* $BUCKET_URI_CFG/ || true
# # gcloud storage cp $WORKDIR_CFG/*.urls.* $BUCKET_URI_CFG/ || true