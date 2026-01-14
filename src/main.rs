use chrono;
use csv::Writer;
use reqwest::Client;
use scraper::{Html, Selector};
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufReader, prelude::*};
use std::path::Path;
use std::{env, error::Error, time::Duration};
use tokio; // Async runtime

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


pub async fn write_data_from_site(
        site: &str,
        base_url: &str,
        isin_filepath: &str,
        csv_path: &str,
    ) -> Vec<HashMap<String, String>> {
    println!("\n----------------------\nWorking on...{}", site);
    let mut results = Vec::new();

    let path = Path::new(isin_filepath);
    let display = path.display();

    // Open the path in read-only mode, returns `io::Result<File>`
    let file = match File::open(&path) {
        Err(why) => panic!("couldn't open {}: {}", display, why),
        Ok(file) => file,
    };
    // create file writer for CSV
    let mut wtr = csv::Writer::from_path(csv_path).unwrap();
    wtr.write_record(&[&"isin", &"price"]).unwrap();

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
                // Spawn async task for each request
                let task = tokio::spawn(async move {
                    println!("----------------------\nRequest to {}:...", url);
                    let response = client
                        .get(url)
                        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
                        .send().await; //?.text().await?;
                    match response {
                        Ok(response) => {
                            if response.status().is_success() {
                                let html_content = response.text().await?;
                                let document = Html::parse_document(&html_content);
                                // TODO: make selector dynamic based on site
                                let product_ask_price_sel =
                                    Selector::parse("#product-ask-price").unwrap();
                                println!("\n===============");
                                for product_ask_price in document.select(&product_ask_price_sel) {
                                    let price = product_ask_price.text().collect::<Vec<_>>();
                                    println!("Price {}: {}", line.to_string(), price[0]);
                                    let mut data: HashMap<String, String> = HashMap::new();
                                    data.insert("isin".to_string(), line.to_string());
                                    data.insert("price".to_string(), price[0].to_string()); 
                                    results.push(data.clone());
                                    // write data to CSV file
                                    wtr.write_record(&[&data["isin"], &data["price"]]).unwrap();
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
        task.await.unwrap();
    }

    results
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
        println!("Site: {} URL: {}", source["site"], source["url"]);
        write_data_from_site(
            &source["site"],
            &source["url"],
            &[data_path_prefix, &source["site"], ".txt"].concat(),
            &[
                output_path_prefix,
                &source["site"],
                &chrono::offset::Local::now()
                    .format("-%Y-%m-%d-%H-%M-%S")
                    .to_string(),
                ".csv",
            ]
            .concat(),
        );
    }
    // Read the file contents into a string, returns `io::Result<usize>`
    // let mut s = String::new();
    // match file.read_to_string(&mut s) {
    //     Err(why) => panic!("couldn't read {}: {}", display, why),
    //     Ok(_) => print!("contains:\n{}\n{}", s, s.split(",").count()),
    // }

    // To respect rate limits, you can add delays between requests as shown below:
    // tokio::time::sleep(Duration::from_secs(2)).await;

    // // Async client
    // let client = Client::new();

    // // URLs to fetch
    // let urls = vec![
    //     "https://certificati.marex.com/it/products/it0006771353/",
    //     "https://certificati.marex.com/it/products/it0006768870/",
    // ];

    // // Vector to hold futures
    // let mut tasks = vec![];

    // // Perform async requests concurrently
    // for url in urls {
    //     let client = client.clone();
    //     // Spawn async task for each request
    //     let task = tokio::spawn(async move {
    //         println!("----------------------\nRequest to {}:...", url);
    //         let response = client
    //             .get(url)
    //             .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
    //             .send().await; //?.text().await?;
    //         match response {
    //             Ok(response) => {
    //                 if response.status().is_success() {
    //                     let html_content = response.text().await?;
    //                     //println!("\nResponse: {:?}", html_content);
    //                     let document = Html::parse_document(&html_content);
    //                     let product_ask_price_sel = Selector::parse("#product-ask-price").unwrap();
    //                     println!("\n===============");
    //                     for product_ask_price in document.select(&product_ask_price_sel) {
    //                         let price = product_ask_price.text().collect::<Vec<_>>();
    //                         println!("Price {}: {}", url, price[0]);
    //                     }
    //                 } else {
    //                     println!("\nReceived a non-success status: {}", response.status());
    //                 }
    //             }
    //             Err(e) => {
    //                 // Log the error if the request fails
    //                 eprintln!("\nError occurred: {}", e);
    //             }
    //         }
    //         //println!("Response from {}: {}", url, response);
    //         Ok::<_, reqwest::Error>(())
    //     });
    //     tasks.push(task);
    // }

    // // Await all tasks to complete
    // println!("Await all tasks to complete...");
    // for task in tasks {
    //     task.await??;
    // }

    Ok(())
}
