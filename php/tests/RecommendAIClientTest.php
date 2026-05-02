<?php

declare(strict_types=1);

namespace RecommendAI\Tests;

use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Response;
use PHPUnit\Framework\TestCase;
use RecommendAI\AuthenticationException;
use RecommendAI\NotFoundException;
use RecommendAI\RateLimitException;
use RecommendAI\RecommendAIClient;

final class RecommendAIClientTest extends TestCase
{
    // ── helpers ───────────────────────────────────────────────────────────────

    /** @var array<int, array{request: \GuzzleHttp\Psr7\Request}> */
    private array $history = [];

    private function makeClient(MockHandler $mock): RecommendAIClient
    {
        $this->history = [];
        $stack = HandlerStack::create($mock);
        $stack->push(Middleware::history($this->history));

        $http = new GuzzleClient([
            'base_uri' => 'http://localhost:8080/',
            'handler'  => $stack,
            'headers'  => [
                'Authorization' => 'Bearer test-key',
                'Content-Type'  => 'application/json',
                'Accept'        => 'application/json',
            ],
            'http_errors' => true,
        ]);

        return new RecommendAIClient('test-key', 'http://localhost:8080', 30, $http);
    }

    private function response(int $status, mixed $body): Response
    {
        return new Response($status, ['Content-Type' => 'application/json'], json_encode($body));
    }

    // ── ping ─────────────────────────────────────────────────────────────────

    public function testPingReturnsTrue(): void
    {
        $mock   = new MockHandler([$this->response(200, new \stdClass())]);
        $client = $this->makeClient($mock);
        $this->assertTrue($client->ping());

        $req = $this->history[0]['request'];
        $this->assertStringEndsWith('/health', (string) $req->getUri());
    }

    public function testPingReturnsFalse(): void
    {
        $mock   = new MockHandler([$this->response(503, new \stdClass())]);
        $client = $this->makeClient($mock);
        $this->assertFalse($client->ping());
    }

    // ── recommendations ───────────────────────────────────────────────────────

    public function testRecommendationsGetReturnsItems(): void
    {
        $body = ['recommendations' => [
            ['item_id' => 'item1', 'score' => 0.9, 'reason' => 'test', 'metadata' => []],
        ]];
        $mock   = new MockHandler([$this->response(200, $body)]);
        $client = $this->makeClient($mock);

        $recs = $client->recommendations()->get('user1', 5);
        $this->assertCount(1, $recs);
        $this->assertSame('item1', $recs[0]->itemId);

        $req = $this->history[0]['request'];
        $this->assertStringContainsString('api/recommendations', (string) $req->getUri());
        $this->assertStringContainsString('user_id=user1', (string) $req->getUri());
    }

    public function testRecommendationsSimilarCallsCorrectPath(): void
    {
        $body = ['recommendations' => [
            ['item_id' => 'item2', 'score' => 0.8, 'reason' => '', 'metadata' => []],
        ]];
        $mock   = new MockHandler([$this->response(200, $body)]);
        $client = $this->makeClient($mock);

        $recs = $client->recommendations()->similar('item99', 10);
        $this->assertCount(1, $recs);
        $this->assertSame('item2', $recs[0]->itemId);

        $req = $this->history[0]['request'];
        $this->assertStringContainsString('api/recommendations/similar/item99', (string) $req->getUri());
    }

    public function testRecommendationsPopularPassesCategoryParam(): void
    {
        $body = ['recommendations' => [
            ['item_id' => 'book1', 'score' => 0.7, 'reason' => '', 'metadata' => []],
        ]];
        $mock   = new MockHandler([$this->response(200, $body)]);
        $client = $this->makeClient($mock);

        $recs = $client->recommendations()->popular(5, 'books');
        $this->assertCount(1, $recs);

        $req = $this->history[0]['request'];
        $this->assertStringContainsString('category=books', (string) $req->getUri());
    }

    // ── items ─────────────────────────────────────────────────────────────────

    public function testItemsUpsertPostsToBulkEndpoint(): void
    {
        $body = ['items' => [
            ['item_id' => 'itemA', 'properties' => [], 'created_at' => null, 'updated_at' => null],
        ]];
        $mock   = new MockHandler([$this->response(200, $body)]);
        $client = $this->makeClient($mock);

        $items = $client->items()->upsert([
            ['item_id' => 'itemA', 'properties' => ['name' => 'Book A']],
        ]);
        $this->assertCount(1, $items);
        $this->assertSame('itemA', $items[0]->itemId);

        $req = $this->history[0]['request'];
        $this->assertSame('POST', $req->getMethod());
        $this->assertStringContainsString('api/items/bulk', (string) $req->getUri());
    }

    // ── error handling ────────────────────────────────────────────────────────

    public function testAuthenticationError(): void
    {
        $this->expectException(AuthenticationException::class);
        $mock   = new MockHandler([$this->response(401, ['detail' => 'invalid api key'])]);
        $client = $this->makeClient($mock);
        $client->recommendations()->get('u', 5);
    }

    public function testNotFoundError(): void
    {
        $this->expectException(NotFoundException::class);
        $mock   = new MockHandler([$this->response(404, ['detail' => 'not found'])]);
        $client = $this->makeClient($mock);
        $client->recommendations()->get('u', 5);
    }

    public function testRateLimitError(): void
    {
        $this->expectException(RateLimitException::class);
        $mock   = new MockHandler([$this->response(429, ['detail' => 'rate limit exceeded'])]);
        $client = $this->makeClient($mock);
        $client->recommendations()->get('u', 5);
    }
}
