use std::{error::Error, io};
use std::io::Read;
use glob::glob_with;
use glob::MatchOptions;
use tokio::{fs::{self, File}, io::{AsyncBufReadExt, AsyncWriteExt, BufReader}};

pub static NODATA_FOUND: &str = "No data found";

pub async fn read_file_as_string(file_path: &str) -> String {
    match std::fs::File::open(file_path) {
        Err(why) => {
            eprintln!("couldn't open {}: {}", file_path, why);
            return NODATA_FOUND.to_string();
        }
        Ok(mut file) => {
            let mut buffer = Vec::new();
            file.read_to_end(&mut buffer)
                .expect(NODATA_FOUND);
            String::from_utf8_lossy(&buffer).into_owned()
        }
    }
}

pub fn get_file_list(path: &str, maxobs: usize) -> Vec<String> {
    let options = MatchOptions {
        case_sensitive: false,
        require_literal_separator: false,
        require_literal_leading_dot: false,
    };
    let mut file_list = Vec::new();
    let mut max_entries = maxobs;
    println!("Reading files from path: {}* {}", path, maxobs);
    for entry in glob_with(&format!("{}*", path), options).unwrap() {
        if let Ok(fpath) = entry {
            //let filename = String::from(path.to_str().unwrap());
            // filename is in format <obsdatetime>.csv and <source> length is variable, so split at first '-' and get obsdatetime and remove .csv extension
            // let obsdatetime = (filename.split_at(filename.find('-').unwrap_or(0)+1).1).to_string();
            // let obsdatetime = filename.strip_suffix(".csv").unwrap().to_string();//.unwrap_or(&obsdatetime).to_string(); // TODO: return Vec<&str> is better?
            println!("Found file: {}", fpath.display());
            file_list.push(fpath.file_name().unwrap().to_str().unwrap().to_string());
            max_entries -= 1;
            if max_entries == 0 {
                break;
            }
        }
    }
    // sort obsdatetimes in descending order
    // obsdatetimes.sort_by(|a, b| b.cmp(a));
    file_list
}
