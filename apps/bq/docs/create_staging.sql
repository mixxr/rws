DROP TABLE `invcerts.ISINs.staging_tickers`;
CREATE TABLE `invcerts.ISINs.staging_tickers` (
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
  stock_pe STRING,
  stock_beta STRING,
  stock_volatility STRING,
  -- Compound Primary Key definition
  PRIMARY KEY (certificate_isin, stock_isin) NOT ENFORCED,
  -- optional metadata (recommended)
  ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

DROP TABLE `invcerts.ISINs.staging_details`;
CREATE TABLE `invcerts.ISINs.staging_details` (
  isin STRING NOT NULL,
  issuer STRING NOT NULL,
  name STRING NOT NULL,
  certificate_type_tags STRING,
  memory_effect STRING,
  phase STRING,
  currency STRING,
  industry STRING,
  callable STRING,
  
  strike_date String,
  issue_date String,
  rembursement_date String,
  autocallable_date String,
  
  capital_barrier STRING,      -- stored as percentage (e.g. 55.0)
  airbag STRING,
  risk_level STRING,
  
  coupon_amount STRING,
  coupon_recurrence STRING,
  coupon_type STRING,
  coupon_next_ex_date STRING,
  coupon_barrier STRING,       -- stored as percentage
  
  leverage STRING,
  exchange_risk STRING,

  PRIMARY KEY (isin) NOT ENFORCED,
  -- optional metadata (recommended)
  ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

DROP if exists `invcerts.ISINs.staging_quotes`;
CREATE TABLE `invcerts.ISINs.staging_quotes` (
  isin STRING NOT NULL,
  issuer STRING,
  
  bid STRING,
  ask STRING,
  
  dt STRING NOT NULL,
  PRIMARY KEY (isin, dt) NOT ENFORCED,
  -- optional metadata (recommended)
  ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE `invcerts.ISINs.staging_issuer` (
  issuer_name STRING NOT NULL,
  specialization STRING,
  geo_region STRING,
  issuer_rating_description STRING,
  issuer_rating_class STRING NOT NULL,

  -- optional metadata (recommended)
  ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);