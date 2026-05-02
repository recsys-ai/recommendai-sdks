use mockito::Server;
use recommendai::{ClientConfig, RecommendAIClient};
use serde_json::json;

fn make_client(server: &Server) -> RecommendAIClient {
    RecommendAIClient::with_config(
        "test-key",
        ClientConfig {
            base_url: server.url(),
            timeout: std::time::Duration::from_secs(5),
        },
    )
    .expect("client creation should succeed")
}

// ── ping ──────────────────────────────────────────────────────────────────────

#[test]
fn ping_returns_true_on_200() {
    let mut server = Server::new();
    let _m = server.mock("GET", "/health").with_status(200).create();

    let client = make_client(&server);
    assert!(client.ping());
}

#[test]
fn ping_returns_false_on_503() {
    let mut server = Server::new();
    let _m = server.mock("GET", "/health").with_status(503).create();

    let client = make_client(&server);
    assert!(!client.ping());
}

// ── recommendations ───────────────────────────────────────────────────────────

#[test]
fn recommendations_similar_calls_correct_path() {
    let mut server = Server::new();
    let body = json!({
        "recommendations": [
            { "item_id": "item2", "score": 0.8, "reason": "", "metadata": {} }
        ]
    });
    let _m = server
        .mock("GET", "/api/recommendations/similar/item99")
        .match_query(mockito::Matcher::UrlEncoded("limit".into(), "10".into()))
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(body.to_string())
        .create();

    let client = make_client(&server);
    let recs = client.recommendations().similar("item99", 10).unwrap();
    assert_eq!(recs.len(), 1);
    assert_eq!(recs[0].item_id, "item2");
}

#[test]
fn recommendations_popular_passes_category_param() {
    let mut server = Server::new();
    let body = json!({
        "recommendations": [
            { "item_id": "book1", "score": 0.7, "reason": "", "metadata": {} }
        ]
    });
    let _m = server
        .mock("GET", "/api/recommendations/popular")
        .match_query(mockito::Matcher::AllOf(vec![
            mockito::Matcher::UrlEncoded("limit".into(), "5".into()),
            mockito::Matcher::UrlEncoded("category".into(), "books".into()),
        ]))
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(body.to_string())
        .create();

    let client = make_client(&server);
    let recs = client
        .recommendations()
        .popular(5, Some("books"))
        .unwrap();
    assert_eq!(recs.len(), 1);
    assert_eq!(recs[0].item_id, "book1");
}

// ── items ─────────────────────────────────────────────────────────────────────

#[test]
fn items_upsert_posts_to_bulk_endpoint() {
    let mut server = Server::new();
    let resp_body = json!({
        "items": [
            { "item_id": "itemA", "properties": {}, "created_at": null, "updated_at": null }
        ]
    });
    let _m = server
        .mock("POST", "/api/items/bulk")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(resp_body.to_string())
        .create();

    let client = make_client(&server);
    let items = client
        .items()
        .upsert(vec![serde_json::from_value(json!({
            "item_id": "itemA",
            "properties": { "name": "Book A" }
        }))
        .unwrap()])
        .unwrap();
    assert_eq!(items.len(), 1);
    assert_eq!(items[0].item_id, "itemA");
}

// ── error handling ────────────────────────────────────────────────────────────

#[test]
fn authentication_error_on_401() {
    let mut server = Server::new();
    let _m = server
        .mock("GET", "/api/recommendations/similar/x")
        .match_query(mockito::Matcher::Any)
        .with_status(401)
        .with_header("content-type", "application/json")
        .with_body(json!({"detail": "invalid api key"}).to_string())
        .create();

    let client = make_client(&server);
    let err = client.recommendations().similar("x", 5).unwrap_err();
    assert!(matches!(err, recommendai::Error::Authentication(_)));
}

#[test]
fn not_found_error_on_404() {
    let mut server = Server::new();
    let _m = server
        .mock("GET", "/api/recommendations/similar/x")
        .match_query(mockito::Matcher::Any)
        .with_status(404)
        .with_header("content-type", "application/json")
        .with_body(json!({"detail": "not found"}).to_string())
        .create();

    let client = make_client(&server);
    let err = client.recommendations().similar("x", 5).unwrap_err();
    assert!(matches!(err, recommendai::Error::NotFound(_)));
}

#[test]
fn rate_limit_error_on_429() {
    let mut server = Server::new();
    let _m = server
        .mock("GET", "/api/recommendations/similar/x")
        .match_query(mockito::Matcher::Any)
        .with_status(429)
        .with_header("content-type", "application/json")
        .with_body(json!({"detail": "rate limit"}).to_string())
        .create();

    let client = make_client(&server);
    let err = client.recommendations().similar("x", 5).unwrap_err();
    assert!(matches!(err, recommendai::Error::RateLimit(_)));
}
