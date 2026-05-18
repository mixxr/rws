CREATE OR REPLACE VIEW `invcerts.ISINs.v_quotes_consolidated` AS

WITH quotes_clean AS (
  SELECT
    isin,
    issuer,

    SAFE_CAST(REPLACE(bid, ',', '.') AS FLOAT64) AS bid,
    SAFE_CAST(REPLACE(ask, ',', '.') AS FLOAT64) AS ask,

    PARSE_DATETIME('%Y-%m-%dT%H-%M-%S', dt) AS dt

  FROM `invcerts.ISINs.quotes`
),

daily_quotes AS (
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

latest_quotes AS (
  SELECT *
  FROM (
    SELECT
      isin,
      issuer,
      bid,
      ask,
      dt,

      ROW_NUMBER() OVER (
        PARTITION BY isin
        ORDER BY dt DESC
      ) AS rn

    FROM daily_quotes
  )
  WHERE rn = 1
),

historical AS (
  SELECT
    l.isin,
    l.issuer,

    l.ask,
    l.bid,

    -- absolute growth
    l.bid - d1.bid AS Growth_1D,
    l.bid - d3.bid AS Growth_3Ds,
    l.bid - w1.bid AS Growth_1W,
    l.bid - w2.bid AS Growth_2W,
    l.bid - w4.bid AS Growth_4W,

    -- percentage growth
    SAFE_DIVIDE(l.bid - d1.bid, d1.bid) * 100 AS Growth_1D_Pct,
    SAFE_DIVIDE(l.bid - d3.bid, d3.bid) * 100 AS Growth_3Ds_Pct,
    SAFE_DIVIDE(l.bid - w1.bid, w1.bid) * 100 AS Growth_1W_Pct,
    SAFE_DIVIDE(l.bid - w2.bid, w2.bid) * 100 AS Growth_2W_Pct,
    SAFE_DIVIDE(l.bid - w4.bid, w4.bid) * 100 AS Growth_4W_Pct

  FROM latest_quotes l

  LEFT JOIN daily_quotes d1
    ON l.isin = d1.isin
   AND d1.d = DATE_SUB(DATE(l.dt), INTERVAL 1 DAY)

  LEFT JOIN daily_quotes d3
    ON l.isin = d3.isin
   AND d3.d = DATE_SUB(DATE(l.dt), INTERVAL 3 DAY)

  LEFT JOIN daily_quotes w1
    ON l.isin = w1.isin
   AND w1.d = DATE_SUB(DATE(l.dt), INTERVAL 7 DAY)

  LEFT JOIN daily_quotes w2
    ON l.isin = w2.isin
   AND w2.d = DATE_SUB(DATE(l.dt), INTERVAL 14 DAY)

  LEFT JOIN daily_quotes w4
    ON l.isin = w4.isin
   AND w4.d = DATE_SUB(DATE(l.dt), INTERVAL 28 DAY)
)

SELECT
  isin AS ISIN,
  issuer AS Issuer,

  ROUND(ask, 2) AS Ask,
  ROUND(bid, 2) AS Bid,

  ROUND(Growth_1D, 2)  AS Growth_1D,
  ROUND(Growth_3Ds, 2) AS Growth_3Ds,
  ROUND(Growth_1W, 2)  AS Growth_1W,
  ROUND(Growth_2W, 2)  AS Growth_2W,
  ROUND(Growth_4W, 2)  AS Growth_4W,

  ROUND(Growth_1D_Pct, 2)  AS Growth_1D_Pct,
  ROUND(Growth_3Ds_Pct, 2) AS Growth_3Ds_Pct,
  ROUND(Growth_1W_Pct, 2)  AS Growth_1W_Pct,
  ROUND(Growth_2W_Pct, 2)  AS Growth_2W_Pct,
  ROUND(Growth_4W_Pct, 2)  AS Growth_4W_Pct

FROM historical;