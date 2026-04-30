-- CHECK
SELECT * FROM `invcerts.ISINs.staging_details`
WHERE isin LIKE 'IT%'
  AND LOWER(issuer) NOT LIKE '%marex%'
-- DELETE
DELETE FROM `invcerts.ISINs.staging_details`
WHERE isin LIKE 'IT%'
  AND LOWER(issuer) NOT LIKE '%marex%'

-- ISIN N/A sanitization
SELECT * FROM `invcerts.ISINs.staging_details`
WHERE upper(isin) LIKE 'N/A%'
-- DELETE
DELETE FROM `invcerts.ISINs.staging_details`
WHERE upper(isin) LIKE 'N/A%'

-- N/A sanitization when #cols >= 10
DELETE
FROM `invcerts.ISINs.staging_details` t
WHERE ARRAY_LENGTH(
  REGEXP_EXTRACT_ALL(LOWER(TO_JSON_STRING(t)), r'"n/a"')
) >= 10;