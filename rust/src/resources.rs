use std::collections::HashMap;

use serde::Serialize;
use serde_json::Value;

use crate::client::RecommendAIClient;
use crate::errors::Error;
use crate::models::{Interaction, InteractionType, Item, Recommendation, RecommendationsResponse, User};

// ── RecommendationsResource ───────────────────────────────────────────────────

pub struct RecommendationsResource<'a> {
    pub(crate) client: &'a RecommendAIClient,
}

impl RecommendationsResource<'_> {
    /// Get personalised recommendations for `user_id`.
    pub fn get(&self, user_id: &str, limit: u32) -> Result<Vec<Recommendation>, Error> {
        let url = format!("{}/api/recommendations", self.client.base_url);
        let req = self.client.http.get(&url)
            .query(&[("user_id", user_id), ("limit", &limit.to_string())]);
        let resp = self.client.send(req)?;
        let data: RecommendationsResponse = resp.json()?;
        Ok(data.recommendations)
    }

    /// Get items similar to `item_id`.
    pub fn similar(&self, item_id: &str, limit: u32) -> Result<Vec<Recommendation>, Error> {
        let url = format!("{}/api/recommendations/similar/{}", self.client.base_url, item_id);
        let req = self.client.http.get(&url).query(&[("limit", &limit.to_string())]);
        let resp = self.client.send(req)?;
        let data: RecommendationsResponse = resp.json()?;
        Ok(data.recommendations)
    }

    /// Get globally popular items, optionally filtered by `category`.
    pub fn popular(&self, limit: u32, category: Option<&str>) -> Result<Vec<Recommendation>, Error> {
        let url = format!("{}/api/recommendations/popular", self.client.base_url);
        let mut params: Vec<(&str, String)> = vec![("limit", limit.to_string())];
        if let Some(cat) = category { params.push(("category", cat.to_string())); }
        let req = self.client.http.get(&url).query(&params);
        let resp = self.client.send(req)?;
        let data: RecommendationsResponse = resp.json()?;
        Ok(data.recommendations)
    }
}

// ── UsersResource ─────────────────────────────────────────────────────────────

pub struct UsersResource<'a> {
    pub(crate) client: &'a RecommendAIClient,
}

#[derive(Serialize)]
struct CreateUserBody<'a> {
    user_id:    &'a str,
    properties: &'a HashMap<String, Value>,
}

#[derive(Serialize)]
struct UpdateUserBody<'a> {
    properties: &'a HashMap<String, Value>,
}

impl UsersResource<'_> {
    pub fn create(&self, user_id: &str, properties: HashMap<String, Value>) -> Result<User, Error> {
        let url = format!("{}/api/users", self.client.base_url);
        let req = self.client.http.post(&url)
            .json(&CreateUserBody { user_id, properties: &properties });
        let resp = self.client.send(req)?;
        Ok(resp.json()?)
    }

    pub fn get(&self, user_id: &str) -> Result<User, Error> {
        let url = format!("{}/api/users/{}", self.client.base_url, user_id);
        let resp = self.client.send(self.client.http.get(&url))?;
        Ok(resp.json()?)
    }

    pub fn update(&self, user_id: &str, properties: HashMap<String, Value>) -> Result<User, Error> {
        let url = format!("{}/api/users/{}", self.client.base_url, user_id);
        let req = self.client.http.put(&url)
            .json(&UpdateUserBody { properties: &properties });
        let resp = self.client.send(req)?;
        Ok(resp.json()?)
    }

    pub fn delete(&self, user_id: &str) -> Result<(), Error> {
        let url = format!("{}/api/users/{}", self.client.base_url, user_id);
        self.client.send(self.client.http.delete(&url))?;
        Ok(())
    }
}

// ── ItemsResource ─────────────────────────────────────────────────────────────

pub struct ItemsResource<'a> {
    pub(crate) client: &'a RecommendAIClient,
}

#[derive(Serialize)]
struct CreateItemBody<'a> {
    item_id:    &'a str,
    properties: &'a HashMap<String, Value>,
}

#[derive(Serialize)]
struct UpdateItemBody<'a> {
    properties: &'a HashMap<String, Value>,
}

impl ItemsResource<'_> {
    pub fn create(&self, item_id: &str, properties: HashMap<String, Value>) -> Result<Item, Error> {
        let url = format!("{}/api/items", self.client.base_url);
        let req = self.client.http.post(&url)
            .json(&CreateItemBody { item_id, properties: &properties });
        let resp = self.client.send(req)?;
        Ok(resp.json()?)
    }

    pub fn get(&self, item_id: &str) -> Result<Item, Error> {
        let url = format!("{}/api/items/{}", self.client.base_url, item_id);
        let resp = self.client.send(self.client.http.get(&url))?;
        Ok(resp.json()?)
    }

    pub fn update(&self, item_id: &str, properties: HashMap<String, Value>) -> Result<Item, Error> {
        let url = format!("{}/api/items/{}", self.client.base_url, item_id);
        let req = self.client.http.put(&url)
            .json(&UpdateItemBody { properties: &properties });
        let resp = self.client.send(req)?;
        Ok(resp.json()?)
    }

    pub fn delete(&self, item_id: &str) -> Result<(), Error> {
        let url = format!("{}/api/items/{}", self.client.base_url, item_id);
        self.client.send(self.client.http.delete(&url))?;
        Ok(())
    }

    /// Bulk create or update items.
    pub fn upsert(&self, items: Vec<Value>) -> Result<Vec<Item>, Error> {
        let url = format!("{}/api/items/bulk", self.client.base_url);
        let body = serde_json::json!({ "items": items });
        let req  = self.client.http.post(&url).json(&body);
        let resp = self.client.send(req)?;
        let data: serde_json::Value = resp.json()?;
        let list = data["items"].as_array().cloned().unwrap_or_default();
        list.into_iter()
            .map(|v| serde_json::from_value(v).map_err(|e| Error::Http { status: 0, message: e.to_string() }))
            .collect()
    }
}

// ── InteractionsResource ──────────────────────────────────────────────────────

pub struct InteractionsResource<'a> {
    pub(crate) client: &'a RecommendAIClient,
}

#[derive(Serialize)]
struct CreateInteractionBody<'a> {
    user_id:          &'a str,
    item_id:          &'a str,
    interaction_type: &'a InteractionType,
    #[serde(skip_serializing_if = "Option::is_none")]
    value:            Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    metadata:         Option<&'a HashMap<String, Value>>,
}

impl InteractionsResource<'_> {
    pub fn create(
        &self,
        user_id:          &str,
        item_id:          &str,
        interaction_type: &InteractionType,
        value:            Option<f64>,
        metadata:         Option<&HashMap<String, Value>>,
    ) -> Result<Interaction, Error> {
        let url = format!("{}/api/interactions", self.client.base_url);
        let req = self.client.http.post(&url).json(&CreateInteractionBody {
            user_id, item_id, interaction_type, value, metadata,
        });
        let resp = self.client.send(req)?;
        Ok(resp.json()?)
    }
}
