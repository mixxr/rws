CREATE OR REPLACE VIEW `invcerts.ISINs.v_next_ex_date` AS
SELECT
    d.isin, d.issuer, d.name,concat(d.coupon_amount,' ',d.coupon_recurrence) as coupon,
    COALESCE(MIN(e.coupon_ex_date), 'N/A') AS next_ex_date
FROM `invcerts.ISINs.staging_details` d
LEFT JOIN `invcerts.ISINs.staging_ex_dates` e
    ON d.isin = e.certificate_isin
    AND DATE(e.coupon_ex_date) >= CURRENT_DATE()
GROUP BY
    d.isin, d.issuer, d.name,d.coupon_amount, d.coupon_recurrence;