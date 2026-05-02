package recommendai_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	recommendai "github.com/recsys-ai/recommendai-go"
)

func newTestServer(t *testing.T, handler http.HandlerFunc) (*httptest.Server, *recommendai.Client) {
	t.Helper()
	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)
	c := recommendai.New("test-key", recommendai.WithBaseURL(srv.URL))
	return srv, c
}

func TestPing_OK(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/health" {
			t.Errorf("unexpected path %s", r.URL.Path)
		}
		w.WriteHeader(http.StatusOK)
	})
	if !c.Ping(context.Background()) {
		t.Error("Ping() returned false; expected true")
	}
}

func TestPing_Down(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	})
	if c.Ping(context.Background()) {
		t.Error("Ping() returned true; expected false")
	}
}

func TestRecommendations_Get(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/recommendations" {
			t.Errorf("unexpected path %s", r.URL.Path)
		}
		if r.URL.Query().Get("user_id") != "user1" {
			t.Errorf("missing user_id param")
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"recommendations": []map[string]any{
				{"item_id": "item1", "score": 0.9, "reason": "test", "metadata": map[string]any{}},
			},
		})
	})
	recs, err := c.Recommendations.Get(context.Background(), "user1", 5)
	if err != nil {
		t.Fatalf("Get: %v", err)
	}
	if len(recs) != 1 || recs[0].ItemID != "item1" {
		t.Errorf("unexpected recs: %+v", recs)
	}
}

func TestRecommendations_Similar(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/recommendations/similar/item99" {
			t.Errorf("unexpected path %s", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"recommendations": []map[string]any{
				{"item_id": "item2", "score": 0.8, "reason": "", "metadata": map[string]any{}},
			},
		})
	})
	recs, err := c.Recommendations.Similar(context.Background(), "item99", 10)
	if err != nil {
		t.Fatalf("Similar: %v", err)
	}
	if len(recs) != 1 {
		t.Errorf("expected 1 rec, got %d", len(recs))
	}
}

func TestRecommendations_Popular(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/recommendations/popular" {
			t.Errorf("unexpected path %s", r.URL.Path)
		}
		if r.URL.Query().Get("category") != "books" {
			t.Errorf("missing category param")
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"recommendations": []map[string]any{
				{"item_id": "book1", "score": 0.7, "reason": "", "metadata": map[string]any{}},
			},
		})
	})
	recs, err := c.Recommendations.Popular(context.Background(), 5, "books")
	if err != nil {
		t.Fatalf("Popular: %v", err)
	}
	if len(recs) != 1 {
		t.Errorf("expected 1 rec, got %d", len(recs))
	}
}

func TestItems_Upsert(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			t.Errorf("expected POST, got %s", r.Method)
		}
		if r.URL.Path != "/api/items/bulk" {
			t.Errorf("unexpected path %s", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"items": []map[string]any{
				{"item_id": "itemA", "properties": map[string]any{}, "created_at": nil, "updated_at": nil},
			},
		})
	})
	items, err := c.Items.Upsert(context.Background(), []map[string]any{
		{"item_id": "itemA", "properties": map[string]any{"name": "Book A"}},
	})
	if err != nil {
		t.Fatalf("Upsert: %v", err)
	}
	if len(items) != 1 || items[0].ItemID != "itemA" {
		t.Errorf("unexpected items: %+v", items)
	}
}

func TestClient_AuthError(t *testing.T) {
	_, c := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]any{"detail": "invalid api key"})
	})
	_, err := c.Recommendations.Get(context.Background(), "u", 5)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
