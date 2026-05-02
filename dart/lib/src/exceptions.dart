/// Base exception for all RecSys.AI SDK errors.
class RecommendAIException implements Exception {
  final String message;
  final int? statusCode;

  const RecommendAIException(this.message, {this.statusCode});

  @override
  String toString() => 'RecommendAIException($statusCode): $message';
}

class AuthenticationException extends RecommendAIException {
  const AuthenticationException(String message)
      : super(message, statusCode: 401);
}

class NotFoundException extends RecommendAIException {
  const NotFoundException(String message) : super(message, statusCode: 404);
}

class ValidationException extends RecommendAIException {
  const ValidationException(String message) : super(message, statusCode: 422);
}

class RateLimitException extends RecommendAIException {
  const RateLimitException(String message) : super(message, statusCode: 429);
}

class ServerException extends RecommendAIException {
  const ServerException(String message, {int statusCode = 500})
      : super(message, statusCode: statusCode);
}
