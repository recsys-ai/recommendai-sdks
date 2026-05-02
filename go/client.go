// Package recommendai provides an official Go client for the RecSys.AI API.
package recommendai

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

const (
	defaultBaseURL = "http://localhost:8080"
	defaultTimeout = 30 * time.Second
	userAgent      = "recommendai-go/1.0.0"
)

// Client is the RecSys.AI API client. Create one with [New].
type Client struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client

	Recommendations *RecommendationsResource
	Users           *UsersResource
	Items           *ItemsResource
	Interactions    *InteractionsResource
}

// Option is a functional option for configuring a [Client].
type Option func(*Client)

// WithBaseURL sets a custom API base URL.
func WithBaseURL(rawURL string) Option {
	return func(c *Client) { c.baseURL = strings.TrimRight(rawURL, "/") }
}

// WithTimeout sets the per-request HTTP timeout.
func WithTimeout(d time.Duration) Option {
	return func(c *Client) { c.httpClient.Timeout = d }
}

// WithHTTPClient replaces the default HTTP client (useful for testing).
func WithHTTPClient(hc *http.Client) Option {
	return func(c *Client) { c.httpClient = hc }
}

// New creates and returns a new RecSys.AI client.
//
//	client := recommendai.New("your_api_key")
//	client := recommendai.New("your_api_key", recommendai.WithBaseURL("https://api.recsys-ai.com"))
func New(apiKey string, opts ...Option) *Client {
	if apiKey == "" {
		panic("recommendai: apiKey must not be empty")
	}
	c := &Client{
		baseURL: defaultBaseURL,
		apiKey:  apiKey,
		httpClient: &http.Client{
			Timeout: defaultTimeout,
		},
	}
	for _, opt := range opts {
		opt(c)
	}
	c.Recommendations = &RecommendationsResource{client: c}
	c.Users            = &UsersResource{client: c}
	c.Items            = &ItemsResource{client: c}
	c.Interactions     = &InteractionsResource{client: c}
	return c
}

// do executes an HTTP request, injects auth headers, and returns the raw JSON body.
// HTTP 4xx/5xx responses are mapped to typed errors.
func (c *Client) do(req *http.Request) ([]byte, error) {
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("User-Agent", userAgent)
	if req.Body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("recommendai: http request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("recommendai: reading body: %w", err)
	}

	if resp.StatusCode == http.StatusNoContent {
		return []byte("{}"), nil
	}
	if resp.StatusCode >= 400 {
		return nil, parseAPIError(resp.StatusCode, body)
	}
	return body, nil
}

// Ping checks the API health endpoint. Returns true if the service is reachable.
func (c *Client) Ping(ctx context.Context) bool {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/health", nil)
	if err != nil {
		return false
	}
	_, err = c.do(req)
	return err == nil
}

func parseAPIError(status int, body []byte) error {
	var payload struct {
		Detail string `json:"detail"`
	}
	detail := fmt.Sprintf("HTTP %d", status)
	if json.Unmarshal(body, &payload) == nil && payload.Detail != "" {
		detail = payload.Detail
	}
	switch status {
	case http.StatusUnauthorized:
		return &AuthenticationError{Message: detail}
	case http.StatusNotFound:
		return &NotFoundError{Message: detail}
	case http.StatusBadRequest, http.StatusUnprocessableEntity:
		return &ValidationError{Message: detail}
	case http.StatusTooManyRequests:
		return &RateLimitError{Message: detail}
	default:
		if status >= 500 {
			return &ServerError{Message: detail, StatusCode: status}
		}
		return &APIError{Message: detail, StatusCode: status}
	}
}
