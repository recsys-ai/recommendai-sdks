import Foundation

// MARK: - InteractionType

public enum InteractionType: String, Codable, Sendable {
    case view, like, dislike, purchase, rating, share, bookmark
}

// MARK: - Response models

public struct Recommendation: Codable, Sendable {
    public let itemId:   String
    public let score:    Double
    public let reason:   String
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id", score, reason, metadata
    }
}

public struct User: Codable, Sendable {
    public let userId:     String
    public let properties: [String: AnyCodable]?
    public let createdAt:  String?
    public let updatedAt:  String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case properties
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct Item: Codable, Sendable {
    public let itemId:     String
    public let properties: [String: AnyCodable]?
    public let createdAt:  String?
    public let updatedAt:  String?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case properties
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct Interaction: Codable, Sendable {
    public let interactionId:   String?
    public let userId:          String
    public let itemId:          String
    public let interactionType: String
    public let value:           Double?
    public let metadata:        [String: AnyCodable]?
    public let timestamp:       String?

    enum CodingKeys: String, CodingKey {
        case interactionId   = "interaction_id"
        case userId          = "user_id"
        case itemId          = "item_id"
        case interactionType = "interaction_type"
        case value, metadata, timestamp
    }
}

// MARK: - AnyCodable (minimal)

/// A type-erased Codable value for arbitrary JSON.
public struct AnyCodable: Codable, Sendable {
    public let value: Any?

    public init(_ value: Any?) { self.value = value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil()                              { value = nil }
        else if let b = try? c.decode(Bool.self)      { value = b   }
        else if let i = try? c.decode(Int.self)       { value = i   }
        else if let d = try? c.decode(Double.self)    { value = d   }
        else if let s = try? c.decode(String.self)    { value = s   }
        else if let a = try? c.decode([AnyCodable].self)            { value = a }
        else if let o = try? c.decode([String: AnyCodable].self)    { value = o }
        else { value = nil }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case nil:                         try c.encodeNil()
        case let b as Bool:               try c.encode(b)
        case let i as Int:                try c.encode(i)
        case let d as Double:             try c.encode(d)
        case let s as String:             try c.encode(s)
        case let a as [AnyCodable]:       try c.encode(a)
        case let o as [String: AnyCodable]: try c.encode(o)
        default:                          try c.encodeNil()
        }
    }
}

// MARK: - Wire types

struct RecommendationsResponse: Codable {
    let recommendations: [Recommendation]
}

struct ErrorBody: Codable {
    let detail: String
}
