import Foundation
import XCTest
@testable import RecommendAI

// MARK: - Mock URLProtocol

final class MockURLProtocol: URLProtocol {
    // Map of path -> (statusCode, responseData)
    static var handlers: [(check: (URLRequest) -> Bool, response: (Int, Data))] = []

    static func stub(path: String, status: Int, json: Any) {
        let data = try! JSONSerialization.data(withJSONObject: json)
        handlers.append((
            check: { $0.url?.path.hasPrefix(path) ?? false },
            response: (status, data)
        ))
    }

    static func reset() { handlers = [] }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let match = MockURLProtocol.handlers.first { $0.check(request) }
        if let (status, data) = match?.response {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        } else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Helpers

func makeClient() -> RecommendAIClient {
    let cfg = URLSessionConfiguration.ephemeral
    cfg.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: cfg)
    return RecommendAIClient(
        apiKey: "test-key",
        config: ClientConfig(baseURL: "http://localhost:8080"),
        session: session
    )
}

// MARK: - Tests

final class RecommendAIClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    // ── ping ─────────────────────────────────────────────────────────────────

    func testPingReturnsTrue() async {
        MockURLProtocol.stub(path: "/health", status: 200, json: [:])
        let result = await makeClient().ping()
        XCTAssertTrue(result)
    }

    func testPingReturnsFalse() async {
        MockURLProtocol.stub(path: "/health", status: 503, json: [:])
        let result = await makeClient().ping()
        XCTAssertFalse(result)
    }

    // ── recommendations ───────────────────────────────────────────────────────

    func testRecommendationsSimilarCallsCorrectPath() async throws {
        MockURLProtocol.stub(path: "/api/recommendations/similar/item99", status: 200, json: [
            "recommendations": [
                ["item_id": "item2", "score": 0.8, "reason": "", "metadata": [:] as [String: Any]]
            ]
        ])
        let client = makeClient()
        let recs = try await client.recommendations.similar(itemId: "item99", limit: 10)
        XCTAssertEqual(recs.count, 1)
        XCTAssertEqual(recs[0].itemId, "item2")
    }

    func testRecommendationsPopularPassesCategoryParam() async throws {
        MockURLProtocol.stub(path: "/api/recommendations/popular", status: 200, json: [
            "recommendations": [
                ["item_id": "book1", "score": 0.7, "reason": "", "metadata": [:] as [String: Any]]
            ]
        ])
        let client = makeClient()
        let recs = try await client.recommendations.popular(limit: 5, category: "books")
        XCTAssertEqual(recs.count, 1)
        XCTAssertEqual(recs[0].itemId, "book1")
    }

    // ── items ─────────────────────────────────────────────────────────────────

    func testItemsUpsertPostsToBulkEndpoint() async throws {
        MockURLProtocol.stub(path: "/api/items/bulk", status: 200, json: [
            "items": [
                ["item_id": "itemA", "properties": [:] as [String: Any]]
            ]
        ])
        let client = makeClient()
        let items = try await client.items.upsert(items: [["item_id": "itemA", "properties": ["name": "Book A"]]])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].itemId, "itemA")
    }

    // ── error handling ────────────────────────────────────────────────────────

    func testAuthenticationErrorOn401() async {
        MockURLProtocol.stub(path: "/api/recommendations/similar/x", status: 401, json: ["detail": "invalid api key"])
        let client = makeClient()
        do {
            _ = try await client.recommendations.similar(itemId: "x", limit: 5)
            XCTFail("Expected error")
        } catch RecommendAIError.authentication {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNotFoundErrorOn404() async {
        MockURLProtocol.stub(path: "/api/recommendations/similar/x", status: 404, json: ["detail": "not found"])
        let client = makeClient()
        do {
            _ = try await client.recommendations.similar(itemId: "x", limit: 5)
            XCTFail("Expected error")
        } catch RecommendAIError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRateLimitErrorOn429() async {
        MockURLProtocol.stub(path: "/api/recommendations/similar/x", status: 429, json: ["detail": "rate limit"])
        let client = makeClient()
        do {
            _ = try await client.recommendations.similar(itemId: "x", limit: 5)
            XCTFail("Expected error")
        } catch RecommendAIError.rateLimit {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
