EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/staging_issuers_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
select * 
from `ISINs.staging_issuer` iss;