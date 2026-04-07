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

### Config and image name
- gcloud auth configure-docker \
    europe-west1-docker.pkg.dev
- Repository/image: europe-west1-docker.pkg.dev/invcerts/cloud-run-source-deploy/jobmonitor

### List current images
- gcloud artifacts docker images list  europe-west1-docker.pkg.dev/invcerts/cloud-run-source-deploy/

### Build and push to Repository
- gcloud builds submit --tag europe-west1-docker.pkg.dev/invcerts/cloud-run-source-deploy/jobmonitor

if it fails to push then you can recover the artifact (gs://) and use it:
- gcloud builds submit "gs://invcerts_cloudbuild/source/1775555709.291417-1887a140ca40436aa17919be6f5651c8.tgz" \
           --tag=europe-west1-docker.pkg.dev/invcerts/cloud-run-source-deploy/jobmonitor

### Deploy the container
- gcloud run deploy jobmonitor \
  --image europe-west1-docker.pkg.dev/invcerts/cloud-run-source-deploy/jobmonitor:latest \
  --platform managed \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars BUCKET_NAME=projects/_/buckets/rws-data

### Beta: alternatively 1 command to build and deploy 
- job: gcloud beta run jobs deploy jobmonitor --source=. --execute-now --region=europe-west1
- service: gcloud beta run deploy jobmonitor --source=. --region=europe-west1

### Permissions

- gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer
