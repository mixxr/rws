gcloud beta run jobs deploy jobmonitor --source=. --execute-now --region=europe-west1 \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data \
--set-env-vars BUCKET_NAME=rws-data


