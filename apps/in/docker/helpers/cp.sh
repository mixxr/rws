#!/bin/bash
# Copy from GCP
# set -euo pipefail
set -u 

# usage: ./cp.sh bnp [quotes|details|issuer] [up|dw]

# ------------------------
# INPUT
# ------------------------
ISSUER="${1}"
TYPE="${2:-quotes}"
VERSUS="${3:-dw}"

# check BUCKET env var is set, if not use default value gs://rws-data
BUCKET="${BUCKET:-gs://rws-data}"

# ------------------------
# FORMAT MAP (future-proof)
# ------------------------
declare -A FORMAT_MAP=(
  [leonteq]="json"
  [bnp]="md"
  [marex]="md"
  [vontobel]="md"
  [mediobanca]="md"
)

FORMAT="${FORMAT_MAP[$ISSUER]:-md}"

echo "==== Processing ISSUER=$ISSUER TYPE=$TYPE FORMAT=$FORMAT"

case "$TYPE" in

  # --------------------
  # DETAILS / issuer
  # --------------------
  details|issuer)
    DEST="${BUCKET}/${TYPE}/jobs/1/${isin}.csv"
    LDEST="${isin}.csv"
    ;;

  # --------------------
  # QUOTES
  # --------------------
  quotes)  
    DEST="${BUCKET}/quotes/config/${ISSUER}.urls.${FORMAT}"
    LDEST="${ISSUER}.urls.${FORMAT}"
    ;;

  # --------------------
  # ERROR
  # --------------------
  *)
    echo "Unknown TYPE: $TYPE"
    exit 1
    ;;
esac

echo "copying $DEST..."
if [[ "$VERSUS" != "up" ]]; then
  gcloud storage cp "$DEST" .
else
  dt=$(date +%F)
  gcloud storage cp "$DEST" "$LDEST.$dt.bak"
  gcloud storage cp "$LDEST" "$DEST" 
fi