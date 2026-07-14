#!/usr/bin/env bash
./adjust_ticker_index.sh config/tickers_index.csv config/exchange.csv
./get_quotes.sh
# cp to GCP
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
BUCKET_URI="gs://rws-data"
# gcloud storage cp --recursive ./quotes/* $BUCKET_URI/stocks/quotes/$datetime/