use google_cloud_bigquery::client::{Client, ClientConfig};
use google_cloud_bigquery::http::job::query::QueryRequest;
use google_cloud_bigquery::query::row::Row;

pub static NODATA_FOUND: &str = "No data found";
pub static HARD_ROW_LIMIT: usize = 1000;
pub static STAGING_PREFIX: &str = "staging_";

// static vector of column names for details query, to avoid repetition and potential typos
// vec!["isin", "issue", "name", "certificate_type_tags","memory_effect", "phase", "currency", "industry", "callable", "strike_date", "issue_date", "rembursement_date", "autocallable_date", "capital_barrier", "airbag", "risk_level", "coupon_amount", "coupon_recurrence", "coupon_type", "coupon_barrier", "leverage", "exchange_risk"],
pub static DETAIL_COLUMNS: &'static [&str] = &[
    "isin",
    "issue",
    "name",
    "certificate_type_tags",
    "memory_effect",
    "phase",
    "currency",
    "industry",
    "callable",
    "strike_date",
    "issue_date",
    "rembursement_date",
    "autocallable_date",
    "capital_barrier",
    "airbag",
    "risk_level",
    "coupon_amount",
    "coupon_recurrence",
    "coupon_type",
    "coupon_barrier",
    "leverage",
    "exchange_risk"
];

// static vector of cols for issuers
// vec!["issuer_name", "specialization", "geo_region", "issuer_rating_description"]
pub static ISSUER_COLUMNS: &'static [&str] = &[
    "issuer_name",
    "specialization",
    "geo_region",
    "issuer_rating_description"
];

pub struct Tables {
    pub _ISIN_TICKER: &'static str,
    pub _QUOTE: &'static str,
    pub _DETAILS: &'static str,
    pub _ISSUER: &'static str,
}

pub static TABLES: Tables = Tables {
    _ISIN_TICKER: "invcerts.ISINs.isin_ticker",
    _QUOTE: "invcerts.ISINs.quote",
    _DETAILS: "invcerts.ISINs.details",
    _ISSUER: "invcerts.Issuers.issuer",
};

pub async fn init_bq_client() -> (Client, String) {
    let (config, project_id) = ClientConfig::new_with_auth().await.unwrap();
    let client = Client::new(config).await.unwrap();
    println!("BigQuery Client initialized with project ID: {:?}", project_id);
    (client, project_id.unwrap_or_default())
}

pub async fn query_bq(
    client: &Client, 
    project_id: &str, 
    colnames: Vec<&str>, 
    tablename: &str, 
    conditions_in_and: Vec<&str>) -> Vec<String> {

    println!("BigQuery Client is already initialized, using existing client with project ID: {:?}", project_id);


    // 2. Prepare the query
    let cols = colnames.join(", ");

    let where_clause = if conditions_in_and.is_empty() {
        "".to_string()
    } else {
        format!(" WHERE {}", conditions_in_and.join(" AND "))
    };

    let q = format!("SELECT {} FROM {}{} LIMIT {}", cols, tablename, where_clause, HARD_ROW_LIMIT);
    // TODO: sanification of inputs to prevent SQL injection, especially for conditions
    
    let request = QueryRequest {
        query: q,
        ..Default::default()
    };

    let mut iter = client.query::<Row>(&project_id, request).await.unwrap();
    let mut rows = Vec::<String>::new();
    while let Some(row) = iter.next().await.unwrap() {
       let mut values = Vec::new();
        for (idx, _) in colnames.iter().enumerate() {
            let value: String = row.column(idx).unwrap();
            values.push(value);
        }
        // Join all values into a single CSV-like string
        rows.push(values.join(", "));
    }

    if rows.is_empty() {
        rows.push(NODATA_FOUND.to_string());
    }
    rows
}
