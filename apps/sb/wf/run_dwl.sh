#!/usr/bin/env bash

cd ./scripts
echo "Copying rws/ws/tickers_index.csv to ./config/ ..."
pwd
ls -la
npx wrangler r2 object get rws/ws/tickers_index.csv --file ./config/tickers_index.csv --remote

