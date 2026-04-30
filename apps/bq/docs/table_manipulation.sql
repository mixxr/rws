CREATE OR REPLACE TABLE `invcerts.ISINs.staging_details_new` (
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
  coupon_barrier STRING,       -- stored as percentage
  
  leverage STRING,
  exchange_risk STRING,

  PRIMARY KEY (isin) NOT ENFORCED,
  -- optional metadata (recommended)
  ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) 
AS
SELECT *, CURRENT_TIMESTAMP() AS ingestion_ts
FROM `invcerts.ISINs.staging_details`;

DROP TABLE `invcerts.ISINs.staging_details`;

