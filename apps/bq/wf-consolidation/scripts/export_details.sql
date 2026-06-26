EXPORT DATA OPTIONS (
  uri='gs://rws-data/bq_export/staging_details_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=';'
)
AS
SELECT
    upper(d.isin) as isin,
    d.issuer,
    d.name,
    d.certificate_type_tags,
    d.memory_effect,
    d.phase,
    d.currency,
    d.industry,
    d.callable,
    d.strike_date,
    d.issue_date,
    d.rembursement_date,
    d.autocallable_date,
    d.capital_barrier,
    d.airbag,
    d.risk_level,
    d.coupon_amount,
    d.coupon_recurrence,
    v.next_ex_date AS coupon_next_ex_date,
    d.coupon_type,
    d.coupon_barrier,
    d.leverage,
    d.exchange_risk
FROM `ISINs.staging_details` d
INNER JOIN `ISINs.v_next_ex_date` v
    ON upper(d.isin) = upper(v.isin);