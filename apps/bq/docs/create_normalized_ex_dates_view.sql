CREATE OR REPLACE VIEW invcerts.ISINs.v_normalized_ex_dates AS
SELECT
    *,
    (
        CASE
    -- already YYYY-MM-DD
    WHEN REGEXP_CONTAINS(coupon_ex_date, r'^\d{4}-\d{2}-\d{2}$') THEN
        coupon_ex_date

    -- DD-MM-YYYY
    WHEN REGEXP_CONTAINS(coupon_ex_date, r'^\d{2}-\d{2}-\d{4}$') THEN
        FORMAT_DATE(
            '%Y-%m-%d',
            SAFE.PARSE_DATE('%d-%m-%Y', coupon_ex_date)
        )

    -- DD.MM.YYYY
    WHEN REGEXP_CONTAINS(coupon_ex_date, r'^\d{2}\.\d{2}\.\d{4}$') THEN
        FORMAT_DATE(
            '%Y-%m-%d',
            SAFE.PARSE_DATE('%d.%m.%Y', coupon_ex_date)
        )

    -- Italian textual month: "1 luglio 2026"
    WHEN REGEXP_CONTAINS(LOWER(coupon_ex_date),
         r'^\d{1,2}\s+[a-zà]+\s+\d{4}$') THEN
        FORMAT_DATE(
            '%Y-%m-%d',
            PARSE_DATE(
                '%d %m %Y',
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                    REGEXP_REPLACE(
                                        REGEXP_REPLACE(
                                            REGEXP_REPLACE(
                                                REGEXP_REPLACE(
                                                    REGEXP_REPLACE(
                                                        REGEXP_REPLACE(
                                                            REGEXP_REPLACE(
                                                                LOWER(coupon_ex_date),
                                                                r'gennaio', '01'
                                                            ),
                                                            r'febbraio', '02'
                                                        ),
                                                        r'marzo', '03'
                                                    ),
                                                    r'aprile', '04'
                                                ),
                                                r'maggio', '05'
                                            ),
                                            r'giugno', '06'
                                        ),
                                        r'luglio', '07'
                                    ),
                                    r'agosto', '08'
                                ),
                                r'settembre', '09'
                            ),
                            r'ottobre', '10'
                        ),
                        r'novembre', '11'
                    ),
                    r'dicembre', '12'
                )
            )
        )

    ELSE NULL
END
    ) AS normalized_coupon_ex_date
FROM invcerts.ISINs.staging_ex_dates;