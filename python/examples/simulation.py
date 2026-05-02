#!/usr/bin/env python3
"""
RecSys.AI Python SDK — Integration Simulation
=============================================
A self-contained simulation demonstrating the full RecSys.AI recommendation
workflow against a local mock API server. No live service required.

Scenario: A movie-streaming service that personalises content for its users.

Usage:
    # From the SDK root directory:
    pip install -e .           # install the SDK in editable mode
    python examples/simulation.py

    # Or run directly (resolves the package via sys.path):
    python recommendai-sdks/python/examples/simulation.py
"""

import asyncio
import json
import sys
import threading
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

# ── Path setup ────────────────────────────────────────────────────────────────
# Support running the script from any directory.
_sdk_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_sdk_root))

from recommendai import AsyncRecommendAIClient, RecommendAIClient  # noqa: E402
from recommendai.models import InteractionType  # noqa: E402

# ── Configuration ─────────────────────────────────────────────────────────────
MOCK_PORT = 17890
MOCK_BASE_URL = f"http://localhost:{MOCK_PORT}"
DEMO_API_KEY = "sim_demo_key_1234567890abcdef"

# ── ANSI colour helpers ────────────────────────────────────────────────────────
_SUPPORTS_COLOUR = sys.stdout.isatty()

GREEN   = "\033[92m" if _SUPPORTS_COLOUR else ""
CYAN    = "\033[96m" if _SUPPORTS_COLOUR else ""
YELLOW  = "\033[93m" if _SUPPORTS_COLOUR else ""
BOLD    = "\033[1m"  if _SUPPORTS_COLOUR else ""
DIM     = "\033[2m"  if _SUPPORTS_COLOUR else ""
RESET   = "\033[0m"  if _SUPPORTS_COLOUR else ""


def header(text: str) -> None:
    print(f"\n{BOLD}{CYAN}{'─' * 62}{RESET}")
    print(f"{BOLD}{CYAN}  {text}{RESET}")
    print(f"{BOLD}{CYAN}{'─' * 62}{RESET}")


def step(text: str) -> None:
    print(f"  {GREEN}▶{RESET} {text}")


def success(text: str) -> None:
    print(f"  {GREEN}✓{RESET} {text}")


# ── In-memory data store ───────────────────────────────────────────────────────
_store: dict = {"users": {}, "items": {}, "interactions": []}


def _compute_recommendations(user_id: str, limit: int) -> list:
    """
    Produce mock recommendations using a simple scoring heuristic:
    - Items from genres the user has purchased/liked/rated get a bonus.
    - Items not yet interacted with score higher (discovery).
    - Score is deterministic given (user_id, item_id) so results are
      consistent across calls within a single simulation run.
    """
    user_ixs = [i for i in _store["interactions"] if i["user_id"] == user_id]
    interacted_ids = {i["item_id"] for i in user_ixs}

    preferred_genres: set = set()
    for ix in user_ixs:
        if ix["interaction_type"] in ("PURCHASE", "LIKE", "RATING"):
            genre = _store["items"].get(ix["item_id"], {}).get("properties", {}).get("genre")
            if genre:
                preferred_genres.add(genre)

    candidates = []
    for item_id, item in _store["items"].items():
        genre = item.get("properties", {}).get("genre", "")
        is_seen = item_id in interacted_ids
        genre_bonus = 0.15 if genre in preferred_genres else 0.0
        # Deterministic pseudo-random base in [0.000, 0.399]
        base = (abs(hash(user_id + item_id)) % 400) / 1000
        score = round(min((0.35 if is_seen else 0.60) + base + genre_bonus, 0.999), 3)
        reason = (
            "watch_again" if is_seen
            else ("because_you_liked_genre" if genre in preferred_genres
                  else "collaborative_filtering")
        )
        candidates.append({
            "item_id": item_id,
            "score": score,
            "reason": reason,
            "metadata": {"genre": genre, "title": item.get("properties", {}).get("title", "")},
        })

    candidates.sort(key=lambda x: x["score"], reverse=True)
    return candidates[:limit]


# ── Mock HTTP server ───────────────────────────────────────────────────────────
class _MockAPIHandler(BaseHTTPRequestHandler):
    """Minimal in-process HTTP server that simulates the RecSys.AI REST API."""

    def log_message(self, fmt, *args) -> None:  # silence default request logs
        pass

    # ── helpers ──────────────────────────────────────────────────────────────
    def _send_json(self, status: int, data) -> None:
        body = json.dumps(data, default=str).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(length)) if length else {}

    def _now(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    # ── GET ───────────────────────────────────────────────────────────────────
    def do_GET(self):
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        path = parsed.path

        if path == "/api/recommendations":
            user_id = qs.get("user_id", ["unknown"])[0]
            limit = int(qs.get("limit", ["10"])[0])
            self._send_json(200, {
                "user_id": user_id,
                "recommendations": _compute_recommendations(user_id, limit),
                "request_id": str(uuid.uuid4()),
            })

        elif path.startswith("/api/users/"):
            uid = path[len("/api/users/"):]
            obj = _store["users"].get(uid)
            self._send_json(200 if obj else 404, obj or {"detail": "User not found"})

        elif path.startswith("/api/items/"):
            iid = path[len("/api/items/"):]
            obj = _store["items"].get(iid)
            self._send_json(200 if obj else 404, obj or {"detail": "Item not found"})

        else:
            self._send_json(404, {"detail": "Not found"})

    # ── POST ──────────────────────────────────────────────────────────────────
    def do_POST(self):
        body = self._read_body()
        now = self._now()

        if self.path == "/api/users":
            uid = body.get("user_id", str(uuid.uuid4()))
            obj = {"user_id": uid, "properties": body.get("properties", {}),
                   "created_at": now, "updated_at": now}
            _store["users"][uid] = obj
            self._send_json(201, obj)

        elif self.path == "/api/items":
            iid = body.get("item_id", str(uuid.uuid4()))
            obj = {"item_id": iid, "properties": body.get("properties", {}),
                   "created_at": now, "updated_at": now}
            _store["items"][iid] = obj
            self._send_json(201, obj)

        elif self.path == "/api/interactions":
            obj = {
                "interaction_id": str(uuid.uuid4()),
                "user_id": body.get("user_id"),
                "item_id": body.get("item_id"),
                "interaction_type": body.get("interaction_type"),
                "value": body.get("value"),
                "timestamp": now,
                "metadata": body.get("metadata", {}),
            }
            _store["interactions"].append(obj)
            self._send_json(201, obj)

        else:
            self._send_json(404, {"detail": "Not found"})

    # ── PUT ───────────────────────────────────────────────────────────────────
    def do_PUT(self):
        body = self._read_body()
        now = self._now()

        if self.path.startswith("/api/users/"):
            uid = self.path[len("/api/users/"):]
            if uid in _store["users"]:
                _store["users"][uid]["properties"] = body.get("properties", {})
                _store["users"][uid]["updated_at"] = now
                self._send_json(200, _store["users"][uid])
            else:
                self._send_json(404, {"detail": "User not found"})

        elif self.path.startswith("/api/items/"):
            iid = self.path[len("/api/items/"):]
            if iid in _store["items"]:
                _store["items"][iid]["properties"] = body.get("properties", {})
                _store["items"][iid]["updated_at"] = now
                self._send_json(200, _store["items"][iid])
            else:
                self._send_json(404, {"detail": "Item not found"})

        else:
            self._send_json(404, {"detail": "Not found"})

    # ── DELETE ────────────────────────────────────────────────────────────────
    def do_DELETE(self):
        if self.path.startswith("/api/users/"):
            _store["users"].pop(self.path[len("/api/users/"):], None)
            self.send_response(204)
            self.end_headers()
        elif self.path.startswith("/api/items/"):
            _store["items"].pop(self.path[len("/api/items/"):], None)
            self.send_response(204)
            self.end_headers()
        else:
            self._send_json(404, {"detail": "Not found"})


def _start_mock_server() -> HTTPServer:
    server = HTTPServer(("localhost", MOCK_PORT), _MockAPIHandler)
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    time.sleep(0.1)  # give the server time to bind
    return server


# ── Sample data ────────────────────────────────────────────────────────────────
_USERS = [
    {"id": "alice",  "name": "Alice Chen",     "tier": "premium",  "age_group": "25-34"},
    {"id": "bob",    "name": "Bob Martinez",   "tier": "standard", "age_group": "35-44"},
    {"id": "carol",  "name": "Carol Johnson",  "tier": "premium",  "age_group": "18-24"},
    {"id": "dave",   "name": "Dave Kim",       "tier": "standard", "age_group": "45-54"},
    {"id": "eve",    "name": "Eve Thompson",   "tier": "premium",  "age_group": "25-34"},
]

_MOVIES = [
    {"id": "movie-001", "title": "Galactic Odyssey",   "genre": "sci-fi",  "year": 2023, "rating": 8.5},
    {"id": "movie-002", "title": "The Last Garden",    "genre": "drama",   "year": 2022, "rating": 7.9},
    {"id": "movie-003", "title": "Laugh Factory",      "genre": "comedy",  "year": 2023, "rating": 7.2},
    {"id": "movie-004", "title": "Quantum Protocol",   "genre": "sci-fi",  "year": 2021, "rating": 8.1},
    {"id": "movie-005", "title": "City Lights",        "genre": "drama",   "year": 2023, "rating": 8.3},
    {"id": "movie-006", "title": "Thunder Force",      "genre": "action",  "year": 2022, "rating": 7.5},
    {"id": "movie-007", "title": "Weekend Escape",     "genre": "comedy",  "year": 2021, "rating": 6.8},
    {"id": "movie-008", "title": "Neural Divide",      "genre": "sci-fi",  "year": 2023, "rating": 9.0},
    {"id": "movie-009", "title": "Beneath the Storm",  "genre": "action",  "year": 2022, "rating": 7.7},
    {"id": "movie-010", "title": "Whispered Truths",   "genre": "drama",   "year": 2021, "rating": 8.6},
]

# (user_id, movie_id, interaction_type, value)
_INTERACTIONS = [
    # Alice loves sci-fi
    ("alice", "movie-001", InteractionType.VIEW,     None),
    ("alice", "movie-001", InteractionType.RATING,   9.0),
    ("alice", "movie-004", InteractionType.VIEW,     None),
    ("alice", "movie-004", InteractionType.LIKE,     None),
    ("alice", "movie-008", InteractionType.VIEW,     None),
    ("alice", "movie-008", InteractionType.RATING,   9.5),
    # Bob prefers drama and action
    ("bob",   "movie-002", InteractionType.VIEW,     None),
    ("bob",   "movie-002", InteractionType.PURCHASE, None),
    ("bob",   "movie-005", InteractionType.VIEW,     None),
    ("bob",   "movie-005", InteractionType.RATING,   8.0),
    ("bob",   "movie-006", InteractionType.VIEW,     None),
    ("bob",   "movie-009", InteractionType.LIKE,     None),
    # Carol enjoys comedy and action
    ("carol", "movie-003", InteractionType.VIEW,     None),
    ("carol", "movie-003", InteractionType.RATING,   7.5),
    ("carol", "movie-006", InteractionType.VIEW,     None),
    ("carol", "movie-007", InteractionType.VIEW,     None),
    ("carol", "movie-007", InteractionType.PURCHASE, None),
    # Dave watches a mix
    ("dave",  "movie-001", InteractionType.VIEW,     None),
    ("dave",  "movie-002", InteractionType.VIEW,     None),
    ("dave",  "movie-010", InteractionType.RATING,   9.0),
    # Eve is a premium power-user
    ("eve",   "movie-001", InteractionType.VIEW,     None),
    ("eve",   "movie-003", InteractionType.VIEW,     None),
    ("eve",   "movie-005", InteractionType.LIKE,     None),
    ("eve",   "movie-008", InteractionType.RATING,   8.5),
    ("eve",   "movie-010", InteractionType.PURCHASE, None),
]


# ── Synchronous simulation ─────────────────────────────────────────────────────
def run_sync_simulation() -> None:
    header("SYNC CLIENT — Full Recommendation Workflow")

    with RecommendAIClient(api_key=DEMO_API_KEY, base_url=MOCK_BASE_URL) as client:

        # ── 1. Seed the movie catalog ─────────────────────────────────────────
        header("Step 1 · Seeding Movie Catalog")
        for movie in _MOVIES:
            item = client.items.create(
                item_id=movie["id"],
                properties={
                    "title": movie["title"],
                    "genre": movie["genre"],
                    "year": movie["year"],
                    "rating": movie["rating"],
                },
            )
            step(f"Created item  {item.item_id!r:<14s}  [{movie['genre']:<7s}]  {movie['title']}")
        success(f"Catalog seeded with {len(_MOVIES)} movies")

        # ── 2. Register users ─────────────────────────────────────────────────
        header("Step 2 · Registering Users")
        for u in _USERS:
            user = client.users.create(
                user_id=u["id"],
                properties={"name": u["name"], "tier": u["tier"], "age_group": u["age_group"]},
            )
            step(f"Registered user  {user.user_id!r:<8s}  ({u['name']}, tier={u['tier']})")
        success(f"Registered {len(_USERS)} users")

        # ── 3. Record interactions ────────────────────────────────────────────
        header("Step 3 · Recording User Interactions")
        for user_id, item_id, itype, value in _INTERACTIONS:
            client.interactions.create(
                user_id=user_id,
                item_id=item_id,
                interaction_type=itype,
                value=value,
            )
            movie_title = next(m["title"] for m in _MOVIES if m["id"] == item_id)
            val_str = f"  (value={value})" if value is not None else ""
            step(f"{user_id:6s}  →  {itype.value:<9s}  {movie_title}{val_str}")
        success(f"Recorded {len(_INTERACTIONS)} interactions")

        # ── 4. Get personalised recommendations ───────────────────────────────
        header("Step 4 · Personalised Recommendations")
        for u in _USERS:
            recs = client.recommendations.get(user_id=u["id"], limit=5)
            print(f"\n  {BOLD}{YELLOW}{u['name']}{RESET}'s top {len(recs)} picks:")
            for rank, rec in enumerate(recs, 1):
                item = client.items.get(item_id=rec.item_id)
                title = item.properties.get("title", rec.item_id)
                genre = item.properties.get("genre", "?")
                print(
                    f"    {rank}. {title:<32s}  score={rec.score:.3f}"
                    f"  [{genre:<7s}]  ({rec.reason})"
                )

        # ── 5. Update metadata ────────────────────────────────────────────────
        header("Step 5 · Updating Item Metadata")
        updated = client.items.update(
            "movie-001",
            {"title": "Galactic Odyssey: Remastered", "genre": "sci-fi",
             "year": 2024, "rating": 8.7},
        )
        step(f"Updated title → {updated.properties.get('title')!r}")

        # ── 6. Update a user profile ──────────────────────────────────────────
        header("Step 6 · Updating User Profile")
        refreshed = client.users.update("alice", {"tier": "elite", "age_group": "25-34"})
        step(f"alice's tier is now: {refreshed.properties.get('tier')!r}")

        # ── 7. Delete a user (cleanup) ────────────────────────────────────────
        header("Step 7 · Clean-up")
        client.users.delete("dave")
        step("Deleted test user 'dave'")
        success("Sync simulation complete")


# ── Async simulation ───────────────────────────────────────────────────────────
async def run_async_simulation() -> None:
    header("ASYNC CLIENT — Concurrent Recommendation Fetching")

    async with AsyncRecommendAIClient(api_key=DEMO_API_KEY, base_url=MOCK_BASE_URL) as client:

        # ── A. Record a new interaction asynchronously ────────────────────────
        header("Async A · Recording Interaction")
        ix = await client.interactions.create(
            user_id="carol",
            item_id="movie-008",
            interaction_type=InteractionType.CLICK,
        )
        step(f"Interaction recorded  id={ix.interaction_id}  type={ix.interaction_type}")

        # ── B. Fetch recommendations for two users concurrently ───────────────
        header("Async B · Concurrent Recommendations")
        alice_task = asyncio.create_task(
            client.recommendations.get(user_id="alice", limit=3)
        )
        eve_task = asyncio.create_task(
            client.recommendations.get(user_id="eve", limit=3)
        )
        alice_recs, eve_recs = await asyncio.gather(alice_task, eve_task)

        print(f"\n  {BOLD}{YELLOW}Alice{RESET} (concurrent fetch):")
        for rank, rec in enumerate(alice_recs, 1):
            print(f"    {rank}. item_id={rec.item_id!r:<14s}  score={rec.score:.3f}  ({rec.reason})")

        print(f"\n  {BOLD}{YELLOW}Eve{RESET} (concurrent fetch):")
        for rank, rec in enumerate(eve_recs, 1):
            print(f"    {rank}. item_id={rec.item_id!r:<14s}  score={rec.score:.3f}  ({rec.reason})")

        # ── C. Async user profile lookup ──────────────────────────────────────
        header("Async C · User Profile")
        alice = await client.users.get("alice")
        step(f"Fetched user  id={alice.user_id!r}  tier={alice.properties.get('tier')!r}")

    success("Async simulation complete")


# ── Error-handling demonstration ───────────────────────────────────────────────
def run_error_demo() -> None:
    header("Error Handling Demo")
    from recommendai.exceptions import NotFoundError

    with RecommendAIClient(api_key=DEMO_API_KEY, base_url=MOCK_BASE_URL) as client:
        try:
            client.users.get("nonexistent-user-xyz")
        except NotFoundError as exc:
            success(f"NotFoundError caught correctly: status={exc.status_code}, msg={exc.message!r}")


# ── Entry point ────────────────────────────────────────────────────────────────
def main() -> None:
    print(f"\n{BOLD}{'=' * 62}{RESET}")
    print(f"{BOLD}  RecSys.AI Python SDK — Integration Simulation{RESET}")
    print(f"{BOLD}{'=' * 62}{RESET}")
    print(f"\n{DIM}Starting in-process mock API server on port {MOCK_PORT} ...{RESET}")
    server = _start_mock_server()
    print(f"{GREEN}✓{RESET} Mock server running at {BOLD}{MOCK_BASE_URL}{RESET}\n")

    try:
        run_sync_simulation()
        asyncio.run(run_async_simulation())
        run_error_demo()

        print(f"\n{BOLD}{GREEN}{'=' * 62}{RESET}")
        print(f"{BOLD}{GREEN}  All simulations completed successfully!{RESET}")
        print(f"{BOLD}{GREEN}{'=' * 62}{RESET}\n")
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
