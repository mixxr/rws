use std::{error::Error, fs::File};
use std::io::{self, BufReader, prelude::*};
use std::collections::HashMap;

use std::sync::{Arc, Mutex};
use actix_web::middleware::Logger;
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
//use serde::Serialize;
use env_logger::Env;
use glob::glob_with;
use glob::MatchOptions;

mod ic_csv;
use ic_csv::*;


 
#[derive(Debug, Clone)]
struct ContentSystem {
    lastDate: String,
    files: HashMap<String, Arc<Mutex<File>>>,
}

// Type alias for shared state
type SharedMap = Arc<Mutex<ContentSystem>>;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port = 8080;
    let log_level = "debug";
    env_logger::init_from_env(Env::default().default_filter_or(log_level));

    

    let shared_state: SharedMap = Arc::new(Mutex::new(ContentSystem {
        lastDate: "1900-01-01-00-00-00".to_string(),
        files: HashMap::new()
    }));

    println!("Server running at http://127.0.0.1:{port}");

    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .app_data(web::Data::new(shared_state.clone()))
            .service(root)
            .service(get_sources)
            .service(get_source)
            .service(get_sources_observations)
            .service(get_all_by_date)
            .service(get_by_isin)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
 
}

// handler for GET /
#[get("/")]
async fn root() -> &'static str {
    "IC Data Extraction Service is running."
}

fn check_dtime(source: &str, dt: &str) -> String {
    if dt.to_lowercase().trim() == "latest" {
        // read directory and get latest file
        return get_latest_dtime(source, "../estractor/data/output");
    }
    return dt.to_string();
}

fn get_latest_dtime(source: &str, arg: &str) -> String {
    let mut latest_time = "1900-01-01-00-00-00".to_string();

    for entry in std::fs::read_dir(arg).unwrap() {
        // file format is <source>-<obsdatetime>.csv
        let entry = entry.unwrap(); 
        // get observation datetime from filename
        let filename = entry.file_name().into_string().unwrap();
        let obsdatetime = filename.split('-').nth(1).unwrap_or("").to_string();
        // observation datetime is in format YYYY-MM-DD-HH-MM-SS
        // check if source matches and if obsdatetime is greater than latest_time
        if filename.starts_with(source) && obsdatetime > latest_time {
            latest_time = obsdatetime;
        }
    }
    // return latest time  
    latest_time
}

fn get_latest_observations(source: &str, maxobs: usize) -> Vec<String> {
    let options = MatchOptions {
        case_sensitive: false,
        require_literal_separator: false,
        require_literal_leading_dot: false,
    };
    let mut obsdatetimes = Vec::new();
    let mut max_entries = maxobs;
    for entry in glob_with(&format!("../estractor/data/output/{}-*.csv", source), options).unwrap() {
        if let Ok(path) = entry {
            let filename = String::from(path.to_str().unwrap());
            // filename is in format <source>-<obsdatetime>.csv and <source> length is variable, so split at first '-' and get obsdatetime and remove .csv extension
            let obsdatetime = (filename.split_at(filename.find('-').unwrap_or(0)+1).1).to_string();
            let obsdatetime = obsdatetime.strip_suffix(".csv").unwrap_or(&obsdatetime).to_string();

            obsdatetimes.push(obsdatetime.clone());
            max_entries -= 1;
            if max_entries == 0 {
                break;
            }
        }
    }
    // sort obsdatetimes in descending order
    obsdatetimes.sort_by(|a, b| b.cmp(a));
    obsdatetimes
}

fn get_ds_name(source: Option<&str>, obsdatetime: Option<&str>) -> String {
    let mut dt = "".to_string();
    let output_path = if obsdatetime.is_some() {
        dt = check_dtime(&source.unwrap_or("sources"), &obsdatetime.unwrap());
        "/output"
    } else {
        ""
    };
    
    format!("../estractor/data{}/{}-{}.csv", output_path, source.unwrap_or("sources"), dt)
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

#[get("/sources")]
/* returns list of sources */
async fn get_sources(
    data: web::Data<SharedMap>,
) -> impl Responder {
    let ds_path = get_ds_name(None, None);
    // let ds_file = get_ds(ds_path, &data);
    let sources: Vec<String> = read_csv(&ds_path, None, true).await;
    HttpResponse::Ok()
        .content_type("application/json")
        .json(sources)
}

#[get("/sources/{source}")]
/* returns list of ISINs per source */
async fn get_source(
    data: web::Data<SharedMap>,
    path: web::Path<String>,
) -> impl Responder {
    let source = path.into_inner();
    let ds_path = get_ds_name(Some(&source), None);
    let sources: Vec<String> = read_csv(&ds_path, None, false).await;
    HttpResponse::Ok()
        .content_type("application/json")
        .json(sources)
}

#[get("/sources/{source}/observations/{maxobs}")]
/* returns list of latest (maxobs) observations per source */
async fn get_sources_observations(
    data: web::Data<SharedMap>,
    path: web::Path<(String, usize)>,
) -> impl Responder {
    let (source, mut maxobs) = path.into_inner();
    // TODO: check if maxobs <=0 then return latest 1000 observations
    if maxobs <= 0 {
        maxobs = 1000;
    }
    let obsdatetimes = get_latest_observations(&source, maxobs);
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
    let ds_path = get_ds_name(Some(&source), Some(&obsdatetime));
    let sources: Vec<String> = read_csv(&ds_path, None, true).await;
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
    let ds_path = get_ds_name(Some(&source), Some(&obsdatetime));
    let sources: Vec<String> = read_csv(&ds_path, Some(&isin), true).await;
    HttpResponse::Ok()
        .content_type("application/json")
        .json(sources)
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


