use reqwest::blocking::{Client as HttpClient, RequestBuilder, Response};
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE, USER_AGENT};

use crate::errors::Error;
use crate::models::ErrorBody;
use crate::resources::{InteractionsResource, ItemsResource, RecommendationsResource, UsersResource};

/// Optional configuration for building a client.
#[derive(Debug, Clone)]
pub struct ClientConfig {
    pub base_url: String,
    pub timeout:  std::time::Duration,
}

impl Default for ClientConfig {
    fn default() -> Self {
        Self {
            base_url: "http://localhost:8080".to_string(),
            timeout:  std::time::Duration::from_secs(30),
        }
    }
}

/// The main entry point for all RecSys.AI API resources.
#[derive(Clone)]
pub struct RecommendAIClient {
    pub(crate) http:     HttpClient,
    pub(crate) base_url: String,
}

impl RecommendAIClient {
    /// Create a client with the given API key and default configuration.
    pub fn new(api_key: &str) -> Result<Self, Error> {
        Self::with_config(api_key, ClientConfig::default())
    }

    /// Create a client with a custom configuration.
    pub fn with_config(api_key: &str, cfg: ClientConfig) -> Result<Self, Error> {
        let mut headers = HeaderMap::new();
        let auth_value = HeaderValue::from_str(&format!("Bearer {api_key}"))
            .map_err(|e| Error::Http { status: 0, message: e.to_string() })?;
        headers.insert(AUTHORIZATION, auth_value);
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        headers.insert(USER_AGENT,    HeaderValue::from_static("recommendai-rust/1.0.0"));

        let http = HttpClient::builder()
            .default_headers(headers)
            .timeout(cfg.timeout)
            .build()?;

        Ok(Self { http, base_url: cfg.base_url.trim_end_matches('/').to_string() })
    }

    /// Access the Recommendations resource.
    pub fn recommendations(&self) -> RecommendationsResource<'_> {
        RecommendationsResource { client: self }
    }

    /// Access the Users resource.
    pub fn users(&self) -> UsersResource<'_> {
        UsersResource { client: self }
    }

    /// Access the Items resource.
    pub fn items(&self) -> ItemsResource<'_> {
        ItemsResource { client: self }
    }

    /// Access the Interactions resource.
    pub fn interactions(&self) -> InteractionsResource<'_> {
        InteractionsResource { client: self }
    }

    /// Returns `true` if the API health endpoint responds successfully.
    pub fn ping(&self) -> bool {
        let url = format!("{}/health", self.base_url);
        self.http.get(&url).send()
            .map(|r| r.status().is_success())
            .unwrap_or(false)
    }

    /// Execute a request and map HTTP errors to typed [`Error`] variants.
    pub(crate) fn send(&self, req: RequestBuilder) -> Result<Response, Error> {
        let resp = req.send()?;
        let status = resp.status().as_u16();
        if (200..300).contains(&status) || status == 204 {
            return Ok(resp);
        }
        let body: ErrorBody = resp.json().unwrap_or(ErrorBody { detail: None });
        let msg = body.detail.unwrap_or_else(|| format!("HTTP {status}"));
        Err(match status {
            401       => Error::Authentication(msg),
            404       => Error::NotFound(msg),
            400 | 422 => Error::Validation(msg),
            429       => Error::RateLimit(msg),
            500..=599 => Error::Server(msg),
            _         => Error::Http { status, message: msg },
        })
    }
}
