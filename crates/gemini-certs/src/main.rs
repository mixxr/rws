use google_ai_rs::{Client, AsSchema};
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

#[derive(Serialize, Deserialize, AsSchema, Debug)]
struct StockInfo {
    certificate_isin: String,
    stock_name: String,
    google_finance_ticker: String,
    isin: String,
    exchange: String,
    stock_sector: String,
}

#[derive(Serialize, Deserialize, AsSchema, Debug)]
struct CertificateResponse {
    certificate_isin: String,
    certificate_issuer: String,
    underlyings: Vec<StockInfo>,
}



#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();
    
    env_logger::init();

    println!("Configuration: {:?}, Log Level: {}", args, std::env::var("RUST_LOG").unwrap_or("ERROR".to_string()));
    
    let content = std::fs::read_to_string(&args.isin_path)
        .map_err(|_| "Please provide a valid text file containing an ISIN list")?;

    // 2. Parse the <isin>,<name> format
    let isins: Vec<String> = content
        .lines()
        .filter(|line| !line.trim().is_empty())
        .filter_map(|line| {
            // Split by comma and take the first part
            line.split(',')
                .next()
                .map(|s| s.trim().to_string())
        })
        .collect();

    if isins.is_empty() {
        return Err("Please provide a valid text file containing an ISIN list".into());
    }

    let output_dir = &args.output_dir;
    // Ensure directory exists
    std::fs::create_dir_all(output_dir)?;

    let g_api_key = std::env::var("G_API_KEY").map_err(|_| "Configuration error, please contact service administrator.".to_string())?;
    let client = Client::new(g_api_key).await?;
    let model = client.typed_model::<CertificateResponse>("gemini-3-flash-preview");

    for isin in isins {
        log::debug!("Processing ISIN: {}", isin);

        let prompt = format!(
            "what are the ISINs underlying the certificate {}, please create a json containing stock name, google finance ticker, ISIN and exchange", 
            isin
        );
        let response = model
            .generate_content(prompt)
            .await?;

        log::debug!("Certificate: {:?}", response);
        // Directly access the structured data
        //println!("Certificate: {}", response.certificate_isin);
        // for stock in &response.underlyings {
        //     println!("- {} ({})", stock.stock_name, stock.isin);
        // }

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
        log::info!("{isin}, OK");
        let delay_secs = rand::thread_rng().gen_range(2..=5);
        log::debug!("Waiting {} seconds before next request...", delay_secs);
        sleep(Duration::from_secs(delay_secs)).await;
    }
    // TODO: remove lines here::86
    // 3. Save to BigQuery
    // let project_id = "your-gcp-project-id";
    // let dataset_id = "ISINs";
    // let table_id = "certificates";

    // // Initialize BQ Client (requires GOOGLE_APPLICATION_CREDENTIALS env var)
    // let bq_client = BQClient::from_service_account_key_file("/home/vscode/.config/gcloud/application_default_credentials.json").await?;

    // let mut insert_request = TableDataInsertAllRequest::new();
    // // BigQuery streaming works best with flat rows. 
    // // Here we insert the whole struct as one row (ensure your BQ table schema matches)
    // insert_request.add_row(None, &response)?;

    // bq_client
    //     .tabledata()
    //     .insert_all(project_id, dataset_id, table_id, insert_request)
    //     .await?;

    // println!("Data successfully streamed to BigQuery table {}.{}", dataset_id, table_id);

    Ok(())
}