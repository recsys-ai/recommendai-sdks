require "spec_helper"

RSpec.describe RecommendAI::Client do
  let(:client) { RecommendAI::Client.new(api_key: "test-key") }
  let(:base)   { "http://localhost:8080" }

  def stub(method, path, status:, body:)
    stub_request(method, "#{base}#{path}")
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  # ── ping ───────────────────────────────────────────────────────────────────

  describe "#ping" do
    it "returns true when the server responds 200" do
      stub_request(:get, "#{base}/health").to_return(status: 200, body: "{}")
      expect(client.ping).to be true
    end

    it "returns false when the server is down" do
      stub_request(:get, "#{base}/health").to_return(status: 503, body: "{}")
      expect(client.ping).to be false
    end
  end

  # ── recommendations ─────────────────────────────────────────────────────────

  describe "#recommendations" do
    let(:rec_body) do
      { "recommendations" => [
        { "item_id" => "item1", "score" => 0.9, "reason" => "test", "metadata" => {} }
      ] }
    end

    it "get returns recommendations with correct path" do
      stub(:get, "/api/recommendations?user_id=user1&limit=5", status: 200, body: rec_body)
      recs = client.recommendations.get("user1", limit: 5)
      expect(recs.length).to eq(1)
      expect(recs.first.item_id).to eq("item1")
    end

    it "similar calls the correct path" do
      stub(:get, "/api/recommendations/similar/item99?limit=10", status: 200, body: rec_body)
      recs = client.recommendations.similar("item99")
      expect(recs.length).to eq(1)
      expect(recs.first.item_id).to eq("item1")
    end

    it "popular passes category param" do
      stub(:get, "/api/recommendations/popular?limit=5&category=books", status: 200, body: rec_body)
      recs = client.recommendations.popular(limit: 5, category: "books")
      expect(recs.length).to eq(1)
    end
  end

  # ── items ──────────────────────────────────────────────────────────────────

  describe "#items" do
    it "upsert posts to /api/items/bulk" do
      items_body = { "items" => [
        { "item_id" => "itemA", "properties" => {}, "created_at" => nil, "updated_at" => nil }
      ] }
      stub_request(:post, "#{base}/api/items/bulk").to_return(status: 200, body: items_body.to_json,
                                                               headers: { "Content-Type" => "application/json" })
      items = client.items.upsert([{ item_id: "itemA", properties: { name: "Book A" } }])
      expect(items.length).to eq(1)
      expect(items.first.item_id).to eq("itemA")
    end
  end

  # ── errors ─────────────────────────────────────────────────────────────────

  describe "error handling" do
    it "raises AuthenticationError on 401" do
      stub_request(:get, /localhost:8080/).to_return(status: 401, body: { detail: "invalid" }.to_json)
      expect { client.recommendations.get("u") }.to raise_error(RecommendAI::AuthenticationError)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, /localhost:8080/).to_return(status: 404, body: { detail: "not found" }.to_json)
      expect { client.recommendations.get("u") }.to raise_error(RecommendAI::NotFoundError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:get, /localhost:8080/).to_return(status: 429, body: { detail: "rate limit" }.to_json)
      expect { client.recommendations.get("u") }.to raise_error(RecommendAI::RateLimitError)
    end
  end
end
