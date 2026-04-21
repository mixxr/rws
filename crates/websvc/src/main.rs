use std::{env, fs::File};
use std::io::{self, BufReader, prelude::*};
use std::collections::HashMap;

use std::sync::{Arc, Mutex};
use actix_cors::Cors;
use actix_web::http::header;
use actix_web::middleware::Logger;
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
//use serde::Serialize;
use env_logger::Env;
use glob::glob_with;
use glob::MatchOptions;

mod ic_csv;
use ic_csv::*;
use clap::Parser;
mod definitions;
use definitions::args::Args;
use tracing::info;

use rand::prelude::*;
 
#[derive(Debug, Clone)]
struct ContentSystem {
    lastDate: String,
    isin_path_prefix: String,
    output_path_prefix: String,
    source_path: String,
    files: HashMap<String, Arc<Mutex<File>>>,
}

// Type alias for shared state
type SharedMap = Arc<Mutex<ContentSystem>>;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let args = Args::parse();
    let path = std::env::current_dir().unwrap();
    let log_level = "debug";

    println!("The current directory is {}", path.display());
    println!("CLI Configuration: {:?}", args);

    // TODO: check trailing slash in path prefixes and add if not present
    let isin_path_prefix = env::var("ISIN_PATH_PREFIX");
    let isin_path_prefix = match isin_path_prefix {
        Err(_e)=> &args.isin_fp_prefix,
        Ok(isin_path_prefix) => &isin_path_prefix.clone()
    };
    let source_path = env::var("SOURCE_PATH");
    let source_path = match source_path {
        Err(_e)=> &args.source_fp,
        Ok(source_path) => &source_path.clone()
    };
    let output_path_prefix = env::var("OUTPUT_PATH_PREFIX");
    let output_path_prefix = match output_path_prefix {
        Err(_e)=> &args.output_fp_prefix,
        Ok(output_path_prefix) => &output_path_prefix.clone()
    };
    let listen_port = env::var("LISTEN_PORT");
    let listen_port = match listen_port {
        Err(_e)=> args.listen_port,
        Ok(listen_port) => listen_port.parse().unwrap_or(args.listen_port)
    };
    // TO DO: check if {isin_path_prefix}, {output_path_prefix} have trailing slash
    println!("ENV Configuration: {isin_path_prefix}, {output_path_prefix}, {source_path}, {listen_port}");

    env_logger::init_from_env(Env::default().default_filter_or(log_level));

    

    let shared_state: SharedMap = Arc::new(Mutex::new(ContentSystem {
        lastDate: "1900-01-01-00-00-00".to_string(),
        isin_path_prefix: isin_path_prefix.to_string(),
        output_path_prefix: output_path_prefix.to_string(),
        source_path: source_path.to_string(),
        files: HashMap::new()
    }));

    println!("Server running at http://127.0.0.1:{listen_port}");

    HttpServer::new(move || {
        //let cors = Cors::default().allow_any_origin().send_wildcard();
        let cors = Cors::default().allow_any_origin();
        App::new()
            .wrap(Logger::default())
            .wrap(cors)
            .app_data(web::Data::new(shared_state.clone()))
            .service(root)
            .service(get_sources)
            .service(get_source)
            .service(get_sources_observations)
            .service(get_all_by_date)
            .service(get_by_isin)
            .service(get_tickers)
            .service(get_by_tickers)
            .service(get_certs_and_tickers)
    })
    .bind(("0.0.0.0", listen_port))?
    .run()
    .await
 
}

// handler for GET /
#[get("/")]
async fn root() -> &'static str {
    "IC Data Extraction Service is running."
}

fn check_dtime(source: &str, dt: &str, output_fp_prefix: &str) -> String {
    if dt.to_lowercase().trim() == "latest" {
        println!("latest required at {}, {}", output_fp_prefix, source);
        // read directory and get latest file
        match get_latest_dtime(source, output_fp_prefix) {
            Ok(latest_dt) => {
                println!("latest observation datetime: {}", latest_dt);
                return latest_dt;
            },
            Err(e) => {
                println!("Error getting latest observation datetime: {}", e);
                return "1900-01-01-00-00-00.csv".to_string();
            }
        }
    }
    // naive format %Y-%m-%d-%H-%M-%S checker
    // let parts: Vec<&str> = dt.split('-').collect();
    // if parts.len() == 6 {
    [dt,".csv"].concat()
    // }else{
    //     Err(anyhow!("observation date format not valid"))
    // }
}

fn get_latest_dtime(source: &str, arg: &str) -> Result<String, io::Error> {
    let mut latest_time = "1900-01-01-00-00-00.csv".to_string();
    let dir_path = [arg, source].concat();
    println!("get_latest_dtime path: {}", dir_path);
    if !std::path::Path::new(&dir_path).exists() {
        println!("Directory {} does not exist", dir_path);
        return Ok(latest_time);
    }
    for entry in std::fs::read_dir(dir_path).unwrap() {
        // file format is <obsdatetime>.csv
        let entry = entry.unwrap(); 
        // get observation datetime from filename
        let filename = entry.file_name().into_string().unwrap();
        println!("latest: {}", filename);
        //let obsdatetime = filename[..filename.rfind('.').unwrap()].to_string();
        // observation datetime is in format YYYY-MM-DD-HH-MM-SS
        if filename > latest_time {
            latest_time = filename;
        }
    }
    // return latest time  
    Ok(latest_time)
}

fn get_latest_observations(shared_state: &ContentSystem, source: &str, maxobs: usize) -> Vec<String> {
    let options = MatchOptions {
        case_sensitive: false,
        require_literal_separator: false,
        require_literal_leading_dot: false,
    };
    let mut obsdatetimes = Vec::new();
    let mut max_entries = maxobs;
    for entry in glob_with(&format!("{}{}/*.csv", shared_state.output_path_prefix, source), options).unwrap() {
        if let Ok(path) = entry {
            //let filename = String::from(path.to_str().unwrap());
            // filename is in format <obsdatetime>.csv and <source> length is variable, so split at first '-' and get obsdatetime and remove .csv extension
            // let obsdatetime = (filename.split_at(filename.find('-').unwrap_or(0)+1).1).to_string();
            // let obsdatetime = filename.strip_suffix(".csv").unwrap().to_string();//.unwrap_or(&obsdatetime).to_string(); // TODO: return Vec<&str> is better?

            obsdatetimes.push(path.file_stem().unwrap().to_str().unwrap().to_string());
            max_entries -= 1;
            if max_entries == 0 {
                break;
            }
        }
    }
    // sort obsdatetimes in descending order
    // obsdatetimes.sort_by(|a, b| b.cmp(a));
    obsdatetimes
}

fn get_ds_name(shared_state: &ContentSystem, source: Option<&str>, obsdatetime: Option<&str>) -> String {
    if obsdatetime.is_some() {
        // means the request is about a specific observation filename => quotes to read
        let dt = check_dtime(&source.unwrap_or("404"), &obsdatetime.unwrap(), &shared_state.output_path_prefix);
        // dt should end with .csv
        return format!("{}{}/{}", shared_state.output_path_prefix, source.unwrap_or("404"), dt);
    } else {
        if source.is_some() {
            // means a specific source is requested => isins to read
            return format!("{}{}.csv", shared_state.isin_path_prefix, source.unwrap());
        } 
        return shared_state.source_path.clone();
    };
}

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

// sanity check for input parameters: only allow alphanumeric characters, hyphens and underscores, and trim whitespace
fn sanitize_input(input: &str) -> String {
    input.trim().replace(|c: char| !c.is_alphanumeric() && c != '-' && c != '_', "")
}


// check if response is empty or contains only header or nodata found
fn check_response(response: &Vec<String>, info: String) -> bool {
    if response.len() <= 0 
        || response[0] == ic_csv::NODATA_FOUND 
        || (response.len() == 1 && response[0].starts_with("isin,")) {
        //response.push(info);
        return true;
    }
    return false;
}

#[get("/sources")]
/* returns list of sources */
async fn get_sources(
    data: web::Data<SharedMap>,
) -> impl Responder {
    // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, None, None);
    // let ds_file = get_ds(ds_path, &data);
    let sources: Vec<String> = read_csv(&ds_path, None, true).await;
    HttpResponse::Ok()
        .content_type("application/json")
        // .append_header((header::ALLOW, "*"))
        .json(sources)
}

#[get("/isins/{source}")]
/* returns list of ISINs per source */
async fn get_source(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
) -> impl Responder {
    let source = sanitize_input(&path.into_inner());
    // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, Some(&source), None);
    let sources: Vec<String> = read_csv(&ds_path, None, false).await;

    if check_response(&sources, format!("source {} not found", source)) {
        return HttpResponse::NotFound()
            .content_type("application/json")
            .json(sources);
    }
    HttpResponse::Ok()
        .content_type("application/json")
        .json(sources)
}

#[get("/observations/{source}/{maxobs}")]
/* returns list of latest (maxobs) observations per source */
async fn get_sources_observations(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String)>,
) -> impl Responder {
    let (source, maxobsStr) = path.into_inner();
    let source = sanitize_input(&source);
    let mut maxobs = maxobsStr.parse::<usize>().unwrap_or(1000);
    // check if maxobs <=0 then return latest 1000 observations
    if maxobs <= 0 {
        maxobs = 1000;
    }
    // obtain shared state
    let shared_state = data.lock().unwrap();
    let obsdatetimes = get_latest_observations(&shared_state, &source, maxobs);
    if check_response(&obsdatetimes, format!("source {} not found", source)) {
        return HttpResponse::NotFound()
            .content_type("application/json")
            .json(obsdatetimes);
    }
    HttpResponse::Ok()
        .content_type("application/json")
        .json(obsdatetimes)
}

#[get("/quotes/{source}/{obsdatetime}")]
/* returns list of quotes (all ISINs) per source and observation date */
async fn get_all_by_date(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String)>
) -> impl Responder { 
    let (source, obsdatetime) = path.into_inner();
    let source = sanitize_input(&source);
    let obsdatetime = sanitize_input(&obsdatetime);
        // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, Some(&source), Some(&obsdatetime));
    let sources: Vec<String> = read_csv(&ds_path, None, true).await;
    if check_response(&sources, format!("source {} or observation {} not found", source, obsdatetime)) {
        return HttpResponse::NotFound()
            .content_type("application/json")
            .json(sources);
    }
    HttpResponse::Ok()
        .content_type("application/json")
        .json(sources)
}

#[get("/quotes/{source}/{obsdatetime}/{isin}")]
/* returns a specific quote (ISIN) per source and observation date */
async fn get_by_isin(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String, String)>
) -> impl Responder {
    let (source, obsdatetime, isin) = path.into_inner();
    let source = sanitize_input(&source);
    let obsdatetime = sanitize_input(&obsdatetime);
    let isin = sanitize_input(&isin);
        // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, Some(&source), Some(&obsdatetime));
    let sources: Vec<String> = read_csv(&ds_path, Some(&isin), true).await;
    if check_response(&sources, format!("source {} or observation {} or ISIN {} not found", source, obsdatetime, isin)) {
        return HttpResponse::NotFound()
            .content_type("application/json")
            .json(sources);
    }
    HttpResponse::Ok()
        .content_type("application/json")
        .json(sources)
}

#[get("/certificates")]
/* returns certificates by ticker list as query string ?tickers={ticker_csv_list} */
async fn get_by_tickers(
    data: web::Data<SharedMap>,
    query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let ticker_csv_list = query.get("tickers").unwrap_or(&"".into()).to_string();
    let ticker_csv_list = sanitize_input(&ticker_csv_list);
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // create a vector of 10 dummy certificates for testing. Each entry should be in format <isin>,<certificate name>,<ask>,<bid>,<currency>,<obsdatetime>
    // first row is the header
    // the vector is composed of 10 certificates with the same ticker but different ISINs and certificate names, and the same ask, bid, currency and obsdatetime
    let mut certificates = Vec::new();
    certificates.push("isin,certificate name,ask,bid,currency,obsdatetime".to_string());
    let mut rng = rand::rng();
    for i in 1..=10 {
        // random ask and bid values between 100 and 110 for ask, and between 90 and 100 for bid
        // create a random number using Rnd library
        let isin = format!("US{:0>10}", rng.random::<u64>() % 10000000);
        let ask = rng.random::<u32>() % 10 + 98;
        let bid = rng.random::<u32>() % 10 + 100;
        certificates.push(format!("{},Certificate {},{},{},USD,2024-06-01-12-00-{}", isin, i, ask, bid, (i % 10) + 10));
    }
    HttpResponse::Ok()
        .content_type("application/json")
        .json(certificates)
}

#[get("/tickers/{matcher}")]
/* returns list of latest (maxobs) observations per source */
async fn get_tickers(
    data: web::Data<SharedMap>,
    path: web::Path<(String)>,
) -> impl Responder {
    let matcher = path.into_inner();
    let matcher = sanitize_input(&matcher);
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // create a vector of dummy tickers for testing. Each entry should be in format <ticker>,<name>
    let tickers = vec!["AAPL,Apple Inc.".to_string(), "MSFT,Microsoft Corp.".to_string(), "GOOGL,Alphabet Inc.".to_string()];
    HttpResponse::Ok()
        .content_type("application/json")
        .json(tickers)
}

#[get("/certificates-tickers/{certs_csv_list}")]
/* returns certificates by ticker */
async fn get_certs_and_tickers(
    data: web::Data<SharedMap>,
    path: web::Path<(String)>
) -> impl Responder {
    let (certs_csv_list) = path.into_inner();
    let certs_csv_list = sanitize_input(&certs_csv_list);
    // obtain shared state
    let shared_state = data.lock().unwrap();
    // create a vector of 10 dummy certificates for testing. Each entry should be in format <isin>,<certificate name>,<ask>,<bid>,<currency>,<obsdatetime>
    // first row is the header
    // the vector is composed of 10 certificates with the same ticker but different ISINs and certificate names, and the same ask, bid, currency and obsdatetime
    let mut certificates = Vec::new();
    //certificates.push("certificate name ISIN,ticker name ISIN".to_string());
    certificates.push("IT32840834324, Certificate ABC ,AAPL, Apple Inc. ".to_string());
    certificates.push("IT32840834324, Certificate ABC ,MSFT, Microsoft Corp. ".to_string());
    certificates.push("IT32840834324, Certificate ABC ,TSLA, Tesla Inc. ".to_string());
    certificates.push("IT32840834324, Certificate ABC ,AMZN, Amazon.com Inc. ".to_string());
    certificates.push("IT32840834328, Certificate 123 ,META, Facebook Inc. ".to_string());
    certificates.push("IT32840834328, Certificate 123 ,TSLA, Tesla Inc. ".to_string());
    certificates.push("IT32840834328, Certificate 123 ,Salesforce.com Inc. CRM".to_string());
    certificates.push("IT32840834331, Certificate DDDD QWERTY ,TSLA, Tesla Inc. ".to_string());
    certificates.push("IT32840834331, Certificate DDDD QWERTY ,ADBE, Adobe Inc. ".to_string());
    certificates.push("IT32840834331, Certificate DDDD QWERTY ,CRM, Salesforce.com Inc. ".to_string());
    certificates.push("IT32840834674, Certificate Booster NAP ,AAPL, Apple Inc. ".to_string());
    certificates.push("IT32840834674, Certificate Booster NAP ,TSLA, Tesla Inc. ".to_string());
    certificates.push("IT32840834675, Certificate Booster ,MSFT, Microsoft Corp. ".to_string());
    HttpResponse::Ok()
        .content_type("application/json")
        .json(certificates)
}

fn read_file_lines(path: &str, isin: &str) -> io::Result<Vec<String>> {
    // Open the file
    let file = File::open(path)?;
    let reader = BufReader::new(file);

    // Collect lines into a Vec<String>
    let lines: io::Result<Vec<String>> = reader
        .lines() // Iterator over Result<String, io::Error>
        .collect();

    lines
}


