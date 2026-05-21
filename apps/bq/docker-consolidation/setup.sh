#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Setup Consolidation Script - Version $VERSION"

set -e

echo "Extracting Quotes"
./growth-wf.sh

echo "Extract Details"
./details-wf.sh

echo "Extract Tickers"

echo "Extract Issuers"

echo "==== Execution completed ===="