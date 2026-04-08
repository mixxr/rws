use std::{env};



use std::sync::{Arc, Mutex};
use actix_cors::Cors;

use actix_web::middleware::Logger;
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
//use serde::Serialize;
use env_logger::Env;
use glob::glob_with;
use glob::MatchOptions;

// use tracing::info;

use google_cloud_storage::client::Storage;
use futures::StreamExt; // for `next()` on the reader stream
use cloud_storage::Object;
 
#[derive(Debug, Clone)]
struct ContentSystem {
    quotes_path: String,
    bucket_name: String,
    mount_dir: String,
    storage: Storage,
}

// Type alias for shared state
type SharedMap = Arc<Mutex<ContentSystem>>;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let log_level = "debug";
    let log_level = env::var("LOG_LEVEL").unwrap_or_else(|_| log_level.to_string());

    let bucket_name = "projects/_/buckets/rws-data";
    let bucket_name = env::var("BUCKET_NAME").unwrap_or_else(|_| bucket_name.to_string());

    let mount_dir = "/data";
    let mount_dir = env::var("MOUNT_DIR").unwrap_or_else(|_| mount_dir.to_string());
    
    let quotes_path = "/quotes/jobs/";
    let quotes_path = env::var("QUOTES_PATH").unwrap_or_else(|_| quotes_path.to_string());

    let listen_port = "8080";
    let listen_port = env::var("LISTEN_PORT").unwrap_or_else(|_| listen_port.to_string()).parse::<u16>()
        .expect("Invalid LISTEN_PORT, must be a number between 0 and 65535");
    // check if quotes_path starts and ends with '/' if not add it
    let quotes_path = if !quotes_path.starts_with('/') {
        format!("/{}", quotes_path)
    } else {
        quotes_path.to_string()
    };  
    let quotes_path = if !quotes_path.ends_with('/') {
        format!("{}/", quotes_path)
    } else {
        quotes_path.to_string()
    };

    println!("ENV Configuration: {quotes_path}, {bucket_name}, {mount_dir}, {listen_port}, {log_level}");

    env_logger::init_from_env(Env::default().default_filter_or(log_level));

    let storage = Storage::builder()
        .build()
        .await
        .expect("Failed to create Storage client");

    let shared_state: SharedMap = Arc::new(Mutex::new(ContentSystem {
        quotes_path: quotes_path.to_string(),
        bucket_name: bucket_name.to_string(),
        mount_dir: mount_dir.to_string(),
        storage: storage
    }));

    let if_addr = "0.0.0.0";
    println!("Server running at http://{if_addr}:{listen_port}");

    HttpServer::new(move || {
        //let cors = Cors::default().allow_any_origin().send_wildcard();
        let cors = Cors::default().allow_any_origin();
        App::new()
            .wrap(Logger::default())
            .wrap(cors)
            .app_data(web::Data::new(shared_state.clone()))
            .service(root)
            .service(get_quotes_jobs)
            .service(get_quotes_job_file)
    })
    .bind((if_addr, listen_port))?
    .run()
    .await
 
}

// handler for GET /
#[get("/")]
async fn root() -> &'static str {
    "Job Monitor Service is running."
}


fn get_file_list(shared_state: &ContentSystem, path: &str, maxobs: usize) -> Vec<String> {
    let options = MatchOptions {
        case_sensitive: false,
        require_literal_separator: false,
        require_literal_leading_dot: false,
    };
    let mut file_list = Vec::new();
    let mut max_entries = maxobs;
    for entry in glob_with(&format!("{}{}/*", shared_state.mount_dir, path), options).unwrap() {
        if let Ok(fpath) = entry {
            //let filename = String::from(path.to_str().unwrap());
            // filename is in format <obsdatetime>.csv and <source> length is variable, so split at first '-' and get obsdatetime and remove .csv extension
            // let obsdatetime = (filename.split_at(filename.find('-').unwrap_or(0)+1).1).to_string();
            // let obsdatetime = filename.strip_suffix(".csv").unwrap().to_string();//.unwrap_or(&obsdatetime).to_string(); // TODO: return Vec<&str> is better?

            file_list.push(fpath.file_stem().unwrap().to_str().unwrap().to_string());
            max_entries -= 1;
            if max_entries == 0 {
                break;
            }
        }
    }
    // sort obsdatetimes in descending order
    // obsdatetimes.sort_by(|a, b| b.cmp(a));
    file_list
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
// fn sanitize_input(input: &str) -> String {
//     input.trim().replace(|c: char| !c.is_alphanumeric() && c != '-' && c != '_', "")
// }


// check if response is empty or contains only header or nodata found
// fn check_response(response: &Vec<String>, info: String) -> bool {
    
//     return false;
// }

#[get("/quotes/jobs/{dt}/{logtype}")]
// /quotes/jobs/:dt/:logtype[f2, bq] -> log file DT
async fn get_quotes_job_file(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String)>,
) -> impl Responder {
    let (dt, logtype) = path.into_inner();
    // let bucket = std::env::var("BUCKET_NAME")
    //      .map_err(|_| "Configuration error, please contact service administrator.".to_string())?;

    // check if dt is in the correct format (e.g. 2024-06-01T12:00:00Z)
    if !dt.chars().all(|c| c.is_digit(10) || c == '-' || c == 'T' || c == ':' || c == 'Z') {
        return HttpResponse::NotFound()
            .content_type("text/plain; charset=utf-8")
            .body("Invalid datetime format, must be in ISO 8601 format (e.g. 2024-06-01T12:00:00Z)");
    }
    // check if logtype is either "f2" or "bq"
    if logtype != "f2" && logtype != "bq" {
        return HttpResponse::NotFound()
            .content_type("text/plain; charset=utf-8")
            .body("Invalid log type, must be 'f2' or 'bq'");
    }
    let shared_state = data.lock().unwrap();
    let name = format!("{}{}.{logtype}.done", shared_state.quotes_path, dt);
    // Read object as a stream of chunks
    // let mut reader = shared_state.storage
    //     .read_object(&shared_state.bucket_name, &name)
    //     .send()
    //     .await
    //     .map_err(|_| format!("Error starting download: {dt}{logtype}."));

    // let mut contents = Vec::new();
    // while let Some(chunk) = reader.next().await.transpose().map_err(|e| format!("Read error: {e}"))? {
    //     contents.extend_from_slice(&chunk);
    // }
    let object = Object::read(&shared_state.bucket_name, &name).await?;
    println!("Object name: {name}, {}", object.name);
    println!("Size: {} bytes", object.size);
    let bytes = Object::download(&shared_state.bucket_name, &name).await?;

    HttpResponse::Ok()
        .content_type("text/plain; charset=utf-8")
        .body(String::from_utf8(bytes).map_err(|_| "File is not valid UTF-8".to_string()))?
}


#[get("/quotes/jobs")]
/* returns list of jobs */
async fn get_quotes_jobs(
    data: web::Data<SharedMap>,
    // path: web::Path<(String, String)>,
) -> impl Responder {
    // let (source, maxobsStr) = path.into_inner();
    // let source = sanitize_input(&source);
    // let mut maxobs = maxobsStr.parse::<usize>().unwrap_or(1000);
    // // check if maxobs <=0 then return latest 1000 observations
    // if maxobs <= 0 {
    //     maxobs = 1000;
    // }

    let shared_state = data.lock().unwrap();
    let files = get_file_list(&shared_state, &shared_state.quotes_path, 1000);

    HttpResponse::Ok()
        .content_type("application/json")
        .json(files)
}




