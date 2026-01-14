use reqwest::Client;
use scraper::{Html, Selector, html};
use std::{env, error::Error, time::Duration};
use std::fs::File;
use std::io::{BufReader, prelude::*};
use std::path::Path;
use tokio; // Async runtime

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // System check
    let path = env::current_dir()?;
    println!("The current directory is {}", path.display());
    let path = Path::new("data/sources.txt");
    let display = path.display();

    // Open the path in read-only mode, returns `io::Result<File>`
    let file = match File::open(&path) {
        Err(why) => panic!("couldn't open {}: {}", display, why),
        Ok(file) => file,
    };
    let mut start = false;
    let reader = BufReader::new(file);
    for line_result in reader.lines() {
        let line = line_result?;
        let line = line.trim();  // Remove leading and trailing whitespace
        if line.len() <= 0 { continue; }
        if start {
            if line.contains("-- END") { start = false; }
            else {
                let cols = line.split(",");
                let collection = cols.collect::<Vec<&str>>();
                if collection.len() == 2 {
                    println!("SITE: {} URL: {}", collection[0].trim(), collection[1].trim());
                } else {
                    println!("Source Error: {}", line);
                }
                // dbg!(collection);
            }
        }else{
            start = line.contains("-- START");
        }
    }
    
    // Read the file contents into a string, returns `io::Result<usize>`
    // let mut s = String::new();
    // match file.read_to_string(&mut s) {
    //     Err(why) => panic!("couldn't read {}: {}", display, why),
    //     Ok(_) => print!("contains:\n{}\n{}", s, s.split(",").count()),
    // }
    
    // To respect rate limits, you can add delays between requests as shown below:
    tokio::time::sleep(Duration::from_secs(2)).await;

    // Async client
    let client = Client::new();

    // URLs to fetch
    let urls = vec![
        "https://certificati.marex.com/it/products/it0006771353/",
        "https://certificati.marex.com/it/products/it0006768870/",
    ];

    // Vector to hold futures
    let mut tasks = vec![];

    // Perform async requests concurrently
    for url in urls {
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
                        //println!("\nResponse: {:?}", html_content);
                        let document = Html::parse_document(&html_content);
                        let product_ask_price_sel = Selector::parse("#product-ask-price").unwrap();
                        println!("\n===============");
                        for product_ask_price in document.select(&product_ask_price_sel) {
                            let price = product_ask_price.text().collect::<Vec<_>>();
                            println!("Price {}: {}", url, price[0]);
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

    // Await all tasks to complete
    println!("Await all tasks to complete...");
    for task in tasks {
        task.await??;
    }

    Ok(())
}
