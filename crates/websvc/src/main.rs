use std::{error::Error, fs::File};
use std::io::{self, BufReader, prelude::*};
use std::collections::HashMap;

use std::sync::{Arc, Mutex};
use actix_web::middleware::Logger;
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
//use serde::Serialize;
use env_logger::Env;

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

fn check_dtime(dt: &str) -> String {
    if dt.to_lowercase() == "latest" {
        return "1900-01-01-00-00-00".to_string();
    }
    return dt.to_string();
}

fn get_ds_name(source: Option<&str>, obsdatetime: Option<&str>) -> String {
    let mut dt = "".to_string();
    let output_path = if obsdatetime.is_some() {
        dt = check_dtime(&obsdatetime.unwrap());
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


