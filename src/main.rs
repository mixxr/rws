use chrono;
// use csv::Writer;
use reqwest::Client;
use scraper::{Html, Selector};
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{BufReader, prelude::*};
use std::path::Path;
// use std::result;
use std::{env, error::Error, time::Duration};
use tokio; // Async runtime
use std::sync::{Arc, Mutex};

// type QuotesSharedState = Arc<Mutex<Vec<HashMap<String, String>>>>;

fn get_ask_price_selector(site: &str) -> Result<Selector, &'static str> {
    match site.trim() {
        "" => Err("invalid site"),
        "marex" => Ok(Selector::parse("#product-ask-price").unwrap()),
        "bnp" => Ok(Selector::parse(r#"span[data-field="ask"]"#).unwrap()),
        "vontobel" => Ok(Selector::parse(r#"h2[data-testid="buy_price_label"]"#).unwrap()),
        _ => Err("site not found"),
    }
}

fn price_formatter(price: &str) -> String {
    let mut p = price.trim().to_string();
    if p.contains(",") && p.contains(".") {
        p = p.replace(",", "");
    }
    p = p.replace(",", ".");
    p
}

pub fn read_sources(source_path: &str) -> Vec<HashMap<String, String>> {
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
    let mut sources: Vec<HashMap<String, String>> = Vec::new();

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
                if collection.len() == 2 {
                    println!(
                        "SITE: {} URL: {}",
                        collection[0].trim(),
                        collection[1].trim()
                    );
                    let mut source: HashMap<String, String> = HashMap::new();
                    source.insert("site".to_string(), collection[0].trim().to_string());
                    source.insert("url".to_string(), collection[1].trim().to_string());
                    sources.push(source);
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


pub async fn get_data_from_site(
        site: &str,
        base_url: &str,
        isin_filepath: &str,
    ) -> Result<Vec<HashMap<String, String>>, std::io::Error>  {
    println!("\n--> init for Site: {} URL: {}", site, base_url);

    let path = Path::new(isin_filepath);

    let file = File::open(&path)?;
    // let file = match File::open(&path) {
    //     Err(why) => println!("couldn't open {}: {}", display, why),
    //     Ok(file) => file,
    // };

    let results = Arc::new(Mutex::new(Vec::new()));
    let site = site.to_owned();

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
                let url = [base_url, &line].concat();
                println!("ISIN: {} URL: {}", line, url);
                let client = client.clone();
                let r = Arc::clone(&results);
                let site = site.clone();
                // Spawn async task for each request
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
                                let document = Html::parse_document(&html_content);
                                let result = get_ask_price_selector(&site);
                                match result {
                                    Ok(product_ask_price_sel) => {
                                        for product_ask_price in document.select(&product_ask_price_sel) {
                                            let price = product_ask_price.text().collect::<Vec<_>>();
                                            println!("Price (Raw) {}: {}", line.to_string(), price[0]);
                                            let mut data: HashMap<String, String> = HashMap::new();
                                            data.insert("isin".to_string(), line.to_string());
                                            data.insert("price".to_string(), price_formatter(&price[0])); 
                                            let mut r = r.lock().unwrap();
                                            r.push(data.clone());
                                        }
                                    },
                                    Err(e) => eprintln!("error parsing site {site}: {e:?}"),
                                }
                                
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
        let r = task.await.unwrap();
        println!("task Result:{:?}", r);
    }

    let r = results.lock().unwrap();
    Ok(r.clone())  
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
        println!("\n----------------------\nWorking on...{}\n----------------------\n", source["site"]);
        let quotes = get_data_from_site(
            &source["site"],
            &source["url"],
            &[data_path_prefix, &source["site"], ".txt"].concat(),
        ).await;
        let quotes = match quotes {
            Err(e)=>{
                eprintln!("Get Data Error: {:?}", e);
                continue;
            },
            Ok(quotes) => quotes,
        };
        print!("Quotes: {:?}", quotes);
        // Write results to CSV
        let csv_filepath = [
            output_path_prefix,
            &source["site"],
            &chrono::offset::Local::now()
                .format("-%Y-%m-%d-%H-%M-%S")
                .to_string(),
            ".csv",
        ].concat();
        print!("Writing quotes to {}", csv_filepath);
        let _ = fs::create_dir_all(&output_path_prefix);
        let mut wtr = csv::Writer::from_path(csv_filepath).unwrap();
        wtr.write_record(&[&"isin", &"price"]).unwrap();
        for quote in quotes {
            wtr.write_record(&[&quote["isin"], &quote["price"]]).unwrap();
        }
        wtr.flush()?;
    }
    Ok(())
}
