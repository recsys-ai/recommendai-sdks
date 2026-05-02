import Foundation

public enum RecommendAIError: Error, LocalizedError {
    case authentication(String)
    case notFound(String)
    case validation(String)
    case rateLimit(String)
    case server(String, statusCode: Int)
    case network(Error)
    case decoding(Error)

    public var errorDescription: String? {
        switch self {
        case .authentication(let m):     return "AuthenticationError: \(m)"
        case .notFound(let m):           return "NotFoundError: \(m)"
        case .validation(let m):         return "ValidationError: \(m)"
        case .rateLimit(let m):          return "RateLimitError: \(m)"
        case .server(let m, let code):   return "ServerError(\(code)): \(m)"
        case .network(let e):            return "NetworkError: \(e.localizedDescription)"
        case .decoding(let e):           return "DecodingError: \(e.localizedDescription)"
        }
    }
}
