#!/bin/bash
./replace-not-provided.sh details.csv details-tmp0.csv
./details-wf-00.sh details-tmp0.csv details-tmp1.csv
./replace-strs.sh details-tmp1.csv " - " "-" details-tmp2.csv
./replace-strs.sh details-tmp2.csv " & " " and " details-final.csv
rm details-tmp*.csv 
echo "Completed."