use std::{env};
mod rwsio;
use rwsio::*;
mod utils;
use utils::*;

use std::sync::{Arc, Mutex};
use actix_cors::Cors;
use actix_web::middleware::Logger;
use actix_web::{App, HttpResponse, HttpServer, Responder, get, put, web};

use env_logger::Env;

// TO-DO: log level
 
#[derive(Debug, Clone)]
struct ContentSystem {
    quotes_path: String,
    bucket_name: String,
    mount_dir: String,
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

    // let storage = Storage::builder()
    //     .build()
    //     .await
    //     .expect("Failed to create Storage client");

    let shared_state: SharedMap = Arc::new(Mutex::new(ContentSystem {
        quotes_path: quotes_path.to_string(),
        bucket_name: bucket_name.to_string(),
        mount_dir: mount_dir.to_string(),
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
            .service(update_quotes_job_status)
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

#[put("/quotes/jobs/{dt}/{logtype}")]
// promote to 'done' a given job (dt and logtype)
async fn update_quotes_job_status(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String)>,
) -> impl Responder {
    let (dt, logtype) = path.into_inner();
    // validate input parameters
    if !validate_parameters(&dt, &logtype, &"partial".to_string()) {
        return HttpResponse::NotFound()
            .content_type("text/plain; charset=utf-8")
            .body("Invalid datetime format, must be in ISO 8601 format (e.g. 2024-06-01T12:00:00Z) or invalid logtype [f2|bq] or ext [partial|done].");
    }
    let shared_state = data.lock().unwrap();
    // update file status by renaming the file with new extension
    let old_file_path = format!("{}{}{}.{logtype}.partial", shared_state.mount_dir, shared_state.quotes_path, dt);
    let new_file_path = format!("{}{}{}.{logtype}.done", shared_state.mount_dir, shared_state.quotes_path, dt);
    if let Err(e) = std::fs::rename(&old_file_path, &new_file_path) {
        eprintln!("Failed to promote job status for {}.{}: {}", dt, logtype, e);
        return HttpResponse::InternalServerError()
            .content_type("text/plain; charset=utf-8")
            .body("Failed to promote job status.");
    }
    HttpResponse::Ok()
        .content_type("text/plain; charset=utf-8")
        .body("Job status promoted successfully.")
}

#[get("/quotes/jobs/{dt}/{logtype}/{ext}")]
// /quotes/jobs/:dt/:logtype[f2, bq] -> log file DT
async fn get_quotes_job_file(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String, String)>,
) -> impl Responder {
    let (dt, logtype, ext) = path.into_inner();
    // let bucket = std::env::var("BUCKET_NAME")
    //      .map_err(|_| "Configuration error, please contact service administrator.".to_string())?;

    if !validate_parameters(&dt, &logtype, &ext) {
        return HttpResponse::NotFound()
            .content_type("text/plain; charset=utf-8")
            .body("Invalid datetime format, must be in ISO 8601 format (e.g. 2024-06-01T12:00:00Z) or invalid logtype [f2|bq] or ext [partial|done].");
    }
    let shared_state = data.lock().unwrap();
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
    let file_path = format!("{}{}{}.{logtype}.{ext}", shared_state.mount_dir, shared_state.quotes_path, dt);
    let contents = read_file_as_string(&file_path).await;

    HttpResponse::Ok()
        .content_type("text/plain; charset=utf-8")
        .body(contents)
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
    let dir_path = format!("{}{}", shared_state.mount_dir, shared_state.quotes_path);
    let files = get_file_list(&dir_path, 1000);

    HttpResponse::Ok()
        .content_type("application/json")
        .json(files)
}



