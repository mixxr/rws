#!/usr/bin/env bash
echo "Using default paramters: ./_work and ./quotes for quotes and ./sectors for roots..."

cd ./scripts
./adjust_ticker_index.sh config/tickers_index.csv config/exchange.csv
./get_quotes.sh

# sunburst flow
 ./create_sunburst_sectors.sh 
 ./calculate_totals.sh
 ./split_sunburst.sh
