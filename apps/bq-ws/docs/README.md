# issuers

## GET /issuers/{name_prefix}
To get all issuers: /issuers/*
## response
```csv
[
    {issuer_name, specialization, geo_region, issuer_rating_description, issuer_rating_class}
]
```
### Examples

```examples
GET /issuers/*
GET /issuers/leon
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
### Examples

```examples
GET /certificates/*
GET /certificates?issuer=leon
GET /certificates
```

# certificates-tickers

## GET /certificates-tickers/{cert_ISINs_csv_list}?tickers={ticker1},...,{tickerN}
Returns stocks of certificate identified by one of the ISIN in the {cert_ISINs_csv_list}
Filters certificates based on their underlyings: returns certificates that have **at least one underlying** matching any of the provided tickers  

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

### Examples

```examples
GET /certificates-tickers/*
GET /certificates-tickers/*?tickers=NYSE:IONQ
```

# tickers

## GET /tickers/{name_prefix}
To get all tickers: /tickers/*
### response
```json
[
  (Ticker, Stock Name)
]
```
### Examples

```examples
GET /tickers/*
GET /tickers/ION
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

