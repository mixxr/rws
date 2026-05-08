use std::{env};
//use std::io::{self, BufReader, prelude::*};
use std::collections::HashMap;
use std::process::Command;


use actix_cors::Cors;
//use actix_web::http::header;
use actix_web::middleware::{self, Logger};
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
use std::sync::{Arc, Mutex};

// mod ic_csv;
// use ic_csv::*;
use clap::Parser;

mod definitions;
mod bq_helpers;
mod svc_helpers;
mod svc_certificates;

use definitions::args::Args;
use definitions::bq_defs::*;
use bq_helpers::*;
use svc_helpers::*;
use svc_certificates::*;
 

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let args = Args::parse();
    // let path = std::env::current_dir().unwrap();

    env_logger::init();
    // args → fallback to env var → fallback to default
    let secret_key = match env::var("SECRET_KEY") {
        Ok(v) => v,
        Err(_) => {
            eprintln!("Error: SECRET_KEY environment variable is not set");
            std::process::exit(1);
        }
    };
    log::debug!("SECRET_KEY: {secret_key}");

    let listen_addr = "0.0.0.0";

    let is_test_mode = args.is_test_mode
        .or_else(|| env::var("IS_TEST_MODE").ok().and_then(|v| v.parse().ok()))
        .unwrap_or(false);

    let listen_port = args.listen_port
        .or_else(|| env::var("LISTEN_PORT").ok().and_then(|v| v.parse().ok()))
        .unwrap_or(8080);

    let is_staging = args.is_staging
        .or_else(|| env::var("IS_STAGING").ok().and_then(|v| v.parse().ok()))
        .unwrap_or(true);

    let shared_state: SharedMap = Arc::new(Mutex::new(ContentSystem {
        table_names: Tables::new(is_staging),
    }));

    println!("Configuration:\n- Listen Port: {listen_port}\n- Is Staging: {is_staging}\n- Is Test Mode: {is_test_mode}\n- Log Level: {}", std::env::var("RUST_LOG").unwrap_or("ERROR".to_string()));

    // TODO: check trailing slash in path prefixes and add if not present
    // let isin_path_prefix = env::var("ISIN_PATH_PREFIX");
    // let isin_path_prefix = match isin_path_prefix {
    //     Err(_e)=> &args.isin_fp_prefix,
    //     Ok(isin_path_prefix) => &isin_path_prefix.clone()
    // };
    // let source_path = env::var("SOURCE_PATH");
    // let source_path = match source_path {
    //     Err(_e)=> &args.source_fp,
    //     Ok(source_path) => &source_path.clone()
    // };
    // let output_path_prefix = env::var("OUTPUT_PATH_PREFIX");
    // let output_path_prefix = match output_path_prefix {
    //     Err(_e)=> &args.output_fp_prefix,
    //     Ok(output_path_prefix) => &output_path_prefix.clone()
    // };

    log::info!("Server running at http://{listen_addr}:{listen_port}");

    HttpServer::new(move || {
        // let cors = Cors::default().allow_any_origin().send_wildcard();
        // let cors = Cors::default().allow_any_origin();
        App::new()
            .app_data(web::Data::new(svc_helpers::AppConfig {
                    secret: secret_key.clone(),
                    is_test_mode: is_test_mode,
                }))
            .wrap(Logger::default())
            // .wrap(cors)
            .wrap(
                Cors::default()
                    .allow_any_origin()
                    .allow_any_method()
                    .allow_any_header()
            )
            .wrap(middleware::from_fn(svc_helpers::auth_middleware))
            .app_data(web::Data::new(shared_state.clone()))
            .service(root)
            .service(get_data)
            .service(get_issuers_by_name_prefix)
            .service(get_certificates_by_issuer)
            .service(get_certificate_by_isin)
            .service(get_certs_and_tickers)
            .service(get_tickers_by_name_prefix)
            .service(get_growth)
            .service(get_test)
            // .default_service(web::route().method(actix_web::http::Method::OPTIONS).to(|| async {
            //     HttpResponse::Ok()
            //     .insert_header(("Access-Control-Allow-Origin", "*"))
            //     .insert_header(("Access-Control-Allow-Methods", "GET, POST, OPTIONS"))
            //     .insert_header(("Access-Control-Allow-Headers", "Authorization, Content-Type"))
            //     .finish()
            // }))
    })
    .bind((listen_addr, listen_port))?
    .run()
    .await
 
}

// handler for GET /
#[get("/")]
async fn root() -> &'static str {
    "IC Data Extraction Service is running."
}

// fn check_dtime(source: &str, dt: &str, output_fp_prefix: &str) -> String {
//     if dt.to_lowercase().trim() == "latest" {
//         println!("latest required at {}, {}", output_fp_prefix, source);
//         // read directory and get latest file
//         match get_latest_dtime(source, output_fp_prefix) {
//             Ok(latest_dt) => {
//                 println!("latest observation datetime: {}", latest_dt);
//                 return latest_dt;
//             },
//             Err(e) => {
//                 println!("Error getting latest observation datetime: {}", e);
//                 return "1900-01-01-00-00-00.csv".to_string();
//             }
//         }
//     }
//     // naive format %Y-%m-%d-%H-%M-%S checker
//     // let parts: Vec<&str> = dt.split('-').collect();
//     // if parts.len() == 6 {
//     [dt,".csv"].concat()
//     // }else{
//     //     Err(anyhow!("observation date format not valid"))
//     // }
// }

// fn get_latest_dtime(source: &str, arg: &str) -> Result<String, io::Error> {
//     let mut latest_time = "1900-01-01-00-00-00.csv".to_string();
//     let dir_path = [arg, source].concat();
//     println!("get_latest_dtime path: {}", dir_path);
//     if !std::path::Path::new(&dir_path).exists() {
//         println!("Directory {} does not exist", dir_path);
//         return Ok(latest_time);
//     }
//     for entry in std::fs::read_dir(dir_path).unwrap() {
//         // file format is <obsdatetime>.csv
//         let entry = entry.unwrap(); 
//         // get observation datetime from filename
//         let filename = entry.file_name().into_string().unwrap();
//         println!("latest: {}", filename);
//         //let obsdatetime = filename[..filename.rfind('.').unwrap()].to_string();
//         // observation datetime is in format YYYY-MM-DD-HH-MM-SS
//         if filename > latest_time {
//             latest_time = filename;
//         }
//     }
//     // return latest time  
//     Ok(latest_time)
// }

// fn get_latest_observations(shared_state: &ContentSystem, source: &str, maxobs: usize) -> Vec<String> {
//     let options = MatchOptions {
//         case_sensitive: false,
//         require_literal_separator: false,
//         require_literal_leading_dot: false,
//     };
//     let mut obsdatetimes = Vec::new();
//     let mut max_entries = maxobs;
//     for entry in glob_with(&format!("{}{}/*.csv", shared_state.output_path_prefix, source), options).unwrap() {
//         if let Ok(path) = entry {
//             //let filename = String::from(path.to_str().unwrap());
//             // filename is in format <obsdatetime>.csv and <source> length is variable, so split at first '-' and get obsdatetime and remove .csv extension
//             // let obsdatetime = (filename.split_at(filename.find('-').unwrap_or(0)+1).1).to_string();
//             // let obsdatetime = filename.strip_suffix(".csv").unwrap().to_string();//.unwrap_or(&obsdatetime).to_string(); // TODO: return Vec<&str> is better?

//             obsdatetimes.push(path.file_stem().unwrap().to_str().unwrap().to_string());
//             max_entries -= 1;
//             if max_entries == 0 {
//                 break;
//             }
//         }
//     }
//     // sort obsdatetimes in descending order
//     // obsdatetimes.sort_by(|a, b| b.cmp(a));
//     obsdatetimes
// }

// fn get_ds_name(shared_state: &ContentSystem, source: Option<&str>, obsdatetime: Option<&str>) -> String {
//     if obsdatetime.is_some() {
//         // means the request is about a specific observation filename => quotes to read
//         let dt = check_dtime(&source.unwrap_or("404"), &obsdatetime.unwrap(), &shared_state.output_path_prefix);
//         // dt should end with .csv
//         return format!("{}{}/{}", shared_state.output_path_prefix, source.unwrap_or("404"), dt);
//     } else {
//         if source.is_some() {
//             // means a specific source is requested => isins to read
//             return format!("{}{}.csv", shared_state.isin_path_prefix, source.unwrap());
//         } 
//         return shared_state.source_path.clone();
//     };
// }

// fn get_ds(key: &str, map: &SharedMap) -> File {
//    /*
// Return the file associated with the key if exists, otherwise open the file and add to map
// */
//    match map.lock().unwrap().files.get(key) {
//        Some(file) => file.try_clone().unwrap(),
//        None => {
//            let file = File::open(key).unwrap();
//            map.lock().unwrap().files.insert(key.to_string(), Arc::new(Mutex::new(file)));
//            file
//        }
//    }
   
// }


// check if response is empty or contains only header or nodata found
// fn check_response(response: &Vec<String>, info: String) -> bool {
//     if response.len() <= 0 
//         || response[0] == ic_csv::NODATA_FOUND 
//         || (response.len() == 1 && response[0].starts_with("isin,")) {
//         //response.push(info);
//         return true;
//     }
//     return false;
// }


// ## GET /issuers/{name_prefix}
#[get("/issuers/{name_prefix}")]
/* returns list of issuers matching the name prefix */
async fn get_issuers_by_name_prefix(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
) -> impl Responder {
    // let config = req
    //     .app_data::<actix_web::web::Data<ContentSystem>>()
    //     .expect("ContentSystem missing");
    let name_prefix = sanitize_input(&path.into_inner());
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // use BigQuery structure as below methods
    let (client, project_id) = init_bq_client().await;
    let where_condition = format!("lower(issuer_name) like '{}%'", name_prefix.to_lowercase());
    let rows = query_bq(
        &client, 
        &project_id,
        ISSUER_COLUMNS.to_vec(), 
        &shared_state.table_names._issuer, 
        vec![&where_condition]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}

#[get("/tickers/{name_prefix}")]
/* returns list of tickers (ticker, stock name) matching the name prefix */
// TO-DO: return unique stock names with their tickers
async fn get_tickers_by_name_prefix(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
) -> impl Responder {
    let name_prefix = sanitize_input(&path.into_inner());
    // name_prefix is in format (optionally) like 'exchange:ticker' or 'ticker' or '*'. In case it was exchange:ticker then we should filter on stock_google_finance_ticker column, otherwise we should filter on stock_name column. If name_prefix is '*' or empty then we should return all tickers and stock names
    let column_to_filter = if name_prefix.contains(":") {
        "stock_google_finance_ticker"
    } else {
        "stock_name"
    };
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // use BigQuery structure as below methods
    let (client, project_id) = init_bq_client().await;
    let where_condition = match name_prefix.as_str() {
        "" => "".into(),
        "*" => "".into(),
        _ => format!("lower({}) like '{}%'", column_to_filter, name_prefix.to_lowercase()),
    };
    let rows = query_bq(
        &client, 
        &project_id,
        vec!["stock_google_finance_ticker", "stock_name"],
        &shared_state.table_names._isin_ticker, 
        vec![&where_condition]).await;
    
    log::debug!("BigQuery rows: {:?}", rows);
    HttpResponse::Ok()
        .content_type("application/json")
        .json(rows)
}

// #[get("/isins/{source}")]
// /* returns list of ISINs per source */
// async fn get_source(
//     data: web::Data<SharedMap>,
//     path: web::Path<String>,
// ) -> impl Responder {
//     let source = sanitize_input(&path.into_inner());
//     // obtain shared state
//     let shared_state = data.lock().unwrap();
//     let ds_path = get_ds_name(&shared_state, Some(&source), None);
//     let sources: Vec<String> = read_csv(&ds_path, None, false).await;

//     if check_response(&sources, format!("source {} not found", source)) {
//         return HttpResponse::NotFound()
//             .content_type("application/json")
//             .json(sources);
//     }
//     HttpResponse::Ok()
//         .content_type("application/json")
//         .json(sources)
// }

// #[get("/observations/{source}/{maxobs}")]
// /* returns list of latest (maxobs) observations per source */
// async fn get_sources_observations(
//     data: web::Data<SharedMap>,
//     path: web::Path<(String, String)>,
// ) -> impl Responder {
//     let (source, maxobsStr) = path.into_inner();
//     let source = sanitize_input(&source);
//     let mut maxobs = maxobsStr.parse::<usize>().unwrap_or(1000);
//     // check if maxobs <=0 then return latest 1000 observations
//     if maxobs <= 0 {
//         maxobs = 1000;
//     }
//     // obtain shared state
//     let shared_state = data.lock().unwrap();
//     let obsdatetimes = get_latest_observations(&shared_state, &source, maxobs);
//     if check_response(&obsdatetimes, format!("source {} not found", source)) {
//         return HttpResponse::NotFound()
//             .content_type("application/json")
//             .json(obsdatetimes);
//     }
//     HttpResponse::Ok()
//         .content_type("application/json")
//         .json(obsdatetimes)
// }

// #[get("/quotes/{source}/{obsdatetime}")]
// /* returns list of quotes (all ISINs) per source and observation date */
// async fn get_all_by_date(
//     data: web::Data<SharedMap>,
//     path: web::Path<(String, String)>
// ) -> impl Responder { 
//     let (source, obsdatetime) = path.into_inner();
//     let source = sanitize_input(&source);
//     let obsdatetime = sanitize_input(&obsdatetime);
//         // obtain shared state
//     let shared_state = data.lock().unwrap();
//     let ds_path = get_ds_name(&shared_state, Some(&source), Some(&obsdatetime));
//     let sources: Vec<String> = read_csv(&ds_path, None, true).await;
//     if check_response(&sources, format!("source {} or observation {} not found", source, obsdatetime)) {
//         return HttpResponse::NotFound()
//             .content_type("application/json")
//             .json(sources);
//     }
//     HttpResponse::Ok()
//         .content_type("application/json")
//         .json(sources)
// }

// #[get("/quotes/{source}/{obsdatetime}/{isin}")]
// /* returns a specific quote (ISIN) per source and observation date */
// async fn get_by_isin(
//     data: web::Data<SharedMap>,
//     path: web::Path<(String, String, String)>
// ) -> impl Responder {
//     let (source, obsdatetime, isin) = path.into_inner();
//     let source = sanitize_input(&source);
//     let obsdatetime = sanitize_input(&obsdatetime);
//     let isin = sanitize_input(&isin);
//         // obtain shared state
//     let shared_state = data.lock().unwrap();
//     let ds_path = get_ds_name(&shared_state, Some(&source), Some(&obsdatetime));
//     let sources: Vec<String> = read_csv(&ds_path, Some(&isin), true).await;
//     if check_response(&sources, format!("source {} or observation {} or ISIN {} not found", source, obsdatetime, isin)) {
//         return HttpResponse::NotFound()
//             .content_type("application/json")
//             .json(sources);
//     }
//     HttpResponse::Ok()
//         .content_type("application/json")
//         .json(sources)
// }
#[get("/test")]
async fn get_test() -> impl Responder {
    let output = Command::new("awk")
        .arg("-F;")
        .arg(r#"NR==1 || $6 > 100 || $8 > 0"#)
        .arg("certs_growth.csv")
        .output()
        .expect("failed to execute awk");

    println!("{}", String::from_utf8_lossy(&output.stdout));
        HttpResponse::Ok()
            .content_type("application/json")
            .json(vec!["test1", "test2", "test3"])
}

#[get("/health")]
async fn get_data(data: web::Data<SharedMap>)  -> impl Responder  {
    let shared_state = data.lock().unwrap();
    let (client, project_id) = init_bq_client().await;
    log::debug!("BigQuery project ID: {:?}", project_id);
    let rows = query_bq(
        &client, 
        &project_id,
        ISIN_TICKER_COLUMNS.to_vec(),
        &shared_state.table_names._isin_ticker, 
        vec![]).await;
    log::debug!("BigQuery rows: {:?}", rows);

            HttpResponse::Ok()
            .content_type("application/json")
            .json(vec!["counter", &rows.len().to_string()])
}

// fn read_file_lines(path: &str, isin: &str) -> io::Result<Vec<String>> {
//     // Open the file
//     let file = File::open(path)?;
//     let reader = BufReader::new(file);

//     // Collect lines into a Vec<String>
//     let lines: io::Result<Vec<String>> = reader
//         .lines() // Iterator over Result<String, io::Error>
//         .collect();

//     lines
// }


