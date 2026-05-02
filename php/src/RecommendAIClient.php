<?php

declare(strict_types=1);

namespace RecommendAI;

use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Exception\ClientException;
use GuzzleHttp\Exception\ServerException as GuzzleServerException;

/**
 * Main entry point for the RecSys.AI PHP SDK.
 */
final class RecommendAIClient
{
    private readonly GuzzleClient $http;
    private readonly RecommendationsResource $recommendationsResource;
    private readonly UsersResource $usersResource;
    private readonly ItemsResource $itemsResource;
    private readonly InteractionsResource $interactionsResource;

    public function __construct(
        string        $apiKey,
        string        $baseUrl = 'http://localhost:8080',
        int           $timeout = 30,
        ?GuzzleClient $httpClient = null,
    ) {
        $this->http = $httpClient ?? new GuzzleClient([
            'base_uri' => rtrim($baseUrl, '/') . '/',
            'timeout'  => $timeout,
            'headers'  => [
                'Authorization' => "Bearer {$apiKey}",
                'Content-Type'  => 'application/json',
                'Accept'        => 'application/json',
                'User-Agent'    => 'recommendai-php/1.0.0',
            ],
        ]);

        $this->recommendationsResource = new RecommendationsResource($this->http);
        $this->usersResource           = new UsersResource($this->http);
        $this->itemsResource           = new ItemsResource($this->http);
        $this->interactionsResource    = new InteractionsResource($this->http);
    }

    public function recommendations(): RecommendationsResource
    {
        return $this->recommendationsResource;
    }

    public function users(): UsersResource
    {
        return $this->usersResource;
    }

    public function items(): ItemsResource
    {
        return $this->itemsResource;
    }

    public function interactions(): InteractionsResource
    {
        return $this->interactionsResource;
    }

    public function ping(): bool
    {
        try {
            $this->http->get('health');
            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    /**
     * Map a Guzzle HTTP error to a typed RecommendAI exception.
     *
     * @internal used by resource classes
     */
    public static function mapError(\Throwable $e): RecommendAIException
    {
        if ($e instanceof ClientException) {
            $status = $e->getResponse()->getStatusCode();
            $body   = (string) $e->getResponse()->getBody();
            $data   = json_decode($body, true);
            $msg    = is_array($data) ? ($data['detail'] ?? "HTTP {$status}") : "HTTP {$status}";
            return match ($status) {
                401     => new AuthenticationException($msg),
                404     => new NotFoundException($msg),
                429     => new RateLimitException($msg),
                400, 422 => new ValidationException($msg, $status),
                default => new RecommendAIException($msg, $status),
            };
        }
        if ($e instanceof GuzzleServerException) {
            $status = $e->getResponse()->getStatusCode();
            $body   = (string) $e->getResponse()->getBody();
            $data   = json_decode($body, true);
            $msg    = is_array($data) ? ($data['detail'] ?? "HTTP {$status}") : "HTTP {$status}";
            return new ServerException($msg, $status);
        }
        return new RecommendAIException($e->getMessage());
    }
}
