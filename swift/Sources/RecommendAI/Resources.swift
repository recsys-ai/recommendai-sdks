import Foundation

// MARK: - Recommendations

public struct RecommendationsResource: Sendable {
    let client: RecommendAIClient

    public func get(
        userId: String,
        limit:  Int = 10,
        type:   String? = nil
    ) async throws -> [Recommendation] {
        var qi: [URLQueryItem] = [
            .init(name: "user_id", value: userId),
            .init(name: "limit",   value: "\(limit)"),
        ]
        if let t = type { qi.append(.init(name: "type", value: t)) }
        let resp: RecommendationsResponse = try await client.send(
            "GET", path: "/api/recommendations", queryItems: qi)
        return resp.recommendations
    }

    public func similar(itemId: String, limit: Int = 10) async throws -> [Recommendation] {
        let qi: [URLQueryItem] = [.init(name: "limit", value: "\(limit)")]
        let resp: RecommendationsResponse = try await client.send(
            "GET", path: "/api/recommendations/similar/\(itemId)", queryItems: qi)
        return resp.recommendations
    }

    public func popular(limit: Int = 10, category: String? = nil) async throws -> [Recommendation] {
        var qi: [URLQueryItem] = [.init(name: "limit", value: "\(limit)")]
        if let cat = category { qi.append(.init(name: "category", value: cat)) }
        let resp: RecommendationsResponse = try await client.send(
            "GET", path: "/api/recommendations/popular", queryItems: qi)
        return resp.recommendations
    }
}

// MARK: - Users

public struct UsersResource: Sendable {
    let client: RecommendAIClient

    private struct CreateBody: Encodable {
        let user_id: String
        let properties: [String: AnyCodable]?
    }
    private struct UpdateBody: Encodable {
        let properties: [String: AnyCodable]
    }

    public func create(
        userId: String,
        properties: [String: Any?]? = nil
    ) async throws -> User {
        let body = CreateBody(
            user_id: userId,
            properties: properties.map { dict in
                dict.mapValues { AnyCodable($0) }
            }
        )
        return try await client.send("POST", path: "/api/users", body: body)
    }

    public func get(userId: String) async throws -> User {
        return try await client.send("GET", path: "/api/users/\(userId)")
    }

    public func update(
        userId: String,
        properties: [String: Any?]
    ) async throws -> User {
        let body = UpdateBody(
            properties: properties.mapValues { AnyCodable($0) }
        )
        return try await client.send("PUT", path: "/api/users/\(userId)", body: body)
    }

    public func delete(userId: String) async throws {
        try await client.sendNoContent("DELETE", path: "/api/users/\(userId)")
    }
}

// MARK: - Items

public struct ItemsResource: Sendable {
    let client: RecommendAIClient

    private struct CreateBody: Encodable {
        let item_id: String
        let properties: [String: AnyCodable]?
    }
    private struct UpdateBody: Encodable {
        let properties: [String: AnyCodable]
    }

    public func create(
        itemId: String,
        properties: [String: Any?]? = nil
    ) async throws -> Item {
        let body = CreateBody(
            item_id: itemId,
            properties: properties.map { dict in
                dict.mapValues { AnyCodable($0) }
            }
        )
        return try await client.send("POST", path: "/api/items", body: body)
    }

    public func get(itemId: String) async throws -> Item {
        return try await client.send("GET", path: "/api/items/\(itemId)")
    }

    public func update(
        itemId: String,
        properties: [String: Any?]
    ) async throws -> Item {
        let body = UpdateBody(
            properties: properties.mapValues { AnyCodable($0) }
        )
        return try await client.send("PUT", path: "/api/items/\(itemId)", body: body)
    }

    public func delete(itemId: String) async throws {
        try await client.sendNoContent("DELETE", path: "/api/items/\(itemId)")
    }

    private struct UpsertBody: Encodable {
        let items: [[String: AnyCodable]]
    }
    private struct ItemsResponse: Decodable {
        let items: [Item]
    }

    public func upsert(items: [[String: Any?]]) async throws -> [Item] {
        let body = UpsertBody(items: items.map { $0.mapValues { AnyCodable($0) } })
        let resp: ItemsResponse = try await client.send("POST", path: "/api/items/bulk", body: body)
        return resp.items
    }
}

// MARK: - Interactions

public struct InteractionsResource: Sendable {
    let client: RecommendAIClient

    private struct Body: Encodable {
        let user_id: String
        let item_id: String
        let interaction_type: String
        let value: Double?
        let metadata: [String: AnyCodable]?
    }

    public func create(
        userId: String,
        itemId: String,
        type:   InteractionType,
        value:  Double? = nil,
        metadata: [String: Any?]? = nil
    ) async throws -> Interaction {
        let body = Body(
            user_id:          userId,
            item_id:          itemId,
            interaction_type: type.rawValue,
            value:            value,
            metadata:         metadata.map { $0.mapValues { AnyCodable($0) } }
        )
        return try await client.send("POST", path: "/api/interactions", body: body)
    }
}
