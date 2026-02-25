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
        let cors = Cors::default().send_wildcard();
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
        println!("latest required at {}", output_fp_prefix);
        // read directory and get latest file
        return get_latest_dtime(source, output_fp_prefix).expect("latest not available");
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

    for entry in std::fs::read_dir([arg, source].concat()).unwrap() {
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

fn add_info(mut response: Vec<String>, info: String) -> Vec<String> {
    if response.len() <= 0 
        || response[0] == ic_csv::NODATA_FOUND 
        || (response.len() == 1 && response[0].starts_with("isin,")) {
        response.push(info);
    }
    response
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
    let source = path.into_inner();
    // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, Some(&source), None);
    let sources: Vec<String> = read_csv(&ds_path, None, false).await;
    let sources = add_info(sources, format!("source {} not found", source));
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
    let mut maxobs = maxobsStr.trim().parse::<usize>().unwrap_or(1000);
    // check if maxobs <=0 then return latest 1000 observations
    if maxobs <= 0 {
        maxobs = 1000;
    }
    // obtain shared state
    let shared_state = data.lock().unwrap();
    let obsdatetimes = get_latest_observations(&shared_state, &source, maxobs);
    let obsdatetimes = add_info(obsdatetimes, format!("source {} not found", source));
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
        // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, Some(&source), Some(&obsdatetime));
    let sources: Vec<String> = read_csv(&ds_path, None, true).await;
    let sources = add_info(sources, format!("source {} or observation {} not found", source, obsdatetime));
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
        // obtain shared state
    let shared_state = data.lock().unwrap();
    let ds_path = get_ds_name(&shared_state, Some(&source), Some(&obsdatetime));
    let sources: Vec<String> = read_csv(&ds_path, Some(&isin), true).await;
    let sources = add_info(sources, format!("source {} or observation {} or ISIN {} not found", source, obsdatetime, isin));
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


