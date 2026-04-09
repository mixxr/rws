use google_ai_rs::{Client, AsSchema};
use serde::Deserialize;

#[derive(Deserialize, AsSchema, Debug)]
struct StockInfo {
    stock_name: String,
    google_finance_ticker: String,
    isin: String,
    exchange: String,
    stock_sector: String,
}

#[derive(Deserialize, AsSchema, Debug)]
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
    for stock in response.underlyings {
        println!("- {} ({})", stock.stock_name, stock.isin);
    }

    Ok(())
}