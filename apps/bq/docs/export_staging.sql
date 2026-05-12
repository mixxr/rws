EXPORT DATA OPTIONS (
  uri='gs://your-bucket/staging_tickers/*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
SELECT *
FROM `invcerts.ISINs.staging_tickers`;