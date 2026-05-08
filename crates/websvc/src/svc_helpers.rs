use actix_web::{
    body::{BoxBody, MessageBody},
    dev::{ServiceRequest, ServiceResponse},
    middleware::Next,
    Error, HttpResponse,
    http::Method
};
use std::sync::{Arc, Mutex};
use crate::definitions;

pub struct AppConfig {
    pub secret: String,
    pub is_test_mode: bool,
}

#[derive(Debug, Clone)]
pub struct Tables {
    pub _isin_ticker: String,
    pub _quote: String,
    pub _details: String,
    pub _issuer: String,
}

impl Tables {
    pub fn new(is_staging: bool) -> Self {
        let prefix = if is_staging { definitions::bq_defs::STAGING_PREFIX } else { "" };

        Self {
            _isin_ticker: format!("invcerts.ISINs.{}tickers", prefix), 
            _quote: format!("invcerts.ISINs.{}quotes", prefix),
            _details: format!("invcerts.ISINs.{}details", prefix),
            _issuer: format!("invcerts.ISINs.{}issuer", prefix),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ContentSystem {
    pub table_names: Tables,
}

// Type alias for shared state
pub type SharedMap = Arc<Mutex<ContentSystem>>;

// sanity check for input parameters: only allow alphanumeric characters, hyphens and underscores, and trim whitespace
pub fn sanitize_input(input: &str) -> String {
    input
        .trim()
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '_' | ':' | '.'))
        .collect()
}

pub async fn auth_middleware<B>(
    req: ServiceRequest,
    next: Next<B>,
) -> Result<ServiceResponse<BoxBody>, Error>
where
    B: MessageBody + 'static,
{
    println!("method {:?} {:?}", req.method(), req.headers().get("Authorization"));
    if req.method() == Method::OPTIONS {
        let res = next.call(req).await?;
        return Ok(res.map_into_boxed_body());
    }
    let config = req
        .app_data::<actix_web::web::Data<AppConfig>>()
        .expect("AppConfig missing");
    
    // test if test mode is enabled, if so skip authentication
    if config.is_test_mode {
        log::debug!("Test mode enabled, skipping authentication");
        let res = next.call(req).await?;
        return Ok(res.map_into_boxed_body());
    }
    let authorized = req
        .headers()
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .map(|h| h == format!("Bearer {}", config.secret))
        .unwrap_or(false);

    if !authorized {
        log::warn!("Unauthorized {:?}", req.headers().get("Authorization"));
        return Ok(
            req.into_response(HttpResponse::Unauthorized().finish())
                .map_into_boxed_body(),
        );
    }

    let res = next.call(req).await?;

    Ok(res.map_into_boxed_body())
}