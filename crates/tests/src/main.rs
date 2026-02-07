use glob::glob_with;
use glob::MatchOptions;



fn main() {
    let options = MatchOptions {
        case_sensitive: false,
        require_literal_separator: false,
        require_literal_leading_dot: false,
    };
    println!("Hello, world!");
    let source = "bnp";
    let mut max_entries = 2;
    let mut obsdatetimes = Vec::new();
    for entry in glob_with(&format!("../estractor/data/output/{}-*.csv", source), options).unwrap() {
        if let Ok(path) = entry {
            let filename = String::from(path.to_str().unwrap());
            // filename is in format <source>-<obsdatetime>.csv and <source> length is variable, so split at first '-' and get obsdatetime and remove .csv extension
            let obsdatetime = (filename.split_at(filename.find('-').unwrap_or(0)+1).1).to_string();
            let obsdatetime = obsdatetime.strip_suffix(".csv").unwrap_or(&obsdatetime).to_string();

            obsdatetimes.push(obsdatetime.clone());
            max_entries -= 1;
            if max_entries == 0 {
                break;
            }
        }
    }
        // sort obsdatetimes in descending order
        obsdatetimes.sort_by(|a, b| b.cmp(a));
        println!("Observation datetimes for source {}: {:?}", source, obsdatetimes);
}
