#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: $0 [details|tickers|issuers|certs_growth|bad_quotes]"
  exit 1
fi
ITEM=$1
WORKDIR=./$ITEM
BUCKET_URI="gs://rws-data/bq_export/staging_${ITEM}_*.csv"
gcloud storage rm $BUCKET_URI 2>/dev/null || true

echo "$ITEM: Extracting BQ to $BUCKET_URI"
bq query \
  --use_legacy_sql=false \
  < export_$ITEM.sql

echo "$ITEM: Downloading CSVs from $BUCKET_URI"

rm -rf $WORKDIR/*
mkdir -p $WORKDIR
gcloud storage cp $BUCKET_URI $WORKDIR/
if [ $? -eq 0 ]; then
  gcloud storage rm $BUCKET_URI
fi
