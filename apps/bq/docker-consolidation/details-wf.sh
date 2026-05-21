#!/bin/bash
./details_export.sh
./details_consolidate.sh details-tmp1.csv
./replace-not-provided.sh details-tmp1.csv details-tmp0.csv
./remove-dupl-isin.sh details-tmp0.csv details-tmp1.csv
./replace-strs.sh details-tmp1.csv " - " "-" details-tmp2.csv
./replace-strs.sh details-tmp2.csv " & " " and " details-final.csv
./gcloud-cp details-final.csv gs://rws-data/ws/details.csv
rm details-tmp*.csv 
echo "Completed."