#!/bin/bash
gcloud run deploy gh-pusher-hello \
      --source src \
      --function hello_gcs \
      --base-image us-central1-docker.pkg.dev/serverless-runtimes/google-24/runtimes/python314 \
      --region europe-west1