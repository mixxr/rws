-- ISIN;Issuer;Name;Coupon;Ex-Date;Ask;Bid;Growth_1D;Growth_3Ds;Growth_1W;Growth_2W;Growth_4W;Growth_1D_Pct;Growth_3Ds_Pct;Growth_1W_Pct;Growth_2W_Pct;Growth_4W_Pct
EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/growth_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
select d.isin as isin, d.issuer as issuer, d.name as name, "TBD" as coupon, "TBD" as ex_date, qc.ask as ask, qc.bid as bid, qc.Growth_1D as Growth_1D, qc.Growth_3Ds as Growth_3Ds, qc.Growth_1W as Growth_1W, qc.Growth_2W as Growth_2W, qc.Growth_4W as Growth_4W, qc.Growth_1D_Pct as Growth_1D_Pct, qc.Growth_3Ds_Pct as Growth_3Ds_Pct, qc.Growth_1W_Pct as Growth_1W_Pct, qc.Growth_2W_Pct as Growth_2W_Pct, qc.Growth_4W_Pct as Growth_4W_Pct
from `ISINs.v_quotes_consolidated` qc inner join `ISINs.staging_details` d on qc.isin=d.isin;

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