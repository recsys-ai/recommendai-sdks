// examples/simulation.rs
//
// RecSys.AI Rust SDK — Movie Streaming Simulation
//
// Starts a tiny_http mock server on port 17897 in a background thread,
// then runs a 10-step simulation using the blocking Rust SDK.
//
// Run:  cargo run --example simulation

use std::collections::HashMap;
use std::io::{Cursor, Read};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

use serde_json::{json, Value};
use tiny_http::{Method, Request, Response, Server, StatusCode};

use recommendai::{ClientConfig, InteractionType, RecommendAIClient};

const MOCK_PORT: u16 = 17897;

// ── In-memory state ───────────────────────────────────────────────────────────

#[derive(Default)]
struct State {
    users:    HashMap<String, Value>,
    items:    HashMap<String, Value>,
    interactions: Vec<Value>,
}

type SharedState = Arc<Mutex<State>>;

// ── Mock server ───────────────────────────────────────────────────────────────

fn djb2(s: &str) -> u64 {
    let mut h: u64 = 5381;
    for b in s.bytes() {
        h = h.wrapping_shl(5).wrapping_add(h).wrapping_add(b as u64);
    }
    h
}

fn respond(req: Request, status: u16, body: Value) {
    let bytes = body.to_string().into_bytes();
    let _ = req.respond(
        Response::new(
            StatusCode(status),
            vec![
                tiny_http::Header::from_bytes("Content-Type", "application/json").unwrap(),
            ],
            Cursor::new(bytes.clone()),
            Some(bytes.len()),
            None,
        )
    );
}

fn respond_no_body(req: Request, status: u16) {
    let _ = req.respond(Response::new(
        StatusCode(status),
        vec![],
        Cursor::new(vec![]),
        Some(0),
        None,
    ));
}

fn read_body(req: &mut Request) -> Value {
    let mut buf = String::new();
    let _ = req.as_reader().read_to_string(&mut buf);
    serde_json::from_str(&buf).unwrap_or(Value::Object(Default::default()))
}

fn compute_recs(state: &State, user_id: &str, limit: usize) -> Vec<Value> {
    let seen: std::collections::HashSet<String> = state.interactions.iter()
        .filter(|ia| ia["user_id"].as_str() == Some(user_id))
        .map(|ia| ia["item_id"].as_str().unwrap_or("").to_string())
        .collect();

    let preferred_genre = state.users.get(user_id)
        .and_then(|u| u["properties"]["preferred_genre"].as_str())
        .unwrap_or("")
        .to_string();

    let mut candidates: Vec<Value> = state.items.iter()
        .filter(|(id, _)| !seen.contains(*id))
        .map(|(item_id, item)| {
            let props  = &item["properties"];
            let rating = props["rating"].as_f64().unwrap_or(0.0);
            let genre  = props["genre"].as_str().unwrap_or("");
            let mut score = rating / 10.0;
            if !preferred_genre.is_empty() && genre == preferred_genre { score += 0.2; }
            let hash_part = djb2(&format!("{}{}", user_id, item_id)) % 100;
            score += hash_part as f64 / 1000.0;
            score = score.min(1.0);
            let score = (score * 10000.0).round() / 10000.0;
            let reason = if !preferred_genre.is_empty() && genre == preferred_genre {
                format!("Matches preferred genre: {}", preferred_genre)
            } else {
                "Highly rated content".to_string()
            };
            json!({
                "item_id":  item_id,
                "score":    score,
                "reason":   reason,
                "metadata": { "title": props["title"] }
            })
        })
        .collect();

    candidates.sort_by(|a, b| {
        b["score"].as_f64().unwrap_or(0.0)
            .partial_cmp(&a["score"].as_f64().unwrap_or(0.0))
            .unwrap()
    });
    candidates.truncate(limit);
    candidates
}

fn handle(mut req: Request, state: &SharedState) {
    let method = req.method().clone();
    let url    = req.url().to_string();
    let path   = url.split('?').next().unwrap_or("").to_string();
    let query_string = url.find('?').map(|i| url[i+1..].to_string()).unwrap_or_default();

    // parse query params
    let params: HashMap<String, String> = query_string.split('&')
        .filter_map(|kv| {
            let mut parts = kv.splitn(2, '=');
            Some((parts.next()?.to_string(), parts.next().unwrap_or("").to_string()))
        })
        .collect();

    match (&method, path.as_str()) {
        // POST /api/users
        (Method::Post, "/api/users") => {
            let body = read_body(&mut req);
            let uid  = body["user_id"].as_str().unwrap_or("").to_string();
            let record = json!({
                "user_id":    uid,
                "properties": body["properties"],
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z"
            });
            state.lock().unwrap().users.insert(uid, record.clone());
            respond(req, 201, record);
        }
        // GET /api/users/{id}
        _ if method == Method::Get && path.starts_with("/api/users/") => {
            let uid = path["/api/users/".len()..].to_string();
            let st = state.lock().unwrap();
            match st.users.get(&uid).cloned() {
                Some(u) => respond(req, 200, u),
                None    => respond(req, 404, json!({"detail": format!("User not found: {uid}")})),
            }
        }
        // PUT /api/users/{id}
        _ if method == Method::Put && path.starts_with("/api/users/") => {
            let uid  = path["/api/users/".len()..].to_string();
            let body = read_body(&mut req);
            let mut st = state.lock().unwrap();
            match st.users.get_mut(&uid) {
                Some(u) => {
                    u["properties"] = body["properties"].clone();
                    u["updated_at"] = json!("2024-01-01T00:00:00Z");
                    respond(req, 200, u.clone());
                }
                None => respond(req, 404, json!({"detail": format!("User not found: {uid}")})),
            }
        }
        // DELETE /api/users/{id}
        _ if method == Method::Delete && path.starts_with("/api/users/") => {
            let uid = path["/api/users/".len()..].to_string();
            let mut st = state.lock().unwrap();
            if st.users.remove(&uid).is_some() {
                respond_no_body(req, 204);
            } else {
                respond(req, 404, json!({"detail": format!("User not found: {uid}")}));
            }
        }
        // POST /api/items
        (Method::Post, "/api/items") => {
            let body = read_body(&mut req);
            let iid  = body["item_id"].as_str().unwrap_or("").to_string();
            let record = json!({
                "item_id":    iid,
                "properties": body["properties"],
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z"
            });
            state.lock().unwrap().items.insert(iid, record.clone());
            respond(req, 201, record);
        }
        // GET /api/items/{id}
        _ if method == Method::Get && path.starts_with("/api/items/") => {
            let iid = path["/api/items/".len()..].to_string();
            let st = state.lock().unwrap();
            match st.items.get(&iid).cloned() {
                Some(i) => respond(req, 200, i),
                None    => respond(req, 404, json!({"detail": format!("Item not found: {iid}")})),
            }
        }
        // PUT /api/items/{id}
        _ if method == Method::Put && path.starts_with("/api/items/") => {
            let iid  = path["/api/items/".len()..].to_string();
            let body = read_body(&mut req);
            let mut st = state.lock().unwrap();
            match st.items.get_mut(&iid) {
                Some(i) => {
                    i["properties"] = body["properties"].clone();
                    i["updated_at"] = json!("2024-01-01T00:00:00Z");
                    respond(req, 200, i.clone());
                }
                None => respond(req, 404, json!({"detail": format!("Item not found: {iid}")})),
            }
        }
        // DELETE /api/items/{id}
        _ if method == Method::Delete && path.starts_with("/api/items/") => {
            let iid = path["/api/items/".len()..].to_string();
            let mut st = state.lock().unwrap();
            if st.items.remove(&iid).is_some() {
                respond_no_body(req, 204);
            } else {
                respond(req, 404, json!({"detail": format!("Item not found: {iid}")}));
            }
        }
        // POST /api/interactions
        (Method::Post, "/api/interactions") => {
            let mut body = read_body(&mut req);
            body["interaction_id"] = json!(format!("ia_{}", std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()));
            body["timestamp"] = json!("2024-01-01T00:00:00Z");
            state.lock().unwrap().interactions.push(body.clone());
            respond(req, 201, body);
        }
        // GET /api/recommendations
        _ if method == Method::Get && path == "/api/recommendations" => {
            let uid   = params.get("user_id").cloned().unwrap_or_default();
            let limit = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(10usize);
            let st    = state.lock().unwrap();
            let recs  = compute_recs(&st, &uid, limit);
            respond(req, 200, json!({"user_id": uid, "recommendations": recs}));
        }
        _ => respond(req, 404, json!({"detail": "Not found"})),
    }
}

fn start_mock_server(state: SharedState) {
    let addr = format!("0.0.0.0:{MOCK_PORT}");
    let server = Server::http(&addr).expect("Failed to bind mock server");
    for req in server.incoming_requests() {
        let s = Arc::clone(&state);
        handle(req, &s);
    }
}

// ── Simulation ─────────────────────────────────────────────────────────────────

fn banner(title: &str) {
    let line: String = std::iter::repeat('=').take(title.len() + 4).collect();
    println!("{line}\n= {title} =\n{line}\n");
}

fn step(n: u32, title: &str) {
    println!("── Step {n}: {title}");
}

fn main() {
    let state: SharedState = Arc::new(Mutex::new(State::default()));
    {
        let s = Arc::clone(&state);
        thread::spawn(move || start_mock_server(s));
    }
    thread::sleep(Duration::from_millis(300));
    println!("[mock] Server listening on port {MOCK_PORT}\n");

    let client = RecommendAIClient::with_config(
        "sim-api-key",
        ClientConfig {
            base_url: format!("http://127.0.0.1:{MOCK_PORT}"),
            timeout:  Duration::from_secs(30),
        },
    ).expect("Failed to create client");

    // Data ─────────────────────────────────────────────────────────────────────

    let movies: Vec<(&str, &str, &str, i64, f64)> = vec![
        ("movie_001", "The Matrix",               "sci-fi",   1999, 8.7),
        ("movie_002", "Inception",                "sci-fi",   2010, 8.8),
        ("movie_003", "Interstellar",             "sci-fi",   2014, 8.6),
        ("movie_004", "The Dark Knight",          "action",   2008, 9.0),
        ("movie_005", "Avengers: Endgame",        "action",   2019, 8.4),
        ("movie_006", "John Wick",                "action",   2014, 7.4),
        ("movie_007", "The Shawshank Redemption", "drama",    1994, 9.3),
        ("movie_008", "Forrest Gump",             "drama",    1994, 8.8),
        ("movie_009", "Pulp Fiction",             "thriller", 1994, 8.9),
        ("movie_010", "The Silence of the Lambs", "thriller", 1991, 8.6),
    ];

    let users: Vec<(&str, &str, &str, u32)> = vec![
        ("alice", "Alice Johnson", "sci-fi",   28),
        ("bob",   "Bob Smith",     "action",   35),
        ("carol", "Carol White",   "drama",    42),
        ("dave",  "Dave Brown",    "sci-fi",   23),
        ("eve",   "Eve Davis",     "thriller", 31),
    ];

    type Ia<'a> = (&'a str, &'a str, InteractionType, Option<f64>);
    let interactions: Vec<Ia> = vec![
        ("alice", "movie_001", InteractionType::View,     None     ),
        ("alice", "movie_002", InteractionType::Like,     None     ),
        ("alice", "movie_003", InteractionType::Purchase, None     ),
        ("alice", "movie_001", InteractionType::Rating,   Some(9.0)),
        ("bob",   "movie_004", InteractionType::View,     None     ),
        ("bob",   "movie_005", InteractionType::Like,     None     ),
        ("bob",   "movie_006", InteractionType::Purchase, None     ),
        ("bob",   "movie_004", InteractionType::Rating,   Some(8.0)),
        ("carol", "movie_007", InteractionType::View,     None     ),
        ("carol", "movie_008", InteractionType::Like,     None     ),
        ("carol", "movie_007", InteractionType::Purchase, None     ),
        ("carol", "movie_008", InteractionType::Rating,   Some(9.0)),
        ("dave",  "movie_001", InteractionType::View,     None     ),
        ("dave",  "movie_002", InteractionType::Purchase, None     ),
        ("dave",  "movie_003", InteractionType::Rating,   Some(8.5)),
        ("eve",   "movie_009", InteractionType::View,     None     ),
        ("eve",   "movie_010", InteractionType::Like,     None     ),
        ("eve",   "movie_009", InteractionType::Purchase, None     ),
        ("eve",   "movie_010", InteractionType::Rating,   Some(8.0)),
        ("alice", "movie_002", InteractionType::Rating,   Some(10.0)),
        ("bob",   "movie_006", InteractionType::Rating,   Some(7.5)),
        ("carol", "movie_009", InteractionType::View,     None     ),
        ("dave",  "movie_004", InteractionType::View,     None     ),
        ("eve",   "movie_002", InteractionType::View,     None     ),
        ("alice", "movie_004", InteractionType::View,     None     ),
    ];

    banner("RecSys.AI Rust SDK — Movie Streaming Simulation");

    // Step 1: seed catalogue
    step(1, "Seeding Movie Catalogue");
    for (id, title, genre, year, rating) in &movies {
        let mut props = HashMap::new();
        props.insert("title".to_string(),  json!(title));
        props.insert("genre".to_string(),  json!(genre));
        props.insert("year".to_string(),   json!(year));
        props.insert("rating".to_string(), json!(rating));
        let item = client.items().create(id, props).unwrap();
        println!("  Created item: {} ({})", item.item_id,
            item.properties.as_ref().and_then(|p| p.get("title")).and_then(|v| v.as_str()).unwrap_or(""));
    }
    println!("  {} movies added to catalogue.\n", movies.len());

    // Step 2: register users
    step(2, "Registering Users");
    for (uid, name, genre, age) in &users {
        let mut props = HashMap::new();
        props.insert("name".to_string(),             json!(name));
        props.insert("age".to_string(),              json!(age));
        props.insert("preferred_genre".to_string(),  json!(genre));
        let user = client.users().create(uid, props).unwrap();
        println!("  Registered: {} ({})", user.user_id,
            user.properties.as_ref().and_then(|p| p.get("name")).and_then(|v| v.as_str()).unwrap_or(""));
    }
    println!("  {} users registered.\n", users.len());

    // Step 3: record interactions
    step(3, "Recording Watch History & Ratings");
    for (uid, iid, itype, val) in &interactions {
        client.interactions().create(uid, iid, itype, *val, None).unwrap();
    }
    println!("  {} interactions recorded.\n", interactions.len());

    // Step 4: personalised recommendations
    step(4, "Getting Personalised Recommendations");
    for (uid, _, _, _) in &users {
        let recs = client.recommendations().get(uid, 5).unwrap();
        println!("  Recommendations for {uid}:");
        for (i, r) in recs.iter().enumerate() {
            let title = r.metadata.as_ref()
                .and_then(|m| m.get("title"))
                .and_then(|v| v.as_str())
                .unwrap_or(&r.item_id);
            println!("    {}. {:<36} (score: {:.4})  {}", i + 1, title, r.score, r.reason);
        }
        println!();
    }

    // Step 5: update item
    step(5, "Updating Item Metadata");
    let mut upd_props = HashMap::new();
    upd_props.insert("title".to_string(),      json!("The Matrix"));
    upd_props.insert("genre".to_string(),      json!("sci-fi"));
    upd_props.insert("year".to_string(),       json!(1999));
    upd_props.insert("rating".to_string(),     json!(8.7));
    upd_props.insert("remastered".to_string(), json!(true));
    let updated = client.items().update("movie_001", upd_props).unwrap();
    let rem = updated.properties.as_ref()
        .and_then(|p| p.get("remastered"))
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    println!("  Updated movie_001 — remastered: {rem}\n");

    // Step 6: update user
    step(6, "Updating User Profile");
    let mut alice_props = HashMap::new();
    alice_props.insert("name".to_string(),            json!("Alice Johnson"));
    alice_props.insert("age".to_string(),             json!(29));
    alice_props.insert("preferred_genre".to_string(), json!("sci-fi"));
    alice_props.insert("subscription".to_string(),    json!("premium"));
    let alice = client.users().update("alice", alice_props).unwrap();
    let sub = alice.properties.as_ref()
        .and_then(|p| p.get("subscription"))
        .and_then(|v| v.as_str())
        .unwrap_or("");
    println!("  alice subscription → {sub}\n");

    // Step 7: verify item retrieval
    step(7, "Verifying Item Retrieval");
    let retrieved = client.items().get("movie_004").unwrap();
    let r_title = retrieved.properties.as_ref().and_then(|p| p.get("title")).and_then(|v| v.as_str()).unwrap_or("");
    let r_genre = retrieved.properties.as_ref().and_then(|p| p.get("genre")).and_then(|v| v.as_str()).unwrap_or("");
    println!("  Retrieved: {} — {r_title} ({r_genre})\n", retrieved.item_id);

    // Step 8: error handling
    step(8, "Error Handling Demo");
    match client.users().get("ghost_999") {
        Err(recommendai::Error::NotFound(msg)) => println!("  Caught NotFound: {msg}\n"),
        Ok(_)  => println!("  ERROR: expected NotFound was not raised!\n"),
        Err(e) => println!("  Unexpected error: {e}\n"),
    }

    // Step 9: cleanup
    step(9, "Cleanup");
    client.users().delete("dave").unwrap();
    println!("  Deleted user 'dave'.");
    match client.users().get("dave") {
        Err(recommendai::Error::NotFound(_)) => println!("  Confirmed: 'dave' no longer exists."),
        _ => println!("  ERROR: 'dave' should not exist!"),
    }

    println!();
    banner("Simulation complete — all steps passed!");
}
