# frozen_string_literal: true

require_relative "lib/lite_cable/version"

Gem::Specification.new do |spec|
  spec.name          = "litecable"
  spec.version       = LiteCable::VERSION
  spec.authors       = ["palkan"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "Fat-free ActionCable implementation"
  spec.description   = "Fat-free ActionCable implementation for using with AnyCable (and without Rails)"
  spec.homepage      = "https://github.com/palkan/litecable"
  spec.license       = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/litecable/issues",
    "changelog_uri" => "https://github.com/palkan/litecable/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/litecable",
    "homepage_uri" => "http://github.com/palkan/litecable",
    "source_code_uri" => "http://github.com/palkan/litecable"
  }

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "anyway_config", ">= 1.0"

  spec.add_development_dependency "rack", "~> 2.0"
  spec.add_development_dependency "websocket", "~> 1.2.4"
  spec.add_development_dependency "websocket-client-simple", "~> 0.3.0"
  spec.add_development_dependency "concurrent-ruby", "~> 1.1"
  spec.add_development_dependency "puma", ">= 3.6"

  spec.add_development_dependency "bundler", ">= 1.13"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", ">= 0.3.8"
  spec.add_development_dependency "rubocop", "~> 0.65.0"
  spec.add_development_dependency "rubocop-md", "~> 0.2"
  spec.add_development_dependency "standard", "~> 0.0.36"
  spec.add_development_dependency "pry-byebug"
end
