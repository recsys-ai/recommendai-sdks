<?php

declare(strict_types=1);

namespace RecommendAI;

use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Exception\TransferException;

// ── RecommendationsResource ──────────────────────────────────────────────────

final class RecommendationsResource
{
    public function __construct(private readonly GuzzleClient $http) {}

    /**
     * Get personalised recommendations for a user.
     *
     * @return Recommendation[]
     */
    public function get(string $userId, int $limit = 10): array
    {
        try {
            $resp = $this->http->get('api/recommendations', [
                'query' => ['user_id' => $userId, 'limit' => $limit],
            ]);
            $data = json_decode((string) $resp->getBody(), true);
            return array_map(
                static fn(array $r) => Recommendation::fromArray($r),
                $data['recommendations'] ?? []
            );
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    /**
     * Get items similar to a given item.
     *
     * @return Recommendation[]
     */
    public function similar(string $itemId, int $limit = 10): array
    {
        try {
            $resp = $this->http->get("api/recommendations/similar/{$itemId}", [
                'query' => ['limit' => $limit],
            ]);
            $data = json_decode((string) $resp->getBody(), true);
            return array_map(
                static fn(array $r) => Recommendation::fromArray($r),
                $data['recommendations'] ?? []
            );
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    /**
     * Get globally popular items.
     *
     * @return Recommendation[]
     */
    public function popular(int $limit = 10, ?string $category = null): array
    {
        try {
            $query = ['limit' => $limit];
            if ($category !== null) $query['category'] = $category;
            $resp = $this->http->get('api/recommendations/popular', ['query' => $query]);
            $data = json_decode((string) $resp->getBody(), true);
            return array_map(
                static fn(array $r) => Recommendation::fromArray($r),
                $data['recommendations'] ?? []
            );
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }
}

// ── UsersResource ─────────────────────────────────────────────────────────────

final class UsersResource
{
    public function __construct(private readonly GuzzleClient $http) {}

    public function create(string $userId, array $properties = []): User
    {
        try {
            $resp = $this->http->post('api/users', [
                'json' => ['user_id' => $userId, 'properties' => $properties],
            ]);
            return User::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    public function get(string $userId): User
    {
        try {
            $resp = $this->http->get("api/users/{$userId}");
            return User::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    public function update(string $userId, array $properties): User
    {
        try {
            $resp = $this->http->put("api/users/{$userId}", [
                'json' => ['properties' => $properties],
            ]);
            return User::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    public function delete(string $userId): void
    {
        try {
            $this->http->delete("api/users/{$userId}");
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }
}

// ── ItemsResource ─────────────────────────────────────────────────────────────

final class ItemsResource
{
    public function __construct(private readonly GuzzleClient $http) {}

    public function create(string $itemId, array $properties = []): Item
    {
        try {
            $resp = $this->http->post('api/items', [
                'json' => ['item_id' => $itemId, 'properties' => $properties],
            ]);
            return Item::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    public function get(string $itemId): Item
    {
        try {
            $resp = $this->http->get("api/items/{$itemId}");
            return Item::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    public function update(string $itemId, array $properties): Item
    {
        try {
            $resp = $this->http->put("api/items/{$itemId}", [
                'json' => ['properties' => $properties],
            ]);
            return Item::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    public function delete(string $itemId): void
    {
        try {
            $this->http->delete("api/items/{$itemId}");
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }

    /**
     * Bulk create or update items.
     *
     * @param  array[] $items  list of item arrays with 'item_id' and optional 'properties'
     * @return Item[]
     */
    public function upsert(array $items): array
    {
        try {
            $resp = $this->http->post('api/items/bulk', ['json' => ['items' => $items]]);
            $data = json_decode((string) $resp->getBody(), true);
            return array_map(
                static fn(array $i) => Item::fromArray($i),
                $data['items'] ?? []
            );
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }
}

// ── InteractionsResource ──────────────────────────────────────────────────────

final class InteractionsResource
{
    public function __construct(private readonly GuzzleClient $http) {}

    public function create(
        string  $userId,
        string  $itemId,
        string  $interactionType,
        ?float  $value    = null,
        ?array  $metadata = null,
    ): Interaction {
        try {
            $payload = [
                'user_id'          => $userId,
                'item_id'          => $itemId,
                'interaction_type' => $interactionType,
            ];
            if ($value !== null)    { $payload['value']    = $value; }
            if ($metadata !== null) { $payload['metadata'] = $metadata; }

            $resp = $this->http->post('api/interactions', ['json' => $payload]);
            return Interaction::fromArray(json_decode((string) $resp->getBody(), true));
        } catch (TransferException $e) {
            throw RecommendAIClient::mapError($e);
        }
    }
}
