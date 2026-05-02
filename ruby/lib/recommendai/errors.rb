module RecommendAI
  # Base error class for all RecSys.AI API errors.
  class Error < StandardError
    attr_reader :status_code

    def initialize(message, status_code: 0)
      super(message)
      @status_code = status_code
    end
  end

  # Raised when the API key is invalid or missing (HTTP 401).
  class AuthenticationError < Error
    def initialize(message)
      super(message, status_code: 401)
    end
  end

  # Raised when a requested resource does not exist (HTTP 404).
  class NotFoundError < Error
    def initialize(message)
      super(message, status_code: 404)
    end
  end

  # Raised when request validation fails (HTTP 400 / 422).
  class ValidationError < Error
    def initialize(message, status_code: 422)
      super(message, status_code: status_code)
    end
  end

  # Raised when the rate limit is exceeded (HTTP 429).
  class RateLimitError < Error
    def initialize(message)
      super(message, status_code: 429)
    end
  end

  # Raised for unexpected server-side errors (HTTP 5xx).
  class ServerError < Error
    def initialize(message, status_code:)
      super(message, status_code: status_code)
    end
  end
end
