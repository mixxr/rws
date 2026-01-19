
mod definitions;
mod utils;

use definitions::globals::DEF_PRICE;
use definitions::types::*;
use utils::price_formatter;

use chrono;
// use csv::Writer;
use reqwest::Client;
use scraper::{Html, Selector};
use std::fs::{self, File};
use std::io::{BufReader, prelude::*};
use std::path::Path;
// use std::result;
use regex::Regex;
use std::sync::{Arc, Mutex};
use std::{env, error::Error, time::Duration};
use tokio; // Async runtime


fn get_ask_price_selector(site: &str) -> Result<Selector, &'static str> {
    match site.trim() {
        "" => Err("invalid site"),
        "marex" => Ok(Selector::parse("#product-ask-price").unwrap()),
        "bnp" => Ok(Selector::parse(r#"span[data-field="ask"]"#).unwrap()),
        // "vontobel" => Ok(Selector::parse(r#"h2[data-testid="buy_price_label"]"#).unwrap()),
        _ => Err("site not found"),
    }
}

fn get_ask_price_pattern(site: &str) -> Result<Regex, &'static str> {
    let vp = r#"\"ask\":[0-9]+\.?[0-9]*,"#;
    match site.trim() {
        "" => Err("invalid site"),
        "vontobel" => Ok(Regex::new(vp).unwrap()), // "ask":[0-9]+\.?[0-9]*,
        _ => Err("site not found"),
    }
}



fn read_sources(source_path: &str) -> Vec<Source> {
    let path = env::current_dir().unwrap();
    println!("The current directory is {}", path.display());
    let path = Path::new(source_path);
    let display = path.display();

    // Open the path in read-only mode, returns `io::Result<File>`
    let file = match File::open(&path) {
        Err(why) => panic!("couldn't open {}: {}", display, why),
        Ok(file) => file,
    };
    let mut start = false;
    let reader = BufReader::new(file);
    let mut sources: Vec<Source> = Vec::new();

    for line_result in reader.lines() {
        //let line = line_result?;
        let line = line_result.unwrap();
        let line = line.trim(); // Remove leading and trailing whitespace
        if line.len() <= 0 {
            continue;
        }
        if start {
            if line.contains("-- END") {
                start = false;
            } else {
                let cols = line.split(",");
                let collection = cols.collect::<Vec<&str>>();
                if collection.len() == 4 {
                    println!("SOURCE: {:?}", collection);
                    sources.push(Source {
                        site: collection[0].trim().to_string(),
                        content_type: collection[1].trim().to_string(),
                        extractor: collection[2].trim().to_string(),
                        base_url: collection[3].trim().to_string(),
                    });
                } else {
                    println!("Source Error: {}", line);
                }
                // dbg!(collection);
            }
        } else {
            start = line.contains("-- START");
        }
    }
    sources
}

fn get_price_by_selector(html_content: &str, source_site: &str) -> Result<String, &'static str> {
    let document = Html::parse_document(&html_content);
    let product_ask_price_sel = get_ask_price_selector(&source_site)?;
    let ask_price = document.select(&product_ask_price_sel).next().unwrap();
    let text = ask_price
        .text()
        .collect::<Vec<_>>()
        .join("")
        .trim()
        .to_string();
    return Ok(price_formatter(&text));
}

fn get_price_by_pattern(html_content: &str, source_site: &str) -> Result<String, &'static str> {
    //let document = Html::parse_document(&html_content);
    let re = get_ask_price_pattern(&source_site)?;
    let mat = re.find(html_content).unwrap().as_str();
    let from: Vec<&str> = mat.split(":").collect();
    let to: Vec<&str> = from[1].split(",").collect();
    let price = price_formatter(&to[0]);
    Ok(price)
}

// TODO: isin by vector
async fn get_quotes_from_source(
    source: &Source,
    isin_filepath: &str,
) -> Result<Vec<Quote>, std::io::Error> {
    println!("\n--> init for Source: {:?}", source);

    let path = Path::new(isin_filepath);

    let file = File::open(&path)?;
    // let file = match File::open(&path) {
    //     Err(why) => println!("couldn't open {}: {}", display, why),
    //     Ok(file) => file,
    // };

    let results = Arc::new(Mutex::new(Vec::new()));

    let mut start = false;
    let reader = BufReader::new(file);

    tokio::time::sleep(Duration::from_secs(2)).await;

    // Async client
    let client = Client::new();
    // Vector to hold futures
    let mut tasks = vec![];

    for line_result in reader.lines() {
        let raw_line = line_result.unwrap();
        let line = raw_line.trim().to_string(); // Remove leading and trailing whitespace and own the data
        if line.len() <= 0 {
            continue;
        }
        if start {
            if line.contains("-- END") {
                start = false;
            } else {
                let url = [source.base_url.clone(), line.clone()].concat();
                println!("> ISIN: {} URL: {}", line, url);
                let client = client.clone();
                let r = Arc::clone(&results);
                // Spawn async task for each request
                let source = source.clone();
                let task = tokio::spawn(async move {
                    println!("Request to {}:...", url);
                    let response = client
                        .get(url)
                        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
                        .send().await; //?.text().await?;
                    match response {
                        Ok(response) => {
                            if response.status().is_success() {
                                let html_content = response.text().await?;
                                let price = match source.extractor.as_str() {
                                    "selector" => {
                                        get_price_by_selector(&html_content, &source.site)
                                    }
                                    "pattern" => get_price_by_pattern(&html_content, &source.site),
                                    _ => Err("Price not found"),
                                };
                                println!("Price {line}: {}", price.clone().unwrap());
                                let mut r = r.lock().unwrap();
                                r.push(Quote {
                                    isin: line.to_string(),
                                    ask: price.unwrap(),
                                    bid: DEF_PRICE.to_string(),
                                    currency: "EUR".to_string(),
                                });
                            } else {
                                println!("\nReceived a non-success status: {}", response.status());
                            }
                        }
                        Err(e) => {
                            // Log the error if the request fails
                            eprintln!("\nError occurred: {}", e);
                        }
                    }
                    //println!("Response from {}: {}", url, response);
                    Ok::<_, reqwest::Error>(())
                });
                tasks.push(task);
            }
        } else {
            start = line.contains("-- START");
        }
    }

    println!("Await all tasks to complete...");
    for task in tasks {
        let r = task.await;
        println!("task Result:{:?}", r);
    }

    let r = results.lock().unwrap();
    Ok(r.to_vec())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let data_path_prefix = "data/";
    let output_path_prefix = "data/output/";
    let fp = [data_path_prefix, "sources.txt"].concat();
    // System check
    let sources = read_sources(&fp);
    println!("Sources: {:?}", sources);
    for source in sources {
        println!(
            "\n----------------------\nWorking on...{}\n----------------------\n",
            source.site
        );
        let quotes =
            get_quotes_from_source(&source, &[data_path_prefix, &source.site, ".txt"].concat())
                .await;
        let quotes = match quotes {
            Err(e) => {
                eprintln!("Get Data Error: {:?}", e);
                continue;
            }
            Ok(quotes) => quotes,
        };
        println!("Quotes: {:?}", quotes);
        // Write results to CSV
        let csv_filepath = [
            output_path_prefix,
            &source.site,
            &chrono::offset::Local::now()
                .format("-%Y-%m-%d-%H-%M-%S")
                .to_string(),
            ".csv",
        ]
        .concat();
        println!("> Writing quotes to {}", csv_filepath);
        let _ = fs::create_dir_all(&output_path_prefix);
        let mut wtr = csv::Writer::from_path(csv_filepath).unwrap();
        wtr.write_record(&[&"isin", &"ask", &"bid", &"currency"])
            .unwrap();
        for quote in quotes {
            wtr.write_record(&[&quote.isin, &quote.ask, &quote.bid, &quote.currency])
                .unwrap();
        }
        wtr.flush()?;
    }
    Ok(())
}
