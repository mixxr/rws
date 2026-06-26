EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/staging_tickers_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
select upper(d.isin) as certificate_isin, d.name as certificate_name, t.stock_name, t.stock_google_finance_ticker, t.stock_exchange, t.stock_isin, t.stock_industry, t.stock_sector 
from `ISINs.staging_tickers` t inner join `ISINs.staging_details` d on upper(t.certificate_isin)=upper(d.isin);