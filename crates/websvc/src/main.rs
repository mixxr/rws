
use std::{error::Error, fs::File};
use std::io::{self, BufReader, prelude::*};
use std::collections::HashMap;

use std::sync::{Arc, Mutex};
use actix_web::middleware::Logger;
use actix_web::{App, HttpResponse, HttpServer, Responder, get, web};
//use serde::Serialize;
use env_logger::Env;
 
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
            .service(get_all_by_date)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
 
}

// handler for GET /
#[get("/")]
async fn root() -> &'static str {
    "Hello, world!"
}

#[get("/quotes/{source}/{obsdate}")]
async fn get_all_by_date(
    data: web::Data<SharedMap>,
    path: web::Path<(String, String)>
) -> impl Responder { 
    let (source, obsdate) = path.into_inner();
    let file_path = &["/workspaces/rws/crates/estractor/data/output/",&source,"-",&obsdate,".csv"].concat(); // Change to your file path
    println!("{source},{obsdate}, File is {} :", file_path);

    let mut map = data.lock().unwrap(); // Lock for write
    map.lastDate = obsdate;
    
    match read_file_lines(file_path, "all") {
        Ok(lines) => {
            println!("File has {} lines:", lines.len());
            for (i, line) in lines.iter().enumerate() {
                println!("{}: {}", i + 1, line);
            }
             HttpResponse::Ok()
            .content_type("application/json")
            .json(lines)
        }
        Err(e) => {
             HttpResponse::BadRequest()
                .content_type("application/json")
                .json(["not found"])
        },
    }
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


