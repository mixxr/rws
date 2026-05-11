DROP TABLE `invcerts.ISINs.tickers`;
CREATE TABLE `invcerts.ISINs.tickers` (
  certificate_isin STRING NOT NULL,
  certificate_name STRING,
  stock_isin STRING NOT NULL,
  stock_name STRING,
  stock_google_finance_ticker STRING,
  stock_exchange STRING,
  stock_sector STRING,
  stock_industry STRING,
  stock_tags STRING,
  stock_specializations STRING,
  stock_capitalization STRING,
  stock_pe FLOAT64,
  stock_beta FLOAT64,
  stock_volatility FLOAT64,
  -- Compound Primary Key definition
  PRIMARY KEY (certificate_isin, stock_isin) NOT ENFORCED
);

DROP TABLE `invcerts.ISINs.details`;
CREATE TABLE `invcerts.ISINs.details` (
  isin STRING,
  issuer STRING,
  name STRING,
  certificate_type_tags STRING,
  memory_effect BOOL,
  phase STRING,
  currency STRING,
  industry STRING,
  callable BOOL,
  
  strike_date String,
  issue_date String,
  rembursement_date String,
  autocallable_date String,
  
  capital_barrier FLOAT64,      -- stored as percentage (e.g. 55.0)
  airbag BOOL,
  risk_level INT64,
  
  coupon_amount STRING,
  coupon_recurrence STRING,
  coupon_type STRING,
  coupon_next_ex_date STRING,
  coupon_barrier FLOAT64,       -- stored as percentage
  
  leverage BOOL,
  exchange_risk BOOL,

  PRIMARY KEY (isin) NOT ENFORCED
);

DROP if exists `invcerts.ISINs.quotes`;
CREATE TABLE `invcerts.ISINs.quotes`
  isin STRING NOT NULL,
  issuer STRING,
  
  bid FLOAT64,
  ask FLOAT64,
  
  dt TIMESTAMP NOT NULL, -- 2026-04-22T15-00-40 → 2026-04-22T15:00:40
  PRIMARY KEY (isin, dt) NOT ENFORCED,
  PARTITION BY DATE(dt)
  AS SELECT * FROM UNNEST([]);
);