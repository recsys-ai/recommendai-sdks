// Simulation.cs — RecSys.AI .NET SDK demo with a self-contained mock HTTP server.
//
// Run:  dotnet run --project examples/Simulation.csproj
//       (or: dotnet script examples/Simulation.cs  if dotnet-script is installed)

using System.Net;
using System.Text;
using System.Text.Json;
using RecommendAI;

const int MockPort = 17894;

// ── Scenario data ─────────────────────────────────────────────────────────────

var movies = new[]
{
    ("movie_001", "The Matrix",                  "sci-fi",   1999, 8.7),
    ("movie_002", "Inception",                   "sci-fi",   2010, 8.8),
    ("movie_003", "Interstellar",                "sci-fi",   2014, 8.6),
    ("movie_004", "The Dark Knight",             "action",   2008, 9.0),
    ("movie_005", "Avengers: Endgame",           "action",   2019, 8.4),
    ("movie_006", "John Wick",                   "action",   2014, 7.4),
    ("movie_007", "The Shawshank Redemption",    "drama",    1994, 9.3),
    ("movie_008", "Forrest Gump",                "drama",    1994, 8.8),
    ("movie_009", "Pulp Fiction",                "thriller", 1994, 8.9),
    ("movie_010", "The Silence of the Lambs",    "thriller", 1991, 8.6),
};

var users = new[]
{
    ("alice", "Alice Johnson", "sci-fi",   28),
    ("bob",   "Bob Smith",     "action",   35),
    ("carol", "Carol White",   "drama",    42),
    ("dave",  "Dave Brown",    "sci-fi",   23),
    ("eve",   "Eve Davis",     "thriller", 31),
};

var interactions = new (string userId, string itemId, string type, double? value)[]
{
    ("alice", "movie_001", "view",     null),
    ("alice", "movie_002", "like",     null),
    ("alice", "movie_003", "purchase", null),
    ("alice", "movie_001", "rating",   9.0),
    ("bob",   "movie_004", "view",     null),
    ("bob",   "movie_005", "like",     null),
    ("bob",   "movie_006", "purchase", null),
    ("bob",   "movie_004", "rating",   8.0),
    ("carol", "movie_007", "view",     null),
    ("carol", "movie_008", "like",     null),
    ("carol", "movie_007", "purchase", null),
    ("carol", "movie_008", "rating",   9.0),
    ("dave",  "movie_001", "view",     null),
    ("dave",  "movie_002", "purchase", null),
    ("dave",  "movie_003", "rating",   8.5),
    ("eve",   "movie_009", "view",     null),
    ("eve",   "movie_010", "like",     null),
    ("eve",   "movie_009", "purchase", null),
    ("eve",   "movie_010", "rating",   8.0),
    ("alice", "movie_002", "rating",   10.0),
    ("bob",   "movie_006", "rating",   7.5),
    ("carol", "movie_009", "view",     null),
    ("dave",  "movie_004", "view",     null),
    ("eve",   "movie_002", "view",     null),
    ("alice", "movie_004", "view",     null),
};

// ── Mock server state ─────────────────────────────────────────────────────────

var usersDb      = new Dictionary<string, Dictionary<string, object?>>();
var itemsDb      = new Dictionary<string, Dictionary<string, object?>>();
var interactsDb  = new List<Dictionary<string, object?>>();
var dbLock       = new ReaderWriterLockSlim();

static string SerializeEnum(InteractionType t) => t switch
{
    InteractionType.CartAdd    => "cart_add",
    InteractionType.CartRemove => "cart_remove",
    _                          => t.ToString().ToLowerInvariant(),
};

// ── Start mock server ─────────────────────────────────────────────────────────

var listener = new HttpListener();
listener.Prefixes.Add($"http://localhost:{MockPort}/");
listener.Start();
Console.WriteLine($"[mock] Server listening on port {MockPort}\n");

var cts = new CancellationTokenSource();
var serverTask = Task.Run(async () =>
{
    while (!cts.Token.IsCancellationRequested)
    {
        HttpListenerContext ctx;
        try { ctx = await listener.GetContextAsync().ConfigureAwait(false); }
        catch { break; }
        _ = Task.Run(() => HandleRequest(ctx));
    }
});

// ── Run simulation ─────────────────────────────────────────────────────────────

using var client = new RecommendAIClient("sim-api-key", $"http://localhost:{MockPort}");

await RunSimulationAsync(client);

cts.Cancel();
listener.Stop();
await serverTask.ConfigureAwait(false);

async Task RunSimulationAsync(RecommendAIClient c)
{
    Banner("RecSys.AI .NET SDK — Movie Streaming Simulation");

    // Step 1: seed catalogue
    Step(1, "Seeding Movie Catalogue");
    foreach (var (id, title, genre, year, rating) in movies)
    {
        var item = await c.Items.CreateAsync(id, new() {
            ["title"] = title, ["genre"] = genre, ["year"] = year, ["rating"] = rating,
        });
        Console.WriteLine($"  Created item: {item.ItemId} ({item.Properties?["title"]})");
    }
    Console.WriteLine($"  {movies.Length} movies added to catalogue.\n");

    // Step 2: register users
    Step(2, "Registering Users");
    foreach (var (id, name, genre, age) in users)
    {
        var user = await c.Users.CreateAsync(id, new() {
            ["name"] = name, ["age"] = age, ["preferred_genre"] = genre,
        });
        Console.WriteLine($"  Registered: {user.UserId} ({user.Properties?["name"]})");
    }
    Console.WriteLine($"  {users.Length} users registered.\n");

    // Step 3: record interactions
    Step(3, "Recording Watch History & Ratings");
    foreach (var (uid, iid, itype, val) in interactions)
    {
        var t = itype switch
        {
            "view"      => InteractionType.View,
            "like"      => InteractionType.Like,
            "purchase"  => InteractionType.Purchase,
            "rating"    => InteractionType.Rating,
            "click"     => InteractionType.Click,
            _           => InteractionType.View,
        };
        await c.Interactions.CreateAsync(uid, iid, t, val);
    }
    Console.WriteLine($"  {interactions.Length} interactions recorded.\n");

    // Step 4: personalised recommendations
    Step(4, "Getting Personalised Recommendations");
    foreach (var (uid, _, _, _) in users)
    {
        var recs = await c.Recommendations.GetAsync(uid, 5);
        Console.WriteLine($"  Recommendations for {uid}:");
        for (int i = 0; i < recs.Count; i++)
        {
            var r = recs[i];
            var meta = r.Metadata;
            var title = meta != null && meta.TryGetValue("title", out var t) ? t?.ToString() : r.ItemId;
            Console.WriteLine($"    {i+1}. {title,-36} (score: {r.Score:F4})  {r.Reason}");
        }
        Console.WriteLine();
    }

    // Step 5: update item
    Step(5, "Updating Item Metadata");
    var updated = await c.Items.UpdateAsync("movie_001", new() {
        ["title"] = "The Matrix", ["genre"] = "sci-fi", ["year"] = 1999,
        ["rating"] = 8.7, ["remastered"] = true,
    });
    Console.WriteLine($"  Updated movie_001 — remastered: {updated.Properties?["remastered"]}\n");

    // Step 6: update user
    Step(6, "Updating User Profile");
    var alice = await c.Users.UpdateAsync("alice", new() {
        ["name"] = "Alice Johnson", ["age"] = 29,
        ["preferred_genre"] = "sci-fi", ["subscription"] = "premium",
    });
    Console.WriteLine($"  alice subscription → {alice.Properties?["subscription"]}\n");

    // Step 7: retrieve item
    Step(7, "Verifying Item Retrieval");
    var retrieved = await c.Items.GetAsync("movie_004");
    Console.WriteLine($"  Retrieved: {retrieved.ItemId} — {retrieved.Properties?["title"]} ({retrieved.Properties?["genre"]})\n");

    // Step 8: parallel recommendations
    Step(8, "Parallel Recommendations (Task.WhenAll)");
    var parallelTasks = new[] { "alice", "bob", "carol" }
        .Select(uid => c.Recommendations.GetAsync(uid, 3))
        .ToArray();
    var allRecs = await Task.WhenAll(parallelTasks);
    var parallelUsers = new[] { "alice", "bob", "carol" };
    for (int i = 0; i < parallelUsers.Length; i++)
        Console.WriteLine($"  {parallelUsers[i]} got {allRecs[i].Count} recommendations");
    Console.WriteLine();

    // Step 9: error handling
    Step(9, "Error Handling Demo");
    try
    {
        await c.Users.GetAsync("ghost_999");
        Console.WriteLine("  ERROR: expected NotFoundException was not thrown!");
    }
    catch (NotFoundException ex)
    {
        Console.WriteLine($"  Caught NotFoundException: {ex.Message}\n");
    }

    // Step 10: cleanup
    Step(10, "Cleanup");
    await c.Users.DeleteAsync("dave");
    Console.WriteLine("  Deleted user 'dave'.");
    try
    {
        await c.Users.GetAsync("dave");
    }
    catch (NotFoundException)
    {
        Console.WriteLine("  Confirmed: 'dave' no longer exists.");
    }

    Console.WriteLine();
    Banner("Simulation complete — all steps passed!");
}

// ── Mock server request handler ───────────────────────────────────────────────

void HandleRequest(HttpListenerContext ctx)
{
    var req  = ctx.Request;
    var resp = ctx.Response;
    var path = req.Url?.AbsolutePath ?? "/";
    var method = req.HttpMethod;

    resp.ContentType = "application/json";

    try
    {
        if (path == "/api/users" && method == "POST")        { HandleUserCreate(req, resp); return; }
        if (path.StartsWith("/api/users/") && method == "GET")    { HandleUserGet(path, resp); return; }
        if (path.StartsWith("/api/users/") && method == "PUT")    { HandleUserUpdate(path, req, resp); return; }
        if (path.StartsWith("/api/users/") && method == "DELETE") { HandleUserDelete(path, resp); return; }
        if (path == "/api/items" && method == "POST")        { HandleItemCreate(req, resp); return; }
        if (path.StartsWith("/api/items/") && method == "GET")    { HandleItemGet(path, resp); return; }
        if (path.StartsWith("/api/items/") && method == "PUT")    { HandleItemUpdate(path, req, resp); return; }
        if (path.StartsWith("/api/items/") && method == "DELETE") { HandleItemDelete(path, resp); return; }
        if (path == "/api/interactions" && method == "POST") { HandleInteractionCreate(req, resp); return; }
        if (path == "/api/recommendations" && method == "GET") { HandleRecommendations(req, resp); return; }

        Write(resp, 404, JsonSerializer.Serialize(new { detail = "Not found" }));
    }
    catch (Exception ex)
    {
        Write(resp, 500, JsonSerializer.Serialize(new { detail = ex.Message }));
    }
}

string ReadBody(HttpListenerRequest req)
{
    using var sr = new StreamReader(req.InputStream, Encoding.UTF8);
    return sr.ReadToEnd();
}

Dictionary<string, object?> ParseBody(HttpListenerRequest req)
    => JsonSerializer.Deserialize<Dictionary<string, object?>>(ReadBody(req)) ?? [];

void Write(HttpListenerResponse resp, int status, string body)
{
    resp.StatusCode = status;
    var bytes = Encoding.UTF8.GetBytes(body);
    resp.ContentLength64 = bytes.Length;
    resp.OutputStream.Write(bytes);
    resp.OutputStream.Close();
}

void HandleUserCreate(HttpListenerRequest req, HttpListenerResponse resp)
{
    var body   = ParseBody(req);
    var userId = body["user_id"]?.ToString() ?? "";
    var record = new Dictionary<string, object?> {
        ["user_id"]    = userId,
        ["properties"] = body.GetValueOrDefault("properties"),
        ["created_at"] = DateTimeOffset.UtcNow,
        ["updated_at"] = DateTimeOffset.UtcNow,
    };
    dbLock.EnterWriteLock();
    usersDb[userId] = record;
    dbLock.ExitWriteLock();
    Write(resp, 201, JsonSerializer.Serialize(record));
}

void HandleUserGet(string path, HttpListenerResponse resp)
{
    var id = path["/api/users/".Length..];
    dbLock.EnterReadLock();
    var found = usersDb.TryGetValue(id, out var u);
    dbLock.ExitReadLock();
    if (!found) { Write(resp, 404, JsonSerializer.Serialize(new { detail = $"User not found: {id}" })); return; }
    Write(resp, 200, JsonSerializer.Serialize(u));
}

void HandleUserUpdate(string path, HttpListenerRequest req, HttpListenerResponse resp)
{
    var id   = path["/api/users/".Length..];
    var body = ParseBody(req);
    dbLock.EnterWriteLock();
    if (!usersDb.TryGetValue(id, out var existing))
    {
        dbLock.ExitWriteLock();
        Write(resp, 404, JsonSerializer.Serialize(new { detail = $"User not found: {id}" })); return;
    }
    existing["properties"] = body.GetValueOrDefault("properties");
    existing["updated_at"] = DateTimeOffset.UtcNow;
    dbLock.ExitWriteLock();
    Write(resp, 200, JsonSerializer.Serialize(existing));
}

void HandleUserDelete(string path, HttpListenerResponse resp)
{
    var id = path["/api/users/".Length..];
    dbLock.EnterWriteLock();
    var removed = usersDb.Remove(id);
    dbLock.ExitWriteLock();
    if (!removed) { Write(resp, 404, JsonSerializer.Serialize(new { detail = $"User not found: {id}" })); return; }
    resp.StatusCode = 204;
    resp.OutputStream.Close();
}

void HandleItemCreate(HttpListenerRequest req, HttpListenerResponse resp)
{
    var body   = ParseBody(req);
    var itemId = body["item_id"]?.ToString() ?? "";
    var record = new Dictionary<string, object?> {
        ["item_id"]    = itemId,
        ["properties"] = body.GetValueOrDefault("properties"),
        ["created_at"] = DateTimeOffset.UtcNow,
        ["updated_at"] = DateTimeOffset.UtcNow,
    };
    dbLock.EnterWriteLock();
    itemsDb[itemId] = record;
    dbLock.ExitWriteLock();
    Write(resp, 201, JsonSerializer.Serialize(record));
}

void HandleItemGet(string path, HttpListenerResponse resp)
{
    var id = path["/api/items/".Length..];
    dbLock.EnterReadLock();
    var found = itemsDb.TryGetValue(id, out var item);
    dbLock.ExitReadLock();
    if (!found) { Write(resp, 404, JsonSerializer.Serialize(new { detail = $"Item not found: {id}" })); return; }
    Write(resp, 200, JsonSerializer.Serialize(item));
}

void HandleItemUpdate(string path, HttpListenerRequest req, HttpListenerResponse resp)
{
    var id   = path["/api/items/".Length..];
    var body = ParseBody(req);
    dbLock.EnterWriteLock();
    if (!itemsDb.TryGetValue(id, out var existing))
    {
        dbLock.ExitWriteLock();
        Write(resp, 404, JsonSerializer.Serialize(new { detail = $"Item not found: {id}" })); return;
    }
    existing["properties"] = body.GetValueOrDefault("properties");
    existing["updated_at"] = DateTimeOffset.UtcNow;
    dbLock.ExitWriteLock();
    Write(resp, 200, JsonSerializer.Serialize(existing));
}

void HandleItemDelete(string path, HttpListenerResponse resp)
{
    var id = path["/api/items/".Length..];
    dbLock.EnterWriteLock();
    var removed = itemsDb.Remove(id);
    dbLock.ExitWriteLock();
    if (!removed) { Write(resp, 404, JsonSerializer.Serialize(new { detail = $"Item not found: {id}" })); return; }
    resp.StatusCode = 204;
    resp.OutputStream.Close();
}

void HandleInteractionCreate(HttpListenerRequest req, HttpListenerResponse resp)
{
    var body = ParseBody(req);
    body["interaction_id"] = $"ia_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
    body["timestamp"]      = DateTimeOffset.UtcNow;
    dbLock.EnterWriteLock();
    interactsDb.Add(body);
    dbLock.ExitWriteLock();
    Write(resp, 201, JsonSerializer.Serialize(body));
}

void HandleRecommendations(HttpListenerRequest req, HttpListenerResponse resp)
{
    var userId = req.QueryString["user_id"] ?? "";
    int.TryParse(req.QueryString["limit"] ?? "10", out int limit);
    var recs = ComputeRecommendations(userId, limit);
    Write(resp, 200, JsonSerializer.Serialize(new { user_id = userId, recommendations = recs }));
}

List<Dictionary<string, object?>> ComputeRecommendations(string userId, int limit)
{
    dbLock.EnterReadLock();
    var seen = new HashSet<string>(interactsDb
        .Where(ia => ia["user_id"]?.ToString() == userId)
        .Select(ia => ia["item_id"]?.ToString() ?? ""));

    string preferredGenre = "";
    if (usersDb.TryGetValue(userId, out var u))
    {
        var props = u["properties"] as Dictionary<string, object?> ??
                    JsonSerializer.Deserialize<Dictionary<string, object?>>(
                        JsonSerializer.Serialize(u["properties"])) ?? [];
        props.TryGetValue("preferred_genre", out var pg);
        preferredGenre = pg?.ToString() ?? "";
    }

    var candidates = new List<(double score, Dictionary<string, object?> rec)>();
    foreach (var (itemId, item) in itemsDb)
    {
        if (seen.Contains(itemId)) continue;
        var props = item["properties"] as Dictionary<string, object?> ??
                    JsonSerializer.Deserialize<Dictionary<string, object?>>(
                        JsonSerializer.Serialize(item["properties"])) ?? [];
        props.TryGetValue("rating",  out var rawRating);
        props.TryGetValue("genre",   out var rawGenre);
        props.TryGetValue("title",   out var rawTitle);
        double rating = rawRating switch
        {
            JsonElement je => je.GetDouble(),
            double d       => d,
            _              => 5.0,
        };
        var genre = rawGenre?.ToString() ?? "";
        double score = rating / 10.0;
        if (!string.IsNullOrEmpty(preferredGenre) && genre == preferredGenre) score += 0.2;
        score += Djb2(userId + itemId) % 100 / 1000.0;
        score  = Math.Min(score, 1.0);
        score  = Math.Round(score, 4);
        string reason = preferredGenre != "" && genre == preferredGenre
            ? $"Matches preferred genre: {preferredGenre}"
            : "Highly rated content";
        candidates.Add((score, new() {
            ["item_id"]  = itemId,
            ["score"]    = score,
            ["reason"]   = reason,
            ["metadata"] = new Dictionary<string, object?> { ["title"] = rawTitle?.ToString() },
        }));
    }
    dbLock.ExitReadLock();

    return candidates
        .OrderByDescending(c => c.score)
        .Take(limit)
        .Select(c => c.rec)
        .ToList();
}

static ulong Djb2(string s)
{
    ulong h = 5381;
    foreach (char c in s) h = ((h << 5) + h) + c;
    return h;
}

// ── Display helpers ───────────────────────────────────────────────────────────

static void Banner(string text)
{
    var line = new string('=', text.Length + 4);
    Console.WriteLine(line);
    Console.WriteLine($"= {text} =");
    Console.WriteLine(line);
    Console.WriteLine();
}

static void Step(int n, string title) => Console.WriteLine($"── Step {n}: {title}");
