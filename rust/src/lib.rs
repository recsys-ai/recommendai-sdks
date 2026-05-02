mod client;
mod errors;
mod models;
mod resources;

pub use client::{ClientConfig, RecommendAIClient};
pub use errors::Error;
pub use models::{Interaction, InteractionType, Item, Recommendation, User};
pub use resources::{InteractionsResource, ItemsResource, RecommendationsResource, UsersResource};
