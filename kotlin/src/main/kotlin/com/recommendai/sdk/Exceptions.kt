package com.recommendai.sdk

open class RecommendAIException(message: String, val statusCode: Int? = null) :
    RuntimeException(message)

class AuthenticationException(message: String) : RecommendAIException(message, 401)
class NotFoundException(message: String)       : RecommendAIException(message, 404)
class ValidationException(message: String)     : RecommendAIException(message, 422)
class RateLimitException(message: String)      : RecommendAIException(message, 429)
class ServerException(message: String, code: Int = 500) : RecommendAIException(message, code)
