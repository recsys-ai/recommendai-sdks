package recommendai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

// ── Recommendations ───────────────────────────────────────────────────────────

// RecommendationsResource provides access to the /api/recommendations endpoint.
type RecommendationsResource struct{ client *Client }

// Get returns personalised recommendations for userID.
func (r *RecommendationsResource) Get(ctx context.Context, userID string, limit int) ([]Recommendation, error) {
	if limit <= 0 {
		limit = 10
	}
	path := fmt.Sprintf("/api/recommendations?user_id=%s&limit=%d",
		url.QueryEscape(userID), limit)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.client.baseURL+path, nil)
	if err != nil {
		return nil, err
	}
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var resp struct {
		Recommendations []Recommendation `json:"recommendations"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("recommendai: unmarshal recommendations: %w", err)
	}
	return resp.Recommendations, nil
}

// Similar returns items similar to itemID.
func (r *RecommendationsResource) Similar(ctx context.Context, itemID string, limit int) ([]Recommendation, error) {
	if limit <= 0 {
		limit = 10
	}
	path := fmt.Sprintf("/api/recommendations/similar/%s?limit=%d", url.PathEscape(itemID), limit)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.client.baseURL+path, nil)
	if err != nil {
		return nil, err
	}
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var resp struct {
		Recommendations []Recommendation `json:"recommendations"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("recommendai: unmarshal similar: %w", err)
	}
	return resp.Recommendations, nil
}

// Popular returns globally trending items, optionally filtered by category.
func (r *RecommendationsResource) Popular(ctx context.Context, limit int, category string) ([]Recommendation, error) {
	if limit <= 0 {
		limit = 10
	}
	path := fmt.Sprintf("/api/recommendations/popular?limit=%d", limit)
	if category != "" {
		path += "&category=" + url.QueryEscape(category)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.client.baseURL+path, nil)
	if err != nil {
		return nil, err
	}
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var resp struct {
		Recommendations []Recommendation `json:"recommendations"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("recommendai: unmarshal popular: %w", err)
	}
	return resp.Recommendations, nil
}

// ── Users ─────────────────────────────────────────────────────────────────────

// UsersResource provides access to the /api/users endpoints.
type UsersResource struct{ client *Client }

// Create registers a new user.
func (r *UsersResource) Create(ctx context.Context, userID string, properties map[string]interface{}) (*User, error) {
	if properties == nil {
		properties = map[string]interface{}{}
	}
	data, _ := json.Marshal(map[string]interface{}{"user_id": userID, "properties": properties})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.client.baseURL+"/api/users", bytes.NewReader(data))
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var u User
	return &u, json.Unmarshal(body, &u)
}

// Get retrieves a user by ID.
func (r *UsersResource) Get(ctx context.Context, userID string) (*User, error) {
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.client.baseURL+"/api/users/"+url.PathEscape(userID), nil)
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var u User
	return &u, json.Unmarshal(body, &u)
}

// Update replaces a user's properties.
func (r *UsersResource) Update(ctx context.Context, userID string, properties map[string]interface{}) (*User, error) {
	data, _ := json.Marshal(map[string]interface{}{"properties": properties})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPut, r.client.baseURL+"/api/users/"+url.PathEscape(userID), bytes.NewReader(data))
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var u User
	return &u, json.Unmarshal(body, &u)
}

// Delete permanently removes a user.
func (r *UsersResource) Delete(ctx context.Context, userID string) error {
	req, _ := http.NewRequestWithContext(ctx, http.MethodDelete, r.client.baseURL+"/api/users/"+url.PathEscape(userID), nil)
	_, err := r.client.do(req)
	return err
}

// ── Items ─────────────────────────────────────────────────────────────────────

// ItemsResource provides access to the /api/items endpoints.
type ItemsResource struct{ client *Client }

// Create adds a new item to the catalogue.
func (r *ItemsResource) Create(ctx context.Context, itemID string, properties map[string]interface{}) (*Item, error) {
	if properties == nil {
		properties = map[string]interface{}{}
	}
	data, _ := json.Marshal(map[string]interface{}{"item_id": itemID, "properties": properties})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.client.baseURL+"/api/items", bytes.NewReader(data))
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var item Item
	return &item, json.Unmarshal(body, &item)
}

// Get retrieves an item by ID.
func (r *ItemsResource) Get(ctx context.Context, itemID string) (*Item, error) {
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.client.baseURL+"/api/items/"+url.PathEscape(itemID), nil)
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var item Item
	return &item, json.Unmarshal(body, &item)
}

// Update replaces an item's properties.
func (r *ItemsResource) Update(ctx context.Context, itemID string, properties map[string]interface{}) (*Item, error) {
	data, _ := json.Marshal(map[string]interface{}{"properties": properties})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPut, r.client.baseURL+"/api/items/"+url.PathEscape(itemID), bytes.NewReader(data))
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var item Item
	return &item, json.Unmarshal(body, &item)
}

// Delete permanently removes an item.
func (r *ItemsResource) Delete(ctx context.Context, itemID string) error {
	req, _ := http.NewRequestWithContext(ctx, http.MethodDelete, r.client.baseURL+"/api/items/"+url.PathEscape(itemID), nil)
	_, err := r.client.do(req)
	return err
}

// Upsert bulk-creates or updates a list of items.
func (r *ItemsResource) Upsert(ctx context.Context, items []map[string]interface{}) ([]Item, error) {
	data, _ := json.Marshal(map[string]interface{}{"items": items})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.client.baseURL+"/api/items/bulk", bytes.NewReader(data))
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var resp struct {
		Items []Item `json:"items"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("recommendai: unmarshal upsert: %w", err)
	}
	return resp.Items, nil
}

// ── Interactions ──────────────────────────────────────────────────────────────

// InteractionsResource provides access to the /api/interactions endpoint.
type InteractionsResource struct{ client *Client }

// Create records a user–item interaction.
func (r *InteractionsResource) Create(ctx context.Context, params CreateInteractionParams) (*Interaction, error) {
	payload := map[string]interface{}{
		"user_id":          params.UserID,
		"item_id":          params.ItemID,
		"interaction_type": string(params.InteractionType),
	}
	if params.Value != nil {
		payload["value"] = *params.Value
	}
	if params.Metadata != nil {
		payload["metadata"] = params.Metadata
	}
	data, _ := json.Marshal(payload)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.client.baseURL+"/api/interactions", bytes.NewReader(data))
	body, err := r.client.do(req)
	if err != nil {
		return nil, err
	}
	var ia Interaction
	return &ia, json.Unmarshal(body, &ia)
}

