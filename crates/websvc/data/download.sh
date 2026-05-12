#!/bin/bash
gsutil -m cp \
  "gs://rws-data/bq_export/staging_details_000000000000.csv" \
  "gs://rws-data/bq_export/staging_details_000000000001.csv" \
  "gs://rws-data/bq_export/staging_issuers_000000000000.csv" \
  "gs://rws-data/bq_export/staging_issuers_000000000001.csv" \
  "gs://rws-data/bq_export/staging_tickers_000000000000.csv" \
  "gs://rws-data/bq_export/staging_tickers_000000000001.csv" \
  .