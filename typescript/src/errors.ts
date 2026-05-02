export class RecommendAIError extends Error {
  constructor(
    message: string,
    public statusCode?: number
  ) {
    super(message);
    this.name = 'RecommendAIError';
  }
}

export class AuthenticationError extends RecommendAIError {
  constructor(message = 'Authentication failed') {
    super(message, 401);
    this.name = 'AuthenticationError';
  }
}

export class NotFoundError extends RecommendAIError {
  constructor(message = 'Resource not found') {
    super(message, 404);
    this.name = 'NotFoundError';
  }
}

export class ValidationError extends RecommendAIError {
  constructor(message = 'Validation error') {
    super(message, 400);
    this.name = 'ValidationError';
  }
}

export class RateLimitError extends RecommendAIError {
  constructor(message = 'Rate limit exceeded') {
    super(message, 429);
    this.name = 'RateLimitError';
  }
}

export class ServerError extends RecommendAIError {
  constructor(message = 'Server error') {
    super(message, 500);
    this.name = 'ServerError';
  }
}
