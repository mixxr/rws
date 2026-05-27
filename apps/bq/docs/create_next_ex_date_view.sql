CREATE OR REPLACE VIEW `invcerts.ISINs.v_next_ex_date` AS
SELECT
    upper(d.isin) as isin, d.issuer, d.name,concat(d.coupon_amount,' ',d.coupon_recurrence) as coupon,
    COALESCE(MIN(ne.normalized_coupon_ex_date), 'N/A') AS next_ex_date
FROM `invcerts.ISINs.staging_details` d
LEFT JOIN `invcerts.ISINs.v_normalized_ex_dates` ne
    ON lower(d.isin) = lower(ne.certificate_isin)
    AND DATE(ne.normalized_coupon_ex_date) >= CURRENT_DATE()
GROUP BY
    d.isin, d.issuer, d.name,d.coupon_amount, d.coupon_recurrence;