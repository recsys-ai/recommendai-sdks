use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Supported interaction types.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum InteractionType {
    View,
    Click,
    Purchase,
    Like,
    Dislike,
    Rating,
    CartAdd,
    CartRemove,
}

/// A single personalised recommendation.
#[derive(Debug, Clone, Deserialize)]
pub struct Recommendation {
    pub item_id:  String,
    pub score:    f64,
    pub reason:   String,
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// A catalogue user.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub user_id:    String,
    pub properties: Option<HashMap<String, serde_json::Value>>,
    pub created_at: Option<String>,
    pub updated_at: Option<String>,
}

/// A catalogue item.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Item {
    pub item_id:    String,
    pub properties: Option<HashMap<String, serde_json::Value>>,
    pub created_at: Option<String>,
    pub updated_at: Option<String>,
}

/// A recorded interaction.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Interaction {
    pub user_id:          String,
    pub item_id:          String,
    pub interaction_type: String,
    pub value:            Option<f64>,
    pub metadata:         Option<HashMap<String, serde_json::Value>>,
    pub interaction_id:   Option<String>,
    pub timestamp:        Option<String>,
}

// ── Wire types ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(crate) struct RecommendationsResponse {
    pub recommendations: Vec<Recommendation>,
}

#[derive(Deserialize)]
pub(crate) struct ErrorBody {
    pub detail: Option<String>,
}
