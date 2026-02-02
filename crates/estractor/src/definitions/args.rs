use clap::*;
use crate::definitions::globals::*; 
/*
pub const ISIN_PATH_PREFIX: &str = "data/";
pub const OUTPUT_PATH_PREFIX: &str = "data/output/";
pub const SOURCE_PATH: &str = "data/sources.txt"; 
*/
#[derive(Parser, Debug)]
#[command(version, about = "Digital Posture RWS", long_about = None)]
pub struct Args {
    /// Source file path 
    #[arg(short, long, default_value = SOURCE_PATH)]
    pub source_fp: String,

    /// Source file path 
    #[arg(short, long, default_value = ISIN_PATH_PREFIX)]
    pub isin_fp_prefix: String,

    /// Output file path 
    #[arg(short, long, default_value = OUTPUT_PATH_PREFIX)]
    pub output_fp_prefix: String,

    /// Output format
    #[arg(short = 'f', long, default_value = "csv")]
    pub output_format: String,
}