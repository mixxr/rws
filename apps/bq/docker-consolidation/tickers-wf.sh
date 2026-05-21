#!/bin/bash
./replace-not-provided.sh tickers.csv tickers-tmp1.csv
./tickers-wf-00.sh tickers-tmp1.csv tickers-tmp2.csv
./tickers-wf-10.sh tickers-tmp2.csv tickers-tmp1.csv
./replace-strs.sh tickers-tmp1.csv " - " "-" tickers-tmp2.csv
./replace-strs.sh tickers-tmp2.csv " & " " and " tickers-final.csv
rm tickers-tmp*.csv 
echo "Completed."