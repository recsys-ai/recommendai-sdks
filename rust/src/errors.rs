use thiserror::Error as ThisError;

#[derive(Debug, ThisError)]
pub enum Error {
    #[error("Authentication failed: {0}")]
    Authentication(String),

    #[error("Resource not found: {0}")]
    NotFound(String),

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Rate limit exceeded: {0}")]
    RateLimit(String),

    #[error("Server error: {0}")]
    Server(String),

    #[error("HTTP error (status {status}): {message}")]
    Http { status: u16, message: String },

    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),
}
