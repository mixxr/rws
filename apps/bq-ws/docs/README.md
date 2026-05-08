# Configuration
## ENV VARS
- IS_STAGING
- LISTEN_PORT
- RUST_LOG
- SECRET_KEY

## AUTHORIZATION
- Authorization: Bearer MY_SECRET_KEY

# ISSUERS

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


# CERTIFICATES (description)

## GET /certificates/{isin}
## GET /certificates?issuer={issuer}
## GET /certificates?tickers={ticker1},...,{tickerN}

## response
```json
[
    {
    isin: String,
    issuer: String,
    name: String, // the name of the certificate, try to add the underlying stock tickers 
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
    coupon_next_ex_date: String, // when the next coupon will be payed
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
GET /certificates/CH1550424647
```

# UNDERLYINGS 

## GET /certificates-tickers/{cert_ISINs_csv_list}?tickers={ticker1},...,{tickerN}
Returns stocks of certificate identified by one of the ISIN in the {cert_ISINs_csv_list}
Filters certificates based on their underlyings: returns certificates that have **at least one underlying** matching any of the provided tickers  

## response
```json
[
  {
    "certificate_isin": string,
    "certificate_name": string,
    "stock_name": string,
    "stock_google_finance_ticker": string,
    "stock_isin": string,
    "stock_industry": string,
    "stock_sector": string
  }
]
```

### Examples

```examples
GET /certificates-tickers/*
GET /certificates-tickers/*?tickers=BIT:BMPS
GET /certificates-tickers/DE000VG656A7
GET /certificates-tickers/DE000VG656A7?tickers=BIT:BMPS
GET /certificates-tickers/DE000VG656A7,NLBNPIT30309?tickers=BIT:BMPS,VIE:RBI
```

# TICKERS

## GET /tickers/{name_prefix}
Returns ticker and stock name by stock name prefix.
To get all tickers: /tickers/*
- Add the exchange (eg. NYSE, BIT) to retrieve via symbol: /tickers/{exchange}:{symbol}

### response
```json
[
  (Ticker, Stock Name)
]
```
### Examples

```examples
GET /tickers/*
GET /tickers/ion
GET /tickers/NYSE:IONQ
```

# CERTIFICATES GROWTH

## GET /certificates-growth?growth1={[up|down]}&parvalue={[over|below]}
Returns cumulative data
- growth1d
- parvalue: if it is over or below the par value

**Note**: One of the parameter is needed otherwise an empty response is provided.

### response
```json
[
  (ISIN, Issuer, Name, Coupon, Ex-Date, Ask, Bid, Growth_1D ,Growth_3Ds, Growth_1W, Growth_2W, Growth_4W)
]
```
### Examples

```examples
GET /certificates-growth?growth1=up&parvalue=below
GET /certificates-growth?parvalue=below
```


# QUOTES
/quotes/<isin>/<dt>
/quotes/<isin>/latest-{days} => last {days} quotes
/quotes/<isin>/<dt>?timespan=<days>

ISIN
Name
Ask
Bid
Currency
DT

