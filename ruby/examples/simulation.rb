#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Simulation — RecSys.AI Ruby SDK demo with a self-contained WEBrick mock server.
#
# Run:  ruby examples/simulation.rb

require "webrick"
require "json"
require "thread"
require_relative "../lib/recommendai"

MOCK_PORT = 17895

# ── Scenario data ──────────────────────────────────────────────────────────────

MOVIES = [
  { id: "movie_001", title: "The Matrix",                  genre: "sci-fi",   year: 1999, rating: 8.7 },
  { id: "movie_002", title: "Inception",                   genre: "sci-fi",   year: 2010, rating: 8.8 },
  { id: "movie_003", title: "Interstellar",                genre: "sci-fi",   year: 2014, rating: 8.6 },
  { id: "movie_004", title: "The Dark Knight",             genre: "action",   year: 2008, rating: 9.0 },
  { id: "movie_005", title: "Avengers: Endgame",           genre: "action",   year: 2019, rating: 8.4 },
  { id: "movie_006", title: "John Wick",                   genre: "action",   year: 2014, rating: 7.4 },
  { id: "movie_007", title: "The Shawshank Redemption",    genre: "drama",    year: 1994, rating: 9.3 },
  { id: "movie_008", title: "Forrest Gump",                genre: "drama",    year: 1994, rating: 8.8 },
  { id: "movie_009", title: "Pulp Fiction",                genre: "thriller", year: 1994, rating: 8.9 },
  { id: "movie_010", title: "The Silence of the Lambs",    genre: "thriller", year: 1991, rating: 8.6 },
].freeze

USERS = [
  { id: "alice", name: "Alice Johnson", preferred_genre: "sci-fi",   age: 28 },
  { id: "bob",   name: "Bob Smith",     preferred_genre: "action",   age: 35 },
  { id: "carol", name: "Carol White",   preferred_genre: "drama",    age: 42 },
  { id: "dave",  name: "Dave Brown",    preferred_genre: "sci-fi",   age: 23 },
  { id: "eve",   name: "Eve Davis",     preferred_genre: "thriller", age: 31 },
].freeze

INTERACTIONS = [
  { user_id: "alice", item_id: "movie_001", type: "view",     value: nil  },
  { user_id: "alice", item_id: "movie_002", type: "like",     value: nil  },
  { user_id: "alice", item_id: "movie_003", type: "purchase", value: nil  },
  { user_id: "alice", item_id: "movie_001", type: "rating",   value: 9.0  },
  { user_id: "bob",   item_id: "movie_004", type: "view",     value: nil  },
  { user_id: "bob",   item_id: "movie_005", type: "like",     value: nil  },
  { user_id: "bob",   item_id: "movie_006", type: "purchase", value: nil  },
  { user_id: "bob",   item_id: "movie_004", type: "rating",   value: 8.0  },
  { user_id: "carol", item_id: "movie_007", type: "view",     value: nil  },
  { user_id: "carol", item_id: "movie_008", type: "like",     value: nil  },
  { user_id: "carol", item_id: "movie_007", type: "purchase", value: nil  },
  { user_id: "carol", item_id: "movie_008", type: "rating",   value: 9.0  },
  { user_id: "dave",  item_id: "movie_001", type: "view",     value: nil  },
  { user_id: "dave",  item_id: "movie_002", type: "purchase", value: nil  },
  { user_id: "dave",  item_id: "movie_003", type: "rating",   value: 8.5  },
  { user_id: "eve",   item_id: "movie_009", type: "view",     value: nil  },
  { user_id: "eve",   item_id: "movie_010", type: "like",     value: nil  },
  { user_id: "eve",   item_id: "movie_009", type: "purchase", value: nil  },
  { user_id: "eve",   item_id: "movie_010", type: "rating",   value: 8.0  },
  { user_id: "alice", item_id: "movie_002", type: "rating",   value: 10.0 },
  { user_id: "bob",   item_id: "movie_006", type: "rating",   value: 7.5  },
  { user_id: "carol", item_id: "movie_009", type: "view",     value: nil  },
  { user_id: "dave",  item_id: "movie_004", type: "view",     value: nil  },
  { user_id: "eve",   item_id: "movie_002", type: "view",     value: nil  },
  { user_id: "alice", item_id: "movie_004", type: "view",     value: nil  },
].freeze

# ── Mock server state ──────────────────────────────────────────────────────────

$db_mutex    = Mutex.new
$users_db    = {}
$items_db    = {}
$interact_db = []

def djb2(str)
  h = 5381
  str.each_char { |c| h = ((h << 5) + h + c.ord) & 0xFFFFFFFFFFFFFFFF }
  h
end

def compute_recommendations(user_id, limit)
  $db_mutex.synchronize do
    seen = $interact_db
           .select { |ia| ia["user_id"] == user_id }
           .map    { |ia| ia["item_id"] }
           .to_set

    preferred_genre = ""
    if (u = $users_db[user_id])
      props = u["properties"] || {}
      preferred_genre = props["preferred_genre"].to_s
    end

    candidates = $items_db.filter_map do |item_id, item|
      next if seen.include?(item_id)

      props  = item["properties"] || {}
      rating = props["rating"].to_f
      genre  = props["genre"].to_s
      score  = rating / 10.0
      score += 0.2 if !preferred_genre.empty? && genre == preferred_genre
      score += djb2(user_id + item_id) % 100 / 1000.0
      score  = [score, 1.0].min.round(4)
      reason = (!preferred_genre.empty? && genre == preferred_genre) ?
               "Matches preferred genre: #{preferred_genre}" :
               "Highly rated content"
      {
        "item_id"  => item_id,
        "score"    => score,
        "reason"   => reason,
        "metadata" => { "title" => props["title"] }
      }
    end

    candidates.sort_by { |c| -c["score"] }.first(limit)
  end
end

# ── WEBrick mock servlet ──────────────────────────────────────────────────────

class MockServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_POST(req, res)
    path = req.path
    body = JSON.parse(req.body || "{}")

    case path
    when "/api/users"
      user_id = body["user_id"].to_s
      record  = { "user_id" => user_id, "properties" => body["properties"],
                  "created_at" => Time.now.iso8601, "updated_at" => Time.now.iso8601 }
      $db_mutex.synchronize { $users_db[user_id] = record }
      json_response(res, 201, record)

    when "/api/items"
      item_id = body["item_id"].to_s
      record  = { "item_id" => item_id, "properties" => body["properties"],
                  "created_at" => Time.now.iso8601, "updated_at" => Time.now.iso8601 }
      $db_mutex.synchronize { $items_db[item_id] = record }
      json_response(res, 201, record)

    when "/api/interactions"
      body["interaction_id"] = "ia_#{Time.now.to_f.to_s.delete('.')}"
      body["timestamp"]      = Time.now.iso8601
      $db_mutex.synchronize { $interact_db << body }
      json_response(res, 201, body)

    else
      json_response(res, 404, { "detail" => "Not found" })
    end
  end

  def do_GET(req, res)
    path  = req.path
    query = req.query

    case path
    when /\A\/api\/users\/(.+)\z/
      user_id = $1
      $db_mutex.synchronize do
        u = $users_db[user_id]
        u ? json_response(res, 200, u) :
            json_response(res, 404, { "detail" => "User not found: #{user_id}" })
      end

    when /\A\/api\/items\/(.+)\z/
      item_id = $1
      $db_mutex.synchronize do
        item = $items_db[item_id]
        item ? json_response(res, 200, item) :
               json_response(res, 404, { "detail" => "Item not found: #{item_id}" })
      end

    when "/api/recommendations"
      user_id = query["user_id"].to_s
      limit   = query["limit"].to_i
      limit   = 10 if limit <= 0
      recs    = compute_recommendations(user_id, limit)
      json_response(res, 200, { "user_id" => user_id, "recommendations" => recs })

    else
      json_response(res, 404, { "detail" => "Not found" })
    end
  end

  def do_PUT(req, res)
    path = req.path
    body = JSON.parse(req.body || "{}")

    case path
    when /\A\/api\/users\/(.+)\z/
      user_id = $1
      $db_mutex.synchronize do
        existing = $users_db[user_id]
        unless existing
          json_response(res, 404, { "detail" => "User not found: #{user_id}" }); return
        end
        existing["properties"] = body["properties"]
        existing["updated_at"] = Time.now.iso8601
        json_response(res, 200, existing)
      end

    when /\A\/api\/items\/(.+)\z/
      item_id = $1
      $db_mutex.synchronize do
        existing = $items_db[item_id]
        unless existing
          json_response(res, 404, { "detail" => "Item not found: #{item_id}" }); return
        end
        existing["properties"] = body["properties"]
        existing["updated_at"] = Time.now.iso8601
        json_response(res, 200, existing)
      end

    else
      json_response(res, 404, { "detail" => "Not found" })
    end
  end

  def do_DELETE(req, res)
    path = req.path
    case path
    when /\A\/api\/users\/(.+)\z/
      user_id = $1
      $db_mutex.synchronize do
        unless $users_db.delete(user_id)
          json_response(res, 404, { "detail" => "User not found: #{user_id}" }); return
        end
      end
      res.status = 204
      res.body   = ""

    when /\A\/api\/items\/(.+)\z/
      item_id = $1
      $db_mutex.synchronize do
        unless $items_db.delete(item_id)
          json_response(res, 404, { "detail" => "Item not found: #{item_id}" }); return
        end
      end
      res.status = 204
      res.body   = ""

    else
      json_response(res, 404, { "detail" => "Not found" })
    end
  end

  private

  def json_response(res, status, data)
    res.status      = status
    res.content_type = "application/json"
    res.body        = JSON.generate(data)
  end
end

# ── Start WEBrick server in background thread ─────────────────────────────────

server = WEBrick::HTTPServer.new(
  Port:         MOCK_PORT,
  Logger:       WEBrick::Log.new(File::NULL),
  AccessLog:    []
)
server.mount("/", MockServlet)
server_thread = Thread.new { server.start }
sleep(0.3) # allow server to bind
puts "[mock] Server listening on port #{MOCK_PORT}\n\n"

# ── SDK client ────────────────────────────────────────────────────────────────

client = RecommendAI::Client.new(
  api_key:  "sim-api-key",
  base_url: "http://localhost:#{MOCK_PORT}"
)

def banner(text)
  line = "=" * (text.length + 4)
  puts line
  puts "= #{text} ="
  puts line
  puts
end

def step(n, title)
  puts "── Step #{n}: #{title}"
end

banner("RecSys.AI Ruby SDK — Movie Streaming Simulation")

# Step 1: seed catalogue
step(1, "Seeding Movie Catalogue")
MOVIES.each do |m|
  item = client.items.create(m[:id], properties: {
    "title" => m[:title], "genre" => m[:genre],
    "year"  => m[:year],  "rating" => m[:rating]
  })
  puts "  Created item: #{item.item_id} (#{item.properties["title"]})"
end
puts "  #{MOVIES.size} movies added to catalogue.\n\n"

# Step 2: register users
step(2, "Registering Users")
USERS.each do |u|
  user = client.users.create(u[:id], properties: {
    "name" => u[:name], "age" => u[:age], "preferred_genre" => u[:preferred_genre]
  })
  puts "  Registered: #{user.user_id} (#{user.properties["name"]})"
end
puts "  #{USERS.size} users registered.\n\n"

# Step 3: record interactions
step(3, "Recording Watch History & Ratings")
INTERACTIONS.each do |ia|
  payload = { user_id: ia[:user_id], item_id: ia[:item_id], interaction_type: ia[:type] }
  payload[:value] = ia[:value] if ia[:value]
  client.interactions.create(**payload)
end
puts "  #{INTERACTIONS.size} interactions recorded.\n\n"

# Step 4: personalised recommendations
step(4, "Getting Personalised Recommendations")
USERS.each do |u|
  recs = client.recommendations.get(u[:id], limit: 5)
  puts "  Recommendations for #{u[:id]}:"
  recs.each_with_index do |r, i|
    title = r.metadata&.dig("title") || r.item_id
    puts "    #{i+1}. #{title.ljust(36)} (score: #{"%.4f" % r.score})  #{r.reason}"
  end
  puts
end

# Step 5: update item
step(5, "Updating Item Metadata")
updated = client.items.update("movie_001", properties: {
  "title" => "The Matrix", "genre" => "sci-fi",
  "year"  => 1999, "rating" => 8.7, "remastered" => true
})
puts "  Updated movie_001 — remastered: #{updated.properties["remastered"]}\n\n"

# Step 6: update user
step(6, "Updating User Profile")
alice = client.users.update("alice", properties: {
  "name" => "Alice Johnson", "age" => 29,
  "preferred_genre" => "sci-fi", "subscription" => "premium"
})
puts "  alice subscription → #{alice.properties["subscription"]}\n\n"

# Step 7: verify item
step(7, "Verifying Item Retrieval")
retrieved = client.items.get("movie_004")
puts "  Retrieved: #{retrieved.item_id} — #{retrieved.properties["title"]} (#{retrieved.properties["genre"]})\n\n"

# Step 8: concurrent recommendations
step(8, "Concurrent Recommendations (Threads)")
threads = %w[alice bob carol].map do |uid|
  Thread.new { [uid, client.recommendations.get(uid, limit: 3)] }
end
threads.each do |t|
  uid, recs = t.value
  puts "  #{uid} got #{recs.size} recommendations"
end
puts

# Step 9: error handling
step(9, "Error Handling Demo")
begin
  client.users.get("ghost_999")
  puts "  ERROR: expected NotFoundError was not thrown!"
rescue RecommendAI::NotFoundError => e
  puts "  Caught NotFoundError: #{e.message}\n\n"
end

# Step 10: cleanup
step(10, "Cleanup")
client.users.delete("dave")
puts "  Deleted user 'dave'."
begin
  client.users.get("dave")
rescue RecommendAI::NotFoundError
  puts "  Confirmed: 'dave' no longer exists."
end

puts
banner("Simulation complete — all steps passed!")

server.shutdown
server_thread.join
