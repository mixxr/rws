use google_cloud_bigquery::client::{Client, ClientConfig};
use google_cloud_bigquery::http::job::query::QueryRequest;
use google_cloud_bigquery::query::row::Row;

use crate::definitions::bq_defs::*;

impl Tables {
    pub fn new(is_staging: bool) -> Self {
        let prefix = if is_staging { STAGING_PREFIX } else { "" };

        Self {
            _isin_ticker: format!("invcerts.ISINs.{}tickers", prefix), 
            _quote: format!("invcerts.ISINs.{}quotes", prefix),
            _details: format!("invcerts.ISINs.{}details", prefix),
            _issuer: format!("invcerts.ISINs.{}issuer", prefix),
        }
    }
}

pub fn like_condition(column: &str, value: &str, use_lower: bool) -> String {
    if value.trim().is_empty() {
        String::new()
    } else {
        if use_lower {
            format!("lower({}) like '%{}%'", column, value.to_lowercase())
        } else {
            format!("{} like '%{}%'", column, value)
        }
    }
}

pub async fn init_bq_client() -> (Client, String) {
    let (config, project_id) = ClientConfig::new_with_auth().await.unwrap();
    let client = Client::new(config).await.unwrap();
    log::debug!("BigQuery Client initialized with project ID: {:?}", project_id);
    (client, project_id.unwrap_or_default())
}

pub async fn query_bq(
    client: &Client, 
    project_id: &str, 
    colnames: Vec<&str>, 
    tablename: &str, 
    conditions_in_and: Vec<&str>) -> Vec<String> {

    log::debug!("-- BigQuery Client project ID: {:?}", project_id);

    // 2. Prepare the query
    let cols = colnames.join(", ");

    // remove empty conditions and trim whitespace
    let conditions_in_and = conditions_in_and.into_iter().filter(|c| !c.trim().is_empty()).collect::<Vec<_>>();

    let where_clause = if conditions_in_and.is_empty() {
        "".to_string()
    } else {
        format!(" WHERE {}", conditions_in_and.join(" AND "))
    };

    let q = format!("SELECT {} FROM {}{} LIMIT {}", cols, tablename, where_clause, HARD_ROW_LIMIT);
    // TODO: sanification of inputs to prevent SQL injection, especially for conditions

    log::debug!("-- Query: {}", q);
    
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
        rows.push(values.join(COL_SEPARATOR));
    }

    if rows.is_empty() {
        rows.push(NODATA_FOUND.to_string());
    }
    rows
}
