package recommendai

import "fmt"

// APIError is the base error for unexpected HTTP status codes.
type APIError struct {
	Message    string
	StatusCode int
}

func (e *APIError) Error() string {
	return fmt.Sprintf("recommendai: api error (%d): %s", e.StatusCode, e.Message)
}

// AuthenticationError is returned for HTTP 401 responses.
type AuthenticationError struct{ Message string }

func (e *AuthenticationError) Error() string { return "recommendai: authentication failed: " + e.Message }

// NotFoundError is returned for HTTP 404 responses.
type NotFoundError struct{ Message string }

func (e *NotFoundError) Error() string { return "recommendai: not found: " + e.Message }

// ValidationError is returned for HTTP 400/422 responses.
type ValidationError struct{ Message string }

func (e *ValidationError) Error() string { return "recommendai: validation error: " + e.Message }

// RateLimitError is returned for HTTP 429 responses.
type RateLimitError struct{ Message string }

func (e *RateLimitError) Error() string { return "recommendai: rate limit exceeded: " + e.Message }

// ServerError is returned for HTTP 5xx responses.
type ServerError struct {
	Message    string
	StatusCode int
}

func (e *ServerError) Error() string {
	return fmt.Sprintf("recommendai: server error (%d): %s", e.StatusCode, e.Message)
}

// IsNotFound reports whether err is a *NotFoundError.
func IsNotFound(err error) bool { _, ok := err.(*NotFoundError); return ok }

// IsAuthError reports whether err is an *AuthenticationError.
func IsAuthError(err error) bool { _, ok := err.(*AuthenticationError); return ok }

// IsRateLimit reports whether err is a *RateLimitError.
func IsRateLimit(err error) bool { _, ok := err.(*RateLimitError); return ok }

// IsServerError reports whether err is a *ServerError.
func IsServerError(err error) bool { _, ok := err.(*ServerError); return ok }
