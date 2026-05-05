use clap::*;
use commons::definitions::globals::*; 

#[derive(Parser, Debug)]
#[command(version, about = "Digital Posture IC Web Service", long_about = None)]
pub struct Args {
    /// Listen port
    #[arg(short, long)] 
    pub listen_port: Option<u16>,

    /// Output format
    #[arg(short = 'f', long, default_value = "csv")]
    pub output_format: String,

    #[arg(short = 's', long)]
    pub is_staging: Option<bool>,
}