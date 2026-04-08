gcloud beta run deploy jobmonitor --source=. --region=europe-west1 \
--allow-unauthenticated \
--add-volume name=gcs-1,bucket=rws-data,type=cloud-storage \
--add-volume-mount volume=gcs-1,mount-path=/data
