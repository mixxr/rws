use std::collections::HashMap;

use std::sync::{Arc, Mutex};
use actix_web::middleware::{self, Logger};
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
use crate::svc_helpers::{AppConfig, ContentSystem, SharedMap, sanitize_input, auth_middleware};
use crate::bq_helpers;
use crate::definitions;
use definitions::bq_defs;


#[get("/certificates")]
/* returns certificates by issuer */
pub async fn get_certificates_by_issuer(
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
pub async fn get_certificate_by_isin(
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
*/
pub async fn get_certs_and_tickers(
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
/*## GET /certificates-growth?growth1={[up|down]}&parvalue={[over|below]}
Returns cumulative data
- growth1d
- parvalue: if it is over or below the par value

**Note**: One of the parameter is needed otherwise an empty response is provided.
*/
pub async fn get_growth(
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
    let shared_state = data.lock().unwrap();
    // first row is the header
    let (client, project_id) = bq_helpers::init_bq_client().await;
    let rows = bq_helpers::query_bq(
        &client, 
        &project_id,
        bq_defs::CERTIFICATE_GROWTH_COLUMNS.to_vec(),
        &shared_state.table_names._isin_ticker, 
        vec![&where_condition1, &where_condition2]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}

pub async fn get_growth_static(
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
    let shared_state = data.lock().unwrap();
    // first row is the header
    let (client, project_id) = bq_helpers::init_bq_client().await;
    let rows = bq_helpers::query_bq(
        &client, 
        &project_id,
        bq_defs::CERTIFICATE_GROWTH_COLUMNS.to_vec(),
        &shared_state.table_names._isin_ticker, 
        vec![&where_condition1, &where_condition2]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}


