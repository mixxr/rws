
pub static NODATA_FOUND: &str = "No data found";
pub static HARD_ROW_LIMIT: usize = 1000;
pub static STAGING_PREFIX: &str = "staging_";
pub static COL_SEPARATOR: &str = "; "; // for joining multiple column values into a single string in the response

// static vector of column names for details query, to avoid repetition and potential typos
// vec!["isin", "issue", "name", "certificate_type_tags","memory_effect", "phase", "currency", "industry", "callable", "strike_date", "issue_date", "rembursement_date", "autocallable_date", "capital_barrier", "airbag", "risk_level", "coupon_amount", "coupon_recurrence", "coupon_type", "coupon_barrier", "leverage", "exchange_risk"],
pub static DETAIL_COLUMNS: &'static [&str] = &[
    "isin",
    "issuer",
    "name",
    "certificate_type_tags",
    "memory_effect",
    "phase",
    "currency",
    "industry",
    "callable",
    "strike_date",
    "issue_date",
    "rembursement_date",
    "autocallable_date",
    "capital_barrier",
    "airbag",
    "risk_level",
    "coupon_amount",
    "coupon_recurrence",
    "coupon_next_ex_date",
    "coupon_type",
    "coupon_barrier",
    "leverage",
    "exchange_risk"
];

// static vector of cols for issuers
// vec!["issuer_name", "specialization", "geo_region", "issuer_rating_description"]
pub static ISSUER_COLUMNS: &'static [&str] = &[
    "issuer_name",
    "specialization",
    "geo_region",
    "issuer_rating_description"
];

// static vector of cols for isin_ticker
// vec!["certificate_isin", "certificate_name", "stock_google_finance_ticker", "stock_name"]
pub static ISIN_TICKER_COLUMNS: &'static [&str] = &[
    "certificate_isin",
    "certificate_name",
    "stock_google_finance_ticker",
    "stock_name",
    "stock_isin",
    "stock_industry",
    "stock_sector"
];

// static vector of cols for certificate_growth
// (ISIN, Issuer, Name, Coupon, Ex-Date, Ask, Bid, Growth_1D ,Growth_3Ds, Growth_1W, Growth_2W, Growth_4W)
pub static CERTIFICATE_GROWTH_COLUMNS: &'static [&str] = &[
    "isin",
    "issuer",
    "name",
    "coupon_amount",
    "coupon_recurrence",
    "coupon_next_ex_date",
    "ask",
    "bid",
    "growth_1d",
    "growth_3d",
    "growth_1w",
    "growth_2w",
    "growth_4w"
];


// pub static TABLES: Tables = Tables {
//     _ISIN_TICKER: "invcerts.ISINs.isin_ticker",
//     _QUOTE: "invcerts.ISINs.quote",
//     _DETAILS: format!("invcerts.ISINs.{}", STAGING_PREFIX).as_str(),
//     _ISSUER: "invcerts.Issuers.issuer",
// };