using System.Text.Json.Serialization;

namespace RecommendAI;

/// <summary>The type of user–item interaction.</summary>
public enum InteractionType
{
    [JsonPropertyName("view")]       View,
    [JsonPropertyName("click")]      Click,
    [JsonPropertyName("purchase")]   Purchase,
    [JsonPropertyName("like")]       Like,
    [JsonPropertyName("dislike")]    Dislike,
    [JsonPropertyName("rating")]     Rating,
    [JsonPropertyName("cart_add")]   CartAdd,
    [JsonPropertyName("cart_remove")]CartRemove,
}

/// <summary>A personalised item recommendation.</summary>
public sealed class Recommendation
{
    [JsonPropertyName("item_id")]  public string ItemId   { get; init; } = "";
    [JsonPropertyName("score")]    public double Score    { get; init; }
    [JsonPropertyName("reason")]   public string? Reason  { get; init; }
    [JsonPropertyName("metadata")] public Dictionary<string, object>? Metadata { get; init; }
}

/// <summary>A registered platform user.</summary>
public sealed class User
{
    [JsonPropertyName("user_id")]    public string UserId     { get; init; } = "";
    [JsonPropertyName("properties")] public Dictionary<string, object>? Properties { get; init; }
    [JsonPropertyName("created_at")] public DateTimeOffset CreatedAt { get; init; }
    [JsonPropertyName("updated_at")] public DateTimeOffset UpdatedAt { get; init; }
}

/// <summary>A catalogue item.</summary>
public sealed class Item
{
    [JsonPropertyName("item_id")]    public string ItemId     { get; init; } = "";
    [JsonPropertyName("properties")] public Dictionary<string, object>? Properties { get; init; }
    [JsonPropertyName("created_at")] public DateTimeOffset CreatedAt { get; init; }
    [JsonPropertyName("updated_at")] public DateTimeOffset UpdatedAt { get; init; }
}

/// <summary>A recorded user–item interaction event.</summary>
public sealed class Interaction
{
    [JsonPropertyName("interaction_id")] public string? InteractionId   { get; init; }
    [JsonPropertyName("user_id")]        public string  UserId          { get; init; } = "";
    [JsonPropertyName("item_id")]        public string  ItemId          { get; init; } = "";
    [JsonPropertyName("interaction_type")]public string InteractionType { get; init; } = "";
    [JsonPropertyName("value")]          public double? Value           { get; init; }
    [JsonPropertyName("timestamp")]      public DateTimeOffset Timestamp { get; init; }
    [JsonPropertyName("metadata")]       public Dictionary<string, object>? Metadata { get; init; }
}
