-- certificate_isin;certificate_name;stock_name;stock_google_finance_ticker;stock_isin;stock_industry;stock_sector
EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/staging_tickers_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
select d.isin as certificate_isin, d.name as certificate_name, t.stock_name, t.stock_google_finance_ticker,t.stock_isin, t.stock_industry, t.stock_sector 
from `ISINs.staging_tickers` t inner join `ISINs.staging_details` d on t.certificate_isin=d.isin;

-- issuer_name,specialization,geo_region,issuer_rating_description,issuer_rating_class
EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/staging_issuers_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
SELECT issuer_name,specialization,geo_region,issuer_rating_description,issuer_rating_class
FROM `ISINs.staging_issuer`

-- isin;issuer;name;certificate_type_tags;memory_effect;phase;currency;industry;callable;strike_date;issue_date;rembursement_date;autocallable_date;capital_barrier;airbag;risk_level;coupon_amount;coupon_recurrence;coupon_next_ex_date;coupon_type;coupon_barrier;leverage;exchange_risk
EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/staging_details_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
SELECT isin,issuer,name,certificate_type_tags,memory_effect,phase,currency,industry,callable,strike_date,issue_date,rembursement_date,autocallable_date,capital_barrier,airbag,risk_level,coupon_amount,coupon_recurrence,coupon_next_ex_date,coupon_type,coupon_barrier,leverage,exchange_risk
from `ISINs.staging_details`