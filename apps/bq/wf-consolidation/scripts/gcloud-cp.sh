#!/usr/bin/env bash
echo "GCP: copying..."
gcloud storage cp $1 $2
