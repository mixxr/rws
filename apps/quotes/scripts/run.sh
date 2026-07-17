#!/usr/bin/env bash
echo "Using default paramters: ./_work and ./quotes for quotes and ./sectors for roots..."
./adjust_ticker_index.sh config/tickers_index.csv config/exchange.csv
./get_quotes.sh
# cp to GCP
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
BUCKET_URI="gs://rws-data"
# gcloud storage cp --recursive ./_quotes/* $BUCKET_URI/stocks/quotes/$datetime/

# sunburst flow
 ./create_sunburst_sectors.sh 
 ./split_sunburst.sh
