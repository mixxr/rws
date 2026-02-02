pub fn price_formatter(price: &str) -> String {
    let mut p = price.trim().to_string();
    if p.contains(",") && p.contains(".") {
        p = p.replace(",", "");
    }
    p = p.replace(",", ".");
    p
}