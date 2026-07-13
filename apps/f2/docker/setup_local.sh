#!/bin/bash
echo "Setup Local running...NOTE: IT IS NEEDED **ONLY** WHEN setup.sh runs locally!!"
TYPE="quotes"
BUCKET_URI="gs://rws-data"
BUCKET_URI_OUTPUT="$BUCKET_URI/$TYPE/ouput"
BUCKET_URI_JOBS="$BUCKET_URI/$TYPE/jobs/2"
WORKDIR="."
WORKDIR_OUTPUT="$WORKDIR/$TYPE/output/*"
WORKDIR_JOBS="$WORKDIR/$TYPE/jobs/2/*"

./setup.sh

echo "Uploading $WORKDIR_JOBS to $BUCKET_URI_JOBS..."
gcloud storage cp --recursive $WORKDIR_JOBS $BUCKET_URI_JOBS/ || true
echo "Uploading $WORKDIR_OUTPUT to $BUCKET_URI_OUTPUT..."
gcloud storage cp --recursive $WORKDIR_OUTPUT $BUCKET_URI_OUTPUT/ || true