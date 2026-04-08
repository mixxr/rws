pub fn validate_parameters(dt: &str, logtype: &str, ext: &str) -> bool {
    // check if dt is in the correct format (e.g. 2024-06-01T12:00:00Z)
    if !dt.chars().all(|c| c.is_digit(10) || c == '-' || c == 'T' || c == ':' || c == 'Z') {
        return false;
    }
    // validate logtype: only allow f2 or bq
    if logtype != "f2" && logtype != "bq" {
        return false;
    }
    // validate ext: only allow done or partial
    if ext != "done" && ext != "partial" {
        return false;
    }
    true
}