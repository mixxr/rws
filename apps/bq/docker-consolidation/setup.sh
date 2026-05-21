#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Setup Consolidation Script - Version $VERSION"

set -e

echo "Extracting Certs Growth"
./item-wf.sh certs_growth

echo "Extracting Details"
./item-wf.sh details

echo "Extracting Tickers"
./item-wf.sh tickers

echo "Extracting Issuers"

echo "==== Execution completed ===="