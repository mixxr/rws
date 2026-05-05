use actix_web::{
    body::{BoxBody, MessageBody},
    dev::{ServiceRequest, ServiceResponse},
    middleware::Next,
    Error, HttpResponse,
};

pub struct AppConfig {
    pub secret: String,
}

pub async fn auth_middleware<B>(
    req: ServiceRequest,
    next: Next<B>,
) -> Result<ServiceResponse<BoxBody>, Error>
where
    B: MessageBody + 'static,
{
    let config = req
        .app_data::<actix_web::web::Data<AppConfig>>()
        .expect("AppConfig missing");

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