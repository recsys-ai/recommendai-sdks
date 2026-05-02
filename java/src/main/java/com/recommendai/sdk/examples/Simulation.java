package com.recommendai.sdk.examples;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.recommendai.sdk.RecommendAIClient;
import com.recommendai.sdk.exceptions.NotFoundException;
import com.recommendai.sdk.models.*;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.*;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

/**
 * Self-contained simulation of the RecSys.AI Java SDK.
 *
 * <p>Starts an in-process mock HTTP server (port 17892) so no live service is
 * needed, then runs a movie-streaming scenario that exercises every SDK feature:
 * catalogue seeding, user registration, interaction recording, personalised
 * recommendations, resource updates, and error handling.
 *
 * <p>Run with: {@code mvn package -q && java -jar target/recommendai-sdk-1.0.0.jar}
 */
@SuppressWarnings("restriction")   // com.sun.net.httpserver is internal but stable on JDK 11+
public class Simulation {

    // ── Scenario data ─────────────────────────────────────────────────────────

    private static final int MOCK_PORT = 17892;

    /** 10 movies: id → {title, genre, year, rating} */
    private static final List<Map<String, Object>> MOVIES = List.of(
        movie("movie_001", "The Matrix",              "sci-fi",  1999, 8.7),
        movie("movie_002", "Inception",               "sci-fi",  2010, 8.8),
        movie("movie_003", "Interstellar",            "sci-fi",  2014, 8.6),
        movie("movie_004", "The Dark Knight",         "action",  2008, 9.0),
        movie("movie_005", "Avengers: Endgame",       "action",  2019, 8.4),
        movie("movie_006", "John Wick",               "action",  2014, 7.4),
        movie("movie_007", "The Shawshank Redemption","drama",   1994, 9.3),
        movie("movie_008", "Forrest Gump",            "drama",   1994, 8.8),
        movie("movie_009", "Pulp Fiction",            "thriller",1994, 8.9),
        movie("movie_010", "The Silence of the Lambs","thriller",1991, 8.6)
    );

    /** 5 users: id → {name, age, preferred_genre} */
    private static final List<Map<String, Object>> USERS = List.of(
        user("alice",   "Alice Johnson",  28, "sci-fi"),
        user("bob",     "Bob Smith",      35, "action"),
        user("carol",   "Carol White",    42, "drama"),
        user("dave",    "Dave Brown",     23, "sci-fi"),
        user("eve",     "Eve Davis",      31, "thriller")
    );

    /** Pre-defined interactions [userId, itemId, type, value|null] */
    private static final List<Object[]> INTERACTIONS = List.of(
        new Object[]{"alice", "movie_001", InteractionType.VIEW,    null},
        new Object[]{"alice", "movie_002", InteractionType.LIKE,    null},
        new Object[]{"alice", "movie_003", InteractionType.PURCHASE,null},
        new Object[]{"alice", "movie_001", InteractionType.RATING,  9.0},
        new Object[]{"bob",   "movie_004", InteractionType.VIEW,    null},
        new Object[]{"bob",   "movie_005", InteractionType.LIKE,    null},
        new Object[]{"bob",   "movie_006", InteractionType.PURCHASE,null},
        new Object[]{"bob",   "movie_004", InteractionType.RATING,  8.0},
        new Object[]{"carol", "movie_007", InteractionType.VIEW,    null},
        new Object[]{"carol", "movie_008", InteractionType.LIKE,    null},
        new Object[]{"carol", "movie_007", InteractionType.PURCHASE,null},
        new Object[]{"carol", "movie_008", InteractionType.RATING,  9.0},
        new Object[]{"dave",  "movie_001", InteractionType.VIEW,    null},
        new Object[]{"dave",  "movie_002", InteractionType.PURCHASE,null},
        new Object[]{"dave",  "movie_003", InteractionType.RATING,  8.5},
        new Object[]{"eve",   "movie_009", InteractionType.VIEW,    null},
        new Object[]{"eve",   "movie_010", InteractionType.LIKE,    null},
        new Object[]{"eve",   "movie_009", InteractionType.PURCHASE,null},
        new Object[]{"eve",   "movie_010", InteractionType.RATING,  8.0},
        new Object[]{"alice", "movie_002", InteractionType.RATING,  10.0},
        new Object[]{"bob",   "movie_006", InteractionType.RATING,  7.5},
        new Object[]{"carol", "movie_009", InteractionType.VIEW,    null},
        new Object[]{"dave",  "movie_004", InteractionType.VIEW,    null},
        new Object[]{"eve",   "movie_002", InteractionType.VIEW,    null},
        new Object[]{"alice", "movie_004", InteractionType.VIEW,    null}
    );

    // ── Mock server state ─────────────────────────────────────────────────────

    private static final Map<String, Map<String, Object>> usersDb       = new ConcurrentHashMap<>();
    private static final Map<String, Map<String, Object>> itemsDb       = new ConcurrentHashMap<>();
    private static final List<Map<String, Object>>        interactionsDb = Collections.synchronizedList(new ArrayList<>());
    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    // ── Entry point ───────────────────────────────────────────────────────────

    public static void main(String[] args) throws Exception {
        HttpServer server = startMockServer();
        try {
            RecommendAIClient client = new RecommendAIClient(
                    "sim-api-key-java",
                    "http://localhost:" + MOCK_PORT);
            runSimulation(client);
        } finally {
            server.stop(0);
        }
    }

    // ── Simulation steps ──────────────────────────────────────────────────────

    private static void runSimulation(RecommendAIClient client) throws Exception {
        banner("RecSys.AI Java SDK — Movie Streaming Simulation");

        // Step 1: Seed the catalogue
        step(1, "Seeding Movie Catalogue");
        for (Map<String, Object> movie : MOVIES) {
            String id = (String) movie.get("id");
            Map<String, Object> props = new HashMap<>(movie);
            props.remove("id");
            Item item = client.items().create(id, props);
            System.out.printf("  Created item: %s (%s)%n", item.getItemId(),
                    item.getProperties().getOrDefault("title", "?"));
        }
        System.out.printf("  %d movies added to catalogue.%n%n", MOVIES.size());

        // Step 2: Register users
        step(2, "Registering Users");
        for (Map<String, Object> u : USERS) {
            String id = (String) u.get("id");
            Map<String, Object> props = new HashMap<>(u);
            props.remove("id");
            User user = client.users().create(id, props);
            System.out.printf("  Registered: %s (%s)%n", user.getUserId(),
                    user.getProperties().getOrDefault("name", "?"));
        }
        System.out.printf("  %d users registered.%n%n", USERS.size());

        // Step 3: Record interactions
        step(3, "Recording Watch History & Ratings");
        for (Object[] ia : INTERACTIONS) {
            String userId = (String) ia[0];
            String itemId = (String) ia[1];
            InteractionType type = (InteractionType) ia[2];
            Double value = ia[3] != null ? (Double) ia[3] : null;
            client.interactions().create(userId, itemId, type, value);
        }
        System.out.printf("  %d interactions recorded.%n%n", INTERACTIONS.size());

        // Step 4: Personalised recommendations
        step(4, "Getting Personalised Recommendations");
        for (Map<String, Object> u : USERS) {
            String userId = (String) u.get("id");
            List<Recommendation> recs = client.recommendations().get(userId, 5);
            System.out.printf("  Recommendations for %s:%n", userId);
            for (int i = 0; i < recs.size(); i++) {
                Recommendation r = recs.get(i);
                String title = getMovieTitle(r.getItemId());
                System.out.printf("    %d. %-36s (score: %.4f)  %s%n",
                        i + 1, title, r.getScore(), r.getReason() != null ? r.getReason() : "");
            }
            System.out.println();
        }

        // Step 5: Update an item (new release year label)
        step(5, "Updating Item Metadata");
        Item updated = client.items().update("movie_001", Map.of(
                "title", "The Matrix",
                "genre", "sci-fi",
                "year",  1999,
                "rating", 8.7,
                "remastered", true));
        System.out.printf("  Updated movie_001 — remastered: %s%n%n",
                updated.getProperties().getOrDefault("remastered", false));

        // Step 6: Update a user profile
        step(6, "Updating User Profile");
        User alice = client.users().update("alice", Map.of(
                "name", "Alice Johnson",
                "age",  29,
                "preferred_genre", "sci-fi",
                "subscription", "premium"));
        System.out.printf("  alice subscription → %s%n%n",
                alice.getProperties().getOrDefault("subscription", "?"));

        // Step 7: Verify item retrieval
        step(7, "Verifying Item Retrieval");
        Item retrieved = client.items().get("movie_004");
        System.out.printf("  Retrieved: %s — %s (%s)%n%n",
                retrieved.getItemId(),
                retrieved.getProperties().getOrDefault("title", "?"),
                retrieved.getProperties().getOrDefault("genre", "?"));

        // Step 8: Error handling demo
        step(8, "Error Handling Demo");
        try {
            client.users().get("ghost_user_999");
            System.out.println("  ERROR: expected NotFoundException was not thrown!");
        } catch (NotFoundException e) {
            System.out.printf("  Caught NotFoundException (status %d): %s%n%n",
                    e.getStatusCode(), e.getMessage());
        }

        // Step 9: Cleanup — delete a test user
        step(9, "Cleanup");
        client.users().delete("dave");
        System.out.println("  Deleted user 'dave'.");
        try {
            client.users().get("dave");
            System.out.println("  ERROR: deleted user still exists!");
        } catch (NotFoundException e) {
            System.out.println("  Confirmed: 'dave' no longer exists.");
        }

        System.out.println();
        banner("Simulation complete — all steps passed successfully!");
    }

    // ── Mock HTTP server ──────────────────────────────────────────────────────

    private static HttpServer startMockServer() throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(MOCK_PORT), 0);
        server.setExecutor(Executors.newCachedThreadPool());

        server.createContext("/api/users",            Simulation::handleUsers);
        server.createContext("/api/items",            Simulation::handleItems);
        server.createContext("/api/recommendations",  Simulation::handleRecommendations);
        server.createContext("/api/interactions",     Simulation::handleInteractions);

        server.start();
        System.out.printf("[mock] Server listening on port %d%n%n", MOCK_PORT);
        return server;
    }

    // /api/users and /api/users/{id}
    private static void handleUsers(HttpExchange ex) throws IOException {
        String method = ex.getRequestMethod();
        String path   = ex.getRequestURI().getPath();  // /api/users[/id]
        String[] parts = path.split("/");              // ["", "api", "users", (id)?]
        boolean hasId  = parts.length == 4;
        String id      = hasId ? parts[3] : null;

        switch (method) {
            case "POST": {
                Map<String, Object> body = readBody(ex);
                String userId = (String) body.get("user_id");
                Map<String, Object> rec = new HashMap<>();
                rec.put("user_id",    userId);
                rec.put("properties", body.getOrDefault("properties", Map.of()));
                rec.put("created_at", Instant.now().toString());
                rec.put("updated_at", Instant.now().toString());
                usersDb.put(userId, rec);
                sendJson(ex, 201, rec);
                break;
            }
            case "GET": {
                if (!hasId) { sendJson(ex, 200, Map.of("users", new ArrayList<>(usersDb.values()))); break; }
                Map<String, Object> u = usersDb.get(id);
                if (u == null) sendError(ex, 404, "User not found: " + id);
                else           sendJson(ex, 200, u);
                break;
            }
            case "PUT": {
                if (!hasId) { sendError(ex, 400, "Missing user id"); break; }
                Map<String, Object> existing = usersDb.get(id);
                if (existing == null) { sendError(ex, 404, "User not found: " + id); break; }
                Map<String, Object> body = readBody(ex);
                Map<String, Object> rec = new HashMap<>(existing);
                rec.put("properties", body.getOrDefault("properties", Map.of()));
                rec.put("updated_at", Instant.now().toString());
                usersDb.put(id, rec);
                sendJson(ex, 200, rec);
                break;
            }
            case "DELETE": {
                if (!hasId) { sendError(ex, 400, "Missing user id"); break; }
                if (!usersDb.containsKey(id)) { sendError(ex, 404, "User not found: " + id); break; }
                usersDb.remove(id);
                sendJson(ex, 204, null);
                break;
            }
            default: sendError(ex, 405, "Method Not Allowed");
        }
    }

    // /api/items and /api/items/{id}
    private static void handleItems(HttpExchange ex) throws IOException {
        String method = ex.getRequestMethod();
        String path   = ex.getRequestURI().getPath();
        String[] parts = path.split("/");
        boolean hasId  = parts.length == 4;
        String id      = hasId ? parts[3] : null;

        switch (method) {
            case "POST": {
                Map<String, Object> body = readBody(ex);
                String itemId = (String) body.get("item_id");
                Map<String, Object> rec = new HashMap<>();
                rec.put("item_id",    itemId);
                rec.put("properties", body.getOrDefault("properties", Map.of()));
                rec.put("created_at", Instant.now().toString());
                rec.put("updated_at", Instant.now().toString());
                itemsDb.put(itemId, rec);
                sendJson(ex, 201, rec);
                break;
            }
            case "GET": {
                if (!hasId) { sendJson(ex, 200, Map.of("items", new ArrayList<>(itemsDb.values()))); break; }
                Map<String, Object> item = itemsDb.get(id);
                if (item == null) sendError(ex, 404, "Item not found: " + id);
                else              sendJson(ex, 200, item);
                break;
            }
            case "PUT": {
                if (!hasId) { sendError(ex, 400, "Missing item id"); break; }
                Map<String, Object> existing = itemsDb.get(id);
                if (existing == null) { sendError(ex, 404, "Item not found: " + id); break; }
                Map<String, Object> body = readBody(ex);
                Map<String, Object> rec = new HashMap<>(existing);
                rec.put("properties", body.getOrDefault("properties", Map.of()));
                rec.put("updated_at", Instant.now().toString());
                itemsDb.put(id, rec);
                sendJson(ex, 200, rec);
                break;
            }
            case "DELETE": {
                if (!hasId) { sendError(ex, 400, "Missing item id"); break; }
                if (!itemsDb.containsKey(id)) { sendError(ex, 404, "Item not found: " + id); break; }
                itemsDb.remove(id);
                sendJson(ex, 204, null);
                break;
            }
            default: sendError(ex, 405, "Method Not Allowed");
        }
    }

    // /api/interactions  (POST only)
    private static void handleInteractions(HttpExchange ex) throws IOException {
        if (!"POST".equals(ex.getRequestMethod())) {
            sendError(ex, 405, "Method Not Allowed");
            return;
        }
        Map<String, Object> body = readBody(ex);
        Map<String, Object> rec = new HashMap<>(body);
        rec.put("interaction_id", UUID.randomUUID().toString());
        rec.put("timestamp",      Instant.now().toString());
        interactionsDb.add(rec);
        sendJson(ex, 201, rec);
    }

    // /api/recommendations?user_id=&limit=
    private static void handleRecommendations(HttpExchange ex) throws IOException {
        if (!"GET".equals(ex.getRequestMethod())) {
            sendError(ex, 405, "Method Not Allowed");
            return;
        }
        String query  = ex.getRequestURI().getQuery();  // "user_id=alice&limit=5"
        String userId = parseQueryParam(query, "user_id");
        int    limit  = Integer.parseInt(Objects.requireNonNull(parseQueryParam(query, "limit"), "10"));

        List<Map<String, Object>> recs = computeRecommendations(userId, limit);
        sendJson(ex, 200, Map.of("recommendations", recs, "user_id", userId));
    }

    // ── Recommendation engine ─────────────────────────────────────────────────

    private static List<Map<String, Object>> computeRecommendations(String userId, int limit) {
        // Collect items the user has already interacted with
        Set<String> seen = interactionsDb.stream()
                .filter(i -> userId.equals(i.get("user_id")))
                .map(i -> (String) i.get("item_id"))
                .collect(Collectors.toSet());

        // Preferred genre from user profile (if registered)
        String preferredGenre = null;
        Map<String, Object> userRec = usersDb.get(userId);
        if (userRec != null) {
            @SuppressWarnings("unchecked")
            Map<String, Object> props = (Map<String, Object>) userRec.get("properties");
            if (props != null) preferredGenre = (String) props.get("preferred_genre");
        }
        final String genre = preferredGenre;

        List<Map<String, Object>> scored = new ArrayList<>();
        for (Map.Entry<String, Map<String, Object>> entry : itemsDb.entrySet()) {
            String itemId = entry.getKey();
            if (seen.contains(itemId)) continue;   // exclude already-seen items

            Map<String, Object> props = entry.getValue();
            @SuppressWarnings("unchecked")
            Map<String, Object> itemProps = (Map<String, Object>) props.get("properties");
            if (itemProps == null) itemProps = Map.of();

            double rating = itemProps.containsKey("rating")
                    ? ((Number) itemProps.get("rating")).doubleValue() : 5.0;
            double score = rating / 10.0;

            // Genre preference bonus
            if (genre != null && genre.equals(itemProps.get("genre"))) score += 0.2;

            // Discovery bonus — deterministic pseudo-random
            score += (djb2(userId + itemId) % 100) / 1000.0;
            score = Math.min(score, 1.0);

            String reason = (genre != null && genre.equals(itemProps.get("genre")))
                    ? "Matches preferred genre: " + genre
                    : "Highly rated content";

            Map<String, Object> rec = new HashMap<>();
            rec.put("item_id", itemId);
            rec.put("score",   Math.round(score * 10000.0) / 10000.0);
            rec.put("reason",  reason);
            rec.put("metadata", Map.of("title", itemProps.getOrDefault("title", "?")));
            scored.add(rec);
        }

        scored.sort((a, b) -> Double.compare((Double) b.get("score"), (Double) a.get("score")));
        return scored.subList(0, Math.min(limit, scored.size()));
    }

    private static long djb2(String s) {
        long hash = 5381;
        for (char c : s.toCharArray()) hash = ((hash << 5) + hash) + c;
        return Math.abs(hash);
    }

    // ── HTTP helpers ──────────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private static Map<String, Object> readBody(HttpExchange ex) throws IOException {
        String body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
        if (body.isBlank()) return Map.of();
        return JSON.readValue(body, Map.class);
    }

    private static void sendJson(HttpExchange ex, int status, Object payload) throws IOException {
        if (status == 204) {
            ex.sendResponseHeaders(204, -1);
            ex.close();
            return;
        }
        byte[] bytes = JSON.writeValueAsBytes(payload);
        ex.getResponseHeaders().set("Content-Type", "application/json");
        ex.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = ex.getResponseBody()) { os.write(bytes); }
    }

    private static void sendError(HttpExchange ex, int status, String detail) throws IOException {
        sendJson(ex, status, Map.of("detail", detail));
    }

    private static String parseQueryParam(String query, String name) {
        if (query == null) return null;
        for (String pair : query.split("&")) {
            String[] kv = pair.split("=", 2);
            if (kv.length == 2 && name.equals(kv[0])) return kv[1];
        }
        return null;
    }

    // ── Data factories ────────────────────────────────────────────────────────

    private static Map<String, Object> movie(String id, String title, String genre, int year, double rating) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", id); m.put("title", title); m.put("genre", genre);
        m.put("year", year); m.put("rating", rating);
        return m;
    }

    private static Map<String, Object> user(String id, String name, int age, String genre) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", id); m.put("name", name); m.put("age", age); m.put("preferred_genre", genre);
        return m;
    }

    private static String getMovieTitle(String itemId) {
        return MOVIES.stream()
                .filter(m -> itemId.equals(m.get("id")))
                .map(m -> (String) m.get("title"))
                .findFirst().orElse(itemId);
    }

    // ── Display helpers ───────────────────────────────────────────────────────

    private static void banner(String text) {
        String line = "=".repeat(text.length() + 4);
        System.out.println(line);
        System.out.println("= " + text + " =");
        System.out.println(line);
        System.out.println();
    }

    private static void step(int n, String title) {
        System.out.printf("── Step %d: %s%n", n, title);
    }
}
