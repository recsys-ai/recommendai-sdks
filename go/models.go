package recommendai

import "time"

// InteractionType represents the kind of user–item interaction.
type InteractionType string

const (
	InteractionView       InteractionType = "view"
	InteractionClick      InteractionType = "click"
	InteractionPurchase   InteractionType = "purchase"
	InteractionLike       InteractionType = "like"
	InteractionDislike    InteractionType = "dislike"
	InteractionRating     InteractionType = "rating"
	InteractionCartAdd    InteractionType = "cart_add"
	InteractionCartRemove InteractionType = "cart_remove"
)

// Recommendation is a personalised item recommendation.
type Recommendation struct {
	ItemID   string                 `json:"item_id"`
	Score    float64                `json:"score"`
	Reason   string                 `json:"reason,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// User is a registered platform user.
type User struct {
	UserID     string                 `json:"user_id"`
	Properties map[string]interface{} `json:"properties"`
	CreatedAt  time.Time              `json:"created_at"`
	UpdatedAt  time.Time              `json:"updated_at"`
}

// Item is a catalogue entry.
type Item struct {
	ItemID     string                 `json:"item_id"`
	Properties map[string]interface{} `json:"properties"`
	CreatedAt  time.Time              `json:"created_at"`
	UpdatedAt  time.Time              `json:"updated_at"`
}

// Interaction is a recorded user–item event.
type Interaction struct {
	InteractionID   string                 `json:"interaction_id,omitempty"`
	UserID          string                 `json:"user_id"`
	ItemID          string                 `json:"item_id"`
	InteractionType InteractionType        `json:"interaction_type"`
	Value           *float64               `json:"value,omitempty"`
	Timestamp       time.Time              `json:"timestamp"`
	Metadata        map[string]interface{} `json:"metadata,omitempty"`
}

// CreateInteractionParams holds the parameters for creating an interaction.
type CreateInteractionParams struct {
	UserID          string
	ItemID          string
	InteractionType InteractionType
	// Value is an optional numeric value, e.g. a rating 1–10.
	Value    *float64
	Metadata map[string]interface{}
}

// Ptr returns a pointer to v — convenience helper for CreateInteractionParams.Value.
func Ptr[T any](v T) *T { return &v }
