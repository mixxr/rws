#!/bin/bash
echo "Setup Local running...NOTE: IT IS NEEDED **ONLY** WHEN setup.sh runs locally!!"
TYPE="quotes"
BUCKET_URI="gs://rws-data"
BUCKET_URI_CFG="$BUCKET_URI/$TYPE/config/*"
BUCKET_URI_JOBS="$BUCKET_URI/$TYPE/jobs/2"
BUCKET_URI_INPUT="$BUCKET_URI/$TYPE/input"
WORKDIR="."
WORKDIR_CFG="$WORKDIR/$TYPE/config"
WORKDIR_JOBS="$WORKDIR/$TYPE/jobs/2/*"
WORKDIR_INPUT="$WORKDIR/$TYPE/input/*"

echo "Downloading $BUCKET_URI_CFG to $WORKDIR_CFG..."
rm -rf $WORKDIR_CFG/*
mkdir -p $WORKDIR_CFG
gcloud storage cp $BUCKET_URI_CFG $WORKDIR_CFG/

./setup.sh

echo "Uploading $WORKDIR_JOBS to $BUCKET_URI_JOBS..."
gcloud storage cp --recursive $WORKDIR_JOBS $BUCKET_URI_JOBS/ || true
echo "Uploading $WORKDIR_INPUT to $BUCKET_URI_INPUT..."
gcloud storage cp --recursive $WORKDIR_INPUT $BUCKET_URI_INPUT/ || true