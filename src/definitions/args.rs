use clap::*;

#[derive(Parser, Debug)]
#[command(version, about = "Digital Posture RWS", long_about = None)]
pub struct Args {
    /// Source file path 
    #[arg(short, long, default_value = "data/sources.txt")]
    pub source_fp: String,

    /// Output format
    #[arg(short, long, default_value = "csv")]
    pub output_format: String,
}