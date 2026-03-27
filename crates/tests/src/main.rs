use std::io::{self};

use std::fs::File;
use std::io::BufReader;
use std::io::prelude::*;

#[derive(Debug, serde::Deserialize, serde::Serialize)]
struct Certificate {
    isin: String,
    name: String,
    tickers: String,
    start_date: String,
    end_date: String,
}

#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
struct Quote {
    isin: String,
    obs_dt: String,
    ask: f32,
    bid: f32,
    currency: String,
}

fn insert_certificates(cs: Vec<Certificate>) -> Vec<String> {
    let db = env.d1("DB")?;
    let query = db.prepare("INSERT INTO certificate VALUES (?,?,?,?,?)");
    let mut result = Vec<String>::new();
    for c in cs {
        let r = query.bind(&[c.isin.into(), c.name.into(), c.tickers.into(), c.start_date.into(), c.end_date.into()])?.run().await?;
        result.push(r);
    }
    result
}

fn insert_quotes(cs: Vec<Quote>) -> Vec<String> {
    let db = env.d1("DB")?;
    let query = db.prepare("INSERT INTO quote VALUES (?,?,?,?,?)");
    let mut result = Vec<String>::new();
    for c in cs {
        let r = query.bind(&[c.isin.into(), c.obs_dt.into(), c.ask.into(), c.bid.into(), c.currency.into()])?.run().await;
        result.push(r);
    }
    result
}

fn read_kv_file(path: &str) -> io::Result<std::collections::HashMap<String, String>> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let mut map = std::collections::HashMap::new();

    for (line_num, line) in reader.lines().enumerate() {
        let line = line?; // Handle I/O errors per line

        // Skip empty lines and comments
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }

        // Split into key and value
        if let Some((key, value)) = trimmed.split_once('=') {
            map.insert(key.trim().to_string(), value.trim().to_string());
        } else {
            eprintln!("Warning: Invalid format at line {}: '{}'", line_num + 1, trimmed);
        }
    }

    Ok(map)
}

fn extract_value(content_str: &str, pattern: &str) -> String {
    //Print the contents
    // println!("{} {}", &content_str[..50], pattern);
    /*
    let start_key = contents.find("POWER_SUPPLY_CAPACITY").unwrap();
contents = contents[start_key..];
let start_value = contents.find(|c| c.is_digit(10)).unwrap(); // is_digit is a method on characters.
contents = contents[start_value..];
let end_value = contents.find(|c| !c.is_digit(10)).unwrap();
contents = contents[..end_value];
*/
    /*
    contents.lines()
    .find(|s| s.contains("POWER_SUPPLY_CAPACITY"))
    .nth(0 as usize)
    .unwrap()
    .split("=")
    .nth(1 as usize)
    .unwrap()
    .parse::<i32>()
    */
    let rx = regex::Regex::new(&pattern).unwrap();
    let Some(caps) = rx.captures(&content_str) else { return "".to_string()};
    caps[1].to_string()
    // let rx_bid = regex::Regex::new(r"\*\*([0-9]+\.[0-9]+)\*\*LETTERA").unwrap();
    // let Some(caps_bid) = rx_bid.captures(&content_str) else { return };
    // println!("bid {}, {}", &caps_bid[1], caps_bid.len())

}

fn read_file(path: &str, max_len: usize) -> String {
    let f = File::open(path).expect("Can't find file!");
    // let mut reader = BufReader::with_capacity(1000,f);
    
    // let mut contents = String::with_capacity(1000);

    // //Read the entire file as a string
    // reader.read_to_string(&mut contents).expect("Can't read file!");

    let mut reader = BufReader::new(f);

    // Read first 100 bytes
    let mut buffer = vec![0; max_len];
    let bytes_read = reader.read(&mut buffer).unwrap();

    // Trim unused bytes and convert to string (if UTF-8)
    let contents = String::from_utf8_lossy(&buffer[..bytes_read]);
    contents.to_string()
}

fn extract_certificates() -> Vec<Certificate> {
    let mut cs: Vec<Certificate> = Vec::new();
    for i in 1..10 {
        let c = Certificate {
            isin: String::from("IT000002"),
            name: String::from("Cert 0002"),
            tickers: String::from("t1000,t2000,t3000,"),
            start_date: String::from("2026-01-01"),
            end_date: String::from("2029-01-01"),
        };
        cs.push(c);
    }
    cs
}

fn extract_quote(isin: &str, dt: &str, content_str: &str, map: &std::collections::HashMap<String, String>) -> Quote {
    let c = Quote {
        isin: String::from(isin),
        obs_dt: String::from(dt),
        ask: extract_value(content_str, &map["ASK"]).parse::<f32>().unwrap_or(0.0),
        bid: extract_value(content_str, &map["BID"]).parse::<f32>().unwrap_or(0.0),
        currency: String::from("EUR"), // TO DO: via regex
    };
    c
}

fn main() -> std::process::ExitCode {
    let args: Vec<String> = std::env::args().collect();
    if args.len() <= 2 {
        eprintln!("Please provide k-v config and file as argumnts!");
        return std::process::ExitCode::from(1);
    }
    match read_kv_file(&args[1]) {
        Ok(map) => {
            println!("Loaded {} entries:", map.len());
            for (key, value) in &map {
                println!("{} => {}", key, value);
            }
            let max_len = map["LEN"].parse::<usize>().unwrap_or(5000);
            let content_str = read_file(&args[2], max_len);
            println!("First bytes:{}", &content_str[..100]);
            println!("ASK: {}", extract_value(&content_str, &map["ASK"]));
            println!("BID: {}", extract_value(&content_str, &map["BID"]));
            //extract_value(&content_str, "rxStr");
            // let cs = extract_certificates();
            // let r = insert_certificates(cs);
            // println!("Results for {}: {}", cs, r);
            let isin = &args[2].split('.').next().unwrap();
            let dt = "2026-03-27 09:00:00";
            let q = extract_quote(&isin, &dt, &content_str, &map);
            let r2 = insert_quotes(vec![q]);
            println!("Results for {:?}: {:?}", q.clone(), r2);
        }
        Err(e) => eprintln!("Error reading file: {}", e),
    }
    std::process::ExitCode::SUCCESS
}
