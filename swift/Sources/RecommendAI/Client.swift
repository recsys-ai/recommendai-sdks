import Foundation

public struct ClientConfig: Sendable {
    public var baseURL: String
    public var timeout: TimeInterval

    public init(
        baseURL: String = "http://localhost:8080",
        timeout: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
    }
}

public actor RecommendAIClient {
    private let apiKey:  String
    private let config:  ClientConfig
    private let session: URLSession

    public init(apiKey: String, config: ClientConfig = .init()) {
        self.apiKey  = apiKey
        self.config  = config
        let cfg      = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = config.timeout
        self.session = URLSession(configuration: cfg)
    }

    /// Internal initialiser for testing — accepts a pre-configured URLSession.
    init(apiKey: String, config: ClientConfig = .init(), session: URLSession) {
        self.apiKey  = apiKey
        self.config  = config
        self.session = session
    }

    // MARK: - Resource accessors

    public var recommendations: RecommendationsResource { .init(client: self) }
    public var users:           UsersResource           { .init(client: self) }
    public var items:           ItemsResource           { .init(client: self) }
    public var interactions:    InteractionsResource    { .init(client: self) }

    /// Returns `true` if the API health endpoint responds successfully.
    public func ping() async -> Bool {
        do {
            var req = URLRequest(url: URL(string: config.baseURL + "/health")!)
            req.httpMethod = "GET"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await session.data(for: req)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Internal HTTP

    func send<T: Decodable>(
        _ method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        var components = URLComponents(string: config.baseURL + path)!
        if let qi = queryItems { components.queryItems = qi }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)",            forHTTPHeaderField: "Authorization")
        req.setValue("application/json",            forHTTPHeaderField: "Content-Type")
        req.setValue("recommendai-swift/1.0.0",     forHTTPHeaderField: "User-Agent")
        if let b = body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(b))
        }
        let (data, response) = try await session.data(for: req)
        let http = response as! HTTPURLResponse
        if http.statusCode >= 200 && http.statusCode < 300 {
            return try JSONDecoder().decode(T.self, from: data)
        }
        let detail = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.detail
                     ?? String(data: data, encoding: .utf8) ?? "Unknown error"
        throw mapError(detail, statusCode: http.statusCode)
    }

    func sendNoContent(_ method: String, path: String) async throws {
        var req = URLRequest(url: URL(string: config.baseURL + path)!)
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)",        forHTTPHeaderField: "Authorization")
        req.setValue("recommendai-swift/1.0.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: req)
        let http = response as! HTTPURLResponse
        if http.statusCode >= 200 && http.statusCode < 300 { return }
        let detail = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.detail
                     ?? String(data: data, encoding: .utf8) ?? "Unknown error"
        throw mapError(detail, statusCode: http.statusCode)
    }

    private func mapError(_ detail: String, statusCode: Int) -> RecommendAIError {
        switch statusCode {
        case 401: return .authentication(detail)
        case 404: return .notFound(detail)
        case 422: return .validation(detail)
        case 429: return .rateLimit(detail)
        default:  return .server(detail, statusCode: statusCode)
        }
    }
}

// MARK: - AnyEncodable helper

private struct AnyEncodable: Encodable {
    let base: Encodable
    init(_ base: Encodable) { self.base = base }
    func encode(to encoder: Encoder) throws { try base.encode(to: encoder) }
}
