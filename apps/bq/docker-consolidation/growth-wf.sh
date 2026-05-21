#!/bin/bash
./growth_export.sh 
./growth_consolidate.sh certs_growth-tmp1.csv
./replace-not-provided.sh certs_growth-tmp1.csv certs_growth-tmp2.csv
./remove-dupl-isin.sh certs_growth-tmp2.csv certs_growth-final.csv
./gcloud-cp.sh certs_growth-final.csv gs://rws-data/ws/certs_growth.csv
rm certs_growth-tmp*.csv 
echo "Completed."