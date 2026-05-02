require_relative "errors"
require_relative "models"
require_relative "resources"

module RecommendAI
  # Main client — entry point for all API resources.
  class Client
    attr_reader :api_key, :base_url, :timeout

    # @param api_key  [String]  Your RecSys.AI API key.
    # @param base_url [String]  Override the default API base URL.
    # @param timeout  [Integer] HTTP timeout in seconds (default 30).
    def initialize(api_key:, base_url: "http://localhost:8080", timeout: 30)
      @api_key  = api_key
      @base_url = base_url.chomp("/")
      @timeout  = timeout

      @recommendations = RecommendationsResource.new(self)
      @users           = UsersResource.new(self)
      @items           = ItemsResource.new(self)
      @interactions    = InteractionsResource.new(self)
    end

    # @return [RecommendationsResource]
    def recommendations = @recommendations

    # @return [UsersResource]
    def users = @users

    # @return [ItemsResource]
    def items = @items

    # @return [InteractionsResource]
    def interactions = @interactions

    # Returns true if the API is reachable.
    def ping
      uri = URI(@base_url + "/health")
      Http.request(method: "GET", uri: uri, api_key: @api_key, timeout: @timeout)
      true
    rescue
      false
    end
  end
end
