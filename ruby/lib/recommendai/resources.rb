require "net/http"
require "uri"
require "json"
require "cgi"

module RecommendAI
  # @api private
  # Internal HTTP helper — used by all resource classes.
  module Http
    def self.request(method:, uri:, api_key:, body: nil, timeout: 30)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout  = timeout
      http.open_timeout  = timeout

      req_class = {
        "GET"    => Net::HTTP::Get,
        "POST"   => Net::HTTP::Post,
        "PUT"    => Net::HTTP::Put,
        "DELETE" => Net::HTTP::Delete
      }.fetch(method)

      req = req_class.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      req["Content-Type"]  = "application/json"
      req["User-Agent"]    = "recommendai-ruby/#{RecommendAI::VERSION}"

      if body
        req.body = JSON.generate(body)
      end

      resp = http.request(req)
      status = resp.code.to_i
      return nil if status == 204

      parsed = JSON.parse(resp.body)
      raise_for_status(status, parsed) unless (200..299).cover?(status)
      parsed
    end

    def self.raise_for_status(status, body)
      detail = body.is_a?(Hash) ? (body["detail"] || "HTTP #{status}") : "HTTP #{status}"
      case status
      when 401 then raise AuthenticationError, detail
      when 404 then raise NotFoundError, detail
      when 400, 422 then raise ValidationError.new(detail, status_code: status)
      when 429 then raise RateLimitError, detail
      when 500..599 then raise ServerError.new(detail, status_code: status)
      else raise Error.new(detail, status_code: status)
      end
    end
  end

  # ── RecommendationsResource ───────────────────────────────────────────────

  class RecommendationsResource
    def initialize(client) = @client = client

    # Returns personalised recommendations for a user.
    def get(user_id, limit: 10)
      uri = URI(@client.base_url + "/api/recommendations")
      uri.query = URI.encode_www_form(user_id: user_id, limit: limit)
      data = Http.request(method: "GET", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      Array(data["recommendations"]).map { Models.recommendation_from_hash(_1) }
    end

    # Returns items similar to the given item.
    def similar(item_id, limit: 10)
      uri = URI(@client.base_url + "/api/recommendations/similar/#{CGI.escape(item_id)}")
      uri.query = URI.encode_www_form(limit: limit)
      data = Http.request(method: "GET", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      Array(data["recommendations"]).map { Models.recommendation_from_hash(_1) }
    end

    # Returns globally popular items, optionally filtered by category.
    def popular(limit: 10, category: nil)
      params = { limit: limit }
      params[:category] = category if category
      uri = URI(@client.base_url + "/api/recommendations/popular")
      uri.query = URI.encode_www_form(params)
      data = Http.request(method: "GET", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      Array(data["recommendations"]).map { Models.recommendation_from_hash(_1) }
    end
  end

  # ── UsersResource ─────────────────────────────────────────────────────────

  class UsersResource
    def initialize(client) = @client = client

    def create(user_id, properties: {})
      uri  = URI(@client.base_url + "/api/users")
      data = Http.request(method: "POST", uri: uri, api_key: @client.api_key,
                          body: { user_id: user_id, properties: properties },
                          timeout: @client.timeout)
      Models.user_from_hash(data)
    end

    def get(user_id)
      uri  = URI(@client.base_url + "/api/users/#{CGI.escape(user_id)}")
      data = Http.request(method: "GET", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      Models.user_from_hash(data)
    end

    def update(user_id, properties:)
      uri  = URI(@client.base_url + "/api/users/#{CGI.escape(user_id)}")
      data = Http.request(method: "PUT", uri: uri, api_key: @client.api_key,
                          body: { properties: properties },
                          timeout: @client.timeout)
      Models.user_from_hash(data)
    end

    def delete(user_id)
      uri = URI(@client.base_url + "/api/users/#{CGI.escape(user_id)}")
      Http.request(method: "DELETE", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      nil
    end
  end

  # ── ItemsResource ─────────────────────────────────────────────────────────

  class ItemsResource
    def initialize(client) = @client = client

    def create(item_id, properties: {})
      uri  = URI(@client.base_url + "/api/items")
      data = Http.request(method: "POST", uri: uri, api_key: @client.api_key,
                          body: { item_id: item_id, properties: properties },
                          timeout: @client.timeout)
      Models.item_from_hash(data)
    end

    def get(item_id)
      uri  = URI(@client.base_url + "/api/items/#{CGI.escape(item_id)}")
      data = Http.request(method: "GET", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      Models.item_from_hash(data)
    end

    def update(item_id, properties:)
      uri  = URI(@client.base_url + "/api/items/#{CGI.escape(item_id)}")
      data = Http.request(method: "PUT", uri: uri, api_key: @client.api_key,
                          body: { properties: properties },
                          timeout: @client.timeout)
      Models.item_from_hash(data)
    end

    def delete(item_id)
      uri = URI(@client.base_url + "/api/items/#{CGI.escape(item_id)}")
      Http.request(method: "DELETE", uri: uri, api_key: @client.api_key, timeout: @client.timeout)
      nil
    end

    def upsert(items)
      uri  = URI(@client.base_url + "/api/items/bulk")
      data = Http.request(method: "POST", uri: uri, api_key: @client.api_key,
                          body: { items: items }, timeout: @client.timeout)
      Array(data["items"]).map { Models.item_from_hash(_1) }
    end
  end

  # ── InteractionsResource ──────────────────────────────────────────────────

  class InteractionsResource
    def initialize(client) = @client = client

    def create(user_id:, item_id:, interaction_type:, value: nil, metadata: nil)
      payload = { user_id: user_id, item_id: item_id, interaction_type: interaction_type }
      payload[:value]    = value    unless value.nil?
      payload[:metadata] = metadata unless metadata.nil?
      uri  = URI(@client.base_url + "/api/interactions")
      data = Http.request(method: "POST", uri: uri, api_key: @client.api_key,
                          body: payload, timeout: @client.timeout)
      Models.interaction_from_hash(data)
    end
  end
end
