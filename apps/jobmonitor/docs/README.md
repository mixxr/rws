# HLA

1. Google Cloud Storage (GCS)
Stores your .txt files.

2. Rust Web Service
Built with:

Axum or Actix‑web (modern async Rust frameworks)

google-cloud-storage crate (official Google Cloud client for Rust)

Runs in a Docker container

3. Google Cloud Run
Fully managed

Auto‑scales

Perfect for stateless HTTP services

Integrates seamlessly with GCS and IAM

## Deployment

- gcloud builds submit --tag gcr.io/invcerts/jobmonitor
- gcloud run deploy jobmonitor \
  --image gcr.io/invcerts/jobmonitor \
  --platform managed \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars BUCKET_NAME=rws-data

## Permissions

- gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer
