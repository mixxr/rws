use csv::{ReaderBuilder, WriterBuilder};
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::error::Error;

#[derive(Debug, Deserialize)]
struct InputRecord {
    certificate_isin: String,
    certificate_name: String,
    stock_isin: String,
    stock_name: String,
    stock_google_finance_ticker: String,
    stock_exchange: String,
    stock_sector: String,
    stock_industry: String,
    stock_tags: String,
    stock_specializations: String,
    stock_capitalization: String,
    stock_pe: String,
    stock_beta: String,
    stock_volatility: String,
}

#[derive(Debug, Serialize)]
struct OutputRecord {
    certificate_isin: String,
    certificate_name: String,
    stock_name: String,
    stock_google_finance_ticker: String,
    stock_isin: String,
    stock_industry: String,
    stock_sector: String,
}

fn is_invalid(v: &str) -> bool {
    let v = v.trim();

    v.is_empty()
        || v.eq_ignore_ascii_case("n/a")
        || v.eq_ignore_ascii_case("null")
}

fn is_valid_isin(v: &str) -> bool {
    let v = v.trim();

    v.len() == 12
        && v.chars().all(|c| c.is_ascii_alphanumeric())
}

fn main() -> Result<(), Box<dyn Error>> {

    let mut rdr = ReaderBuilder::new()
        .delimiter(b';')
        .from_path("staging_tickers.csv")?;

    let mut wtr = WriterBuilder::new()
        .delimiter(b';')
        .from_path("tickers.csv")?;

    let mut seen: HashSet<(String, String)> = HashSet::new();

    for result in rdr.deserialize() {

        let r: InputRecord = match result {
            Ok(v) => v,
            Err(_) => continue,
        };

        // validate PK
        if is_invalid(&r.certificate_isin)
            || is_invalid(&r.stock_isin)
        {
            continue;
        }

        if !is_valid_isin(&r.certificate_isin)
            || !is_valid_isin(&r.stock_isin)
        {
            continue;
        }

        // deduplicate PK
        let pk = (
            r.certificate_isin.clone(),
            r.stock_isin.clone(),
        );

        if !seen.insert(pk) {
            continue;
        }

        // remove rows with invalid core fields
        if is_invalid(&r.stock_name)
            || is_invalid(&r.stock_google_finance_ticker)
        {
            continue;
        }

        let out = OutputRecord {
            certificate_isin: r.certificate_isin,
            certificate_name: r.certificate_name,
            stock_name: r.stock_name,
            stock_google_finance_ticker: r.stock_google_finance_ticker,
            stock_isin: r.stock_isin,
            stock_industry: r.stock_industry,
            stock_sector: r.stock_sector,
        };

        wtr.serialize(out)?;
    }

    wtr.flush()?;

    println!("tickers.csv generated");

    Ok(())
}