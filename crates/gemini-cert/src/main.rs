use google_ai_rs::{Client, AsSchema};
//use google_ai_rs::Tool;
use serde::*;
use std::fs::File;
use std::io::Write;
use rand::Rng;
use tokio::time::{sleep, Duration};
// use gcp_bigquery_client::Client as BQClient;
// use gcp_bigquery_client::model::table_data_insert_all_request::TableDataInsertAllRequest;

mod definitions;
use clap::Parser;
use definitions::args::Args;
use std::io::{BufRead, BufReader};

#[derive(Serialize, Deserialize, AsSchema, Debug)]
struct StockInfo {
    certificate_isin: String,
    stock_name: String,
    stock_google_finance_ticker: String,
    stock_isin: String,
    stock_exchange: String,
    stock_sector: String,
    stock_industry: String,
    stock_tags: String,
}

#[derive(Serialize, Deserialize, AsSchema, Debug)]
struct CertificateResponse {
    certificate_isin: String,
    certificate_issuer: String,
    underlyings: Vec<StockInfo>,
}

#[derive(Debug)]
struct ModelQuota {
    model_name: String,
    rpm: f32,
}

fn read_quotas_simple(path: &str) -> Vec<ModelQuota> {
    let mut quotas = Vec::new();

    // 1. Open the file
    let file = File::open(path).expect("Could not open file");
    let reader = BufReader::new(file);

    // 2. Iterate over each line
    for line in reader.lines() {
        if let Ok(content) = line {
            // 3. Split by comma
            let parts: Vec<&str> = content.split(',').collect();
            
            if parts.len() == 2 {
                let name = parts[0].trim().to_string();
                let rpm = parts[1].trim().parse::<f32>().unwrap_or(0.0);
                
                quotas.push(ModelQuota { model_name: name, rpm });
            }
        }
    }

    quotas
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();
    
    env_logger::init();

    println!("Configuration: {:?}, Log Level: {}", args, std::env::var("RUST_LOG").unwrap_or("ERROR".to_string()));
    
    let content = std::fs::read_to_string(&args.isin_path)
        .map_err(|_| "Please provide a valid text file containing the certificate description")?;

    let model_list: Vec<ModelQuota> = match args.model_list_path {
        Some(path) => {
            log::debug!("Loading models from: {}", path);
            read_quotas_simple(&path)
        },
        None => {
            log::debug!("No model list provided. Using default: {}", &args.model);
            vec![ModelQuota {
                model_name: args.model,
                rpm: args.rpm,
            }]
        }
    };

    let output_dir = &args.output_dir;
    // Ensure directory exists
    std::fs::create_dir_all(output_dir)?;

    let g_api_key = std::env::var("G_API_KEY").map_err(|_| "Configuration error, please contact service administrator.".to_string())?;
    let client = Client::new(g_api_key).await?;
    
    let mut model_position = args.model_pos;
    log::info!("Using model: {}", &model_list[model_position].model_name);
    // let search_tool = Tool {
    //     google_search: Some(Default::default()),
    //     ..Default::default()
    // };
    let mut model = client
        .typed_model::<CertificateResponse>(&model_list[model_position].model_name);
        // .tools(vec![search_tool]);

    let mut rpm = &model_list[model_position].rpm;
    let mut ave_wait = 60.0/rpm + 0.5;

    log::debug!("Processing ISIN: {}", &args.isin);

    // let response = model
    //     .generate_content(prompt)
    //     .await?;


    let mut attempts = 0;
    let isin = &args.isin;
    let response: CertificateResponse = loop {
        let prompt = format!(
            "what are the underlying stocks under the certificate {isin} based on {content}?"
        );
        log::debug!("Prompt: {prompt}");
        match model.generate_content(prompt).await {
            Ok(res) => break res, // Success! Exit the retry loop
            Err(e) => {
                attempts += 1;
                if attempts > args.retries {
                    log::error!("Final failure for ISIN {}: {}", isin, e);
                    return Err(e.into()); // Exit the program
                }
                
                let wait_time = attempts as u64 * 5; // Exponential-ish backoff
                log::warn!("Error fetching {}: {:.100}. Retry {}/{} in {}s...", isin, &e, attempts, args.retries, wait_time);
                sleep(Duration::from_secs(wait_time)).await;

                let error_msg = e.to_string();
                let is_rate_limited = error_msg.contains("ResourceExhausted") || error_msg.contains("429");
                if model_list.len() > 1 && is_rate_limited {
                    model_position = (model_position + 1) % model_list.len();
                    log::info!("Rate limit hit. Switching to model: {}", &model_list[model_position].model_name);
                    model = client
                        .typed_model::<CertificateResponse>(&model_list[model_position].model_name);
                        //.tools(vec![search_tool]);
                    rpm = &model_list[model_position].rpm;
                    ave_wait = 60.0/rpm + 0.5;

                }
            }
        }
    };

    log::debug!("Certificate: {:?}", response);

    // create a json file to store single certificate response
    let file_name = format!("{}.json", isin);
    let full_path = std::path::Path::new(output_dir).join(file_name);

    // Serialize and write
    let json_string = serde_json::to_string_pretty(&response)?;
    std::fs::write(&full_path, &json_string)?;
    log::debug!("File saved to: {:?}", full_path);

    // create a ndjson file to store underlyings if required
    if args.output_format == "ndjson" {
        let ndj_file_name = format!("{}-tickers.json", isin);
        let ndj_full_path = std::path::Path::new(output_dir).join(ndj_file_name);
        let mut file = File::create(&ndj_full_path)?;
        for stock in &response.underlyings {
            log::debug!("Writing json to {:?}...", &ndj_full_path);
            // ndJSON is 1 file containing multiple JSON objects, each in a new line
            serde_json::to_writer(&mut file, &stock).unwrap();
            // add a new line after each JSON object
            file.write_all(b"\n").unwrap();
        }
    }
    log::info!("{}, OK", isin.to_ascii_uppercase());

    if args.wait {
        let jitter = rand::thread_rng().gen_range(0.0..2.0);
        let delay_secs = (ave_wait + jitter) as u64;
        log::debug!("Waiting {} seconds before next request...", delay_secs);
        sleep(Duration::from_secs(delay_secs)).await;
    }

    Ok(())
}