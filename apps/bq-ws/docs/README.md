# issuers

## GET /issuers/{name_prefix}
To get all issuers: /issuers/*
## response
```csv
[
    {issuer_name, specialization, geo_region, issuer_rating_description, issuer_rating_class}
]
```
# certificates (description)

## GET /certificates/{isin}
## GET /certificates?issuer={issuer}

## response
```json
[
    {
    isin: String,
    issuer: String,
    name: String, // the name of the certificate, try to add the underlying stock tickers to the name if possible
    certificate_type_tags: String, // e.g. step-down, memory, cash collect, booster, etc.
    memory_effect: String, // yes, no, etc.
    phase: String, // rembursed, active, etc.
    currency: String,
    industry: String,  // try to infer the industry of the certificate based on the underlying stocks' industries
    callable: String, // yes, no, autocallable,
    strike_date: String, // format YYYY-MM-DD
    issue_date: String, // format YYYY-MM-DD
    rembursement_date: String, // format YYYY-MM-DD
    autocallable_date: String, // format YYYY-MM-DD
    capital_barrier: String, // e.g. 100% of the strike price, 50% of the underlying stock price, etc.
    airbag: String, // yes, no, etc.
    risk_level: String, // low, medium, high, etc.
    coupon_amount: String,
    coupon_recurrence: String,
    coupon_type: String, // fixed, variable, etc.
    coupon_barrier: String, // e.g. 100% of the strike price, 50% of the underlying stock price, etc.
    leverage: String,
    exchange_risk: String,
    }
]
```

# certificates-tickers

## GET /certificates-tickers?tickers=[{ticker1},...,{tickerN}]&op=[OR|AND]
Returns stocks of certificates whose underlyings match a logical condition on a set of tickers
Filters certificates based on their underlyings:

- `OR`: returns certificates that have **at least one underlying** matching any of the provided tickers  
- `AND`: returns certificates that have underlyings matching **all provided tickers**

## GET /certificates-tickers/{cert_ISINs_csv_list}
Returns stocks of certificate identified by one of the ISIN in the {cert_ISINs_csv_list}

## response
```json
[
  {
    "certificate_isin": "string",
    "certificate_name": "string",
    "stock_name": "string",
    "stock_google_finance_ticker": "string",
    "stock_isin": "string",
    "stock_exchange": "string",
    "stock_sector": "string",
    "stock_industry": "string",
    "stock_specializations": "string",
    "stock_capitalization": "string",
    "stock_pe": "string",
    "stock_beta": "string",
    "stock_volatility": "string"
  }
]
```

# quotes
/quotes/<isin>/<dt>
/quotes/<isin>/latest
/quotes/<isin>/latest-1
/quotes/<isin>/<dt>?timespan=<days>

ISIN
Name
Ask
Bid
Currency
DT

# tickers

/tickers
/tickers?prefix=<prefix>

Ticker
Name

