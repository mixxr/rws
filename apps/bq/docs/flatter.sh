#!/bin/bash

# de-prettify json
# gcloud storage cat gs://rws-data/details/output/NLBNPIT21TB7-details.json | jq -c . | gcloud storage cp - gs://rws-data/details/output/NLBNPIT21TB7-details.json

BUCKET_PATH="gs://rws-data/details/output/*-details.json"

for file in $(gcloud storage ls $BUCKET_PATH); do
  echo "Processing $file ..."

  gcloud storage cat "$file" \
    | jq -c . \
    | gcloud storage cp - "$file"

done

echo "Done."