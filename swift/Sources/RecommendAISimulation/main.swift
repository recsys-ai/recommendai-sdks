// Sources/RecommendAISimulation/main.swift
//
// RecSys.AI Swift SDK — Movie Streaming Simulation
//
// Uses a URLProtocol subclass to intercept HTTP calls in-process.
// No real network socket or OS port is required; the mock runs entirely
// inside the same process.
//
// Run:  swift run RecommendAISimulation

import Foundation
import RecommendAI

// ── djb2 ─────────────────────────────────────────────────────────────────────

func djb2(_ s: String) -> UInt32 {
    var h: UInt32 = 5381
    for byte in s.utf8 {
        h = h &* 33 &+ UInt32(byte)
    }
    return h
}

// ── In-memory state (protected by a lock) ────────────────────────────────────

final class State {
    var users        = [String: [String: Any]]()
    var items        = [String: [String: Any]]()
    var interactions = [[String: Any]]()
    var counter      = 0

    static let shared = State()
    private init() {}
}

let stateLock = NSLock()

// ── Scoring ───────────────────────────────────────────────────────────────────

func computeRecs(userId: String, limit: Int) -> [[String: Any]] {
    let seen: Set<String> = Set(
        State.shared.interactions
            .filter { ($0["user_id"] as? String) == userId }
            .compactMap { $0["item_id"] as? String }
    )
    let prefGenre = ((State.shared.users[userId]?["properties"] as? [String: Any])?["preferred_genre"] as? String) ?? ""

    var candidates: [(score: Double, item: [String: Any], itemId: String)] = []
    for (iid, item) in State.shared.items where !seen.contains(iid) {
        let props   = (item["properties"] as? [String: Any]) ?? [:]
        let rating  = (props["rating"] as? Double) ?? 0.0
        let genre   = (props["genre"] as? String) ?? ""
        var score   = rating / 10.0
        if !prefGenre.isEmpty && genre == prefGenre { score += 0.2 }
        let hashPart = Double(djb2(userId + iid) % 100) / 1000.0
        score = min(score + hashPart, 1.0)
        score = (score * 10000).rounded() / 10000
        let reason  = (!prefGenre.isEmpty && genre == prefGenre)
            ? "Matches preferred genre: \(prefGenre)"
            : "Highly rated content"
        let title   = (props["title"] as? String) ?? iid
        candidates.append((score, [
            "item_id":  iid,
            "score":    score,
            "reason":   reason,
            "metadata": ["title": title],
        ], iid))
    }
    candidates.sort { $0.score > $1.score }
    return Array(candidates.prefix(limit).map(\.item))
}

// ── JSON helpers ──────────────────────────────────────────────────────────────

func toJSONData(_ value: Any) -> Data {
    (try? JSONSerialization.data(withJSONObject: value, options: [])) ?? Data()
}

func fromJSONData(_ data: Data) -> [String: Any]? {
    try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

// ── MockURLProtocol ────────────────────────────────────────────────────────────

final class MockURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let method  = request.httpMethod ?? "GET"
        let path    = request.url?.path ?? "/"
        var parts   = path.split(separator: "/").map(String.init)
        // e.g. ["api","users"] or ["api","users","alice"]

        var bodyDict: [String: Any]? = nil
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            let buf  = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
            defer { buf.deallocate(); stream.close() }
            while stream.hasBytesAvailable {
                let n = stream.read(buf, maxLength: 4096)
                if n > 0 { data.append(buf, count: n) }
            }
            bodyDict = fromJSONData(data)
        } else if let body = request.httpBody {
            bodyDict = fromJSONData(body)
        }

        stateLock.lock()
        let (status, responseBody) = handleRoute(
            method: method, parts: parts, body: bodyDict,
            query: request.url?.query ?? "")
        stateLock.unlock()

        let url      = request.url!
        let response = HTTPURLResponse(
            url: url, statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    // Must be called with stateLock held
    private func handleRoute(
        method: String, parts: [String],
        body: [String: Any]?, query: String
    ) -> (Int, Data) {

        func ok(_ v: Any)         -> (Int, Data) { (200, toJSONData(v)) }
        func created(_ v: Any)    -> (Int, Data) { (201, toJSONData(v)) }
        func noContent()          -> (Int, Data) { (204, Data()) }
        func notFound(_ m: String)-> (Int, Data) { (404, toJSONData(["detail": m])) }
        func badRequest(_ m: String)-> (Int, Data){ (422, toJSONData(["detail": m])) }

        // /api/users
        if parts == ["api", "users"] && method == "POST" {
            guard let b = body, let uid = b["user_id"] as? String else {
                return badRequest("user_id required")
            }
            let rec: [String: Any] = [
                "user_id": uid, "properties": b["properties"] ?? [:],
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
            ]
            State.shared.users[uid] = rec
            return created(rec)
        }
        if parts.count == 3 && parts[0] == "api" && parts[1] == "users" {
            let uid = parts[2]
            switch method {
            case "GET":
                return State.shared.users[uid].map { ok($0) } ?? notFound("User not found: \(uid)")
            case "PUT":
                guard var u = State.shared.users[uid] else {
                    return notFound("User not found: \(uid)")
                }
                u["properties"] = body?["properties"] ?? [:]
                u["updated_at"] = "2024-01-01T00:00:00Z"
                State.shared.users[uid] = u
                return ok(u)
            case "DELETE":
                if State.shared.users.removeValue(forKey: uid) != nil { return noContent() }
                return notFound("User not found: \(uid)")
            default: break
            }
        }

        // /api/items
        if parts == ["api", "items"] && method == "POST" {
            guard let b = body, let iid = b["item_id"] as? String else {
                return badRequest("item_id required")
            }
            let rec: [String: Any] = [
                "item_id": iid, "properties": b["properties"] ?? [:],
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
            ]
            State.shared.items[iid] = rec
            return created(rec)
        }
        if parts.count == 3 && parts[0] == "api" && parts[1] == "items" {
            let iid = parts[2]
            switch method {
            case "GET":
                return State.shared.items[iid].map { ok($0) } ?? notFound("Item not found: \(iid)")
            case "PUT":
                guard var i = State.shared.items[iid] else {
                    return notFound("Item not found: \(iid)")
                }
                i["properties"] = body?["properties"] ?? [:]
                i["updated_at"] = "2024-01-01T00:00:00Z"
                State.shared.items[iid] = i
                return ok(i)
            case "DELETE":
                if State.shared.items.removeValue(forKey: iid) != nil { return noContent() }
                return notFound("Item not found: \(iid)")
            default: break
            }
        }

        // /api/interactions
        if parts == ["api", "interactions"] && method == "POST" {
            guard let b = body else { return badRequest("body required") }
            State.shared.counter += 1
            var rec = b
            rec["interaction_id"] = "ia_\(State.shared.counter)"
            rec["timestamp"]       = "2024-01-01T00:00:00Z"
            State.shared.interactions.append(rec)
            return created(rec)
        }

        // /api/recommendations
        if parts == ["api", "recommendations"] && method == "GET" {
            let params = queryToDict(query)
            let uid    = params["user_id"] ?? ""
            let limit  = Int(params["limit"] ?? "") ?? 10
            let recs   = computeRecs(userId: uid, limit: limit)
            return ok(["user_id": uid, "recommendations": recs])
        }

        return (404, toJSONData(["detail": "Not found"]))
    }

    private func queryToDict(_ q: String) -> [String: String] {
        var d = [String: String]()
        for pair in q.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2 {
                d[kv[0].removingPercentEncoding ?? kv[0]] =
                    kv[1].removingPercentEncoding ?? kv[1]
            }
        }
        return d
    }
}

// ── Simulation helpers ─────────────────────────────────────────────────────────

func banner(_ title: String) {
    let line = String(repeating: "=", count: title.count + 4)
    print("\(line)\n= \(title) =\n\(line)\n")
}

func step(_ n: Int, _ title: String) {
    print("── Step \(n): \(title)")
}

// ── Data ──────────────────────────────────────────────────────────────────────

let movies: [(id: String, title: String, genre: String, year: Int, rating: Double)] = [
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
]

let userList: [(id: String, name: String, genre: String, age: Int)] = [
    ("alice", "Alice Johnson", "sci-fi",   28),
    ("bob",   "Bob Smith",     "action",   35),
    ("carol", "Carol White",   "drama",    42),
    ("dave",  "Dave Brown",    "sci-fi",   23),
    ("eve",   "Eve Davis",     "thriller", 31),
]

let interactions: [(uid: String, iid: String, type: InteractionType, val: Double?)] = [
    ("alice", "movie_001", .view,     nil),
    ("alice", "movie_002", .like,     nil),
    ("alice", "movie_003", .purchase, nil),
    ("alice", "movie_001", .rating,   9.0),
    ("bob",   "movie_004", .view,     nil),
    ("bob",   "movie_005", .like,     nil),
    ("bob",   "movie_006", .purchase, nil),
    ("bob",   "movie_004", .rating,   8.0),
    ("carol", "movie_007", .view,     nil),
    ("carol", "movie_008", .like,     nil),
    ("carol", "movie_007", .purchase, nil),
    ("carol", "movie_008", .rating,   9.0),
    ("dave",  "movie_001", .view,     nil),
    ("dave",  "movie_002", .purchase, nil),
    ("dave",  "movie_003", .rating,   8.5),
    ("eve",   "movie_009", .view,     nil),
    ("eve",   "movie_010", .like,     nil),
    ("eve",   "movie_009", .purchase, nil),
    ("eve",   "movie_010", .rating,   8.0),
    ("alice", "movie_002", .rating,   10.0),
    ("bob",   "movie_006", .rating,   7.5),
    ("carol", "movie_009", .view,     nil),
    ("dave",  "movie_004", .view,     nil),
    ("eve",   "movie_002", .view,     nil),
    ("alice", "movie_004", .view,     nil),
]

// ── Entry point ───────────────────────────────────────────────────────────────

URLProtocol.registerClass(MockURLProtocol.self)
print("[mock] URLProtocol interceptor registered (in-process mock on port 17900)\n")

let cfg    = ClientConfig(baseURL: "http://127.0.0.1:17900")
let client = RecommendAIClient(apiKey: "sim-api-key", config: cfg)

let task = Task {
    banner("RecSys.AI Swift SDK — Movie Streaming Simulation")

    // Step 1: seed catalogue
    step(1, "Seeding Movie Catalogue")
    for m in movies {
        let item = try await client.items.create(
            itemId: m.id,
            properties: ["title": m.title, "genre": m.genre, "year": m.year, "rating": m.rating]
        )
        let title = (item.properties?["title"]?.value as? String) ?? m.id
        print("  Created item: \(item.itemId) (\(title))")
    }
    print("  \(movies.count) movies added to catalogue.\n")

    // Step 2: register users
    step(2, "Registering Users")
    for u in userList {
        let user = try await client.users.create(
            userId: u.id,
            properties: ["name": u.name, "age": u.age, "preferred_genre": u.genre]
        )
        let name = (user.properties?["name"]?.value as? String) ?? u.id
        print("  Registered: \(user.userId) (\(name))")
    }
    print("  \(userList.count) users registered.\n")

    // Step 3: record interactions
    step(3, "Recording Watch History & Ratings")
    for ia in interactions {
        _ = try await client.interactions.create(
            userId: ia.uid, itemId: ia.iid, type: ia.type, value: ia.val)
    }
    print("  \(interactions.count) interactions recorded.\n")

    // Step 4: recommendations
    step(4, "Getting Personalised Recommendations")
    for u in userList {
        let recs = try await client.recommendations.get(userId: u.id, limit: 5)
        print("  Recommendations for \(u.id):")
        for (i, r) in recs.enumerated() {
            let title = (r.metadata?["title"]?.value as? String) ?? r.itemId
            let padded = title.padding(toLength: 36, withPad: " ", startingAt: 0)
            print("    \(i+1). \(padded) (score: \(String(format: "%.4f", r.score)))  \(r.reason)")
        }
        print("")
    }

    // Step 5: update item
    step(5, "Updating Item Metadata")
    let updated = try await client.items.update(
        itemId: "movie_001",
        properties: ["title": "The Matrix", "genre": "sci-fi", "year": 1999, "rating": 8.7, "remastered": true]
    )
    let remastered = (updated.properties?["remastered"]?.value as? Bool) ?? false
    print("  Updated movie_001 — remastered: \(remastered)\n")

    // Step 6: update user
    step(6, "Updating User Profile")
    let alice = try await client.users.update(
        userId: "alice",
        properties: ["name": "Alice Johnson", "age": 29, "preferred_genre": "sci-fi", "subscription": "premium"]
    )
    let sub = (alice.properties?["subscription"]?.value as? String) ?? ""
    print("  alice subscription → \(sub)\n")

    // Step 7: retrieve item
    step(7, "Verifying Item Retrieval")
    let retrieved = try await client.items.get(itemId: "movie_004")
    let rTitle = (retrieved.properties?["title"]?.value as? String) ?? ""
    let rGenre = (retrieved.properties?["genre"]?.value as? String) ?? ""
    print("  Retrieved: \(retrieved.itemId) — \(rTitle) (\(rGenre))\n")

    // Step 8: error handling
    step(8, "Error Handling Demo")
    do {
        _ = try await client.users.get(userId: "ghost_999")
        print("  ERROR: expected notFound not thrown!\n")
    } catch RecommendAIError.notFound(let msg) {
        print("  Caught notFound: \(msg)\n")
    }

    // Step 9: cleanup
    step(9, "Cleanup")
    try await client.users.delete(userId: "dave")
    print("  Deleted user 'dave'.")
    do {
        _ = try await client.users.get(userId: "dave")
        print("  ERROR: 'dave' should not exist!")
    } catch RecommendAIError.notFound {
        print("  Confirmed: 'dave' no longer exists.")
    }

    print("")
    banner("Simulation complete — all steps passed!")
}

// Run until the task finishes
let sema = DispatchSemaphore(value: 0)
Task {
    do    { try await task.value }
    catch { print("Simulation error: \(error)") }
    sema.signal()
}
sema.wait()
