WORKDIR=./details
BUCKET_URI="gs://rws-data/bq_export/staging_details_*.csv"
gcloud storage rm $BUCKET_URI 2>/dev/null || true

bq query \
  --use_legacy_sql=false \
  < export_details.sql

echo "Quotes: Downloading CSVs from $BUCKET_URI"

rm -rf $WORKDIR/*
mkdir -p $WORKDIR
gcloud storage cp $BUCKET_URI $WORKDIR/
if [ $? -eq 0 ]; then
  gcloud storage rm $BUCKET_URI
fi
