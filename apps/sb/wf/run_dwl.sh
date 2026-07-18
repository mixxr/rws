#!/usr/bin/env bash

cd ./scripts
echo "Copying rws/ws/tickers_index.csv to ./config/ ..."
npx wrangler r2 object get rws/ws/sectors/$datetime/ --file ./config/ --remote

