use reqwest::Client;
use std::{error::Error, time::Duration};
use tokio; // Async runtime

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // To respect rate limits, you can add delays between requests as shown below:
    tokio::time::sleep(Duration::from_secs(2)).await;

    // Async client
    let client = Client::new();

    // URLs to fetch
    let urls = vec![
        "https://httpbin.org/get",
        "https://httpbin.org/ip",
        "https://httpbin.org/user-agent",
        "https://httpbin.org/user-agent-bad",
        "https://bad.httpbin.org/get"
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
                        println!("\nResponse: {:?}", response.text().await?);
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
