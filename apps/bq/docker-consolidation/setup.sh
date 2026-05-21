#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Setup Quotes Consolidation Script - Version $VERSION"

set -e

WORKDIR=./growths

echo "Exporting BigQuery data..."
gcloud storage rm gs://rws-data/bq_export/growth_*.csv 2>/dev/null || true

bq query \
  --use_legacy_sql=false \
  < export_growth.sql

echo "Downloading CSVs..."

rm -rf $WORKDIR/*
mkdir -p $WORKDIR
gcloud storage cp gs://rws-data/bq_export/growth_*.csv $WORKDIR/
if [ $? -eq 0 ]; then
  gcloud storage rm gs://rws-data/bq_export/growth_*.csv
fi

echo "Running consolidation..."
# TODO: pass $WORKDIR to the script
./growth-wf.sh

echo "Uploading final file..."

gcloud storage cp certs_growth-final.csv \
  gs://rws-data/ws/certs_growth.csv

echo "Done."

echo "==== Execution completed ===="