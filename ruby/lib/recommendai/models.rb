module RecommendAI
  INTERACTION_TYPES = %w[view click purchase like dislike rating cart_add cart_remove].freeze

  Recommendation = Struct.new(:item_id, :score, :reason, :metadata, keyword_init: true)

  User = Struct.new(:user_id, :properties, :created_at, :updated_at, keyword_init: true)

  Item = Struct.new(:item_id, :properties, :created_at, :updated_at, keyword_init: true)

  Interaction = Struct.new(
    :interaction_id, :user_id, :item_id, :interaction_type,
    :value, :timestamp, :metadata,
    keyword_init: true
  )

  module Models
    def self.recommendation_from_hash(h)
      Recommendation.new(
        item_id:  h["item_id"],
        score:    h["score"].to_f,
        reason:   h["reason"],
        metadata: h["metadata"]
      )
    end

    def self.user_from_hash(h)
      User.new(
        user_id:    h["user_id"],
        properties: h["properties"],
        created_at: h["created_at"],
        updated_at: h["updated_at"]
      )
    end

    def self.item_from_hash(h)
      Item.new(
        item_id:    h["item_id"],
        properties: h["properties"],
        created_at: h["created_at"],
        updated_at: h["updated_at"]
      )
    end

    def self.interaction_from_hash(h)
      Interaction.new(
        interaction_id:   h["interaction_id"],
        user_id:          h["user_id"],
        item_id:          h["item_id"],
        interaction_type: h["interaction_type"],
        value:            h["value"],
        timestamp:        h["timestamp"],
        metadata:         h["metadata"]
      )
    end
  end
end
