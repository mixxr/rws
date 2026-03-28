use clap::*;
use commons::definitions::globals::*; 
/*
pub const ISIN_PATH_PREFIX: &str = "data/";
pub const OUTPUT_PATH_PREFIX: &str = "data/output/";
pub const SOURCE_PATH: &str = "data/sources.txt"; 
*/

#[derive(Parser, Debug)]
#[command(version, about = "Digital Posture RegEx2", long_about = None)]
pub struct Args {
    /// Config k-v file path 
    #[arg(short, long)]
    pub config: String,

    /// Input dir path 
    #[arg(short, long)]
    pub input_dir: String,

    /// Output file format [json|sql|csv] 
    #[arg(short = 'f', long, default_value = "json")]
    pub output_format: String,

    /// Output dir path
    #[arg(short = 'o', long, default_value = "./")]
    pub output_dir: String,
}