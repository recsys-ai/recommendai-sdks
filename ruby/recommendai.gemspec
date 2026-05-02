Gem::Specification.new do |spec|
  spec.name          = "recommendai"
  spec.version       = "1.0.0"
  spec.authors       = ["RecSys.AI"]
  spec.summary       = "Official Ruby SDK for the RecSys.AI recommendation platform"
  spec.description   = "Access recommendations, users, items, and interactions via the RecSys.AI API."
  spec.homepage      = "https://recsys-ai.com"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0.0"
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.23"
end
