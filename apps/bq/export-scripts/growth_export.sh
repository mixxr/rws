#!/bin/bash
rm -rf ./growths/*
mkdir ./growths
gsutil -m cp \
  "gs://rws-data/bq_export/growth_*.csv" \
  ./growths
if [ $? -eq 0 ]; then
  gsutil -m rm gs://rws-data/bq_export/growth_*.csv
fi