WORKDIR=./growths
gcloud storage rm gs://rws-data/bq_export/growth_*.csv 2>/dev/null || true

bq query \
  --use_legacy_sql=false \
  < export_growth.sql

echo "Quotes: Downloading CSVs..."

rm -rf $WORKDIR/*
mkdir -p $WORKDIR
gcloud storage cp gs://rws-data/bq_export/growth_*.csv $WORKDIR/
if [ $? -eq 0 ]; then
  gcloud storage rm gs://rws-data/bq_export/growth_*.csv
fi
