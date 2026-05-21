EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/growth_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS SELECT *,"TBD" as coupon, "TBD" as ex_date FROM invcerts.ISINs.v_quotes_consolidated