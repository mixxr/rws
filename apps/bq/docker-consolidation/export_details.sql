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