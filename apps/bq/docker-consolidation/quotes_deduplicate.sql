
DELETE FROM `ISINs.staging_quotes`  t
WHERE EXISTS (
  SELECT 1
  FROM (
    SELECT
      isin,
      dt,
      bid,
      ask,
      ROW_NUMBER() OVER (
        PARTITION BY isin, dt, bid, ask
        ORDER BY 1
      ) AS rn
    FROM `ISINs.staging_quotes`
  ) d
  WHERE d.rn > 1
    AND t.isin = d.isin
    AND t.dt   = d.dt
    AND t.bid  = d.bid
    AND t.ask  = d.ask
);

