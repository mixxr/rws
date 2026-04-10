use google_ai_rs::{Client, AsSchema};
use serde::*;
use gcp_bigquery_client::Client as BQClient;
use gcp_bigquery_client::model::table_data_insert_all_request::TableDataInsertAllRequest;

#[derive(Serialize, Deserialize, AsSchema, Debug)]
struct StockInfo {
    stock_name: String,
    google_finance_ticker: String,
    isin: String,
    exchange: String,
    stock_sector: String,
}

#[derive(Serialize, Deserialize, AsSchema, Debug)]
struct CertificateResponse {
    certificate_isin: String,
    underlyings: Vec<StockInfo>,
}



#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let g_api_key = std::env::var("G_API_KEY").map_err(|_| "Configuration error, please contact service administrator.".to_string())?;
    let client = Client::new(g_api_key).await?;
    let model = client.typed_model::<CertificateResponse>("gemini-3-flash-preview");

    let response = model
        .generate_content("What are the ISINs underlying certificate IT0006772062?")
        .await?;

    println!("Certificate: {:?}", response);
    // Directly access the structured data
    println!("Certificate: {}", response.certificate_isin);
    for stock in &response.underlyings {
        println!("- {} ({})", stock.stock_name, stock.isin);
    }

    let folder_path = "/tmp/data/certificates/";
    let file_name = format!("{}.json", response.certificate_isin);
    let full_path = std::path::Path::new(folder_path).join(file_name);

    // Ensure directory exists
    std::fs::create_dir_all(folder_path)?;

    // Serialize and write
    let json_string = serde_json::to_string_pretty(&response)?;
    std::fs::write(&full_path, &json_string)?;
    println!("File saved to: {:?}", full_path);

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