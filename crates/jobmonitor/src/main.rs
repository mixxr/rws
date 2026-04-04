use axum::{
    extract::{Path, State},
    routing::get,
    Router,
};
use google_cloud_storage::client::Storage;
use std::sync::Arc;
use tokio::net::TcpListener;
//use futures::StreamExt; // for `next()` on the reader stream

#[tokio::main]
async fn main() {
    // Build the Storage client (uses Application Default Credentials)
    let storage = Storage::builder()
        .build()
        .await
        .expect("Failed to create Storage client");

    let bucket_name = std::env::var("BUCKET_NAME")
        .map_err(|_| "BUCKET_NAME environment variable missing".to_string())?;

    // set the bucket name as default for the storage client (optional, can also specify in get_file)
    storage.set_default_bucket(bucket_name);
    // storage.read_object("example.txt").send().await.expect("Failed to read object");
    
    let storage = Arc::new(storage);

    // Build Axum router
    let app = Router::new()
        .route("/jobs", get(get_file_list))
        .route("/jobs/:name", get(get_file))
        .with_state(storage);

    // Bind to port (Cloud Run expects 0.0.0.0:8080)
    let listener = TcpListener::bind("0.0.0.0:8080")
        .await
        .expect("Failed to bind to port 8080");

    println!("Server running on http://0.0.0.0:8080");

    axum::serve(listener, app)
        .await
        .expect("Server error");
}

async fn get_file_list(
    State(storage): State<Arc<Storage>>,
) -> Result<String, String> {
    let bucket = std::env::var("BUCKET_NAME")
        .map_err(|_| "BUCKET_NAME environment variable missing".to_string())?;

    // List objects in the bucket
    let objects = storage
        .list_objects(&bucket)
        .send()
        .await
        .map_err(|e| format!("Error listing objects: {e}"))?;

    // Collect object names
    let mut names = Vec::new();
    for object in objects {
        names.push(object.name());
    }

    Ok(names.join(", "))
}

async fn get_file(
    Path(name): Path<String>,
    State(storage): State<Arc<Storage>>,
) -> Result<String, String> {
    let bucket = std::env::var("BUCKET_NAME")
        .map_err(|_| "BUCKET_NAME environment variable missing".to_string())?;

    // Read object as a stream of chunks
    let mut reader = storage
        .read_object(&bucket, &name)
        .send()
        .await
        .map_err(|e| format!("Error starting download: {e}"))?;

    let mut contents = Vec::new();
    while let Some(chunk) = reader.next().await.transpose().map_err(|e| format!("Read error: {e}"))? {
        contents.extend_from_slice(&chunk);
    }

    String::from_utf8(contents).map_err(|_| "File is not valid UTF-8".to_string())
}
