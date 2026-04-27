DROP TABLE `invcerts.ISINs.isin_ticker`;
CREATE TABLE `invcerts.ISINs.isin_ticker` (
  certificate_isin STRING NOT NULL,
  certificate_name STRING NOT NULL,
  stock_isin STRING NOT NULL,
  stock_name STRING,
  stock_google_finance_ticker STRING,
  stock_exchange STRING,
  stock_sector STRING,
  stock_industry STRING,
  stock_tags STRING,
  -- Compound Primary Key definition
  PRIMARY KEY (certificate_isin, stock_isin) NOT ENFORCED
);