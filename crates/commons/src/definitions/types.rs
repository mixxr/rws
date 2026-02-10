// type QuotesSharedState = Arc<Mutex<Vec<HashMap<String, String>>>>;

// types
// Define a custom struct
#[derive(Debug, Clone)]
pub struct Source {
    pub site: String,
    pub base_url: String,
    pub content_type: String,
    pub extractor: String,
}

#[derive(Debug, Clone)]
pub struct Quote {
    pub isin: String,
    pub name: String,
    pub ask: String,
    pub bid: String,
    pub currency: String,
}

#[derive(Debug, Clone)]
pub struct ISIN {
    pub isin: String,
    pub name: String,
    // pub url: Option<String>,
}