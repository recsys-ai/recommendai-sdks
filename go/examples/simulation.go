// Simulation demonstrates the RecSys.AI Go SDK with a self-contained
// in-process mock HTTP server.  No live API key or running service needed.
//
// Run:
//
//	go run ./examples/simulation.go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	recommendai "github.com/recsys-ai/recommendai-sdks/go"
)

const mockPort = 17893

// ── Scenario data ─────────────────────────────────────────────────────────────

type movieData struct{ id, title, genre string; year int; rating float64 }
type userData struct{ id, name, preferredGenre string; age int }

var movies = []movieData{
	{"movie_001", "The Matrix", "sci-fi", 1999, 8.7},
	{"movie_002", "Inception", "sci-fi", 2010, 8.8},
	{"movie_003", "Interstellar", "sci-fi", 2014, 8.6},
	{"movie_004", "The Dark Knight", "action", 2008, 9.0},
	{"movie_005", "Avengers: Endgame", "action", 2019, 8.4},
	{"movie_006", "John Wick", "action", 2014, 7.4},
	{"movie_007", "The Shawshank Redemption", "drama", 1994, 9.3},
	{"movie_008", "Forrest Gump", "drama", 1994, 8.8},
	{"movie_009", "Pulp Fiction", "thriller", 1994, 8.9},
	{"movie_010", "The Silence of the Lambs", "thriller", 1991, 8.6},
}

var users = []userData{
	{"alice", "Alice Johnson", "sci-fi", 28},
	{"bob", "Bob Smith", "action", 35},
	{"carol", "Carol White", "drama", 42},
	{"dave", "Dave Brown", "sci-fi", 23},
	{"eve", "Eve Davis", "thriller", 31},
}

type interaction struct{ userID, itemID, itype string; value *float64 }

var interactions = []interaction{
	{"alice", "movie_001", "view", nil},
	{"alice", "movie_002", "like", nil},
	{"alice", "movie_003", "purchase", nil},
	{"alice", "movie_001", "rating", ptr(9.0)},
	{"bob", "movie_004", "view", nil},
	{"bob", "movie_005", "like", nil},
	{"bob", "movie_006", "purchase", nil},
	{"bob", "movie_004", "rating", ptr(8.0)},
	{"carol", "movie_007", "view", nil},
	{"carol", "movie_008", "like", nil},
	{"carol", "movie_007", "purchase", nil},
	{"carol", "movie_008", "rating", ptr(9.0)},
	{"dave", "movie_001", "view", nil},
	{"dave", "movie_002", "purchase", nil},
	{"dave", "movie_003", "rating", ptr(8.5)},
	{"eve", "movie_009", "view", nil},
	{"eve", "movie_010", "like", nil},
	{"eve", "movie_009", "purchase", nil},
	{"eve", "movie_010", "rating", ptr(8.0)},
	{"alice", "movie_002", "rating", ptr(10.0)},
	{"bob", "movie_006", "rating", ptr(7.5)},
	{"carol", "movie_009", "view", nil},
	{"dave", "movie_004", "view", nil},
	{"eve", "movie_002", "view", nil},
	{"alice", "movie_004", "view", nil},
}

func ptr(v float64) *float64 { return &v }

// ── Mock server state ─────────────────────────────────────────────────────────

var (
	mu          sync.RWMutex
	usersDB     = map[string]map[string]interface{}{}
	itemsDB     = map[string]map[string]interface{}{}
	interactDB  []map[string]interface{}
)

func main() {
	srv := startMockServer()
	defer srv.Close()

	client := recommendai.New("sim-api-key",
		recommendai.WithBaseURL(fmt.Sprintf("http://localhost:%d", mockPort)))

	runSimulation(client)
}

func runSimulation(client *recommendai.Client) {
	banner("RecSys.AI Go SDK — Movie Streaming Simulation")

	// Step 1: seed catalogue
	step(1, "Seeding Movie Catalogue")
	for _, m := range movies {
		item, err := client.Items.Create(context.Background(), m.id, map[string]interface{}{
			"title":  m.title,
			"genre":  m.genre,
			"year":   m.year,
			"rating": m.rating,
		})
		must(err)
		fmt.Printf("  Created item: %s (%s)\n", item.ItemID, item.Properties["title"])
	}
	fmt.Printf("  %d movies added to catalogue.\n\n", len(movies))

	// Step 2: register users
	step(2, "Registering Users")
	for _, u := range users {
		user, err := client.Users.Create(context.Background(), u.id, map[string]interface{}{
			"name":             u.name,
			"age":              u.age,
			"preferred_genre":  u.preferredGenre,
		})
		must(err)
		fmt.Printf("  Registered: %s (%s)\n", user.UserID, user.Properties["name"])
	}
	fmt.Printf("  %d users registered.\n\n", len(users))

	// Step 3: record interactions
	step(3, "Recording Watch History & Ratings")
	for _, ia := range interactions {
		_, err := client.Interactions.Create(context.Background(), recommendai.CreateInteractionParams{
			UserID:          ia.userID,
			ItemID:          ia.itemID,
			InteractionType: recommendai.InteractionType(ia.itype),
			Value:           ia.value,
		})
		must(err)
	}
	fmt.Printf("  %d interactions recorded.\n\n", len(interactions))

	// Step 4: personalised recommendations
	step(4, "Getting Personalised Recommendations")
	for _, u := range users {
		recs, err := client.Recommendations.Get(context.Background(), u.id, 5)
		must(err)
		fmt.Printf("  Recommendations for %s:\n", u.id)
		for i, r := range recs {
			title := movieTitle(r.ItemID)
			reason := r.Reason
			if reason == "" {
				reason = "-"
			}
			fmt.Printf("    %d. %-36s (score: %.4f)  %s\n", i+1, title, r.Score, reason)
		}
		fmt.Println()
	}

	// Step 5: update item metadata
	step(5, "Updating Item Metadata")
	updated, err := client.Items.Update(context.Background(), "movie_001", map[string]interface{}{
		"title": "The Matrix", "genre": "sci-fi", "year": 1999,
		"rating": 8.7, "remastered": true,
	})
	must(err)
	fmt.Printf("  Updated movie_001 — remastered: %v\n\n", updated.Properties["remastered"])

	// Step 6: update user profile
	step(6, "Updating User Profile")
	alice, err := client.Users.Update(context.Background(), "alice", map[string]interface{}{
		"name": "Alice Johnson", "age": 29,
		"preferred_genre": "sci-fi", "subscription": "premium",
	})
	must(err)
	fmt.Printf("  alice subscription → %v\n\n", alice.Properties["subscription"])

	// Step 7: verify item retrieval
	step(7, "Verifying Item Retrieval")
	retrieved, err := client.Items.Get(context.Background(), "movie_004")
	must(err)
	fmt.Printf("  Retrieved: %s — %s (%s)\n\n",
		retrieved.ItemID,
		retrieved.Properties["title"],
		retrieved.Properties["genre"])

	// Step 8: concurrent recommendations
	step(8, "Concurrent Recommendations (goroutines)")
	type result struct {
		userID string
		recs   []recommendai.Recommendation
		err    error
	}
	ch := make(chan result, 3)
	for _, uid := range []string{"alice", "bob", "carol"} {
		go func(uid string) {
			recs, err := client.Recommendations.Get(context.Background(), uid, 3)
			ch <- result{uid, recs, err}
		}(uid)
	}
	for range 3 {
		r := <-ch
		must(r.err)
		fmt.Printf("  %s got %d recommendations\n", r.userID, len(r.recs))
	}
	fmt.Println()

	// Step 9: error handling demo
	step(9, "Error Handling Demo")
	_, err = client.Users.Get(context.Background(), "ghost_999")
	if recommendai.IsNotFound(err) {
		fmt.Printf("  Caught NotFoundError: %v\n\n", err)
	} else {
		fmt.Println("  ERROR: expected NotFoundError was not thrown!")
	}

	// Step 10: cleanup
	step(10, "Cleanup")
	must(client.Users.Delete(context.Background(), "dave"))
	fmt.Println("  Deleted user 'dave'.")
	_, err = client.Users.Get(context.Background(), "dave")
	if recommendai.IsNotFound(err) {
		fmt.Println("  Confirmed: 'dave' no longer exists.")
	}

	fmt.Println()
	banner("Simulation complete — all steps passed!")
}

// ── Mock HTTP server ──────────────────────────────────────────────────────────

func startMockServer() *http.Server {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/users/{id}", handleUserByID)
	mux.HandleFunc("/api/users", handleUsers)
	mux.HandleFunc("/api/items/{id}", handleItemByID)
	mux.HandleFunc("/api/items", handleItems)
	mux.HandleFunc("/api/interactions", handleInteractions)
	mux.HandleFunc("/api/recommendations", handleRecommendations)

	srv := &http.Server{Addr: fmt.Sprintf(":%d", mockPort), Handler: mux}

	ln, err := net.Listen("tcp", srv.Addr)
	if err != nil {
		panic(err)
	}
	fmt.Printf("[mock] Server listening on port %d\n\n", mockPort)
	go srv.Serve(ln) //nolint:errcheck
	return srv
}

func handleUsers(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		var body map[string]interface{}
		readJSON(r, &body)
		userID := str(body["user_id"])
		rec := map[string]interface{}{
			"user_id":    userID,
			"properties": body["properties"],
			"created_at": time.Now().Format(time.RFC3339),
			"updated_at": time.Now().Format(time.RFC3339),
		}
		mu.Lock()
		usersDB[userID] = rec
		mu.Unlock()
		writeJSON(w, http.StatusCreated, rec)
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleUserByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	switch r.Method {
	case http.MethodGet:
		mu.RLock()
		u, ok := usersDB[id]
		mu.RUnlock()
		if !ok {
			writeJSON(w, http.StatusNotFound, map[string]string{"detail": "User not found: " + id})
			return
		}
		writeJSON(w, http.StatusOK, u)
	case http.MethodPut:
		mu.Lock()
		existing, ok := usersDB[id]
		if !ok {
			mu.Unlock()
			writeJSON(w, http.StatusNotFound, map[string]string{"detail": "User not found: " + id})
			return
		}
		var body map[string]interface{}
		readJSON(r, &body)
		existing["properties"] = body["properties"]
		existing["updated_at"] = time.Now().Format(time.RFC3339)
		mu.Unlock()
		writeJSON(w, http.StatusOK, existing)
	case http.MethodDelete:
		mu.Lock()
		_, ok := usersDB[id]
		if !ok {
			mu.Unlock()
			writeJSON(w, http.StatusNotFound, map[string]string{"detail": "User not found: " + id})
			return
		}
		delete(usersDB, id)
		mu.Unlock()
		w.WriteHeader(http.StatusNoContent)
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleItems(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		var body map[string]interface{}
		readJSON(r, &body)
		itemID := str(body["item_id"])
		rec := map[string]interface{}{
			"item_id":    itemID,
			"properties": body["properties"],
			"created_at": time.Now().Format(time.RFC3339),
			"updated_at": time.Now().Format(time.RFC3339),
		}
		mu.Lock()
		itemsDB[itemID] = rec
		mu.Unlock()
		writeJSON(w, http.StatusCreated, rec)
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleItemByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	switch r.Method {
	case http.MethodGet:
		mu.RLock()
		item, ok := itemsDB[id]
		mu.RUnlock()
		if !ok {
			writeJSON(w, http.StatusNotFound, map[string]string{"detail": "Item not found: " + id})
			return
		}
		writeJSON(w, http.StatusOK, item)
	case http.MethodPut:
		mu.Lock()
		existing, ok := itemsDB[id]
		if !ok {
			mu.Unlock()
			writeJSON(w, http.StatusNotFound, map[string]string{"detail": "Item not found: " + id})
			return
		}
		var body map[string]interface{}
		readJSON(r, &body)
		existing["properties"] = body["properties"]
		existing["updated_at"] = time.Now().Format(time.RFC3339)
		mu.Unlock()
		writeJSON(w, http.StatusOK, existing)
	case http.MethodDelete:
		mu.Lock()
		_, ok := itemsDB[id]
		if !ok {
			mu.Unlock()
			writeJSON(w, http.StatusNotFound, map[string]string{"detail": "Item not found: " + id})
			return
		}
		delete(itemsDB, id)
		mu.Unlock()
		w.WriteHeader(http.StatusNoContent)
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleInteractions(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var body map[string]interface{}
	readJSON(r, &body)
	body["interaction_id"] = fmt.Sprintf("ia_%d", time.Now().UnixNano())
	body["timestamp"] = time.Now().Format(time.RFC3339)
	mu.Lock()
	interactDB = append(interactDB, body)
	mu.Unlock()
	writeJSON(w, http.StatusCreated, body)
}

func handleRecommendations(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	q := r.URL.Query()
	userID := q.Get("user_id")
	limit := 10
	fmt.Sscan(q.Get("limit"), &limit)

	recs := computeRecommendations(userID, limit)
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"user_id":         userID,
		"recommendations": recs,
	})
}

func computeRecommendations(userID string, limit int) []map[string]interface{} {
	mu.RLock()
	defer mu.RUnlock()

	seen := map[string]bool{}
	for _, ia := range interactDB {
		if str(ia["user_id"]) == userID {
			seen[str(ia["item_id"])] = true
		}
	}

	var preferredGenre string
	if u, ok := usersDB[userID]; ok {
		if props, ok := u["properties"].(map[string]interface{}); ok {
			preferredGenre, _ = props["preferred_genre"].(string)
		}
	}

	type scored struct {
		score float64
		rec   map[string]interface{}
	}
	var candidates []scored

	for itemID, item := range itemsDB {
		if seen[itemID] {
			continue
		}
		props, _ := item["properties"].(map[string]interface{})
		if props == nil {
			props = map[string]interface{}{}
		}
		rating := 5.0
		if r, ok := props["rating"].(float64); ok {
			rating = r
		}
		score := rating / 10.0
		genre, _ := props["genre"].(string)
		if preferredGenre != "" && genre == preferredGenre {
			score += 0.2
		}
		score += float64(djb2(userID+itemID)%100) / 1000.0
		score = math.Min(score, 1.0)
		score = math.Round(score*10000) / 10000

		reason := "Highly rated content"
		if preferredGenre != "" && genre == preferredGenre {
			reason = "Matches preferred genre: " + preferredGenre
		}

		title, _ := props["title"].(string)
		candidates = append(candidates, scored{score, map[string]interface{}{
			"item_id":  itemID,
			"score":    score,
			"reason":   reason,
			"metadata": map[string]interface{}{"title": title},
		}})
	}

	// sort descending by score
	for i := 1; i < len(candidates); i++ {
		for j := i; j > 0 && candidates[j].score > candidates[j-1].score; j-- {
			candidates[j], candidates[j-1] = candidates[j-1], candidates[j]
		}
	}

	result := []map[string]interface{}{}
	for i, c := range candidates {
		if i >= limit {
			break
		}
		result = append(result, c.rec)
	}
	return result
}

func djb2(s string) uint64 {
	var h uint64 = 5381
	for _, c := range s {
		h = ((h << 5) + h) + uint64(c)
	}
	return h
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func readJSON(r *http.Request, dst interface{}) {
	data, _ := io.ReadAll(r.Body)
	json.Unmarshal(data, dst) //nolint:errcheck
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v) //nolint:errcheck
}

func str(v interface{}) string {
	if v == nil {
		return ""
	}
	s, _ := v.(string)
	return s
}

func movieTitle(itemID string) string {
	for _, m := range movies {
		if m.id == itemID {
			return m.title
		}
	}
	return itemID
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

func banner(text string) {
	line := strings.Repeat("=", len(text)+4)
	fmt.Println(line)
	fmt.Println("= " + text + " =")
	fmt.Println(line)
	fmt.Println()
}

func step(n int, title string) {
	fmt.Printf("── Step %d: %s\n", n, title)
}
