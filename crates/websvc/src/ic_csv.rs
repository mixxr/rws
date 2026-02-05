use std::{error::Error, io};

use tokio::{fs::{self, File}, io::{AsyncBufReadExt, AsyncWriteExt, BufReader}};

pub async fn read_csv(file_path: &str, isin: &str, has_header: bool) -> Vec<String> {
    let isin = isin.trim(); // TODO: sanification
    let mut is_header = has_header;
    match File::open(file_path).await {
        Err(why) => {
            eprintln!("couldn't open {}: {}", file_path, why);
            return Vec::new();
        }
        Ok(file) => {
            let mut rv: Vec<String> = Vec::new();
            let reader = BufReader::new(file);
            let mut lines = reader.lines();
            while let Some(line) = lines.next_line().await.unwrap() {
                let line = line.trim();
                if line.len() <= 0 {
                    continue;
                }
                if !is_header {
                    let cols = line.split(",").collect::<Vec<&str>>();
                    if isin.len() > 0 && isin != cols[0] {
                        continue;
                    }
                    is_header = false;
                }
                rv.push(line.to_string());
            }
            return rv;
        }
    }
}

pub async fn write_csv(file_path: &str, lines: Vec<String>) {
    let mut file = match File::open(file_path).await {
        Ok(file) => file,
        Err(e) if e.kind() == io::ErrorKind::NotFound => {
            File::create(file_path).await.unwrap()
        }
        Err(e) => {
            let tmp_file_path = &["/tmp/", &file_path.split("/").last().unwrap()].concat();
            eprintln!("Cannot create file {} due to {} and created a tmp file {}", file_path, e, tmp_file_path);
            File::create(tmp_file_path).await.unwrap()
        },
    };
    let content = lines.join("\n");
    //fs::write(file_path, content).await;
    //let mut file = fs::File::create(file_path).await?;
    file.write_all(content.as_bytes()).await;
    file.flush().await;
}
