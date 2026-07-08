#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: $0 [details|tickers|issuers|certs_growth]"
  exit 1
fi
ITEM=$1
./item_export.sh $ITEM
if [ $? -ne 0 ]; then
    echo "[ERROR] stopped"
fi
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
    tickers-tmp21.csv \
    stock_exchange \
    correct_name \
    alt_name
./normalize-cols.sh \
    tickers-tmp21.csv \
    alt_names.csv \
    tickers-tmp2.csv \
    stock_google_finance_ticker \
    correct_name \
    alt_name
echo "==> Creating ticker alternative symbols..."
./extract_alt_symbols.sh tickers-tmp1.csv tickers-tmp_alt_symbols_generated.csv stock_google_finance_ticker
./normalize-cols.sh \
    tickers-tmp2.csv \
    tickers-tmp_alt_symbols_generated.csv \
    tickers-tmp1.csv \
    stock_google_finance_ticker \
    stock_symbol \
    stock_alt_symbol
fi
if [[ "$ITEM" == "issuers" ]]; then
cp $ITEM-tmp0.csv $ITEM-tmp1.csv
fi
./replace-strs.sh $ITEM-tmp1.csv " - " "-" $ITEM-tmp2.csv
./replace-strs.sh $ITEM-tmp2.csv " & " " and " $ITEM-final.csv
if [[ "$ITEM" == "tickers" ]]; then
echo "==> Creating ticker index..."
./create-tickers-index.sh tickers-final.csv
#./gcloud-cp.sh tickers_index.csv gs://rws-data/ws/tickers_index.csv
npx wrangler r2 object put rws/ws/tickers_index.csv --file ./tickers_index.csv --remote
fi
if [ $(stat -c%s "$ITEM-final.csv") -gt "100" ]; then
    #./gcloud-cp.sh $ITEM-final.csv gs://rws-data/ws/$ITEM.csv
    npx wrangler r2 object put rws/ws/$ITEM.csv --file ./$ITEM-final.csv --remote
else
    echo "[WARN] $ITEM-final.csv is empty!"
fi
rm $ITEM-tmp*.csv $ITEM-consolidated.csv
echo "$ITEM: Completed."
