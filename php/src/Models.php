<?php

declare(strict_types=1);

namespace RecommendAI;

/**
 * Interaction-type constants.
 */
final class InteractionType
{
    public const VIEW         = 'view';
    public const CLICK        = 'click';
    public const PURCHASE     = 'purchase';
    public const LIKE         = 'like';
    public const DISLIKE      = 'dislike';
    public const RATING       = 'rating';
    public const CART_ADD     = 'cart_add';
    public const CART_REMOVE  = 'cart_remove';
}

/**
 * A single recommendation item.
 */
final class Recommendation
{
    public function __construct(
        public readonly string  $itemId,
        public readonly float   $score,
        public readonly string  $reason,
        public readonly ?array  $metadata = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            itemId:   $data['item_id'],
            score:    (float) $data['score'],
            reason:   $data['reason'],
            metadata: $data['metadata'] ?? null,
        );
    }
}

/**
 * A catalogue user.
 */
final class User
{
    public function __construct(
        public readonly string  $user_id,
        public readonly ?array  $properties = null,
        public readonly ?string $created_at = null,
        public readonly ?string $updated_at = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            user_id:    $data['user_id'],
            properties: $data['properties'] ?? null,
            created_at: $data['created_at'] ?? null,
            updated_at: $data['updated_at'] ?? null,
        );
    }
}

/**
 * A catalogue item.
 */
final class Item
{
    public function __construct(
        public readonly string  $itemId,
        public readonly ?array  $properties = null,
        public readonly ?string $createdAt = null,
        public readonly ?string $updatedAt = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            itemId:     $data['item_id'],
            properties: $data['properties'] ?? null,
            createdAt:  $data['created_at'] ?? null,
            updatedAt:  $data['updated_at'] ?? null,
        );
    }
}

/**
 * A recorded interaction.
 */
final class Interaction
{
    public function __construct(
        public readonly string  $user_id,
        public readonly string  $item_id,
        public readonly string  $interaction_type,
        public readonly ?float  $value = null,
        public readonly ?array  $metadata = null,
        public readonly ?string $interaction_id = null,
        public readonly ?string $timestamp = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            user_id:          $data['user_id'],
            item_id:          $data['item_id'],
            interaction_type: $data['interaction_type'],
            value:            isset($data['value']) ? (float) $data['value'] : null,
            metadata:         $data['metadata'] ?? null,
            interaction_id:   $data['interaction_id'] ?? null,
            timestamp:        $data['timestamp'] ?? null,
        );
    }
}
