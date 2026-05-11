use csv::StringRecord;
use std::error::Error;

pub struct CsvQueryEngine {
    pub path: String,
    pub delimiter: u8,
}

impl CsvQueryEngine {
    pub fn new(path: &str) -> Self {
        Self {
            path: path.to_string(),
            delimiter: b';',
        }
    }

    pub fn run<F, M>(&self, filter_fn: F, map_fn: M) -> Result<Vec<String>, Box<dyn Error>>
    where
        F: Fn(&StringRecord) -> bool,
        M: Fn(&StringRecord) -> String,
    {
        let mut rdr = csv::ReaderBuilder::new()
            .delimiter(self.delimiter)
            .from_path(&self.path)?;

        let mut rows = Vec::new();

        // header
        if let Ok(headers) = rdr.headers() {
            rows.push(map_fn(&headers));
        }

        for result in rdr.records() {
            let record = match result {
                Ok(r) => r,
                Err(_) => continue,
            };

            if filter_fn(&record) {
                rows.push(map_fn(&record));
            }
        }

        Ok(rows)
    }
}