CREATE OR REPLACE VIEW `invcerts.ISINs.v_quotes_consolidated` AS

WITH quotes_clean AS (
  SELECT
    UPPER(isin) as isin,
    issuer,

    SAFE_CAST(REPLACE(bid, ',', '.') AS FLOAT64) AS bid,
    SAFE_CAST(REPLACE(ask, ',', '.') AS FLOAT64) AS ask,

    PARSE_DATETIME('%Y-%m-%dT%H-%M-%S', dt) AS dt

  FROM `invcerts.ISINs.staging_quotes`

  WHERE SAFE_CAST(REPLACE(bid, ',', '.') AS FLOAT64) IS NOT NULL
    -- AND SAFE_CAST(REPLACE(ask, ',', '.') AS FLOAT64) IS NOT NULL
    AND dt IS NOT NULL
),

daily_quotes AS (
  -- keep latest quote per trading day
  SELECT *
  FROM (
    SELECT
      isin,
      issuer,
      bid,
      ask,
      dt,
      DATE(dt) AS d,

      ROW_NUMBER() OVER (
        PARTITION BY isin, DATE(dt)
        ORDER BY dt DESC
      ) AS rn

    FROM quotes_clean
  )
  WHERE rn = 1
),

quotes_with_history AS (
  SELECT
    isin,
    issuer,
    ask,
    bid,
    dt,
    d,

    -- previous trading days
    LAG(bid, 1)  OVER (PARTITION BY isin ORDER BY d) AS bid_1d,
    LAG(bid, 3)  OVER (PARTITION BY isin ORDER BY d) AS bid_3d,
    LAG(bid, 5)  OVER (PARTITION BY isin ORDER BY d) AS bid_1w,
    LAG(bid, 10) OVER (PARTITION BY isin ORDER BY d) AS bid_2w,
    LAG(bid, 20) OVER (PARTITION BY isin ORDER BY d) AS bid_4w,

    ROW_NUMBER() OVER (
      PARTITION BY isin
      ORDER BY dt DESC
    ) AS latest_rn

  FROM daily_quotes
)

SELECT
  upper(isin) AS ISIN,
  issuer AS Issuer,

  ROUND(ask, 2) AS Ask,
  ROUND(bid, 2) AS Bid,

  -- absolute growth
  ROUND(bid - bid_1d, 2)  AS Growth_1D,
  ROUND(bid - bid_3d, 2)  AS Growth_3Ds,
  ROUND(bid - bid_1w, 2)  AS Growth_1W,
  ROUND(bid - bid_2w, 2)  AS Growth_2W,
  ROUND(bid - bid_4w, 2)  AS Growth_4W,

  -- percentage growth
  ROUND(SAFE_DIVIDE(bid - bid_1d, bid_1d) * 100, 2)  AS Growth_1D_Pct,
  ROUND(SAFE_DIVIDE(bid - bid_3d, bid_3d) * 100, 2)  AS Growth_3Ds_Pct,
  ROUND(SAFE_DIVIDE(bid - bid_1w, bid_1w) * 100, 2)  AS Growth_1W_Pct,
  ROUND(SAFE_DIVIDE(bid - bid_2w, bid_2w) * 100, 2)  AS Growth_2W_Pct,
  ROUND(SAFE_DIVIDE(bid - bid_4w, bid_4w) * 100, 2)  AS Growth_4W_Pct,

  dt AS Last_Update_DT,
  CASE
    WHEN bid < 20 THEN 10
    WHEN bid < 200 THEN 100
    WHEN bid < 2000 THEN 1000
    WHEN bid < 20000 THEN 10000
    ELSE 0
  END AS Par_Value

FROM quotes_with_history
WHERE latest_rn = 1;