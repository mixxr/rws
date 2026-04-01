#!/bin/bash
gcloud eventarc triggers create gh-pusher-hello-trigger  \
    --location=europe-west1 \
    --destination-run-service=gh-pusher-hello  \
    --destination-run-region=europe-west1 \
    --event-filters="type=google.cloud.storage.object.v1.finalized" \
    --event-filters="bucket=rws-data" \
    --service-account=600125851897-compute@developer.gserviceaccount.com