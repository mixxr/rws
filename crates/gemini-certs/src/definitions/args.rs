use clap::*;

#[derive(Parser, Debug)]
#[command(version, about = "Digital Posture Gemini Certificate Get Tickers", long_about = None)]
pub struct Args {
    /// ISIN list file path 
    #[arg(short = 'i', long)]
    pub isin_path: String,

    /// Output file format [json|ndjson|csv] 
    #[arg(short = 'f', long, default_value = "ndjson", value_parser = ["json-only", "ndjson", "csv"])]
    pub output_format: String,

    /// Output dir path
    #[arg(short = 'o', long, default_value = "./")]
    pub output_dir: String,

        /// Gemini retries
    #[arg(short = 'r', long, default_value_t = 3)]
    pub retries: i8,

    /// Gemini model
    #[arg(short = 'm', long, default_value = "gemini-3-flash-preview")]
    pub model: String,

     /// Gemini model RPM
    #[arg(short = 'p', long, default_value_t = 10.0)]
    pub rpm: f32,  

     /// Gemini model list file path (to cycle on models if provided)
    #[arg(short = 'l', long)]
    pub model_list_path: Option<String>,
}