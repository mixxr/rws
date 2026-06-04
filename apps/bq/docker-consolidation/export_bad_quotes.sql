
EXPORT DATA OPTIONS (
    uri="gs://rws-data/bq_export/staging_bad_quotes_*.csv",
    format="CSV",
    overwrite=true,
    header=true,
    field_delimiter=";"
  )
  AS
SELECT isin,ask,bid,dt from `ISINs.staging_quotes` where ask='' or bid=''