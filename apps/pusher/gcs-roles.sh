#!/bin/bash
gcloud projects add-iam-policy-binding invcerts \
    --member=serviceAccount:600125851897-compute@developer.gserviceaccount.com \
    --role=roles/run.invoker
gcloud projects add-iam-policy-binding invcerts \
    --member=serviceAccount:600125851897-compute@developer.gserviceaccount.com \
    --role=roles/eventarc.eventReceiver

SERVICE_ACCOUNT="$(gcloud storage service-agent --project=600125851897)"
gcloud projects add-iam-policy-binding 600125851897 \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role='roles/pubsub.publisher'