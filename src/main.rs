mod definitions;
mod utils;

use clap::Parser;
use definitions::globals::*;
use definitions::types::*;
use definitions::args::Args;
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
use tokio;

use crate::definitions::globals::OUTPUT_PATH_PREFIX; // Async runtime

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

fn read_sources_from_file(source_path: &str) -> Vec<Source> {
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

fn read_isins_from_file(isin_path: &str) -> Result<Vec<ISIN>, std::io::Error> {
    //let path = env::current_dir().unwrap();
    let path = Path::new(isin_path);
    // let display = path.display();

    // Open the path in read-only mode, returns `io::Result<File>`
    let file = File::open(&path)?; //{
    //     Err(why) => panic!("couldn't open {}: {}", display, why),
    //     Ok(file) => file,
    // };
    let mut start = false;
    let reader = BufReader::new(file);
    let mut isins: Vec<ISIN> = Vec::new();

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
                let line = line.split(",").collect::<Vec<&str>>();
                if line.len() < 2 {
                    println!("[ISIN] discarding line: {:?}", line);
                    continue;
                }
                isins.push(ISIN {
                    isin: line[0].trim().to_string(),
                    name: line[1].trim().to_string(),
                });
            }
        } else {
            start = line.contains("-- START");
        }
    }
    Ok(isins)
}

async fn extract_quotes_from_source(
    source: &Source,
    isins: &Vec<ISIN>,
) -> Result<Vec<Quote>, std::io::Error> {
    println!("\n--> init for Source: {:?}", source);

    let results = Arc::new(Mutex::new(Vec::new()));

    tokio::time::sleep(Duration::from_secs(2)).await;

    // Async client
    let client = Client::new();
    // Vector to hold futures
    let mut tasks = vec![];

    for isin in isins {
        let url = [source.base_url.clone(), isin.isin.clone()].concat();
        println!("> ISIN: {} URL: {}", isin.isin, url);
        let client = client.clone();
        let r = Arc::clone(&results);
        // Spawn async task for each request
        let source = source.clone();
        let isin = isin.clone();
        let task = tokio::spawn(async move {
            println!("Request to {}:...", url);
            // TODO: make user-agent random
            let response = client
                        .get(url)
                        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
                        .send().await; //?.text().await?;
            match response {
                Ok(response) => {
                    if response.status().is_success() {
                        let html_content = response.text().await?;
                        let price = match source.extractor.as_str() {
                            "selector" => get_price_by_selector(&html_content, &source.site),
                            "pattern" => get_price_by_pattern(&html_content, &source.site),
                            _ => Err("Price not found"),
                        };
                        println!("Price {}: {}", isin.isin, price.clone().unwrap());
                        let mut r = r.lock().unwrap();
                        r.push(Quote {
                            isin: isin.isin.clone(),
                            name: isin.name.clone(),
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

    println!("Await all tasks to complete...");
    for task in tasks {
        let r = task.await;
        println!("task Result:{:?}", r);
    }

    let r = results.lock().unwrap();
    Ok(r.to_vec())
}

fn write_quotes_to_csv(quotes: &Vec<Quote>, output_filepath: &str) -> Result<(), Box<dyn Error>> {
    let mut wtr = csv::Writer::from_path(output_filepath)?;
    wtr.write_record(&[&"isin", &"name", &"ask", &"bid", &"currency"])?;
    for quote in quotes {
        wtr.write_record(&[&quote.isin, &quote.name, &quote.ask, &quote.bid, &quote.currency])?;
    }
    wtr.flush()?;
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    let fp = &args.source_fp;
    let path = env::current_dir().unwrap();

    println!("Configuration: {:?}", args);
    println!("The current directory is {}", path.display());

    // System check
    let sources = read_sources_from_file(&fp);
    println!("Sources: {:?}", sources);
    for source in sources {
        println!(
            "\n----------------------\nWorking on...{}\n----------------------\n",
            source.site
        );
        let isins =
            read_isins_from_file(&[DATA_PATH_PREFIX, &source.site, ".txt"].concat().as_str());
        let isins = match isins {
            Err(e) => {
                eprintln!("ISIN Read Error: {:?}", e);
                continue;
            }
            Ok(isins) => isins,
        };
        let quotes = extract_quotes_from_source(&source, &isins).await;
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
            OUTPUT_PATH_PREFIX,
            &source.site,
            &chrono::offset::Local::now()
                .format("-%Y-%m-%d-%H-%M-%S")
                .to_string(),
            ".csv",
        ]
        .concat();
        println!("> Writing quotes to {}", csv_filepath);
        let _ = fs::create_dir_all(&OUTPUT_PATH_PREFIX);
        write_quotes_to_csv(&quotes, &csv_filepath)?;
    }
    Ok(())
}
