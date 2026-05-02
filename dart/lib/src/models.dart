/// Interaction types supported by the platform.
enum InteractionType {
  view,
  like,
  dislike,
  purchase,
  rating,
  share,
  bookmark,
}

class Recommendation {
  final String itemId;
  final double score;
  final String reason;
  final Map<String, dynamic> metadata;

  const Recommendation({
    required this.itemId,
    required this.score,
    required this.reason,
    this.metadata = const {},
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        itemId:   json['item_id'] as String,
        score:    (json['score'] as num).toDouble(),
        reason:   json['reason'] as String? ?? '',
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

class User {
  final String userId;
  final Map<String, dynamic> properties;
  final String? createdAt;
  final String? updatedAt;

  const User({
    required this.userId,
    this.properties = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId:     json['user_id'] as String,
        properties: (json['properties'] as Map<String, dynamic>?) ?? {},
        createdAt:  json['created_at'] as String?,
        updatedAt:  json['updated_at'] as String?,
      );
}

class Item {
  final String itemId;
  final Map<String, dynamic> properties;
  final String? createdAt;
  final String? updatedAt;

  const Item({
    required this.itemId,
    this.properties = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemId:     json['item_id'] as String,
        properties: (json['properties'] as Map<String, dynamic>?) ?? {},
        createdAt:  json['created_at'] as String?,
        updatedAt:  json['updated_at'] as String?,
      );
}

class Interaction {
  final String interactionId;
  final String userId;
  final String itemId;
  final String interactionType;
  final double? value;
  final Map<String, dynamic> metadata;
  final String? timestamp;

  const Interaction({
    required this.interactionId,
    required this.userId,
    required this.itemId,
    required this.interactionType,
    this.value,
    this.metadata = const {},
    this.timestamp,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        interactionId:   json['interaction_id'] as String? ?? '',
        userId:          json['user_id'] as String,
        itemId:          json['item_id'] as String,
        interactionType: json['interaction_type'] as String,
        value:           (json['value'] as num?)?.toDouble(),
        metadata:        (json['metadata'] as Map<String, dynamic>?) ?? {},
        timestamp:       json['timestamp'] as String?,
      );
}
