use std::collections::HashMap;

use std::sync::{Arc, Mutex};
use actix_web::middleware::{self, Logger};
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
use crate::svc_helpers::{AppConfig, ContentSystem, SharedMap, sanitize_input, auth_middleware};
use crate::bq_helpers;
use crate::definitions;
use definitions::bq_defs;
use definitions::csv_query_engine;

pub async fn get_certificates_by_issuer_sql(
    data: web::Data<SharedMap>,
    query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let issuer = query.get("issuer").unwrap_or(&"".into()).to_string();
    let issuer = sanitize_input(&issuer);
    let tickers_csv_list = query.get("tickers").unwrap_or(&"".into()).to_string();
    let tickers_csv_list = tickers_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",");
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // create a vector of dummy certificates for testing. Each entry should be in format <isin>,<certificate name>,<ask>,<bid>,<currency>,<obsdatetime>
    let (client, project_id) = bq_helpers::init_bq_client().await;
    let i_where_condition = bq_helpers::like_condition("issuer", &issuer, true);
    let ts_where_condition = match tickers_csv_list.as_str() {
        "" => "".into(),
        _ => format!("isin in (SELECT certificate_isin FROM {} WHERE stock_google_finance_ticker in ('{}'))", &shared_state.table_names._isin_ticker, tickers_csv_list.replace(",", "','"))
    };
    let rows = bq_helpers::query_bq(
        &client,
        &project_id,
        bq_defs::DETAIL_COLUMNS.to_vec(),
        &shared_state.table_names._details,
        vec![&i_where_condition, &ts_where_condition]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}

#[get("/certificates/{isin}")]
/* returns a specific certificate by ISIN */
// /* returns all certificates 
/* optional parameter:
- issuer={issuer name prefix}
- tickers={ticker1},...,{tickerN}
- industries={industry1},...,{industryN}
*/
pub async fn get_certificates(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
     query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let isins = sanitize_input(&path.into_inner());
    let is_all = isins == "*";
    let issuer = query.get("issuer").unwrap_or(&"".into()).to_string();
    let issuer = sanitize_input(&issuer);
    let tickers_csv_list = query.get("tickers").unwrap_or(&"".into()).to_string();
    let is_ticker_list_provided = !tickers_csv_list.is_empty();
    // TODO: add a comma at the end of tickers_csv_list to simplify the filtering logic later
    let tickers_csv_list = tickers_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",").to_lowercase();

    let industries_csv_list = query.get("industries").unwrap_or(&"".into()).to_string();
    let is_industry_list_provided = !industries_csv_list.is_empty();
    // TODO: add a comma at the end of industries_csv_list to simplify the filtering logic later
    let industries_csv_list = industries_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",").to_lowercase();
    // obtain shared state
    let shared_state = data.lock().unwrap();

    // if tickers_csv_list is not empty, filter by stock_google_finance_ticker in tickers_csv_list
    let tickers_csv_list_filter = format!("{},", tickers_csv_list.clone());
    let industries_csv_list_filter = industries_csv_list.clone();
    let isin_filter_list = match is_ticker_list_provided || is_industry_list_provided {
        false => "".into(),
        true => {
            log::debug!("Filtering by tickers {} and industries: {}", tickers_csv_list_filter, industries_csv_list_filter);
            let pre_engine = csv_query_engine::CsvQueryEngine::new("tickers.csv"); 
            // certificate_isin;certificate_name;stock_name;stock_google_finance_ticker;stock_isin;stock_industry;stock_sector
            pre_engine.run(
                move |r| {
                    // remove N/A data
                    if r.get(0).unwrap_or("").is_empty() || r.get(0).unwrap_or("N/A").to_uppercase() == "N/A" {
                        return false;
                    }
                    if is_ticker_list_provided {
                        let stock_google_finance_ticker = format!("{},", r.get(3).unwrap_or("").to_lowercase());
                        if stock_google_finance_ticker.trim() == "," {
                            return false;
                        }
                        if !tickers_csv_list_filter.contains(&stock_google_finance_ticker) {
                            return false;
                        }
                    } 
                    if is_industry_list_provided {
                        let industry_and_sector = format!("{},", r.get(5).unwrap_or("").to_lowercase() + "," + &r.get(6).unwrap_or("").to_lowercase());
                        log::debug!("Filtering by industry: {}, stock industry and sector: {} => {}", industries_csv_list_filter, industry_and_sector, industries_csv_list_filter.split(",").any(|ind| industry_and_sector.contains(ind)));
                        if industry_and_sector.trim() == "," {
                            return false;
                        }
                        // test if the string "industry,sector" contains any of the industries in industries_csv_list, for example if industry is "technology,software" and industries_csv_list is "technology,finance", it should return true because "technology,software" contains "technology"
                        return industries_csv_list_filter.split(",").any(|ind| industry_and_sector.contains(ind));
                    } 
                    true
                },
                |r| r.get(0).unwrap_or("NOT PROVIDED").to_string(), // certificate_isin 
            ).unwrap_or(vec![]).join(",") // join by removing the first item because it is the header
        }
    };
 
    log::debug!("ISINs: all={}, list={}",is_all, isin_filter_list);
    // if isin_filter_list contains only one element, it means that the header is the only one present and no ISIN matches the provided tickers, so we can return an empty response
    if (is_industry_list_provided || is_ticker_list_provided) && isin_filter_list.split(",").count() <= 1 {
        log::info!("No ISIN matches the provided tickers, returning empty response");
        return HttpResponse::Ok().json(vec![bq_defs::DETAIL_COLUMNS.join(";")]);
    }

     let engine = csv_query_engine::CsvQueryEngine::new("details.csv");
      
     // isin;issuer;name;certificate_type_tags;memory_effect;phase;currency;industry;callable;strike_date;issue_date;rembursement_date;autocallable_date;capital_barrier;airbag;risk_level;coupon_amount;coupon_recurrence;coupon_next_ex_date;coupon_type;coupon_barrier;leverage;exchange_risk
     let result = engine.run(
        move |r| {
            // filter by issuer
            let issuer_col = r.get(1).unwrap_or("");
            if !issuer.is_empty() && !issuer_col.to_uppercase().contains(&issuer.to_uppercase()) {
                return false;
            }
            // if pre-filtering by tickers or industries is provided, filter by isin using isin_filter_list
            if is_ticker_list_provided || is_industry_list_provided {
                let certificate_isin = r.get(0).unwrap_or("");
                if !isin_filter_list.contains(certificate_isin) {
                    return false;
                }
            }
            // if not is_all, filter by isin
            if !is_all {
                let isin_col = r.get(0).unwrap_or("").to_lowercase();
                if  !isins.to_lowercase().contains(&isin_col) {
                    return false;
                }
            }
            
            true
        },
        |r| r.iter().collect::<Vec<_>>().join(";"),
    );

    match result {
        Ok(rows) => HttpResponse::Ok().json(rows),
        Err(_) => HttpResponse::InternalServerError().json(vec!["error"]),
    }
}

pub async fn get_certificate_by_isin_sql(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
) -> impl Responder {
    let isin = path.into_inner();
    let isin = sanitize_input(&isin);
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // create a vector of 10 dummy certificates for testing. Each entry should be in format <isin>,<certificate name>,<ask>,<bid>,<currency>,<obsdatetime>
    // first row is the header
    // the vector is composed of 10 certificates with the same ticker but different ISINs and certificate names, and the same ask, bid, currency and obsdatetime
    let (client, project_id) = bq_helpers::init_bq_client().await;
    let where_condition = match isin.as_str() {
        "" => "".into(),
        "*" => "".into(),
        _ => format!("upper(isin) = '{}'", isin.to_uppercase()),
    };
    let rows = bq_helpers::query_bq(
        &client, 
        &project_id,
        bq_defs::DETAIL_COLUMNS.to_vec(),
        &shared_state.table_names._details, 
        vec![&where_condition]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}

#[get("/certificates-tickers/{certs_csv_list}")]
/* returns certificates by ticker */
/* optional parameter:
- tickers={ticker1},...,{tickerN}
- industries={industry1},...,{industryN}
*/
pub async fn get_certs_and_tickers(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
    query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let certs_csv_list = path.into_inner();
    // certs_csv_list is a comma separated list of certificates isins, for example: US0000000001,US0000000002,US0000000003 or * for all certificates
    let certs_csv_list = certs_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",");    
    // retrieve tickers (array) as querystring parameters, for example: tickers=AAPL,MSFT,GOOGL
    let tickers_csv_list = query.get("tickers").unwrap_or(&"".into()).to_string();
    // Note: adding a comma at the end of tickers_csv_list to simplify the filtering logic later
    let tickers_csv_list = format!("{},", tickers_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",").to_lowercase());
    // retrieve industries (array) as querystring parameters, for example: industries=Technology,Healthcare
    let industries_csv_list = query.get("industries").unwrap_or(&"".into()).to_string();
    let industries_csv_list = industries_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",").to_lowercase();

    let shared_state = data.lock().unwrap();
    let engine = csv_query_engine::CsvQueryEngine::new("tickers.csv");
    // let where_growth = growth1d.clone();
    // let where_par = parvalue.clone();

    let result = engine.run(
        move |r| {
            // certificate_isin;certificate_name;stock_name;stock_google_finance_ticker;stock_isin;stock_industry;stock_sector
            let certificate_isin = r.get(0).unwrap_or("");
            let stock_google_finance_ticker = format!("{},", r.get(3).unwrap_or("").to_lowercase());
            let stock_industry_sector = format!("{},{}", r.get(5).unwrap_or("").to_lowercase(), r.get(6).unwrap_or("").to_lowercase());
            // println!("-- industries_csv_list: {}, tickers_csv_list: {}", industries_csv_list, tickers_csv_list);
            // if certs_csv_list is not empty, filter by certificate_isin AND if tickers_csv_list is not empty, filter by stock_google_finance_ticker
            let ok = match certs_csv_list.as_str() {
                "*" => true,
                _ => certs_csv_list.contains(certificate_isin),
            } && match tickers_csv_list.as_str() {
                "," => true,
                _ => tickers_csv_list.contains(&stock_google_finance_ticker),
            } && match industries_csv_list.as_str() {
                "" => true,
                _ => industries_csv_list.split(",").any(|ind| stock_industry_sector.contains(ind)),
            };
            // println!("Filtering certificate_isin: {}, stock_google_finance_ticker: {}, stock_industry_sector: {} => {}", certificate_isin, stock_google_finance_ticker, stock_industry_sector, ok);
            ok
        },
        |r| r.iter().collect::<Vec<_>>().join(";"),
    );

    match result {
        Ok(rows) => HttpResponse::Ok().json(rows),
        Err(_) => HttpResponse::InternalServerError().json(vec!["error"]),
    }
}

pub async fn get_certs_and_tickers_sql(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
    query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let certs_csv_list = path.into_inner();
    // certs_csv_list is a comma separated list of certificates isins, for example: US0000000001,US0000000002,US0000000003
    // sanitize input to prevent SQL injection one ISIN by one
    let certs_csv_list = certs_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",");    
    // obtain shared state
    // retrieve tickers (array) as querystring parameters, for example: tickers=AAPL,MSFT,GOOGL
    let tickers_csv_list = query.get("tickers").unwrap_or(&"".into()).to_string();
    let tickers_csv_list = tickers_csv_list.split(",").map(sanitize_input).collect::<Vec<_>>().join(",");

    let shared_state = data.lock().unwrap();
    // first row is the header
    let (client, project_id) = bq_helpers::init_bq_client().await;
    let where_condition = match certs_csv_list.as_str() {
        "" => "".into(),
        "*" => "".into(),
        _ => format!("certificate_isin IN ('{}')", certs_csv_list.replace(",", "','")),
    };
    let filter_condition = match tickers_csv_list.as_str() {
        "" => "".into(),
        "*" => "".into(),
        _ => format!("stock_google_finance_ticker IN ('{}')", tickers_csv_list.replace(",", "','")),
    };
    let rows = bq_helpers::query_bq(
        &client, 
        &project_id,
        bq_defs::ISIN_TICKER_COLUMNS.to_vec(),
        &shared_state.table_names._isin_ticker, 
        vec![&where_condition, &filter_condition]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}

#[get("/certificates-growth")]
/*## GET /certificates-growth?{growth1=[up|down]]}&{parvalue=[over|below]}
Returns cumulative data
- growth1d
- parvalue: if it is over or below the par value

**Note**: One of the parameter is needed otherwise an empty response is provided.
*/
pub async fn get_growth(
    query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let growth1d = sanitize_input(&query.get("growth1d").unwrap_or(&"".into()));
    let parvalue = sanitize_input(&query.get("parvalue").unwrap_or(&"".into()));

    if growth1d.is_empty() && parvalue.is_empty() {
        return HttpResponse::Ok().json(vec![bq_defs::CERTIFICATE_GROWTH_COLUMNS.join(";")]);
    }
    let engine = csv_query_engine::CsvQueryEngine::new("certs_growth.csv");
    let where_growth = growth1d.clone();
    let where_par = parvalue.clone();

    let result = engine.run(
        move |r| {
            let growth: f64 = r.get(7).unwrap_or("0").parse().unwrap_or(0.0);
            let ask: f64 = r.get(5).unwrap_or("0").parse().unwrap_or(0.0);

            let mut ok = true;

            match where_growth.as_str() {
                "up" => ok &= growth > 0.0,
                "down" => ok &= growth < 0.0,
                _ => {}
            }

            match where_par.as_str() {
                "over" => ok &= ask >= 100.0,
                "below" => ok &= ask < 100.0,
                _ => {}
            }

            ok
        },
        |r| r.iter().collect::<Vec<_>>().join(";"),
    );

    match result {
        Ok(rows) => HttpResponse::Ok().json(rows),
        Err(_) => HttpResponse::InternalServerError().json(vec!["error"]),
    }
}

pub async fn get_growth_file(
    data: web::Data<SharedMap>,
    query: web::Query<HashMap<String, String>>
) ->  impl Responder {
    let growth1d = query.get("growth1d").unwrap_or(&"".into()).to_string();
    let growth1d = sanitize_input(&growth1d);
    let parvalue = query.get("parvalue").unwrap_or(&"".into()).to_string();
    let parvalue = sanitize_input(&parvalue);

    let where_condition1 = match growth1d.as_str() {
        "up" => "growth_1d>0".to_string(),
        "down" => "growth_1d<0".to_string(),
        _ => "".to_string()
    };
    let where_condition2 = match parvalue.as_str() {
        "over" => "ask>=100".to_string(),
        "below" => "ask<100".to_string(),
        _ => "".to_string()
    };

    // Final rows
    let mut rows: Vec<String> = Vec::new();

    // CSV reader
    let mut rdr = match csv::ReaderBuilder::new()
        .delimiter(b';')
        .from_path("certs_growth.csv")
    {
        Ok(r) => r,
        Err(e) => {
            log::error!("Error reading CSV file: {}", e);
            return HttpResponse::Ok()
                .content_type("application/json")
                .json(vec!["No Data Available".to_string()]);
        }
    };

    // Add header
    if let Ok(headers) = rdr.headers() {
        rows.push(
            headers.iter()
                .collect::<Vec<_>>()
                .join(";")
        );
    }

    // Read records
    for result in rdr.records() {

        let record = match result {
            Ok(r) => r,
            Err(_) => continue,
        };

        if !where_condition1.is_empty() {
            let growth1d_value: f64 = record[7].parse().unwrap_or(0.0);
            if where_condition1.contains("growth_1d>0") && growth1d_value <= 0.0 {
                continue; // Skip if growth1d is not up
            }
            if where_condition1.contains("growth_1d<0") && growth1d_value >= 0.0 {
                continue; // Skip if growth1d is not down
            }
        }
        if !where_condition2.is_empty() {
            let ask_value: f64 = record[5].parse().unwrap_or(0.0);
            if where_condition2.contains("ask>=100") && ask_value < 100.0 {
                continue; // Skip if ask is not over par value
            }
            if where_condition2.contains("ask<100") && ask_value >= 100.0 {
                continue; // Skip if ask is not below par value
            }
        }
        
        rows.push(
            record.iter()
                .collect::<Vec<_>>()
                .join(";")
        );
    }

    log::debug!("RESULTS for {parvalue} and {growth1d}: {}", rows.len());

    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}




