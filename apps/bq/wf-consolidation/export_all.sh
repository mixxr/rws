#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Setup Consolidation Script - Version $VERSION"

# --- gcloud authentication check ---
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
  echo "ERROR: gcloud is not authenticated. Run 'gcloud auth login' or activate a service account."
  exit 1
fi
# -----------------------------------

set -e
cd scripts
echo "Extracting Certs Growth"
./item-wf.sh certs_growth

echo "Extracting Details"
./item-wf.sh details

echo "Extracting Tickers"
./item-wf.sh tickers

#echo "Extracting Issuers"

echo "==== Execution completed ===="