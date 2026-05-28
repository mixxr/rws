#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: $0 [details|tickers|issuers|certs_growth]"
  exit 1
fi
ITEM=$1
./item_export.sh $ITEM
./item_consolidate.sh $ITEM
./replace-not-provided.sh $ITEM-consolidated.csv $ITEM-tmp0.csv
if [[ "$ITEM" == "details" || "$ITEM" == "certs_growth" ]]; then
./remove-dupl-isin.sh $ITEM-tmp0.csv $ITEM-tmp1.csv
fi
if [[ "$ITEM" == "tickers" ]]; then
./tickers-wf-00.sh tickers-tmp0.csv tickers-tmp2.csv
./tickers-wf-10.sh tickers-tmp2.csv tickers-tmp1.csv
./normalize-cols.sh \
    tickers-tmp1.csv \
    alt_names.csv \
    tickers-tmp2.csv \
    stock_exchange \
    correct_name \
    alt_name
./extract_alt_symbols.sh tickers-tmp1.csv tickers-tmp_tickers_alt_symbols.csv stock_google_finance_ticker
./normalize-cols.sh \
    tickers-tmp2.csv \
    tickers-tmp_tickers_alt_symbols.csv \
    tickers-tmp1.csv \
    stock_google_finance_ticker \
    stock_symbol \
    stock_alt_symbol
fi
./replace-strs.sh $ITEM-tmp1.csv " - " "-" $ITEM-tmp2.csv
./replace-strs.sh $ITEM-tmp2.csv " & " " and " $ITEM-final.csv
./gcloud-cp.sh $ITEM-final.csv gs://rws-data/ws/$ITEM.csv
rm $ITEM-tmp*.csv $ITEM-consolidated.csv
echo "$ITEM: Completed."