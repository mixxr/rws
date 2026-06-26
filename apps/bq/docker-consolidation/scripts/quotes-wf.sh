#!/bin/bash

echo "Exports bad quotes (empty bid OR ask). Remove quotes with empty bid AND ask. Deduplicates rows if same DT."

datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
mv bad_quotes-consolidated.csv bad_quotes-consolidated.$datetime.csv
./item_export.sh bad_quotes
./item_consolidate.sh bad_quotes
if [ $? -eq 0 ]; then
  echo "Removing quotes with empty bid AND ask..."
  bq query \
    --use_legacy_sql=false \
    < quotes_remove_null.sql

  echo "Deduplicating rows if same DT...."
  bq query \
    --use_legacy_sql=false \
    < quotes_deduplicate.sql
else
  echo "[WARN] Error when exporting."
fi